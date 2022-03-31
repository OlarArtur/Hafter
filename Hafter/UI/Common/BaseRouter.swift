//
//  BaseRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

protocol RouterProtocol {

}

class BaseRouter: NSObject, RouterProtocol {
    weak var presenter: UIViewController?

    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
}
