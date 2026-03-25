// SearchHistoryService.swift
// Persists the last 5 unique search queries to UserDefaults.
import Foundation

// MARK: - SearchHistoryService

final class SearchHistoryService: ObservableObject {

    @Published private(set) var queries: [String] = []

    private let key = "pd_searchHistory"
    private let maxCount = 5

    init() {
        queries = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// Records a search query. Deduplicates, inserts at front, trims to maxCount.
    func record(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = queries.filter { $0.lowercased() != trimmed.lowercased() }
        updated.insert(trimmed, at: 0)
        queries = Array(updated.prefix(maxCount))
        UserDefaults.standard.set(queries, forKey: key)
    }

    /// Clears all saved searches.
    func clear() {
        queries = []
        UserDefaults.standard.removeObject(forKey: key)
    }
}
