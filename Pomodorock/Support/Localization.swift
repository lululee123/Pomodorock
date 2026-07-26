import Foundation

// MARK: - App Language
enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHant = "zh-Hant"
    case en = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHant: return "繁體中文"
        case .en: return "English"
        }
    }
}

// MARK: - Localized Keys
enum LocKey {
    case settings
    case signOut
    case rockThemeColor
    case pomodoroMode
    case startFocus
    case pause
    case focusingSubtitle
    case focusCompleted
    case language
    case appearance
    case done
    case targetDate
    case setTargetDate
    case targetReached
    case companionDays(Int)
    case targetDays(Int)

    func value(for lang: AppLanguage) -> String {
        let en = lang == .en
        switch self {
        case .settings:
            return en ? "Settings" : "設定"
        case .signOut:
            return en ? "Sign out" : "登出"
        case .rockThemeColor:
            return en ? "Rock theme" : "石頭主題色"
        case .pomodoroMode:
            return en ? "Pomodoro" : "Pomodoro"
        case .startFocus:
            return en ? "Start" : "開始專注"
        case .pause:
            return en ? "Pause" : "暫停"
        case .focusingSubtitle:
            return en
                ? "The Rock acknowledges your concentration"
                : "「石頭正凝視著你的專注...」"
        case .focusCompleted:
            return en
                ? "🎉 Congratulations! The rock is so proud of you! 🎉 "
                : "🎉 專注完成！石頭為你感到無比驕傲！ 🎉 "
        case .language:
            return en ? "Language" : "語言"
        case .appearance:
            return en ? "Appearance" : "外觀"
        case .done:
            return en ? "Done" : "完成"
        case .targetDate:
            return en ? "Target date" : "目標日期"
        case .setTargetDate:
            return en ? "Set target" : "設定目標日"
        case .targetReached:
            return en ? "Reached 🎉" : "已達成 🎉"
        case .companionDays(let days):
            return en ? "\(days) Day of Not Moving" : "沒動彈第 \(days) 天"
        case .targetDays(let days):
            return en ? "\(days) Days of Staring Left" : "再盯你 \(days) 天"
        }
    }
}
