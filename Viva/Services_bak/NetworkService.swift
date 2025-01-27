import Foundation

// First define the common error types
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed
    case unauthorized
    case noInternet
    case serverError(Int)
    case rateLimited
}

// Protocol for dependency injection and testing
protocol NetworkServicing {
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func post<T: Decodable>(_ endpoint: Endpoint, body: Encodable) async throws -> T
    func upload(_ endpoint: Endpoint, data: Data, mimeType: String) async throws -> UploadResponse
    func download(_ endpoint: Endpoint) async throws -> Data
}

// Endpoint type for clean URL construction
struct Endpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem]?
    var headers: [String: String]?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    static func user(id: String) -> Endpoint {
        Endpoint(path: "/users/\(id)", method: .get)
    }
    
    static func updateUser(id: String) -> Endpoint {
        Endpoint(path: "/users/\(id)", method: .put)
    }
}

class NetworkService: NetworkServicing {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(baseURL: URL = URL(string: "https://api.yourapp.com")!,
         session: URLSession = .shared,
         decoder: JSONDecoder = JSONDecoder(),
         encoder: JSONEncoder = JSONEncoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        
        // Configure decoders
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Main Network Methods
    
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try createRequest(for: endpoint)
        return try await performRequest(request)
    }
    
    func post<T: Decodable>(_ endpoint: Endpoint, body: Encodable) async throws -> T {
        var request = try createRequest(for: endpoint)
        request.httpBody = try encoder.encode(body)
        return try await performRequest(request)
    }
    
    func upload(_ endpoint: Endpoint, data: Data, mimeType: String) async throws -> UploadResponse {
        var request = try createRequest(for: endpoint)
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let formData = createMultipartFormData(data: data, boundary: boundary, mimeType: mimeType)
        request.httpBody = formData
        
        return try await performRequest(request)
    }
    
    func download(_ endpoint: Endpoint) async throws -> Data {
        let request = try createRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return data
    }
    
    // MARK: - Helper Methods
    
    private func createRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        components?.queryItems = endpoint.queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
                         forHTTPHeaderField: "X-App-Version")
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            return try decoder.decode(T.self, from: data)
        } catch is DecodingError {
            throw NetworkError.decodingFailed
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - Retry Logic
    
    private func performRequestWithRetry<T: Decodable>(_ request: URLRequest,
                                                       retries: Int = 3) async throws -> T {
        do {
            return try await performRequest(request)
        } catch NetworkError.rateLimited where retries > 0 {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            return try await performRequestWithRetry(request, retries: retries - 1)
        } catch {
            throw error
        }
    }
     
    private func createMultipartFormData(data: Data, boundary: String, mimeType: String, fieldName: String = "file", fileName: String = "file") -> Data {
        var formData = Data()
        
        // Add boundary prefix
        formData.append("--\(boundary)\r\n")
        
        // Add content disposition
        formData.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        
        // Add content type
        formData.append("Content-Type: \(mimeType)\r\n\r\n")
        
        // Add file data
        formData.append(data)
        
        // Add final boundary
        formData.append("\r\n--\(boundary)--\r\n")
        
        return formData
    }
}

// Helper extension to make it easier to append strings to Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// Convenience methods for common operations
extension NetworkService {
    func fetchWithProgress(_ endpoint: Endpoint,
                          progress: @escaping (Double) -> Void) async throws -> Data {
        let request = try createRequest(for: endpoint)
        let (bytes, response) = try await session.bytes(for: request)
        
        let expectedLength = Double(response.expectedContentLength)
        var currentLength = 0.0
        
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            currentLength += 1
            progress(currentLength / expectedLength)
        }
        
        return data
    }
    
    // Cancellable requests
    func fetchCancellable<T: Decodable>(_ endpoint: Endpoint) -> Task<T, Error> {
        Task {
            try await fetch(endpoint)
        }
    }
}

struct UploadResponse: Decodable {
    let fileId: String
    let url: URL
    let mimeType: String
    let size: Int
    let filename: String
    let status: UploadStatus
    
    enum UploadStatus: String, Decodable {
        case completed
        case processing
        case failed
    }
}

// Example usage:
class UserService_bak {
    private let network: NetworkServicing
    
    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }
    
    func fetchUser(id: String) async throws -> User {
        try await network.fetch(Endpoint.user(id: id))
    }
    
    func updateUser(_ user: User) async throws -> User {
        try await network.post(Endpoint.updateUser(id: user.id), body: user)
    }
}


// Usage example:
class ImageUploader {
    let networkService: NetworkServicing
    
    init(networkService: NetworkServicing) {
        self.networkService = networkService
    }
    
    func uploadImage(_ imageData: Data) async throws -> UploadResponse {
        let endpoint = Endpoint(
            path: "/upload/image",
            method: .post
        )
        
        return try await networkService.upload(
            endpoint,
            data: imageData,
            mimeType: "image/jpeg"
        )
    }
}

// Mock for testing
class MockNetworkService: NetworkServicing {
    var mockResult: Any?
    var error: Error?
    var requestLog: [String] = []  // Track which endpoints were called
    
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        requestLog.append("GET: \(endpoint.path)")
        
        if let error = error {
            throw error
        }
        
        guard let result = mockResult as? T else {
            throw NetworkError.decodingFailed
        }
        
        return result
    }
    
    func post<T: Decodable>(_ endpoint: Endpoint, body: Encodable) async throws -> T {
        requestLog.append("POST: \(endpoint.path)")
        
        if let error = error {
            throw error
        }
        
        guard let result = mockResult as? T else {
            throw NetworkError.decodingFailed
        }
        
        return result
    }
    
    func upload(_ endpoint: Endpoint, data: Data, mimeType: String) async throws -> UploadResponse {
        requestLog.append("UPLOAD: \(endpoint.path)")
        
        if let error = error {
            throw error
        }
        
        guard let result = mockResult as? UploadResponse else {
            throw NetworkError.decodingFailed
        }
        
        return result
    }
    
    func download(_ endpoint: Endpoint) async throws -> Data {
        requestLog.append("DOWNLOAD: \(endpoint.path)")
        
        if let error = error {
            throw error
        }
        
        guard let result = mockResult as? Data else {
            throw NetworkError.decodingFailed
        }
        
        return result
    }
    
    // Helper methods for testing
    func reset() {
        mockResult = nil
        error = nil
        requestLog.removeAll()
    }
    
    func setMockResponse<T>(_ response: T) {
        mockResult = response
    }
    
    func setMockError(_ mockError: Error) {
        error = mockError
    }
}


