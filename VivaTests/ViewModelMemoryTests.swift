import XCTest
import Combine
@testable import Viva

/// Tests to ensure ViewModels are properly deallocated and don't have memory leaks
/// These tests verify the fixes from the ViewModel anti-pattern audit
class ViewModelMemoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing state
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up after tests
    }
    
    // MARK: - ProfileViewModel Memory Tests
    
    func testProfileViewModelDeallocation() async {
        await assertViewModelDeallocation {
            ProfileViewModel(
                userId: "test-user-123",
                userSession: MockUserSession(),
                userService: MockServices.createMockUserService(),
                matchupService: MockServices.createMockMatchupService()
            )
        }
    }
    
    func testProfileViewModelWithAsyncOperations() async {
        await assertViewModelDeallocation(
            createViewModel: {
                ProfileViewModel(
                    userId: "test-user-123",
                    userSession: MockUserSession(),
                    userService: MockServices.createMockUserService(),
                    matchupService: MockServices.createMockMatchupService()
                )
            },
            performAsyncOperations: { viewModel in
                // Simulate async operations that might cause retain cycles
                await viewModel.loadInitialDataIfNeeded()
                
                // Wait a bit to ensure any async operations complete
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        )
    }
    
    func testProfileViewModelNoRetainCycles() {
        assertNoRetainCycles {
            ProfileViewModel(
                userId: "test-user-\(UUID().uuidString)",
                userSession: MockUserSession(),
                userService: MockServices.createMockUserService(),
                matchupService: MockServices.createMockMatchupService()
            )
        }
    }
    
    // MARK: - MatchupDetailViewModel Memory Tests
    
    func testMatchupDetailViewModelDeallocation() async {
        await assertViewModelDeallocation {
            MatchupDetailViewModel(
                matchupId: "test-matchup-123",
                matchupService: MockServices.createMockMatchupService(),
                userMeasurementService: MockUserMeasurementService(),
                friendService: MockFriendService(),
                userService: MockServices.createMockUserService(),
                userSession: MockUserSession(),
                healthKitDataManager: MockHealthKitDataManager()
            )
        }
    }
    
    func testMatchupDetailViewModelWithDataLoading() async {
        await assertViewModelDeallocation(
            createViewModel: {
                MatchupDetailViewModel(
                    matchupId: "test-matchup-123",
                    matchupService: MockServices.createMockMatchupService(),
                    userMeasurementService: MockUserMeasurementService(),
                    friendService: MockFriendService(),
                    userService: MockServices.createMockUserService(),
                    userSession: MockUserSession(),
                    healthKitDataManager: MockHealthKitDataManager()
                )
            },
            performAsyncOperations: { viewModel in
                // Test async operations don't cause memory leaks
                await viewModel.loadInitialDataIfNeeded()
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
        )
    }
    
    // MARK: - MatchupCardViewModel Memory Tests
    
    func testMatchupCardViewModelDeallocation() async {
        await assertViewModelDeallocation {
            MatchupCardViewModel(
                matchupId: "test-matchup-123",
                matchupService: MockServices.createMockMatchupService(),
                userMeasurementService: MockUserMeasurementService(),
                healthKitDataManager: MockHealthKitDataManager(),
                userSession: MockUserSession(),
                lastRefreshTime: Date()
            )
        }
    }
    
    func testMatchupCardViewModelMultipleInstances() {
        // Test that multiple instances don't interfere with each other's deallocation
        assertNoRetainCycles(iterations: 5) {
            MatchupCardViewModel(
                matchupId: "test-matchup-\(UUID().uuidString)",
                matchupService: MockServices.createMockMatchupService(),
                userMeasurementService: MockUserMeasurementService(),
                healthKitDataManager: MockHealthKitDataManager(),
                userSession: MockUserSession(),
                lastRefreshTime: Date()
            )
        }
    }
    
    // MARK: - HomeViewModel Memory Tests
    
    func testHomeViewModelDeallocation() async {
        await assertViewModelDeallocation {
            HomeViewModel(
                userSession: MockUserSession(),
                matchupService: MockServices.createMockMatchupService()
            )
        }
    }
    
    // MARK: - FriendsViewModel Memory Tests
    
    func testFriendsViewModelDeallocation() async {
        await assertViewModelDeallocation {
            FriendsViewModel(
                friendService: MockFriendService(),
                userService: MockServices.createMockUserService(),
                matchupService: MockServices.createMockMatchupService(),
                userSession: MockUserSession()
            )
        }
    }
    
    // MARK: - MatchupHistoryViewModel Memory Tests
    
    func testMatchupHistoryViewModelDeallocation() async {
        await assertViewModelDeallocation {
            MatchupHistoryViewModel(
                statsService: MockStatsService(),
                matchupService: MockServices.createMockMatchupService()
            )
        }
    }
    
    // MARK: - Notification Observer Tests
    
    func testViewModelNotificationObserverCleanup() async {
        let wasDeallOcated = await MemoryTestingUtils.testNotificationObserverCleanup(
            createViewModel: {
                ProfileViewModel(
                    userId: "test-user-123",
                    userSession: MockUserSession(),
                    userService: MockServices.createMockUserService(),
                    matchupService: MockServices.createMockMatchupService()
                )
            },
            triggerNotifications: {
                // Trigger notifications that the ViewModel might observe
                NotificationCenter.default.post(
                    name: .healthDataUpdated,
                    object: nil
                )
                NotificationCenter.default.post(
                    name: .userSessionChanged,
                    object: nil
                )
            }
        )
        
        XCTAssertTrue(wasDeallOcated, "ViewModel should be deallocated and observers cleaned up")
    }
    
    // MARK: - Memory Performance Tests
    
    func testProfileViewModelMemoryPerformance() async {
        await measureViewModelMemoryPerformance(
            name: "ProfileViewModel Memory Usage",
            createViewModel: {
                ProfileViewModel(
                    userId: "test-user-123",
                    userSession: MockUserSession(),
                    userService: MockServices.createMockUserService(),
                    matchupService: MockServices.createMockMatchupService()
                )
            },
            operation: { viewModel in
                await viewModel.loadInitialDataIfNeeded()
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        )
    }
    
    func testMatchupDetailViewModelMemoryPerformance() async {
        await measureViewModelMemoryPerformance(
            name: "MatchupDetailViewModel Memory Usage",
            createViewModel: {
                MatchupDetailViewModel(
                    matchupId: "test-matchup-123",
                    matchupService: MockServices.createMockMatchupService(),
                    userMeasurementService: MockUserMeasurementService(),
                    friendService: MockFriendService(),
                    userService: MockServices.createMockUserService(),
                    userSession: MockUserSession(),
                    healthKitDataManager: MockHealthKitDataManager()
                )
            },
            operation: { viewModel in
                await viewModel.loadInitialDataIfNeeded()
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        )
    }
    
    // MARK: - Stress Tests
    
    func testMultipleViewModelCreationAndDestruction() async {
        // Test creating and destroying many ViewModels rapidly
        // This simulates heavy navigation usage that could expose memory leaks
        
        let iterations = 20
        var completedIterations = 0
        
        for i in 0..<iterations {
            await autoreleasepool {
                let profileViewModel = ProfileViewModel(
                    userId: "test-user-\(i)",
                    userSession: MockUserSession(),
                    userService: MockServices.createMockUserService(),
                    matchupService: MockServices.createMockMatchupService()
                )
                
                let matchupDetailViewModel = MatchupDetailViewModel(
                    matchupId: "test-matchup-\(i)",
                    matchupService: MockServices.createMockMatchupService(),
                    userMeasurementService: MockUserMeasurementService(),
                    friendService: MockFriendService(),
                    userService: MockServices.createMockUserService(),
                    userSession: MockUserSession(),
                    healthKitDataManager: MockHealthKitDataManager()
                )
                
                // Simulate some usage
                await profileViewModel.loadInitialDataIfNeeded()
                await matchupDetailViewModel.loadInitialDataIfNeeded()
                
                completedIterations += 1
            }
            
            // Small delay between iterations
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        XCTAssertEqual(completedIterations, iterations, "All iterations should complete without crashes")
        
        // Force cleanup and wait
        await autoreleasepool { }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // If we get here without crashes, the test passed
        XCTAssertTrue(true, "Stress test completed successfully")
    }
}

// MARK: - Mock Services for Testing

private class MockUserMeasurementService: UserMeasurementService {
    init() {
        super.init(
            networkClient: NetworkClient(
                settings: NetworkClientSettings(baseURL: "https://mock.api"),
                tokenRefreshHandler: nil
            )
        )
    }
}

private class MockFriendService: FriendService {
    init() {
        super.init(
            networkClient: NetworkClient(
                settings: NetworkClientSettings(baseURL: "https://mock.api"),
                tokenRefreshHandler: nil
            ),
            tokenRefreshHandler: MockTokenRefreshHandler()
        )
    }
}

private class MockStatsService: StatsService {
    init() {
        super.init(
            networkClient: NetworkClient(
                settings: NetworkClientSettings(baseURL: "https://mock.api"),
                tokenRefreshHandler: nil
            )
        )
    }
}

private class MockHealthKitDataManager: HealthKitDataManager {
    init() {
        // Initialize with mock implementation
        super.init()
    }
}

// MARK: - Test Notification Names

extension Notification.Name {
    static let healthDataUpdated = Notification.Name("healthDataUpdated")
    static let userSessionChanged = Notification.Name("userSessionChanged")
}