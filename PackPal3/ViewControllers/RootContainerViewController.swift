import UIKit
import MapKit

final class RootContainerViewController: UIViewController {
    private let mapView = MKMapView(frame: .zero)
    private let sheetController = PullableSheetViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        addMap()
        embedSheet()
        refreshMapPins(centerOn: nil)
    }

    private func addMap() {
        if #available(iOS 16.0, *) {
            let config = MKImageryMapConfiguration(elevationStyle: .realistic)
            mapView.preferredConfiguration = config
        } else {
            mapView.mapType = .satellite
        }
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func embedSheet() {
        addChild(sheetController)
        view.addSubview(sheetController.view)
        sheetController.view.translatesAutoresizingMaskIntoConstraints = false
        sheetController.rootContainer = self
        sheetController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            sheetController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])

        // Keep map interactive behind sheet by ensuring sheet view does not intercept touches above its frame
        sheetController.view.isUserInteractionEnabled = true
    }

    func refreshMapPins(centerOn trip: Trip?) {
        mapView.removeAnnotations(mapView.annotations)
        let trips = TripManager.shared.loadTrips()
        var coords: [CLLocationCoordinate2D] = []
        let group = DispatchGroup()
        trips.forEach { trip in
            group.enter()
            TripGeocoder.shared.geocodeIfNeeded(destination: trip.destination) { coord in
                if let coord = coord {
                    coords.append(coord)
                    let a = MKPointAnnotation()
                    a.title = trip.name
                    a.subtitle = trip.destination
                    a.coordinate = coord
                    self.mapView.addAnnotation(a)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            if let specific = trip, let coord = TripGeocoder.shared.cachedCoordinate(for: specific.destination) {
                self.mapView.setRegion(MKCoordinateRegion(center: coord, span: .init(latitudeDelta: 8, longitudeDelta: 8)), animated: true)
            } else if let first = coords.first {
                self.mapView.setRegion(MKCoordinateRegion(center: first, span: .init(latitudeDelta: 20, longitudeDelta: 20)), animated: true)
            }
        }
    }
}


