// TempleFactsGrid.swift
// 2-column grid of fact chips derived from TempleFacts.
// Only renders chips where the underlying value is non-nil.
import SwiftUI

// MARK: - FactItem

private struct FactItem: Identifiable {
    let id: String  // unique label text used as stable identity
    let icon: String
    let label: String
}

// MARK: - TempleFactsGrid

struct TempleFactsGrid: View {

    let facts: TempleFacts

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]

    // MARK: - Body

    var body: some View {
        let items = factItems()
        if items.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(items) { item in
                    TempleFactChip(icon: item.icon, label: item.label)
                }
            }
        }
    }

    // MARK: - Fact Mapping

    private func factItems() -> [FactItem] {
        var items: [FactItem] = []

        if let established = facts.established {
            items.append(FactItem(id: "established", icon: "building.columns", label: "Est. \(established)"))
        }

        if let architectureStyle = facts.architectureStyle {
            items.append(FactItem(id: "architecture", icon: "building.2", label: architectureStyle))
        }

        if let darshanaTimings = facts.darshanaTimings {
            items.append(FactItem(id: "timings", icon: "clock", label: darshanaTimings))
        }

        if let dresscode = facts.dresscode {
            items.append(FactItem(id: "dresscode", icon: "person.fill", label: dresscode))
        }

        if let photographyAllowed = facts.photographyAllowed {
            let icon = photographyAllowed ? "camera" : "video.slash"
            let label = photographyAllowed ? "Photography allowed" : "No photography"
            items.append(FactItem(id: "photography", icon: icon, label: label))
        }

        if let entryFee = facts.entryFee {
            items.append(FactItem(id: "entryfee", icon: "ticket", label: entryFee))
        }

        if let altitude = facts.altitude {
            items.append(FactItem(id: "altitude", icon: "mountain.2", label: "\(altitude)m above sea level"))
        }

        if let openingMonth = facts.openingMonth, let closingMonth = facts.closingMonth {
            let open = Date.monthName(for: openingMonth)
            let close = Date.monthName(for: closingMonth)
            items.append(FactItem(id: "season", icon: "calendar", label: "Open \(open)–\(close)"))
        }

        if let dynasty = facts.dynasty {
            items.append(FactItem(id: "dynasty", icon: "scroll", label: dynasty))
        }

        return items
    }
}

// MARK: - TempleFactChip

struct TempleFactChip: View {

    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSaffron)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.brandEarthBrown)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.brandWarmCream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .stroke(Color.brandEarthBrown.opacity(0.12), lineWidth: 1)
        )
        .accessibilityLabel(label)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("Temple Facts Grid") {
    let facts = TempleFacts(
        established: "Unknown antiquity",
        dynasty: "Chaulukya",
        architectureStyle: "Solanki",
        openingMonth: 4,
        closingMonth: 11,
        altitude: 2742,
        dresscode: "Traditional attire",
        photographyAllowed: false,
        entryFee: "Free",
        darshanaTimings: "6:00 AM – 9:30 PM"
    )

    ScrollView {
        TempleFactsGrid(facts: facts)
            .padding()
    }
    .background(Color.brandWarmCream)
}
