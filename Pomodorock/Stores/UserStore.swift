import Observation
import SwiftUI

// MARK: - User Store
@MainActor
@Observable
final class UserStore {
    static let defaultAccentHex = "D87D4A"

    private(set) var uid: String?
    private(set) var createdAt: Date?

    var accent: Color {
        didSet { onSettingChanged() }
    }
    var pomodoroMode: Bool {
        didSet { onSettingChanged() }
    }
    var language: AppLanguage {
        didSet { onSettingChanged() }
    }
    var appearance: AppAppearance {
        didSet { onSettingChanged() }
    }
    var targetDateEnabled: Bool {
        didSet { onSettingChanged() }
    }
    var targetDate: Date? {
        didSet { onSettingChanged() }
    }

    private let sync: UserSyncService
    private let defaults = UserDefaults.standard
    private var isApplying = false

    private let accentKey = "com.pomodorock.accentHex"
    private let pomodoroKey = "com.pomodorock.pomodoroMode"
    private let languageKey = "com.pomodorock.language"
    private let appearanceKey = "com.pomodorock.appearance"
    private let createdAtKey = "com.pomodorock.createdAt"
    private let targetDateEnabledKey = "com.pomodorock.targetDateEnabled"
    private let targetDateKey = "com.pomodorock.targetDate"

    init(sync: UserSyncService) {
        self.sync = sync

        // 先讀本地快取
        let hex =
            UserDefaults.standard.string(forKey: accentKey)
            ?? UserStore.defaultAccentHex
        self.accent = Color(hex: hex)
        self.pomodoroMode = UserDefaults.standard.bool(forKey: pomodoroKey)
        if let code = UserDefaults.standard.string(forKey: languageKey),
            let lang = AppLanguage(rawValue: code)
        {
            self.language = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            self.language = preferred.hasPrefix("zh") ? .zhHant : .en
        }
        self.appearance =
            AppAppearance(
                rawValue: UserDefaults.standard.string(forKey: appearanceKey)
                    ?? ""
            ) ?? .system
        self.createdAt =
            UserDefaults.standard.object(forKey: createdAtKey) as? Date
        self.targetDateEnabled =
            UserDefaults.standard.bool(forKey: targetDateEnabledKey)
        self.targetDate =
            UserDefaults.standard.object(forKey: targetDateKey) as? Date
    }

    // SwiftUI 用的色彩模式；nil 表示跟隨系統
    var preferredColorScheme: ColorScheme? {
        appearance.colorScheme
    }

    // 從 createdAt 算起的陪伴天數，當天為第 1 天
    var companionDays: Int {
        guard let createdAt else { return 1 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())
        let days =
            calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return days + 1
    }
    // 距目標日還有幾天 (可能為 0 或負數)
    var targetDays: Int {
        guard let targetDate else { return 0 }
        let calendar = Calendar.current
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents(
            [.day],
            from: startOfNow,
            to: startOfTarget
        )
        return components.day ?? 0
    }

    // 在地化字串查詢
    func callAsFunction(_ key: LocKey) -> String {
        key.value(for: language)
    }

    // 啟動：確保匿名登入 → 載入或建立雲端 profile
    func start() async {
        let uid: String
        do {
            uid = try await sync.ensureSignedIn()
        } catch {
            print("[UserStore] ensureSignedIn failed: \(error)")
            return
        }
        self.uid = uid

        do {
            if let profile = try await sync.loadProfile(uid: uid) {
                apply(profile)
            } else {
                // 首次：用目前設定與現在時間建立雲端資料
                let profile = UserProfile(
                    createdAt: Date(),
                    accentHex: accent.hexString ?? UserStore.defaultAccentHex,
                    pomodoroMode: pomodoroMode,
                    languageCode: language.rawValue,
                    appearance: appearance.rawValue,
                    targetDateEnabled: targetDateEnabled,
                    targetDate: targetDate
                )
                createdAt = profile.createdAt
                persistLocal()
                try await sync.saveProfile(uid: uid, profile)
            }
        } catch {
            print("[UserStore] load/save profile failed: \(error)")
        }
    }

    func resetAccent() {
        accent = Color(hex: UserStore.defaultAccentHex)
    }

    // 套用雲端載入的資料 (期間不觸發回寫)
    private func apply(_ profile: UserProfile) {
        isApplying = true
        createdAt = profile.createdAt
        accent = Color(hex: profile.accentHex)
        pomodoroMode = profile.pomodoroMode
        if let lang = AppLanguage(rawValue: profile.languageCode) {
            language = lang
        }
        if let mode = AppAppearance(rawValue: profile.appearance) {
            appearance = mode
        }
        targetDateEnabled = profile.targetDateEnabled
        targetDate = profile.targetDate
        isApplying = false
        persistLocal()
    }

    // 任一設定變更：更新本地快取並回寫雲端
    private func onSettingChanged() {
        guard !isApplying else { return }
        persistLocal()

        guard let uid, let createdAt else { return }
        let profile = UserProfile(
            createdAt: createdAt,
            accentHex: accent.hexString ?? UserStore.defaultAccentHex,
            pomodoroMode: pomodoroMode,
            languageCode: language.rawValue,
            appearance: appearance.rawValue,
            targetDateEnabled: targetDateEnabled,
            targetDate: targetDate
        )
        Task { try? await sync.saveProfile(uid: uid, profile) }
    }

    private func persistLocal() {
        defaults.set(accent.hexString, forKey: accentKey)
        defaults.set(pomodoroMode, forKey: pomodoroKey)
        defaults.set(language.rawValue, forKey: languageKey)
        defaults.set(appearance.rawValue, forKey: appearanceKey)
        if let createdAt {
            defaults.set(createdAt, forKey: createdAtKey)
        }
        defaults.set(targetDateEnabled, forKey: targetDateEnabledKey)
        if let targetDate {
            defaults.set(targetDate, forKey: targetDateKey)
        } else {
            defaults.removeObject(forKey: targetDateKey)
        }
    }
}
