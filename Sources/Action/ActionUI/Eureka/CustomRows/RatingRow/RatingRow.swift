//
//  RatingRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka

public class RatingCell: Cell<Double>, CellType {

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
        cosmosRating.rating = ratingRow.value ?? 0

        if let text = ratingRow.text {
            cosmosRating.text = text
        }

        if let fillMode = ratingRow.fillMode {
            cosmosRating.cosmosSettings.fillMode = fillMode
        }

        if let starSize = ratingRow.starSize {
            cosmosRating.cosmosSettings.starSize = starSize
        }

        if let starMargin = ratingRow.starMargin {
            cosmosRating.cosmosSettings.starMargin = starMargin
        }

        if let filledColor = ratingRow.filledColor {
            cosmosRating.cosmosSettings.filledColor = filledColor
        }

        if let emptyBorderColor = ratingRow.emptyBorderColor {
            cosmosRating.cosmosSettings.emptyBorderColor = emptyBorderColor
        }

        if let filledBorderColor = ratingRow.filledBorderColor {
            cosmosRating.cosmosSettings.filledBorderColor = filledBorderColor
        }

        // set rating to base value for eureka
        cosmosRating.didFinishTouchingCosmos = {[weak self] rating in
            self?.row.value = rating
            self?.ratingRow.value = rating
        }
    }

    open override func update() {
        super.update()

        cosmosRating.text = ratingRow.text
        cosmosRating.rating = ratingRow.value ?? 0
    }
}

// The custom Row also has the cell: CustomCell and its correspond value
public final class RatingRow: Row<RatingCell>, RowType {

    public var fillMode: StarFillMode?
    public var starSize: Double?
    public var starMargin: Double?
    public var filledColor: UIColor?
    public var emptyBorderColor: UIColor?
    public var filledBorderColor: UIColor?
    public var text: String?

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
