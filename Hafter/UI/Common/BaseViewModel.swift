//
//  BaseViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation
import Combine

protocol UpdatableViewModelProtocol {
    var updateSignal: PassthroughSubject<Void, Never> { get }
}

class BaseViewModel<T: RouterProtocol>: NSObject, UpdatableViewModelProtocol {

    let updateSignal = PassthroughSubject<Void, Never>()
    private(set) var router: T?

    init(router: T?) {
        self.router = router
    }
}
