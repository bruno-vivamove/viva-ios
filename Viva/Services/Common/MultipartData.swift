import Foundation

struct MultipartData {
    let data: Data
    let name: String
    let fileName: String?
    let mimeType: String?
    
    init(
        data: Data, name: String, fileName: String? = nil,
        mimeType: String? = nil
    ) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
        debugPrint(
            "📦 MultipartData initialized - name: \(name), fileName: \(String(describing: fileName)), mimeType: \(String(describing: mimeType)), size: \(data.count) bytes"
        )
    }
}
