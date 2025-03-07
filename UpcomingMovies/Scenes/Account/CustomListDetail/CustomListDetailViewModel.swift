//
//  CustomListDetailViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 4/19/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class CustomListDetailViewModel: CustomListDetailViewModelProtocol {

    // MARK: - Dependencies

    private let list: List
    private let interactor: CustomListDetailInteractorProtocol

    // MARK: - Reactive properties

    let viewState = BehaviorBindable(CustomListDetailViewState.loading).eraseToAnyBindable()

    // MARK: - Computed properties

    private var movies: [Movie] {
        viewState.value.currentMovies
    }

    var movieCells: [MovieCellViewModel] {
        movies.map { MovieCellViewModel($0) }
    }

    var listName: String? {
        self.list.name
    }

    // MARK: - Initializers

    init(_ list: List, interactor: CustomListDetailInteractorProtocol) {
        self.list = list
        self.interactor = interactor
    }

    // MARK: - CustomListDetailViewModelProtocol

    func buildHeaderViewModel() -> CustomListDetailHeaderViewModelProtocol {
        CustomListDetailHeaderViewModel(list: list)
    }

    func buildSectionViewModel() -> CustomListDetailSectionViewModel {
        CustomListDetailSectionViewModel(list: list)
    }

    func movie(at index: Int) -> Movie {
        movies[index]
    }

    func getListMovies() {
        interactor.getCustomListMovies(listId: list.id, completion: { result in
            switch result {
            case .success(let movies):
                self.viewState.value = self.processResult(movies)
            case .failure(let error):
                self.viewState.value = .error(error)
            }
        })
    }

    // MARK: - Private

    private func processResult(_ movies: [Movie]) -> CustomListDetailViewState {
        guard !movies.isEmpty else { return .empty }

        return .populated(movies)
    }

}
