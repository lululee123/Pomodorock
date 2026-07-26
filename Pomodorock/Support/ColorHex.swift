import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

// MARK: - Helper Extensions (Hex Color)
extension Color {
    // 依系統深/淺色自動切換的動態顏色
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
            self = Color(
                UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(dark) : UIColor(light)
                }
            )
        #elseif canImport(AppKit)
            self = Color(
                nsColor: NSColor(name: nil) { appearance in
                    let isDark =
                        appearance.bestMatch(from: [.aqua, .darkAqua])
                        == .darkAqua
                    return isDark ? NSColor(dark) : NSColor(light)
                }
            )
        #else
            self = light
        #endif
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (
                255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
            )
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (
                int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF
            )
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // 轉成 6 碼 RGB hex（不含 alpha），用來持久化使用者選的顏色
    var hexString: String? {
        #if canImport(UIKit)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
                return nil
            }
        #elseif canImport(AppKit)
            guard let ns = NSColor(self).usingColorSpace(.sRGB) else {
                return nil
            }
            let r = ns.redComponent
            let g = ns.greenComponent
            let b = ns.blueComponent
        #else
            return nil
        #endif
        return String(
            format: "%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}
