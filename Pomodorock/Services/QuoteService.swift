import Foundation

// MARK: - Localized Quote
struct LocalizedQuote: Sendable {
    let zh: String
    let en: String

    func text(for language: AppLanguage) -> String {
        switch language {
        case .zhHant: return zh.isEmpty ? en : zh
        case .en: return en.isEmpty ? zh : en
        }
    }
}

// MARK: - Quote Service (金句資料來源抽象)
protocol QuoteService: Sendable {
    func fetchQuotes() async throws -> [LocalizedQuote]
}

// MARK: - Local Fallback
struct LocalQuoteService: QuoteService {
    // 《媽的多重宇宙》
    static let defaultQuotes: [LocalizedQuote] = [
        LocalizedQuote(
            zh: "「我沒有感應到宇宙」",
            en: "\"I feel nothing\""
        )
    ]

    func fetchQuotes() async throws -> [LocalizedQuote] {
        LocalQuoteService.defaultQuotes
    }
}
