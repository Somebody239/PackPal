import UIKit
import SwiftUI

// MARK: - SearchViewControllerDelegate

/// Delegate protocol for search view controller events
protocol SearchViewControllerDelegate: AnyObject {
    func searchViewControllerDidCancel(_ controller: SearchViewController)
    func searchViewController(_ controller: SearchViewController, didSelectTrip trip: Trip)
}

// MARK: - SearchViewController

/// View controller for searching and selecting trips
final class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    
    // Delegate
    weak var delegate: SearchViewControllerDelegate?

    // UI Components
    private let containerView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()
    private var closeHosting: UIHostingController<GlassCloseButton>?
    private var hosting: UIHostingController<SearchView>?

    // Data
    private var allTrips: [Trip] = []
    private var filteredTrips: [Trip] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.backgroundColor = .black
        containerView.layer.cornerRadius = 24
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80)
        ])

        allTrips = TripManager.shared.loadTrips()
        filteredTrips = allTrips

        // SwiftUI SearchView with .searchable and glass close button
        let searchView = SearchView(
            allTrips: allTrips,
            onCancel: { [weak self] in self?.cancelTapped() },
            onSelectTrip: { [weak self] trip in
                guard let self = self else { return }
                self.delegate?.searchViewController(self, didSelectTrip: trip)
            }
        )
        let hosting = UIHostingController(rootView: searchView)
        self.hosting = hosting
        addChild(hosting)
        containerView.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        hosting.didMove(toParent: self)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.searchViewControllerDidCancel(self)
    }

    // MARK: - UISearchBarDelegate (unused with SwiftUI .searchable)

    // MARK: - UITableViewDataSource/Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTrips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        let trip = filteredTrips[indexPath.row]
        cell.textLabel?.text = "\(trip.name) — \(trip.destination)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = filteredTrips[indexPath.row]
        delegate?.searchViewController(self, didSelectTrip: trip)
    }
}



