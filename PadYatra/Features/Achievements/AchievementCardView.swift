// AchievementCardView.swift
// Single card in the achievements grid. Three visual states:
//   1. Locked — dot-grid pattern, progress bar
//   2. Unlocked & unrevealed — saffron glow, shimmer
//   3. Unlocked & revealed — category colour gradient, rarity badge
import SwiftUI

struct AchievementCardView: View {

    let definition: AchievementDefinition
    let category: TempleCategory
    let visitedCount: Int
    let isComplete: Bool
    let isRevealed: Bool
    /// Stagger delay for entrance animation.
    var animationDelay: Double = 0
    var onTap: () -> Void

    @State private var shimmerPhase: CGFloat = 0
    @State private var appeared = false
    @State private var showingBadgeDetail = false

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(
                .spring(response: 0.4, dampingFraction: 0.75)
                .delay(min(animationDelay, 0.3))
            ) { appeared = true }
        }
        .onTapGesture(count: 2) {
            if isComplete && isRevealed { showingBadgeDetail = true }
        }
        .sheet(isPresented: $showingBadgeDetail) {
            BadgeDetailView(definition: definition)
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isComplete && !isRevealed ? .isButton : [])
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        if isComplete && isRevealed {
            revealedCard
        } else if isComplete && !isRevealed {
            unrevealedCard
        } else {
            lockedCard
        }
    }

    // MARK: - Locked Card

    private var lockedCard: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.brandTempleGrey.opacity(0.5))

            Text(category.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandTempleGrey)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            progressBar

            Text("\(visitedCount) / \(category.totalRequired)")
                .font(.caption2)
                .foregroundStyle(Color.brandTempleGrey)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.brandWarmCream
                dotGridCanvas
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.brandTempleGrey.opacity(0.2), lineWidth: 1)
        )
        .appShadow()
    }

    /// Sacred geometry dot pattern — repeating grid of 2px circles at 8px spacing.
    private var dotGridCanvas: some View {
        Canvas { context, size in
            let spacing: CGFloat = 8
            let dotRadius: CGFloat = 1
            var y: CGFloat = spacing / 2
            while y < size.height {
                var x: CGFloat = spacing / 2
                while x < size.width {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.brandTempleGrey.opacity(0.18))
                    )
                    x += spacing
                }
                y += spacing
            }
        }
    }

    // MARK: - Unrevealed Card

    private var unrevealedCard: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Image(systemName: "seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.brandGold.opacity(0.3))

                Image(systemName: "questionmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.brandSaffron)
            }

            Text(category.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            shimmerText
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.brandWarmCream)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.brandSaffron.opacity(0.6), lineWidth: 2)
                )
        )
        .shadow(color: Color.brandSaffron.opacity(0.35), radius: 10, x: 0, y: 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                shimmerPhase = 1
            }
        }
    }

    private var shimmerText: some View {
        Text("Scratch to Reveal!")
            .font(.caption.weight(.bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.brandSaffron, Color.brandGold, Color.brandSaffron],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(0.7 + 0.3 * shimmerPhase)
    }

    // MARK: - Revealed Card

    private var revealedCard: some View {
        VStack(spacing: AppSpacing.sm) {
            badgeImage

            Text(definition.name.replacingOccurrences(of: "Complete ", with: ""))
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandEarthBrown)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            rarityBadge
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(revealedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color(hex: definition.colors.unlocked).opacity(0.4), lineWidth: 1.5)
        )
        .appShadow()
    }

    private var revealedBackground: some View {
        let accent = Color(hex: definition.colors.unlocked)
        return RoundedRectangle(cornerRadius: AppRadius.md)
            .fill(
                LinearGradient(
                    colors: [accent.opacity(0.18), accent.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    /// Badge image: uses PNG asset when available, falls back to SF Symbol.
    @ViewBuilder
    private var badgeImage: some View {
        if let badgeName = definition.badgeImageName {
            Image(badgeName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
        } else {
            Image(systemName: definition.iconAssetName)
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: definition.colors.unlocked))
                .frame(maxWidth: .infinity)
        }
    }

    private var rarityBadge: some View {
        Text(definition.rarity.displayName.uppercased())
            .font(.system(size: 7, weight: .heavy))
            .tracking(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(definition.rarity.color)
            .clipShape(Capsule())
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let fraction = category.totalRequired > 0
            ? Double(visitedCount) / Double(category.totalRequired)
            : 0
        return ProgressBar(fraction: fraction, height: 4, animated: false)
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        if isComplete && isRevealed {
            let shortName = definition.name.replacingOccurrences(of: "Complete ", with: "")
            return "\(shortName), \(definition.rarity.displayName) achievement, revealed"
        } else if isComplete {
            return "\(category.name), completed, double-tap to reveal"
        } else {
            return "\(category.name), \(visitedCount) of \(category.totalRequired) temples visited"
        }
    }
}

