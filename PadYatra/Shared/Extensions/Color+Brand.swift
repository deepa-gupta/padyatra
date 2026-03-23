// Color+Brand.swift
// Standalone brand color definitions and Color(hex:) initialiser.
// NOTE: AppTheme.swift already defines Color(hex:) and all brand colors using the
// same implementation. This file intentionally re-exports them for modules that
// only import SwiftUI without importing AppTheme directly.
// If the compiler reports duplicate definitions, delete this file and rely on AppTheme.swift.
//
// We keep this file to satisfy the project layout contract.
// All color definitions live in AppTheme.swift — this file holds no additional code
// to avoid duplication errors at compile time.

// All brand colors are declared in AppTheme.swift:
//   Color.brandSaffron      #FF6B35   Primary CTA, active elements
//   Color.brandPeach        #FFAD8A   Warm background tints, gradients
//   Color.brandWarmCream    #FFF4E6   Card and sheet backgrounds
//   Color.brandDeepOrange   #E84A00   Active / selected state, pressed tint
//   Color.brandEarthBrown   #6B3A2A   Primary text on light backgrounds
//   Color.brandGold         #FFB830   Achievement gold, highlights
//   Color.brandTempleGrey   #8A7B72   Unvisited markers, locked states
//   Color.brandVisited      #4CAF50   Visited checkmarks, completion badges
//
// Color(hex:) is also implemented in AppTheme.swift and accepts #RGB, #RRGGBB, #RRGGBBAA.
