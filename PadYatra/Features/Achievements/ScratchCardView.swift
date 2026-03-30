// ScratchCardView.swift
// Full-screen scratch-card reveal. Uses Canvas + destinationOut blending to
// punch holes in a grey overlay as the user drags a finger across the screen.
import SwiftUI
import OSLog

struct ScratchCardView: View {

    let achievement: AchievementDefinition
    var onRevealComplete: () -> Void

    // MARK: - State

    @State private var scratchPoints: [CGPoint] = []
    @State private var isFullyRevealed: Bool = false
    @State private var showCelebration: Bool = false

    // MARK: - Constants

    private let scratchRadius: CGFloat = 28
    /// Estimated fraction of surface covered to trigger auto-complete.
    private let autoCompleteThreshold: Double = 0.65
    private let gridCellSize: CGFloat = 12

    private let logger = Logger(subsystem: "com.padyatra", category: "ScratchCardView")

    // MARK: - Body

    var body: some View {
        ZStack {
            // Underlying revealed content
            revealContent

            // Scratch overlay — hidden when fully revealed
            if !isFullyRevealed {
                scratchOverlay
                    .transition(.opacity)
            }

            // Celebration overlay
            if showCelebration {
                celebrationOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .accessibilityAction(named: "Reveal achievement") {
            triggerFullReveal()
        }
        .onChange(of: isFullyRevealed) { _, newValue in
            if newValue { handleRevealComplete() }
        }
    }

    // MARK: - Revealed Content

    private var revealContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: achievement.iconAssetName)
                .font(.system(size: 96))
                .foregroundStyle(Color(hex: achievement.colors.unlocked))

            VStack(spacing: AppSpacing.sm) {
                Text(achievement.name)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(achievement.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)

                rarityBadge
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: achievement.colors.unlocked).opacity(0.8),
                    Color.brandDeepOrange
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var rarityBadge: some View {
        Text(achievement.rarity.displayName.uppercased())
            .font(.system(size: 11, weight: .heavy))
            .tracking(2)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(achievement.rarity.color.opacity(0.85))
            .clipShape(Capsule())
    }

    // MARK: - Scratch Overlay

    private var scratchOverlay: some View {
        Canvas { context, size in
            // Fill with grey scratch surface
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color.brandTempleGrey)
            )

            // Punch holes via destinationOut blend along scratch path
            context.blendMode = .destinationOut
            for point in scratchPoints {
                let rect = CGRect(
                    x: point.x - scratchRadius,
                    y: point.y - scratchRadius,
                    width: scratchRadius * 2,
                    height: scratchRadius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
        .compositingGroup()
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    scratchPoints.append(value.location)
                    checkAutoComplete()
                }
        )
        .overlay(alignment: .center) {
            if scratchPoints.isEmpty {
                scratchHintLabel
            }
        }
    }

    private var scratchHintLabel: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "hand.draw.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.9))
            Text("Scratch to reveal your achievement!")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
        .allowsHitTesting(false)
    }

    // MARK: - Celebration Overlay

    private var celebrationOverlay: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.brandGold)

            Text("Achievement Unlocked!")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logic

    private func checkAutoComplete() {
        guard !isFullyRevealed else { return }

        // Estimate coverage using a grid approach: for each cell, check if any
        // scratch point falls within scratchRadius of its centre.
        // Deliberately approximate — performance matters more than precision here.
        guard let bounds = scratchBounds() else { return }

        let cols = Int(bounds.width  / gridCellSize) + 1
        let rows = Int(bounds.height / gridCellSize) + 1
        let total = cols * rows
        guard total > 0 else { return }

        var covered = 0
        for row in 0..<rows {
            for col in 0..<cols {
                let cx = bounds.minX + CGFloat(col) * gridCellSize + gridCellSize / 2
                let cy = bounds.minY + CGFloat(row) * gridCellSize + gridCellSize / 2
                let cellCenter = CGPoint(x: cx, y: cy)
                if scratchPoints.contains(where: { distance($0, cellCenter) < scratchRadius }) {
                    covered += 1
                }
            }
        }

        let fraction = Double(covered) / Double(total)
        if fraction >= autoCompleteThreshold {
            logger.debug("Auto-completing scratch card at \(Int(fraction * 100))% coverage.")
            triggerFullReveal()
        }
    }

    private func scratchBounds() -> CGRect? {
        guard !scratchPoints.isEmpty else { return nil }
        // All force-unwraps below are safe: the guard above guarantees
        // scratchPoints is non-empty, so min()/max() always return a value.
        let xs = scratchPoints.map { $0.x }
        let ys = scratchPoints.map { $0.y }
        return CGRect(
            x: xs.min()! - scratchRadius,                          // safe: non-empty
            y: ys.min()! - scratchRadius,                          // safe: non-empty
            width: (xs.max()! - xs.min()!) + scratchRadius * 2,   // safe: non-empty
            height: (ys.max()! - ys.min()!) + scratchRadius * 2   // safe: non-empty
        )
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func triggerFullReveal() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.35)) {
            isFullyRevealed = true
        }
    }

    private func handleRevealComplete() {
        withAnimation(.spring(duration: 0.5)) {
            showCelebration = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000) // 1.4 s
            withAnimation {
                showCelebration = false
            }
            try? await Task.sleep(nanoseconds: 200_000_000)  // 0.2 s
            onRevealComplete()
        }
    }
}

// MARK: - Preview

#Preview("Scratch Card") {
    let achievement = AchievementDefinition(
        id: "jyotirlinga_ach",
        categoryID: "jyotirlinga",
        name: "Lord of Light",
        description: "You have visited all 12 Jyotirlinga shrines of Lord Shiva.",
        iconAssetName: "flame.fill",
        badgeImageName: nil,
        rarity: .legendary,
        colors: AchievementColors(locked: "#8A7B72", unlocked: "#FFB830")
    )

    ScratchCardView(achievement: achievement, onRevealComplete: {})
}
