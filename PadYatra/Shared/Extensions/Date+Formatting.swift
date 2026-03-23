// Date+Formatting.swift
// Convenience display strings for dates shown in the Pad Yatra UI.
// All formatters are lazily cached via static properties to avoid repeated allocation.
import Foundation

extension Date {

    // MARK: - Cached Formatters

    private static let shortVisitFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"  // e.g. "15 Mar 2026"
        f.locale = Locale(identifier: "en_IN")
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"        // e.g. "2026"
        f.locale = Locale(identifier: "en_IN")
        return f
    }()

    private static let monthNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"        // e.g. "March"
        f.locale = Locale(identifier: "en_IN")
        return f
    }()

    // MARK: - Public API

    /// Human-readable visit date: "15 Mar 2026"
    var shortVisitDisplay: String {
        Date.shortVisitFormatter.string(from: self)
    }

    /// Four-digit year: "2026"
    var yearDisplay: String {
        Date.yearFormatter.string(from: self)
    }

    /// Full month name: "March"
    var monthNameDisplay: String {
        Date.monthNameFormatter.string(from: self)
    }
}
