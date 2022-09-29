//
//  AccountViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 3/20/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class AccountViewModel: AccountViewModelProtocol {

    private let interactor: AccountInteractorProtocol

    let showAuthPermission: PublishBindable<URL> = PublishBindable()
    let didSignIn: Bindable<Void> = Bindable()
    let didReceiveError: Bindable<Void> = Bindable()

    // MARK: - Initializers

    init(interactor: AccountInteractorProtocol) {
        self.interactor = interactor
    }

    // MARK: - AccountViewModelProtocol

    func startAuthorizationProcess() {
        interactor.getAuthPermissionURL { result in
            switch result {
            case .success(let url):
                self.showAuthPermission.send(url)
            case .failure:
                self.didReceiveError.fire()
            }
        }
    }

    func signInUser() {
        interactor.signInUser { result in
            switch result {
            case .success:
                self.didSignIn.fire()
            case .failure:
                self.didReceiveError.fire()
            }
        }
    }

    func signOutCurrentUser() {
        interactor.signOutUser()
    }

    func isUserSignedIn() -> Bool {
        return currentUser() != nil
    }

    func currentUser() -> User? {
        return interactor.currentUser()
    }

}
