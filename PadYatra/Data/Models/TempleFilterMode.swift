// TempleFilterMode.swift
// Shared filter/sort mode used by both the temple list and the map.
// The filter predicate (which temples to include) lives in TempleDataService.applyFilter.
import Foundation

enum TempleFilterMode: String, CaseIterable, Sendable {
    case all        = "All"
    case nearMe     = "Near Me"
    case byCategory = "By Category"
    case visited    = "Visited"
    case notVisited = "Not Visited"
}
