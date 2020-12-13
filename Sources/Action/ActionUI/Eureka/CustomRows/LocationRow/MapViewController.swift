//
//  MapViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit
import MapKit

import Eureka

public class MapViewController: UIViewController, TypedRowControllerType, MKMapViewDelegate, CLLocationManagerDelegate {

    public var row: RowOf<Coordinate>!
    public var onDismissCallback: ((UIViewController) -> Void)?
    let locationManager = CLLocationManager()
    var resultSearchController: UISearchController?

    lazy var mapView: MKMapView = { [unowned self] in
        let view = MKMapView(frame: self.view.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
        }()

    lazy var pinView: UIImageView = { [unowned self] in
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.image = UIImage(systemName: "mappin.and.ellipse")
        view.image = view.image?.withRenderingMode(.alwaysTemplate)
        view.tintColor = self.view.tintColor
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        return view
        }()

    let width: CGFloat = 10.0
    let height: CGFloat = 5.0

    lazy var ellipse: UIBezierPath = { [unowned self] in
        let ellipse = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        return ellipse
        }()

    lazy var ellipsisLayer: CAShapeLayer = { [unowned self] in
        let layer = CAShapeLayer()
        layer.bounds = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        layer.path = self.ellipse.cgPath
        layer.fillColor = ColorCompatibility.systemGray.cgColor
        layer.fillRule = .nonZero
        layer.lineCap = .butt
        layer.lineDashPattern = nil
        layer.lineDashPhase = 0.0
        layer.lineJoin = .miter
        layer.lineWidth = 1.0
        layer.miterLimit = 10.0
        layer.strokeColor = ColorCompatibility.systemGray.cgColor
        return layer
        }()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    convenience public init(_ callback: ((UIViewController) -> Void)?) {
        self.init(nibName: nil, bundle: nil)
        onDismissCallback = callback
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)

        mapView.delegate = self
        mapView.addSubview(pinView)
        mapView.layer.insertSublayer(ellipsisLayer, below: pinView.layer)

        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(MapViewController.tappedDone(_:)))
        button.title = "Done"
        navigationItem.rightBarButtonItem = button

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

        if let value = row.value {
            let region = MKCoordinateRegion(center: value.coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(region, animated: true)
        } else {
            mapView.showsUserLocation = true
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways,
               let coordinate  = locationManager.location?.coordinate {
                let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
                mapView.setRegion(region, animated: true)
            }
        }

        if let locationSearchTable = UIStoryboard(name: "LocationSearchTable", bundle: Bundle(for: MapViewController.self)).instantiateViewController(withIdentifier: "LocationSearchTable") as? LocationSearchTable {
            resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        } else {
            assertionFailure("Cannot instanciate location search")
        }

        updateTitle()

        let myLocationButton = UIButton(frame: CGRect(x: self.view.bounds.width - 80, y: self.view.bounds.height - 80, width: 50, height: 50))
        myLocationButton.backgroundColor = UIColor.clear
        myLocationButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        myLocationButton.setImage(UIImage(systemName: "paperplane"), for: .highlighted)
        myLocationButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        myLocationButton.layer.borderColor = myLocationButton.tintColor.cgColor
        myLocationButton.layer.borderWidth = 1
        myLocationButton.layer.cornerRadius = 25
        myLocationButton.layer.masksToBounds = true
        myLocationButton.addTarget(self, action: #selector(self.onCancelButton(_:)), for: .touchUpInside)
        mapView.addSubview(myLocationButton)

    }
    @objc func onCancelButton(_ sender: UIButton) {
        // TODO maybe a request here
        locationManager.requestLocation()
        guard let location = locationManager.location else {
            return
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let center = mapView.convert(mapView.centerCoordinate, toPointTo: pinView)
        pinView.center = CGPoint(x: center.x, y: center.y - (pinView.bounds.height/2))
        ellipsisLayer.position = center
    }

    @objc func tappedDone(_ sender: UIBarButtonItem) {
        let target = mapView.convert(ellipsisLayer.position, toCoordinateFrom: mapView)
        row.value = target.toStruct()
        onDismissCallback?(self)
    }

    func updateTitle() {
        let fmt = NumberFormatter()
        fmt.maximumFractionDigits = 4
        fmt.minimumFractionDigits = 4
        let latitude = fmt.string(from: NSNumber(value: mapView.centerCoordinate.latitude))!
        let longitude = fmt.string(from: NSNumber(value: mapView.centerCoordinate.longitude))!
        title = "\(latitude), \(longitude)"
    }

    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        ellipsisLayer.transform = CATransform3DMakeScale(0.5, 0.5, 1)
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.pinView.center = CGPoint(x: self!.pinView.center.x, y: self!.pinView.center.y - 10)
        })
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        ellipsisLayer.transform = CATransform3DIdentity
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.pinView.center = CGPoint(x: self!.pinView.center.x, y: self!.pinView.center.y + 10)
        })
        updateTitle()
    }

    // MARK: - delegate
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location:: \(location)")
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: (error)")
    }
}
class LocationSearchTable: UITableViewController {
    var matchingItems: [MKMapItem] = []
    var mapView: MKMapView?

    func parseAddress(selectedItem: MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format: "%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}

extension LocationSearchTable: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
}
