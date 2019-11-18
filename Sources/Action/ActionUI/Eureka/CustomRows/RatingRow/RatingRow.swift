//
//  RatingRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import Eureka

public class RatingCell: Cell<Int>, CellType {

    lazy private var cosmosRating: CosmosView = {
        return CosmosView()
    }()

    private var ratingRow: RatingRow {
        return row as! RatingRow //swiftlint:disable:this force_cast
    }

    open override func setup() {
        super.setup()
        selectionStyle = .none

        cosmosRating.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cosmosRating)
        height = {44}

        // set constraints in tableView
        let topConstraint = NSLayoutConstraint(item: cosmosRating, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        let leadingConstraint = NSLayoutConstraint(item: cosmosRating, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: -10.0)

        contentView.addConstraints([topConstraint, leadingConstraint])
        cosmosRating.rating = Double(ratingRow.value ?? 0)

        cosmosRating.text = ratingRow.text
        cosmosRating.cosmosSettings = ratingRow.cosmosSettings

        // set rating to base value for eureka
        cosmosRating.didFinishTouchingCosmos = {[weak self] rating in
            self?.row.value = Int(rating)
            self?.ratingRow.value = Int(rating)
        }
    }

    open override func update() {
        super.update()

        cosmosRating.text = ratingRow.text
        cosmosRating.rating = Double(ratingRow.value ?? 0)
    }
}

// The custom Row also has the cell: CustomCell and its correspond value
public final class RatingRow: Row<RatingCell>, RowType {

    public var cosmosSettings: CosmosSettings = .default

    public var text: String?

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
