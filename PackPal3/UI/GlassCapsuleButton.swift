import SwiftUI

/// A capsule-shaped button with glass morphism design
/// Supports both iOS 18+ glass effects and fallback material design
struct GlassCapsuleButton: View {
    // MARK: - Properties
    
    var title: String
    var tint: Color = .orange
    var action: () -> Void

    // MARK: - Body
    
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                modernButton
            } else {
                fallbackButton
            }
        }
    }
    
    // MARK: - View Components
    
    @available(iOS 18.0, *)
    private var modernButton: some View {
        Button(role: .confirm, action: action) {
            Text(title)
                .bold()
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .contentShape(Capsule())
        }
        .glassEffect(.regular.tint(tint).interactive())
        .clipShape(Capsule())
        .accessibilityLabel(Text(title))
    }
    
    private var fallbackButton: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .tint(tint)
        .accessibilityLabel(Text(title))
    }
}


