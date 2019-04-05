//
//  AccountViewController.swift
//  UpcomingMovies
//
//  Created by Alonso on 3/20/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController, SegueHandler {
    
    private lazy var signInViewController: SignInViewController = {
        var viewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! SignInViewController
        viewController.delegate = self
        self.add(asChildViewController: viewController)
        return viewController
    }()
    
    private lazy var profileViewController: ProfileTableViewController = {
        var viewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileTableViewController") as! ProfileTableViewController
        viewController.delegate = self
        viewController.viewModel = viewModel.buildProfileViewModel()
        self.add(asChildViewController: viewController)
        return viewController
    }()
    
    private var viewModel = AccountViewModel()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindables()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        title = Constants.Title
        setupContainerView()
        setupNavigationBar()
    }
    
    private func setupContainerView() {
        if AuthenticationManager.shared.isUserSignedIn() {
            navigationController?.navigationBar.isHidden = false
            add(asChildViewController: profileViewController)
        } else {
            navigationController?.navigationBar.isHidden = true
            add(asChildViewController: signInViewController)
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.title = Constants.NavigationItemTitle
    }
    
    private func showSignInView() {
        remove(asChildViewController: profileViewController)
        add(asChildViewController: signInViewController)
    }
    
    private func showProfileView() {
        remove(asChildViewController: signInViewController)
        // Rebuild the profile view model to show an up to date profile.
        profileViewController.viewModel = viewModel.buildProfileViewModel()
        add(asChildViewController: profileViewController)
    }
    
    private func didSignIn() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        showProfileView()
    }
    
    private func didSignOut() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        showSignInView()
    }
    
    // MARK: - Reactive Behaviour
    
    private func setupBindables() {
        viewModel.showAuthPermission = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.performSegue(withIdentifier: SegueIdentifier.authPermission.rawValue,
                                    sender: nil)
        }
        viewModel.didSignIn = { [weak self] in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.didSignIn()
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .authPermission:
            guard let navController = segue.destination as? UINavigationController,
                let viewController = navController.topViewController as? AuthPermissionViewController else {
                    return
            }
            _ = viewController.view
            viewController.delegate = self
            viewController.viewModel = viewModel.buildAuthPermissionViewModel()
        case .favoriteMovies:
            guard let viewController = segue.destination as? FavoriteMoviesViewController else {
                return
            }
            _ = viewController.view
            viewController.viewModel = viewModel.buildFavoriteMoviesViewModel()
        }
    }
    
}

// MARK: - SignInViewControllerDelegate

extension AccountViewController: SignInViewControllerDelegate {
    
    func signInViewController(_ signInViewController: SignInViewController, didTapSignInButton tapped: Bool) {
        viewModel.getRequestToken()
    }
    
}

// MARK: - ProfileViewControllerDelegate

extension AccountViewController: ProfileViewControllerDelegate {
    
    func profileViewController(_ profileViewController: ProfileTableViewController, didTapCollection collection: ProfileOption) {
        switch collection {
        case .favorites:
            performSegue(withIdentifier: SegueIdentifier.favoriteMovies.rawValue,
                         sender: nil)
        case .watchlist:
            break
        }
    }
    
    func profileViewController(_ profileViewController: ProfileTableViewController, didTapSignOutButton tapped: Bool) {
        AuthenticationManager.shared.deleteCurrentUser()
        didSignOut()
    }
    
}

// MARK: - AuthPermissionViewControllerDelegate

extension AccountViewController: AuthPermissionViewControllerDelegate {
    
    func authPermissionViewController(_ authPermissionViewController: AuthPermissionViewController,
                                      didSignedIn signedIn: Bool) {
        viewModel.createSessionId()
    }
    
}

// MARK: - Segue Identifiers

extension AccountViewController {
    
    enum SegueIdentifier: String {
        case authPermission = "AuthPermissionSegue"
        case favoriteMovies = "FavoriteMoviesSegue"
    }
    
}

// MARK: - Constants

extension AccountViewController {
    
    struct Constants {
        
        static let Title = NSLocalizedString("accountTabBarTitle", comment: "")
        static let NavigationItemTitle = NSLocalizedString("accountTitle", comment: "")
        
    }
    
}
