#if canImport(FirebaseFirestore)
    import FirebaseFirestore
    import Foundation

    // MARK: - Firestore Quote Service
    struct FirestoreQuoteService: QuoteService {
        private let collectionName = "quotes"

        func fetchQuotes() async throws -> [LocalizedQuote] {
            let snapshot = try await Firestore.firestore()
                .collection(collectionName)
                .whereField("enabled", isEqualTo: true)
                .getDocuments()

            return snapshot.documents.compactMap { document in
                let data = document.data()
                let zh = data["zh"] as? String ?? ""
                let en = data["en"] as? String ?? ""
                guard !zh.isEmpty || !en.isEmpty else { return nil }
                return LocalizedQuote(zh: zh, en: en)
            }
        }
    }
#endif
