//
//  CustomListDetailSectionView.swift
//  UpcomingMovies
//
//  Created by Alonso on 4/20/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit

class CustomListDetailSectionView: UIView, NibLoadable {

    @IBOutlet private weak var movieCountLabel: UILabel!
    @IBOutlet private weak var ratingLabel: UILabel!
    @IBOutlet private weak var runtimeLabel: UILabel!

    @IBOutlet var titleLabels: [UILabel]!

    var viewModel: CustomListDetailSectionViewModel? {
        didSet {
            setupBindables()
        }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    // MARK: - Private

    private func setupUI() {
        movieCountLabel.textColor = ColorPalette.whiteColor
        movieCountLabel.font = FontHelper.body

        ratingLabel.textColor = ColorPalette.whiteColor
        ratingLabel.font = FontHelper.body

        runtimeLabel.textColor = ColorPalette.whiteColor
        runtimeLabel.font = FontHelper.body

        titleLabels.forEach { $0.textColor = ColorPalette.whiteColor }
        titleLabels.forEach { $0.font = FontHelper.caption1Light }
    }

    // MARK: - Reactive Behavior

    private func setupBindables() {
        movieCountLabel.text = viewModel?.movieCountText
        ratingLabel.text = viewModel?.ratingText
        runtimeLabel.text = viewModel?.runtimeText
    }

}
