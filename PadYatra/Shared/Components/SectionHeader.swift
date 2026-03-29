// SectionHeader.swift
// Decorative section header: saffron diamond ornament + earth-brown label + extending rule.
import SwiftUI

struct SectionHeader: View {

    let title: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("◆")
                .font(.system(size: 7, weight: .heavy))
                .foregroundStyle(Color.brandSaffron)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandEarthBrown)
                .textCase(.uppercase)
                .tracking(0.5)

            Rectangle()
                .fill(Color.brandSaffron.opacity(0.3))
                .frame(height: 1)
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(title)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.md) {
        SectionHeader(title: "Jyotirlinga")
        SectionHeader(title: "Temple Facts")
        SectionHeader(title: "Visit History")
    }
    .padding()
    .background(Color.brandWarmCream)
}
