# PadYatra iOS App — Engineering Rules

## ROLE

You are a senior iOS engineer building a production-quality SwiftUI app.
All code must be scalable, maintainable, testable, and safe for long-term data evolution.

---

# 🧠 SYSTEM DESIGN RULES

## Data Architecture

* Use a strict two-layer system:
  * Static data (JSON): temples, categories, achievements
  * Mutable data (SwiftData): visits, UI state
* Never mix static and mutable models
* Never duplicate data across layers

## Stable Identity

* Every entity must have a stable, opaque ID (e.g. `t_kedarnath`)
* IDs must NEVER be derived from names, slugs, or location
* Slugs are for display only and may change
* Support `legacyIDs` for migration

## Relationships

* All relationships must be ID-based
* Do NOT embed or duplicate objects
* A temple can belong to multiple categories

## Derived vs Stored Data

* Completion state must always be derived
* Only persist data that cannot be recomputed
* Example:
  * ✅ Store: `hasBeenRevealed`
  * ❌ Do NOT store: `isCompleted`

---

# 🧩 ARCHITECTURE RULES

## MVVM

* Views must be presentation-only
* Business logic belongs in ViewModels or Services

## Service Layer

* All non-trivial logic must live in services
* Services must be reusable, testable, and focused (no "god services")

## Dependency Injection

* Do not instantiate services inside views
* Inject dependencies via initializers or environment

---

# ♻️ DRY (DON'T REPEAT YOURSELF)

## Core Rule

* Every piece of logic must have a single source of truth
* If logic appears more than once, it must be extracted

## UI DRY

* Do not duplicate layouts across views
* Extract reusable components (rows, cards, chips, badges)
* Reuse styling via modifiers or shared components

## Logic DRY

* Do not duplicate filtering, sorting, or business logic
* Centralize logic in services or helpers
* Use extensions for reusable transformations

## Data DRY

* Do not duplicate data across models
* Use IDs instead of copying objects

---

# 📁 FILE SIZE & STRUCTURE RULES

## File Size Limits

* No file should exceed ~300 lines
* Preferred range: 100–250 lines
* If a file grows too large, split it immediately

## View Rules

* One primary view per file
* Extract subviews if:
  * reusable OR
  * exceed ~50 lines

## ViewModel Rules

* One ViewModel per feature
* Move complex logic into services

## Service Rules

* Each service must have a single responsibility

## Extensions

* Keep extensions small and focused
* Do not create large "utility dump" files

---

# 🎨 DESIGN SYSTEM & TOKENS

## Design Tokens

* All colors must come from a centralized theme
* Do NOT hardcode colors in views

## Semantic Naming

* Use semantic names:
  * `primaryBackground`
  * `achievementLocked`
  * `visitedBadge`

## Typography & Spacing

* Use Dynamic Type
* Avoid fixed font sizes
* Use consistent spacing system

## Accessibility

* Support light/dark mode
* Ensure sufficient contrast
* Never rely on color alone

---

# ⚡ PERFORMANCE RULES

## Data Access

* Use cached sets/dictionaries:
  * `visitedTempleIDs: Set<String>`
  * `templeIndex: [String: Temple]`
  * `templesByCategory: [String: [Temple]]`

## Filtering & Sorting

* Must NOT be done inside SwiftUI views
* Must live in ViewModels or Services

---

# 🧪 TESTING RULES (STRICT)

## Core Principle

* All business logic must be covered by unit tests
* Code is NOT complete without tests

## Required Coverage

### Data Integrity
* ID migration (legacyIDs → new IDs)
* JSON validation (duplicates, broken references)
* Decoding with missing/extra fields

### Business Logic
* Visit tracking (multiple visits, visited state)
* Category completion (including overlapping categories)
* Achievement unlock logic

### Persistence
* Visits persist across launches
* No data loss after JSON updates or migrations

### Remote Data
* Higher version replaces local
* Invalid remote data falls back safely
* Offline mode uses cached data

### Edge Cases
* Missing references
* Duplicate visits
* Empty datasets
* Partial completion

## Test Rules

* Use XCTest
* Tests must be deterministic and isolated
* Use mock data (no real network calls)

## Execution Requirement

* All tests must compile and pass before completion
* Fix failures before returning code

## Anti-Patterns

* ❌ Writing logic without tests
* ❌ Weak tests (only happy path)
* ❌ Ignoring edge cases
* ❌ Commenting out failing tests

---

# 🔄 DATA VALIDATION & MIGRATION

## Validation

* Validate JSON before use:
  * no duplicate IDs
  * valid references
* DEBUG: fail fast (`assert`)
* RELEASE: log and recover (`Logger`)

## Migration

* Handle versioned updates
* Support legacy ID remapping
* Never lose user data
* Run migration when: version changed OR remote JSON replaced local cache

---

# ☁️ PERSISTENCE & SYNC

## SwiftData

* Store only IDs for relationships
* All properties must be optional or have defaults (CloudKit requirement)
* Avoid `@Attribute(.unique)` on fields synced via CloudKit — enforce uniqueness manually via fetch-before-insert

## CloudKit Merge Rules

* App must be offline-first
* Implement merge strategies:
  * Arrays → union (deduplicated)
  * Timestamps → latest wins (use `lastEditedAt`)
  * Boolean flags → `true` wins (monotonic)

---

# ❗ ERROR HANDLING

## No Print Statements

* NEVER use `print()` for debugging or errors

## Error Modeling

* Use typed error enums
* Use `throws` or `Result`

## Logging

* Use structured logging (`Logger` from `os.log`)
* Include context in log messages

## Failure Strategy

* DEBUG: crash early (`assert`, `fatalError`)
* RELEASE: fail gracefully (log + recover)

---

# 🧱 CODE QUALITY

* Write clear, readable Swift code
* Avoid force unwrapping (`!`)
* Use meaningful names
* Prefer composition over inheritance
* Mark `final` on classes that are not subclassed

---

# 🗺️ MAP & LOCATION

* Use MapKit; `UIViewRepresentable` wrapping `MKMapView` is justified only for clustering
* Request location only after user action (tapping "Near Me")
* Provide graceful fallback (By State sort) if location denied
* Never request background location in v1

---

# 🏆 ACHIEVEMENTS

* Completion must always be derived — never stored
* A temple can belong to multiple categories
* Unlock logic must be centralized in `AchievementService`
* Only persist `hasBeenRevealed` state (in `AchievementReveal`)

---

# 📦 DATA LOADING

* JSON must be loaded through a single service (`TempleDataService`)
* Do not access JSON directly from views or ViewModels
* Build O(1) indices after loading (`templeIndex`, `templesByCategory`, `templesByState`)
* Validate JSON before vending any data to the UI

---

# 📱 AI OUTPUT RULES

* Always return complete, runnable code
* Respect file size limits (~300 lines max)
* Follow DRY principles strictly
* Do not create monolithic files
* Preserve architecture and rules
* Every piece of business logic must have a corresponding test

---

# 🚫 ANTI-PATTERNS

* ❌ Duplicating logic or UI
* ❌ Large monolithic files (>300 lines)
* ❌ Business logic in views
* ❌ Hardcoded colors, spacing, or strings in views
* ❌ Using array index as identity
* ❌ Storing derived state (e.g. `isCompleted`)
* ❌ Using `print()` for errors or debugging
* ❌ Ignoring migration/versioning
* ❌ Force unwrapping (`!`) without a comment explaining why it's safe
* ❌ `@Attribute(.unique)` on CloudKit-synced fields
* ❌ Writing code without tests
