//
//  LocationRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit
import MapKit

import Eureka

// MARK: LocationRow

public final class LocationRow: Eureka.OptionsRow<PushSelectorCell<Coordinate>>, PresenterRowType, RowType {

    public typealias PresenterRow = MapViewController

    /// Defines how the view controller will be presented, pushed, etc.
    public var presentationMode: PresentationMode<PresenterRow>?

    /// Will be called before the presentation occurs.
    public var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .show(controllerProvider: ControllerProvider.callback { return MapViewController { _ in } }, onDismiss: { viewController in _ = viewController.navigationController?.popViewController(animated: true) })

        displayValueFor = {
            guard let location = $0 else { return "" }
            return location.stringValue
        }
        self.cell?.accessoryView = UIImageView(image: UIImage(systemName: "map"))
    }

    /**
     Extends `didSelect` method
     */
    public override func customDidSelect() {
        super.customDidSelect()
        guard let presentationMode = presentationMode, !isDisabled else { return }
        if let controller = presentationMode.makeController() {
            controller.row = self
            controller.title = selectorTitle ?? controller.title
            onPresentCallback?(cell.formViewController()!, controller)
            presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
        } else {
            presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
        }
    }

    /**
     Prepares the pushed row setting its title and completion callback.
     */
    public override func prepare(for segue: UIStoryboardSegue) {
        super.prepare(for: segue)
        guard let rowVC = segue.destination as? PresenterRow else { return }
        rowVC.title = selectorTitle ?? rowVC.title
        rowVC.onDismissCallback = presentationMode?.onDismissCallback ?? rowVC.onDismissCallback
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = self
    }
}

import QMobileAPI

public struct Coordinate: Equatable {
    public var latitude: Double
    public var longitude: Double

    public static func == (left: Coordinate, right: Coordinate) -> Bool {
        return left.latitude == right.latitude && left.longitude == right.longitude
    }
}

extension Coordinate: ActionParameterEncodable {

    public func encodeForActionParameter() -> Any {
        return stringValue
    }

    var stringValue: String {
        let fmt = NumberFormatter()
        fmt.maximumFractionDigits = 4
        fmt.minimumFractionDigits = 4
        let latitude = fmt.string(from: NSNumber(value: self.latitude))!
        let longitude = fmt.string(from: NSNumber(value: self.longitude))!
        return "\(latitude), \(longitude)"
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
