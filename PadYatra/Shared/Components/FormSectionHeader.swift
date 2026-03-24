// FormSectionHeader.swift
// Section header for Form-based sheets (AddVisitSheet, VisitEditView).
// Replaces the identical private sectionHeader(_:) helpers in both files.
import SwiftUI

struct FormSectionHeader: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.brandTempleGrey)
            .textCase(nil)
    }
}
