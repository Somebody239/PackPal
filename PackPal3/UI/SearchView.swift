import SwiftUI

// MARK: - SearchView

/// SwiftUI view for searching and selecting trips
struct SearchView: View {
    // MARK: - Properties
    
    let allTrips: [Trip]
    var onCancel: () -> Void
    var onSelectTrip: (Trip) -> Void

    @State private var searchText: String = ""
    @Environment(\.dismissSearch) private var dismissSearch

    // MARK: - Computed Properties
    
    private var filteredTrips: [Trip] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return allTrips }
        return allTrips.filter { trip in
            trip.name.localizedCaseInsensitiveContains(text) ||
            trip.destination.localizedCaseInsensitiveContains(text)
        }
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List(filteredTrips, id: \.id) { trip in
                Button {
                    onSelectTrip(trip)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 52, height: 52)
                            Image(systemName: "airplane")
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(trip.destination)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                let days = max(1, Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0)
                                Label("\(days)d", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Label(trip.tripType.rawValue, systemImage: "suitcase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismissSearch()
                    }
                    .foregroundStyle(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.black)
        .searchable(text: $searchText, prompt: Text("Search trips by name or destination"))
        .applySearchToolbarBehaviorIfAvailable()
    }
}

private extension View {
    @ViewBuilder
    func applySearchToolbarBehaviorIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.searchToolbarBehavior(.automatic)
        } else {
            self
        }
    }
}


