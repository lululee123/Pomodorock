import AuthenticationServices
import Foundation
import Observation

// MARK: - Model

// 登入來源，之後要加 Google 直接擴充這裡
enum AuthProvider: String, Codable {
    case apple
}

// 成功登入後保存的使用者資訊
struct UserSession: Codable, Equatable {
    let userID: String
    let provider: AuthProvider
    let displayName: String?
}

// MARK: - Session Store (可抽換的儲存介面)
// 預設用本地 UserDefaults
protocol SessionStore: Sendable {
    func load() -> UserSession?
    func save(_ session: UserSession)
    func clear()
}

// 本地儲存實作
struct UserDefaultsSessionStore: SessionStore {
    private let key = "com.pomodorock.userSession"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserSession? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    func save(_ session: UserSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Auth Manager

@MainActor
@Observable
final class AuthManager {
    private(set) var session: UserSession?
    private let store: SessionStore

    init(store: SessionStore = UserDefaultsSessionStore()) {
        self.store = store
        self.session = store.load()
    }

    var isSignedIn: Bool {
        session != nil
    }

    // 設定 Sign in with Apple 要求的授權範圍
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName]
    }

    // 處理 Sign in with Apple 的回傳結果
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential
                    as? ASAuthorizationAppleIDCredential
            else { return }

            let name = [
                credential.fullName?.givenName,
                credential.fullName?.familyName,
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            let session = UserSession(
                userID: credential.user,
                provider: .apple,
                displayName: name.isEmpty ? nil : name
            )
            self.session = session
            store.save(session)

        case .failure(let error):
            print("Apple sign-in failed: \(error.localizedDescription)")
        }
    }

    func signOut() {
        session = nil
        store.clear()
    }
}
