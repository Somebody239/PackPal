import SwiftUI

/// A circular close button with glass morphism design
/// Supports both iOS 18+ glass effects and fallback material design
struct GlassCloseButton: View {
    // MARK: - Properties
    
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
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .glassEffect(.regular.interactive())
        .clipShape(Circle())
        .accessibilityLabel(Text("Close"))
    }
    
    private var fallbackButton: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .accessibilityLabel(Text("Close"))
    }
}


