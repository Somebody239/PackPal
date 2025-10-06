import UIKit
import SwiftUI

final class PullableSheetViewController: UIViewController {
    private enum Constants {
        static let cornerRadius: CGFloat = 24
        static let grabberHeight: CGFloat = 4
        static let grabberWidth: CGFloat = 44
        static let minTopInset: CGFloat = 0     // fully open to top
        static let midHeightRatio: CGFloat = 0.45
    }

    private let containerView = UIView()
    private var bottomHosting: UIHostingController<GlassBottomBarView>?
    private var topConstraint: NSLayoutConstraint!
    private var panGesture: UIPanGestureRecognizer!
    private lazy var contentController = HomeContentViewController()
    private var tripCreationController: TripCreationViewController?
    private var tripDetailsController: TripDetailsViewController?
    private var searchController: SearchViewController?

    // Reference to root container for modal presentation
    weak var rootContainer: RootContainerViewController?
    private var didSetInitialPosition = false
    private let snapGenerator = UIImpactFeedbackGenerator(style: .soft)

    private var maximumTopY: CGFloat { Constants.minTopInset }
    private var middleTopY: CGFloat {
        guard let h = view?.bounds.height else { return 300 }
        return h * (1 - Constants.midHeightRatio)
    }
    private var minimumTopY: CGFloat {
        // Collapsed height shows only header row and stays above the bottom bar
        let safeBottom = view.safeAreaInsets.bottom
        let barHeight: CGFloat = (bottomHosting?.view.bounds.height ?? 76)
        let barBottomMargin: CGFloat = 8 // Place bar close to bottom
        let headerVisible: CGFloat = 64
        let extraSpacing: CGFloat = 36 // Raise collapsed sheet a bit higher
        return view.bounds.height - safeBottom - (barHeight + barBottomMargin + headerVisible + extraSpacing)
    }

    override func loadView() {
        let passthrough = PassthroughView()
        passthrough.backgroundColor = .clear
        self.view = passthrough
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Set initial snap position once we have a final height
        if !didSetInitialPosition {
            topConstraint.constant = minimumTopY
            updateTripsVisibility(for: minimumTopY) // Start collapsed with trips hidden
            didSetInitialPosition = true
        }
    }

    private func configure() {
        view.backgroundColor = .clear

        // Black background with rounded top corners
        containerView.backgroundColor = .black
        containerView.layer.cornerRadius = Constants.cornerRadius
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        topConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: middleTopY)
        NSLayoutConstraint.activate([
            topConstraint,
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let passthrough = view as? PassthroughView {
            passthrough.passthroughView = containerView
            // Ensure bottom bar gets its own interactive view after it's added
        }

        let grabber = UIView()
        grabber.backgroundColor = .tertiaryLabel
        grabber.layer.cornerRadius = Constants.grabberHeight / 2
        grabber.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(grabber)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: Constants.grabberWidth),
            grabber.heightAnchor.constraint(equalToConstant: Constants.grabberHeight)
        ])

        addChild(contentController)
        containerView.addSubview(contentController.view)
        contentController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentController.view.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 8),
            contentController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        contentController.didMove(toParent: self)

        // Set up home content delegate for navigation
        contentController.delegate = self

        // Native SwiftUI glass bottom bar: search | travel log pill | plus
        let hosting = UIHostingController(rootView: makeBarView())
        bottomHosting = hosting
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        hosting.didMove(toParent: self)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hosting.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6), // move way lower
            hosting.view.heightAnchor.constraint(equalToConstant: 76)
        ])

        // Ensure the SwiftUI view is above the sheet and register for touch handling
        view.bringSubviewToFront(hosting.view)
        view.bringSubviewToFront(containerView)
        view.bringSubviewToFront(hosting.view)
        
        if let passthrough = view as? PassthroughView {
            passthrough.additionalInteractiveViews = [hosting.view]
        }

        // Add content inset so table content doesn't hide under the bar
        if let tableView = (contentController.view as? UITableView) ?? contentController.view.subviews.first(where: { $0 is UITableView }) as? UITableView {
            let inset: CGFloat = 76 + 24
            tableView.contentInset.bottom = inset
            tableView.verticalScrollIndicatorInsets.bottom = inset
        }

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }

    private func makeBarView() -> GlassBottomBarView {
        let trips = TripManager.shared.loadTrips()
        let tripCountText = trips.count == 1 ? "1 trip" : "\(trips.count) trips"
        let countries = Set(trips.map { $0.destination }).count
        let countryText = countries == 1 ? "1 country" : "\(countries) countries"
        let summary = trips.isEmpty ? "No trips yet" : "\(tripCountText), \(countryText)"
        return GlassBottomBarView(
            tripCountText: summary,
            onSearch: { [weak self] in self?.showSearch() },
            onTravelLog: { [weak self] in self?.showTravelLog() },
            onAdd: { [weak self] in self?.showAddTrip() }
        )
    }

    private func updateBottomBarStats() {
        guard let hosting = bottomHosting else { return }
        hosting.rootView = makeBarView()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .began:
            snapGenerator.prepare()
        case .changed:
            var proposed = topConstraint.constant + translation.y
            // Rubber-band when overshooting limits
            if proposed < maximumTopY {
                let delta = proposed - maximumTopY
                proposed = maximumTopY + rubberBand(delta)
            } else if proposed > minimumTopY {
                let delta = proposed - minimumTopY
                proposed = minimumTopY + rubberBand(delta)
            }
            topConstraint.constant = proposed
            gesture.setTranslation(.zero, in: view)
            
            // Update trips visibility based on position
            updateTripsVisibility(for: proposed)
        case .ended, .cancelled:
            let velocityY = gesture.velocity(in: view).y
            let target: CGFloat
            // Only snap to top (maximumTopY) or bottom (minimumTopY), no middle
            if velocityY < -400 || topConstraint.constant < (maximumTopY + minimumTopY) / 2 {
                target = maximumTopY // Fully open
            } else {
                target = minimumTopY // Collapsed
            }
            animate(to: target, initialVelocity: velocityY / 2000)
            snapGenerator.impactOccurred()
        default:
            break
        }
    }

    private func animate(to value: CGFloat, initialVelocity: CGFloat = 0) {
        topConstraint.constant = value
        let timing = UISpringTimingParameters(dampingRatio: 0.9, initialVelocity: CGVector(dx: 0, dy: initialVelocity))
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: timing)
        animator.addAnimations { [weak self] in
            self?.view.layoutIfNeeded()
            self?.updateTripsVisibility(for: value)
        }
        animator.startAnimation()
    }
    
    private func updateTripsVisibility(for topY: CGFloat) {
        // When collapsed (at minimumTopY), hide trip rows
        let isCollapsed = topY >= minimumTopY - 20 // Give 20pt threshold
        
        // Update background color based on state
        if isCollapsed {
            containerView.backgroundColor = UIColor.black
        } else {
            containerView.backgroundColor = UIColor.black
        }
        
        // Hide/show trip rows by updating the content controller
        // Bottom bar stays visible always
        contentController.setTripsHidden(isCollapsed)
    }

    private func rubberBand(_ delta: CGFloat) -> CGFloat {
        let c: CGFloat = 0.55 // similar to UIScrollView rubber-banding
        return c * atan(delta / 120) * 120
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - HomeContentDelegate

extension PullableSheetViewController: HomeContentDelegate {
    func homeContentViewControllerDidRequestCreateTrip(_ controller: HomeContentViewController) {
        showTripCreation()
    }

    func homeContentViewController(_ controller: HomeContentViewController, didSelectTrip trip: Trip) {
        showTripDetails(trip: trip)
    }

    func homeContentViewControllerDidRequestOpenSettings(_ controller: HomeContentViewController) {
        let settings = SettingsViewController()
        settings.modalPresentationStyle = .overFullScreen
        settings.modalTransitionStyle = .coverVertical
        (rootContainer ?? self).present(settings, animated: true)
    }

    private func showTripCreation() {
        print("DEBUG: showTripCreation called")
        // Dismiss any existing modal views
        tripDetailsController?.dismiss(animated: true)
        searchController?.dismiss(animated: true)
        tripDetailsController = nil
        searchController = nil

        // Create and present trip creation controller
        let tripCreationVC = TripCreationViewController()
        tripCreationVC.delegate = self
        tripCreationVC.modalPresentationStyle = .overFullScreen
        tripCreationVC.modalTransitionStyle = .coverVertical
        if let presenter = rootContainer ?? self.presentingViewController ?? self.view.window?.rootViewController {
            presenter.present(tripCreationVC, animated: true)
        } else {
            self.present(tripCreationVC, animated: true)
        }
        tripCreationController = tripCreationVC
        print("DEBUG: Trip creation controller presented")
    }

    private func showTripDetails(trip: Trip) {
        // Dismiss any existing modal views
        tripCreationController?.dismiss(animated: true)
        searchController?.dismiss(animated: true)
        tripCreationController = nil
        searchController = nil

        // Create and present trip details as swipeable modal
        let details = TripDetailsViewController(trip: trip)
        details.delegate = self
        details.modalPresentationStyle = .pageSheet
        details.isModalInPresentation = false // Allow dismissal by swiping down
        
        // Configure sheet to be swipeable
        if let sheet = details.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false // We have custom handle
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .large // Don't dim background, prevents dismiss-on-tap outside sheet
        }
        
        (rootContainer ?? self).present(details, animated: true)
        tripDetailsController = details
    }
}

// MARK: - TripCreationDelegate

extension PullableSheetViewController: TripCreationDelegate {
    func tripCreationViewController(_ controller: TripCreationViewController, didCreateTrip trip: Trip) {
        // Save the trip and refresh the home view
        TripManager.shared.saveTrip(trip)
        contentController.addTrip(trip)
        updateBottomBarStats()
        rootContainer?.refreshMapPins(centerOn: trip)

        // Dismiss the creation controller
        rootContainer?.dismiss(animated: true)
        tripCreationController = nil
    }

    func tripCreationViewControllerDidCancel(_ controller: TripCreationViewController) {
        rootContainer?.dismiss(animated: true)
        tripCreationController = nil
    }
}

// MARK: - Bottom Bar Actions

extension PullableSheetViewController {
    private func showSearch() {
        print("DEBUG: showSearch called")
        // Dismiss any existing modal views
        tripCreationController?.dismiss(animated: true)
        tripDetailsController?.dismiss(animated: true)
        searchController?.dismiss(animated: true)
        tripCreationController = nil
        tripDetailsController = nil
        searchController = nil

        // Create and present search controller
        let searchVC = SearchViewController()
        searchVC.delegate = self
        searchVC.modalPresentationStyle = .overFullScreen
        searchVC.modalTransitionStyle = .coverVertical
        (rootContainer ?? self).present(searchVC, animated: true)
        searchController = searchVC
        print("DEBUG: Search controller presented")
    }

    private func showTravelLog() {
        // Dismiss any existing modal views
        tripCreationController?.dismiss(animated: true)
        tripDetailsController?.dismiss(animated: true)
        searchController?.dismiss(animated: true)
        tripCreationController = nil
        tripDetailsController = nil
        searchController = nil

        // Reset to home view
        contentController.refreshTrips()
        updateBottomBarStats()
    }

    private func showAddTrip() {
        print("DEBUG: showAddTrip called")
        // Use the existing trip creation delegate method
        homeContentViewControllerDidRequestCreateTrip(contentController)
    }
}

// MARK: - TripDetailsDelegate

extension PullableSheetViewController: TripDetailsDelegate {
    func tripDetailsViewControllerDidUpdateTrip(_ controller: TripDetailsViewController, trip: Trip) {
        // Update the trip and refresh the home view
        TripManager.shared.saveTrip(trip)
        contentController.refreshTrips()
        updateBottomBarStats()
        rootContainer?.refreshMapPins(centerOn: trip)

        // Don't dismiss the details controller - let user interact with the list
        // The sheet should only close when user explicitly swipes down or taps outside
    }

    func tripDetailsViewControllerDidDeleteTrip(_ controller: TripDetailsViewController, trip: Trip) {
        // Delete the trip and refresh the home view
        TripManager.shared.deleteTrip(trip)
        contentController.refreshTrips()
        updateBottomBarStats()
        rootContainer?.refreshMapPins(centerOn: nil)

        // Dismiss the details controller
        rootContainer?.dismiss(animated: true)
        tripDetailsController = nil
    }
}

// MARK: - SearchViewControllerDelegate

extension PullableSheetViewController: SearchViewControllerDelegate {
    func searchViewControllerDidCancel(_ controller: SearchViewController) {
        (rootContainer ?? self).dismiss(animated: true)
        searchController = nil
    }

    func searchViewController(_ controller: SearchViewController, didSelectTrip trip: Trip) {
        // Show trip details
        showTripDetails(trip: trip)
        searchController = nil
    }
}


