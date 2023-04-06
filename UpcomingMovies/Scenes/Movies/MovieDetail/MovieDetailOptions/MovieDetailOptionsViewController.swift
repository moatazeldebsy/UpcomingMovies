//
//  MovieDetailOptionsViewController.swift
//  UpcomingMovies
//
//  Created by Alonso on 4/04/23.
//  Copyright © 2023 Alonso. All rights reserved.
//

import UIKit

protocol MovieDetailOptionsViewControllerDelegate: AnyObject {

    func movieDetailOptionsViewController(_ movieDetailOptionsViewController: MovieDetailOptionsViewController,
                                          didSelectOption option: MovieDetailOption)

}

final class MovieDetailOptionsViewController: UIViewController {

    @IBOutlet private weak var optionsStackView: UIStackView!

    var viewModel: MovieDetailOptionsViewModelProtocol?
    weak var delegate: MovieDetailOptionsViewControllerDelegate?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMovieOptions()
    }

    // MARK: - Private

    private func configureMovieOptions() {
        guard let viewModel else { return }
        // TODO: - Improve this logic
        guard optionsStackView.arrangedSubviews.isEmpty else { return }
        let optionsViews = viewModel.options.map { MovieDetailOptionView(option: $0) }
        for optionView in optionsViews {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(optionAction(_:)))
            optionView.addGestureRecognizer(tapGesture)
            optionsStackView.addArrangedSubview(optionView)
        }
    }

    // MARK: - Selectors

    @objc private func optionAction(_ sender: UITapGestureRecognizer) {
        guard let sender = sender.view as? MovieDetailOptionView else { return }
        let movieDetailOption = sender.option
        delegate?.movieDetailOptionsViewController(self, didSelectOption: movieDetailOption)
    }

}
