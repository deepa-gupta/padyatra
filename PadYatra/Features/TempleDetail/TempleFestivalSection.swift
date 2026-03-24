// TempleFestivalSection.swift
// Displays a list of festivals associated with a temple.
// High-significance festivals receive a saffron star badge.
import SwiftUI

// MARK: - TempleFestivalSection

struct TempleFestivalSection: View {

    let festivals: [TempleFestival]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Festivals")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)

            ForEach(festivals, id: \.name) { festival in
                FestivalRow(festival: festival)
            }
        }
    }
}

// MARK: - FestivalRow

private struct FestivalRow: View {

    let festival: TempleFestival

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(festival.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandEarthBrown)

                    if festival.significance == .high {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.brandSaffron)
                            .accessibilityLabel("High significance festival")
                    }
                }

                Text(monthDisplay(for: festival))
                    .font(.caption)
                    .foregroundStyle(Color.brandTempleGrey)

                Text(festival.description)
                    .font(.caption)
                    .foregroundStyle(Color.brandEarthBrown.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(Color.brandWarmCream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .stroke(Color.brandEarthBrown.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: festival))
    }

    // MARK: - Helpers

    private func monthDisplay(for festival: TempleFestival) -> String {
        var parts: [String] = []
        if let month = festival.approximateMonth {
            parts.append("~\(Date.monthName(for: month))")
        }
        if festival.isLunar {
            parts.append("(lunar calendar)")
        }
        return parts.joined(separator: " ")
    }

    private func accessibilityLabel(for festival: TempleFestival) -> String {
        var parts = [festival.name]
        if festival.significance == .high { parts.append("High significance") }
        parts.append(monthDisplay(for: festival))
        parts.append(festival.description)
        return parts.joined(separator: ". ")
    }
}

// MARK: - Preview

#Preview("Temple Festival Section") {
    let festivals: [TempleFestival] = [
        TempleFestival(
            name: "Mahashivratri",
            approximateMonth: 2,
            isLunar: true,
            description: "The great night of Shiva. Pilgrims observe fasts and all-night vigils.",
            significance: .high
        ),
        TempleFestival(
            name: "Shravan Month Celebrations",
            approximateMonth: 8,
            isLunar: false,
            description: "Month-long special pooja and abhisheka during the holy month of Shravan.",
            significance: .medium
        ),
        TempleFestival(
            name: "Kartik Purnima",
            approximateMonth: 11,
            isLunar: true,
            description: "Bathing ghats lit with lamps; special darshan offered.",
            significance: .low
        )
    ]

    ScrollView {
        TempleFestivalSection(festivals: festivals)
            .padding()
    }
    .background(Color.brandWarmCream)
}
