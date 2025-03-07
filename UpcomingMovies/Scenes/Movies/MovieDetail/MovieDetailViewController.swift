//
//  MovieDetailViewController.swift
//  UpcomingMovies
//
//  Created by Alonso on 11/7/18.
//  Copyright © 2018 Alonso. All rights reserved.
//

import UIKit

final class MovieDetailViewController: UIViewController, Storyboarded, Transitionable {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var posterContainerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var voteAverageView: VoteAverageView!
    @IBOutlet private weak var genreLabel: UILabel!
    @IBOutlet private weak var releaseDateLabel: UILabel!
    @IBOutlet private weak var overviewLabel: UILabel!
    @IBOutlet private weak var optionsContainerView: UIView!

    static var storyboardName: String = "MovieDetail"

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "Ellipsis"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(moreBarButtonAction(_:)))
        return barButtonItem
    }()

    private lazy var favoriteBarButtonItem: FavoriteToggleBarButtonItem = {
        let barButtonItem = FavoriteToggleBarButtonItem()
        barButtonItem.target = self
        barButtonItem.action = #selector(favoriteButtonAction(_:))

        return barButtonItem
    }()

    // MARK: - Dependencies

    var viewModel: MovieDetailViewModelProtocol?
    var userInterfaceHelper: MovieDetailUIHelperProtocol?
    weak var coordinator: MovieDetailCoordinatorProtocol?

    var transitionContainerView: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindables()

        viewModel?.getMovieDetail(showLoader: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel, !viewModel.startLoading.value else {
            return
        }
        viewModel.checkMovieAccountState()
    }

    // MARK: - Private

    private func setupUI() {
        title = viewModel?.screenTitle

        setupNavigationBar()
        setupLabels()
    }

    private func setupNavigationBar() {
        let backItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        navigationItem.rightBarButtonItems = [moreBarButtonItem]
    }

    private func setupLabels() {
        titleLabel.font = FontHelper.headline
        titleLabel.adjustsFontForContentSizeCategory = true

        genreLabel.font = FontHelper.body
        genreLabel.adjustsFontForContentSizeCategory = true

        releaseDateLabel.font = FontHelper.body
        releaseDateLabel.adjustsFontForContentSizeCategory = true

        overviewLabel.font = FontHelper.body
        overviewLabel.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Reactive Behavior

    private func setupBindables() {
        setupViewBindables()
        setupLoaderBindable()
        setupErrorBindables()
        setupAlertBindables()
    }

    private func setupViewBindables() {
        viewModel?.didSetupMovieDetail.bindAndFire({ [weak self] _ in
            guard let self else { return }
            self.configureUI()
            self.userInterfaceHelper?.hideRetryView()
            self.viewModel?.saveVisitedMovie()
        }, on: .main)
        viewModel?.showGenreName.bindAndFire({ [weak self] genreName in
            self?.genreLabel.text = genreName
        }, on: .main)
        viewModel?.didSelectShareAction.bind({ [weak self] _ in
            self?.shareMovie()
        }, on: .main)
        viewModel?.movieAccountState.bind({ [weak self] accountState in
            guard let self else { return }
            guard let accountState else {
                // We remove favorite button from navigation bar.
                self.navigationItem.rightBarButtonItems = [self.moreBarButtonItem]
                return
            }
            let isFavorite = accountState.isFavorite
            self.favoriteBarButtonItem.toggle(to: isFavorite.intValue)
            self.navigationItem.rightBarButtonItems = [self.moreBarButtonItem, self.favoriteBarButtonItem]
        }, on: .main)
    }

    private func configureUI() {
        guard let viewModel = viewModel else { return }

        coordinator?.embedMovieDetailPoster(on: self, in: posterContainerView,
                                            with: viewModel.backdropURL,
                                            and: viewModel.posterURL)
        coordinator?.embedMovieDetailOptions(on: self,
                                             in: optionsContainerView,
                                             with: viewModel.movieDetailOptions)

        titleLabel.text = viewModel.title
        releaseDateLabel.text = viewModel.releaseDate

        voteAverageView.voteValue = viewModel.voteAverage

        overviewLabel.text = viewModel.overview
    }

    private func setupLoaderBindable() {
        viewModel?.startLoading.bind({ [weak self] start in
            guard let self else { return }
            start ? self.userInterfaceHelper?.showLoader(in: self.view) : self.userInterfaceHelper?.hideLoader()
        }, on: .main)
    }

    private func setupErrorBindables() {
        viewModel?.showErrorRetryView.bind({ [weak self] error in
            guard let self else { return }
            self.showErrorView(error: error)
        }, on: .main)
    }

    private func setupAlertBindables() {
        viewModel?.showSuccessAlert.bind({ [weak self] message in
            guard let self else { return }
            self.userInterfaceHelper?.showHUD(with: message, in: self.view)
        }, on: .main)

        viewModel?.showErrorAlert.bind({ [weak self] error in
            guard let self else { return }
            self.view.showFailureToast(withMessage: error.localizedDescription)
        }, on: .main)
    }

    private func showErrorView(error: Error) {
        userInterfaceHelper?.presentRetryView(in: view, with: error.localizedDescription, retryHandler: { [weak self] in
            self?.viewModel?.getMovieDetail(showLoader: false)
        })
    }

    // MARK: - Actions

    @IBAction private func moreBarButtonAction(_ sender: Any) {
        guard let movieTitle = viewModel?.title,
              let actionModels = viewModel?.getAvailableAlertActions() else { return }
        let availableActions = actionModels.map { actionModel in
            UIAlertAction(title: actionModel.title, style: .default) { _ in actionModel.action() }
        }
        let cancelAction = UIAlertAction(title: LocalizedStrings.cancel(), style: .cancel) { _ in
            self.dismiss(animated: true)
        }
        let actions = [cancelAction] + availableActions
        coordinator?.showActionSheet(title: movieTitle, message: nil, actions: actions)
    }

    private func shareMovie() {
        guard let viewModel else { return }
        coordinator?.showSharingOptions(withShareTitle: viewModel.shareTitle)
    }

    @IBAction private func favoriteButtonAction(_ sender: Any) {
        viewModel?.handleFavoriteMovie()
    }

}

// MARK: - MovieDetailPosterViewControllerDelegate

extension MovieDetailViewController: MovieDetailPosterViewControllerDelegate {

    func movieDetailPosterViewController(_ movieDetailPosterViewController: MovieDetailPosterViewController, transitionContainerView: UIView) {
        self.transitionContainerView = transitionContainerView
    }

}

// MARK: - MovieDetailOptionsViewControllerDelegate

extension MovieDetailViewController: MovieDetailOptionsViewControllerDelegate {

    func movieDetailOptionsViewController(_ movieDetailOptionsViewController: MovieDetailOptionsViewController,
                                          didSelectOption option: MovieDetailOption) {
        coordinator?.showMovieOption(option)
    }

}
