import Foundation

// MARK: - User Profile
// 每個使用者存在 Firestore users/{uid} 的資料
// createdAt 為首次建立時間 (Firestore Timestamp)，用來計算陪伴天數
struct UserProfile: Sendable {
    var createdAt: Date
    var accentHex: String
    var pomodoroMode: Bool
    var languageCode: String
    var appearance: String
    var targetDateEnabled: Bool = false
    var targetDate: Date? = nil
}

// MARK: - User Sync Service (身分 + 雲端偏好同步抽象)
protocol UserSyncService: Sendable {
    // 確保已登入 (需要時匿名登入)，回傳 uid
    func ensureSignedIn() async throws -> String
    func loadProfile(uid: String) async throws -> UserProfile?
    func saveProfile(uid: String, _ profile: UserProfile) async throws
}

// MARK: - Local Fallback
// 無 Firebase 的平台/情境：用本地產生的穩定 id，不做雲端同步
struct LocalUserSyncService: UserSyncService {
    private let uidKey = "com.pomodorock.localUID"

    func ensureSignedIn() async throws -> String {
        if let id = UserDefaults.standard.string(forKey: uidKey) {
            return id
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: uidKey)
        return id
    }

    func loadProfile(uid: String) async throws -> UserProfile? { nil }
    func saveProfile(uid: String, _ profile: UserProfile) async throws {}
}
