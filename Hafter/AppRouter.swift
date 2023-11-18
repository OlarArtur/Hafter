//
//  AppRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

final class AppRouter: NSObject {
    
    private var startingRect: CGRect = .zero
    private var selectedType: HereafterMovieType?
    
    private(set) var window: UIWindow
    private var baseNavigationController: UINavigationController?
    private var localDataService: LocalServiceProtocol = LocalService(provider: LocalDataProvider())
    private let imageLoader = ImageLoader()
    
    private var addCompetion: (() -> Void)?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func run() {
        start()
    }
    
    var rootViewController: UIViewController? {
        return window.rootViewController
    }
    
    internal func start() {
        let introductionFinished = Settings.shared.introductionFinished
        
        if introductionFinished {
            showMainStoryboard()
        } else {
            let introductionNavVC = IntroductionBuilder.build(output: self)
            window.rootViewController = introductionNavVC
            window.makeKeyAndVisible()
        }
    }
    
    func showMainStoryboard(animated: Bool = false) {
        let dummyView = UIViewController()
        window.rootViewController = dummyView
        window.makeKeyAndVisible()
        
        guard let hereafterViewController = HereafterBuilder.build(localDataService: localDataService, output: self) else { return }
        let navigationVC = NavigationControllerViewController(rootViewController: hereafterViewController)
        baseNavigationController = navigationVC
        window.setRootViewController(navigationVC, animated: animated, completion: nil)
    }
}

private extension AppRouter {
    
}

extension AppRouter: IntroductionOutputProtocol {
    
    func introductionFinished() {
        Settings.shared.introductionFinished = true
        showMainStoryboard()
    }
}

extension AppRouter: HereafterOutputProtocol {
    
    func selected(_ movie: DetailedMovie, type: HereafterMovieType) {
        guard let detailVC = ItemDetailBuilder.build(movie: movie, type: type, localDataService: localDataService) else {
            return
        }
        rootViewController?.present(detailVC, animated: true)
    }
    
    func randomize() {
        let movies = localDataService.getMovies(type: .none)
        
        guard let randomizeVC = RandomizeBuilder.build(output: self, movies: movies, imageLoader: imageLoader) else {
            return
        }
        rootViewController?.present(randomizeVC, animated: true)
    }
    
    func add(completion: @escaping () -> Void) {
        addCompetion = completion
        guard let addVC = AddBuilder.build(output: self) else {
            return
        }
        rootViewController?.show(addVC, sender: nil)
    }
    
    func openMenu() {
        guard let addVC = MenuBuilder.build(output: self) else {
            return
        }
        addVC.modalPresentationStyle = .fullScreen
        addVC.transitioningDelegate = addVC as? UIViewControllerTransitioningDelegate
        rootViewController?.present(addVC, animated: true)
    }
    
    func openViewed() {
        guard let listVC = ListBuilder.build(type: .viewed, output: self, localDataService: localDataService, admissibleTypes: [.foremost, .possibly, .ifNothingElse]) else {
            return
        }
        selectedType = .viewed
        rootViewController?.present(listVC, animated: true)
    }
    
    func openList(type: HereafterMovieType, rect: CGRect) {
        startingRect = rect
        selectedType = type
        let types = HereafterMovieType.allCases.filter { $0 != type }
        guard let listVC = ListBuilder.build(type: type, output: self, localDataService: localDataService, admissibleTypes: types) else {
            return
        }
        listVC.modalPresentationStyle = .fullScreen
        listVC.transitioningDelegate = self
        rootViewController?.present(listVC, animated: true)
    }
}

extension AppRouter: AddOutputProtocol {
    
    func added(movie: HereafterMovie, controller: UIViewController) {
        localDataService.save(movie: movie) { [weak self] success in
            controller.hide(animated: true)
            self?.addCompetion?()
        }
    }
}

extension AppRouter: MenuOutputProtocol {
    
}

extension AppRouter: RandomizeOutputProtocol {
    
}

extension AppRouter: ListOutputProtocol {
    
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        localDataService.update(movie: movie, completion: completion)
    }
}

extension AppRouter: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentAnimator = ExpandViewPresentAnimator()
        presentAnimator.startingRect = startingRect
        presentAnimator.color = selectedType?.typeColor
        return presentAnimator
    }
}

