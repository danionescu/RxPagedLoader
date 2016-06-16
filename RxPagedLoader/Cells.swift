//
//  Cells.swift
//  RxPagedLoader
//
//  Created by Dan Ionescu on 15/06/16.
//  Copyright © 2016 Alt Tab. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!

    var viewModel: ProductViewModel? {
        didSet {
            nameLabel.text = viewModel?.name
            priceLabel.text = viewModel?.price
            categoryLabel.text = viewModel?.category
        }
    }
}

class LoaderTableViewCell: UITableViewCell {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    override func layoutSubviews() {
        super.layoutSubviews()
        self.separatorInset = UIEdgeInsets(top: 0, left: CGRectGetWidth(self.bounds), bottom: 0, right: 0)
    }
}