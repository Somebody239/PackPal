import SwiftUI

/// Bottom navigation bar with glass morphism design
/// Contains search, travel log, and add trip buttons
struct GlassBottomBarView: View {
    // MARK: - Properties
    
    var tripCountText: String = ""
    var onSearch: (() -> Void)?
    var onTravelLog: (() -> Void)?
    var onAdd: (() -> Void)?

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            searchButton
            travelLogButton
            addButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - View Components
    
    private var searchButton: some View {
        Group {
            if #available(iOS 18.0, *) {
                Button(action: { onSearch?() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                }
                .glassEffect(.regular)
                .clipShape(Circle())
                .contentShape(Circle())
            } else {
                Button(action: { onSearch?() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: Circle())
                        .contentShape(Circle())
                }
            }
        }
    }
    
    private var travelLogButton: some View {
        Group {
            if #available(iOS 18.0, *) {
                Button(action: { onTravelLog?() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Travel Log").font(.headline).foregroundStyle(.white)
                            Text(tripCountText.isEmpty ? "" : tripCountText).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                }
                .glassEffect(.regular)
                .clipShape(Capsule())
            } else {
                Button(action: { onTravelLog?() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Travel Log").font(.headline).foregroundStyle(.white)
                            Text(tripCountText.isEmpty ? "" : tripCountText).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(.ultraThinMaterial, in: Capsule())
                    .contentShape(Capsule())
                }
            }
        }
    }
    
    private var addButton: some View {
        Group {
            if #available(iOS 18.0, *) {
                Button(role: .confirm, action: { onAdd?() }) {
                    Label("Add", systemImage: "plus")
                        .bold()
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.white)
                        .frame(width: 52, height: 52)
                }
                .tint(.orange)
                .glassEffect(.regular.tint(.orange).interactive())
                .clipShape(Circle())
                .contentShape(Circle())
            } else {
                Button(action: { onAdd?() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.systemOrange, in: Circle())
                        .contentShape(Circle())
                }
            }
        }
    }
}

private extension Color {
    static var systemOrange: Color { Color(UIColor.systemOrange) }
}


