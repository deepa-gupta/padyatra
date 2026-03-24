// ProgressBar.swift
// Shared horizontal capsule progress bar used in achievement cards and profile stats.
import SwiftUI

struct ProgressBar: View {

    let fraction: Double
    var height: CGFloat = 6
    var animated: Bool = true

    private var clamped: Double { max(0, min(1, fraction)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.brandTempleGrey.opacity(0.15))
                    .frame(height: height)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandSaffron, Color.brandDeepOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * clamped, height: height)
                    .animation(animated ? .easeOut(duration: 0.4) : nil, value: fraction)
            }
        }
        .frame(height: height)
    }
}
