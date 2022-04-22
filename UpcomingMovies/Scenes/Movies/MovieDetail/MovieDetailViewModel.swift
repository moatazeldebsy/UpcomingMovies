//
//  MovieDetailViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 11/7/18.
//  Copyright © 2018 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class MovieDetailViewModel: MovieDetailViewModelProtocol {

    // MARK: - Dependencies

    private let interactor: MovieDetailInteractorProtocol
    private let factory: MovieDetailFactoryProtocol

    // MARK: - Reactive properties

    private(set) var startLoading: Bindable<Bool> = Bindable(false)

    private(set) var showErrorView: Bindable<Error?> = Bindable(nil)
    private(set) var showGenreName: Bindable<String> = Bindable("-")
    private(set) var showMovieOptions: Bindable<[MovieDetailOption]> = Bindable([])

    private(set) var didSetupMovieDetail: Bindable<Bool> = Bindable(true)

    private(set) var didUpdateFavoriteSuccess: Bindable<Bool> = Bindable(false)
    private(set) var didUpdateFavoriteFailure: Bindable<Error?> = Bindable(nil)

    private(set) var didSelectShareAction: Bindable<Bool> = Bindable(true)

    private(set) var movieAccountState: Bindable<MovieAccountStateModel?> = Bindable(nil)

    // MARK: - Properties

    private(set) var id: Int
    private(set) var title: String
    private(set) var releaseDate: String?
    private(set) var overview: String?
    private(set) var voteAverage: Double?
    private(set) var posterURL: URL?
    private(set) var backdropURL: URL?

    private(set) var needsFetch: Bool

    // MARK: - Initializers

    init(_ movie: Movie,
         interactor: MovieDetailInteractorProtocol,
         factory: MovieDetailFactoryProtocol) {
        self.id = movie.id
        self.title = movie.title
        self.interactor = interactor
        self.factory = factory

        self.needsFetch = false

        setupMovie(movie)

        showMovieOptions.value = factory.options
    }

    init(id: Int, title: String,
         interactor: MovieDetailInteractorProtocol,
         factory: MovieDetailFactoryProtocol) {
        self.id = id
        self.title = title
        self.interactor = interactor
        self.factory = factory

        self.needsFetch = true

        showMovieOptions.value = factory.options
    }

    // MARK: - Private

    private func setupMovie(_ movie: Movie) {
        releaseDate = movie.releaseDate
        voteAverage = movie.voteAverage
        overview = movie.overview
        posterURL = movie.posterURL
        backdropURL = movie.backdropURL

        getMovieGenreName(for: movie.genreIds?.first)

        didSetupMovieDetail.value = true
    }

    private func getMovieGenreName(for genreId: Int?) {
        guard let genreId = genreId else { return }
        interactor.findGenre(with: genreId, completion: { [weak self] result in
            guard let self = self else { return }
            let genre = try? result.get()
            self.showGenreName.value = genre?.name ?? "-"
        })
    }

    // MARK: - Networking

    func getMovieDetail(showLoader: Bool) {
        fetchMovieDetail(showLoader: showLoader)
    }

    private func fetchMovieDetail(showLoader: Bool = true) {
        guard needsFetch else { return }
        startLoading.value = showLoader
        interactor.getMovieDetail(for: id, completion: { result in
            self.startLoading.value = false
            switch result {
            case .success(let movie):
                self.setupMovie(movie)
                self.checkMovieAccountState()
            case .failure(let error):
                self.showErrorView.value = error
            }
        })
    }

    func saveVisitedMovie() {
        interactor.saveMovieVisit(with: id, title: title, posterPath: posterURL?.absoluteString)
    }

    // MARK: - Movie account state

    func checkMovieAccountState() {
        guard interactor.isUserSignedIn() else {
            self.movieAccountState.value = nil
            return
        }
        interactor.getMovieAccountState(for: id, completion: { result in
            guard let accountState = try? result.get() else {
                self.movieAccountState.value = nil
                return
            }
            self.movieAccountState.value = MovieAccountStateModel.init(accountState)
        })
    }

    // MARK: - Favorites

    func handleFavoriteMovie() {
        guard let currentFavoriteValue = movieAccountState.value?.isFavorite else { return }
        let newFavoriteValue = !currentFavoriteValue
        interactor.markMovieAsFavorite(movieId: id, favorite: newFavoriteValue, completion: { result in
            switch result {
            case .success:
                let movieAccountState = self.movieAccountState.value
                movieAccountState?.isFavorite = newFavoriteValue
                self.movieAccountState.value = movieAccountState
                self.didUpdateFavoriteSuccess.value = newFavoriteValue
            case .failure(let error):
                self.didUpdateFavoriteFailure.value = error
            }
        })
    }

    // MARK: - Alert actions

    func getAvailableAlertActions() -> [MovieDetailActionModel] {
        let shareAction = MovieDetailActionModel(title: LocalizedStrings.movieDetailShareActionTitle()) {
            self.didSelectShareAction.value = true
        }
        return [shareAction]
    }

}

final class MovieAccountStateModel {

    init(_ accountState: Movie.AccountState) {
        self.isFavorite = accountState.favorite
        self.isInWatchlist = accountState.watchlist
    }

    var isFavorite: Bool
    var isInWatchlist: Bool

}
