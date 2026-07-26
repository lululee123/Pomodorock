import Foundation
import Observation

// MARK: - Quote Store
@MainActor
@Observable
final class QuoteStore {
    private(set) var quotes: [LocalizedQuote]
    private let remoteService: QuoteService?

    init(remoteService: QuoteService? = nil) {
        self.quotes = LocalQuoteService.defaultQuotes
        self.remoteService = remoteService
    }

    // 從遠端載入；失敗就沿用本地 fallback
    func loadRemoteQuotes() async {
        guard let remoteService else { return }
        do {
            let remote = try await remoteService.fetchQuotes()
            if !remote.isEmpty {
                quotes = remote
            }
        } catch {
            print("Load remote quotes failed, keep local fallback: \(error.localizedDescription)")
        }
    }

    func randomQuote(for language: AppLanguage) -> String {
        quotes.randomElement()?.text(for: language) ?? ""
    }
}
