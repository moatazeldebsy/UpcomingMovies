//
//  SimilarMoviesCoordinator.swift
//  UpcomingMovies
//
//  Created by Alonso on 7/31/20.
//  Copyright © 2020 Alonso. All rights reserved.
//

import UIKit
import UpcomingMoviesDomain

final class SimilarMoviesCoordinator: BaseCoordinator, MovieListCoordinatorProtocol, MovieDetailCoordinable {

    private let movieId: Int

    init(navigationController: UINavigationController, movieId: Int) {
        self.movieId = movieId
        super.init(navigationController: navigationController)
    }

    override func start() {
        let viewController = MovieListViewController.instantiate()

        viewController.viewModel = DIContainer.shared.resolve(name: "SimilarMovies",
                                                              arguments: LocalizedStrings.similarMoviesTitle.localized, movieId)
        viewController.coordinator = self

        navigationController.pushViewController(viewController, animated: true)
    }

}
