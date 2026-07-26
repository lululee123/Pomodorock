#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
    import FirebaseAuth
    import FirebaseFirestore
    import Foundation

    // MARK: - Firebase User Sync Service
    struct FirebaseUserSyncService: UserSyncService {
        private let collectionName = "users"

        func ensureSignedIn() async throws -> String {
            if let user = Auth.auth().currentUser {
                return user.uid
            }
            let result = try await Auth.auth().signInAnonymously()
            return result.user.uid
        }

        func loadProfile(uid: String) async throws -> UserProfile? {
            let snapshot = try await Firestore.firestore()
                .collection(collectionName)
                .document(uid)
                .getDocument()

            guard snapshot.exists, let data = snapshot.data() else {
                return nil
            }

            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            return UserProfile(
                createdAt: createdAt,
                accentHex: data["accentHex"] as? String
                    ?? UserStore.defaultAccentHex,
                pomodoroMode: data["pomodoroMode"] as? Bool ?? false,
                languageCode: data["language"] as? String
                    ?? AppLanguage.zhHant.rawValue,
                appearance: data["appearance"] as? String
                    ?? AppAppearance.system.rawValue,
                targetDateEnabled: data["targetDateEnabled"] as? Bool ?? false,
                targetDate: (data["targetDate"] as? Timestamp)?.dateValue()
            )
        }

        func saveProfile(uid: String, _ profile: UserProfile) async throws {
            var data: [String: Any] = [
                "createdAt": Timestamp(date: profile.createdAt),
                "accentHex": profile.accentHex,
                "pomodoroMode": profile.pomodoroMode,
                "language": profile.languageCode,
                "appearance": profile.appearance,
                "targetDateEnabled": profile.targetDateEnabled,
            ]
            // 有目標日就存 Timestamp，沒有就從文件移除
            if let targetDate = profile.targetDate {
                data["targetDate"] = Timestamp(date: targetDate)
            } else {
                data["targetDate"] = FieldValue.delete()
            }

            try await Firestore.firestore()
                .collection(collectionName)
                .document(uid)
                .setData(data, merge: true)
        }
    }
#endif
