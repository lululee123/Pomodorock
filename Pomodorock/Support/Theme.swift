import SwiftUI

// MARK: - App Color Palette
extension Color {
    // 主背景
    static let appBackground = Color(
        light: Color(hex: "F7F6F2"),
        dark: Color(hex: "1B1A19")
    )
    // 卡片 / 廢話 / 白底按鈕
    static let appSurface = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "2C2B29")
    )
    // 計時圈進度、主要按鈕 (深淺共用)
    static let appAccent = Color(hex: "D87D4A")
    // 計時圈底軌 / 標籤底色
    static let appRingTrack = Color(
        light: Color(hex: "E8E6DF"),
        dark: Color(hex: "3A3835")
    )
    // 主要文字
    static let appTextPrimary = Color(
        light: Color(hex: "2D3142"),
        dark: Color(hex: "F0EFEA")
    )
    // 次要文字
    static let appTextSecondary = Color(
        light: Color(hex: "6B7C96"),
        dark: Color(hex: "9AA3B0")
    )
}

// MARK: - App Appearance (深淺色偏好)
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    // SwiftUI 用的色彩模式；system 回 nil 表示跟隨系統
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func displayName(_ language: AppLanguage) -> String {
        let en = language == .en
        switch self {
        case .system: return en ? "System" : "系統"
        case .light: return en ? "Light" : "淺色"
        case .dark: return en ? "Dark" : "深色"
        }
    }
}

// MARK: - Timer Configuration
// 專注計時的相關設定
enum TimerConfig {
    static let focusMinutes: Int = 25
    static let focusDuration: TimeInterval = Double(focusMinutes) * 60
}

enum Compeletion {
    static let soudEffectID = 1025
    static let vibrateDuration: Double = 3.0
}
