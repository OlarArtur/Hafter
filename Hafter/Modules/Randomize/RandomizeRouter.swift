//
//  RandomizeRouter.swift
//  Hafter
//
//  Created by Artur Olar on 09.04.2022.
//

import UIKit

protocol RandomizeOutputProtocol: AnyObject {
    
}

protocol RandomizeRouterProtocol: RouterProtocol {
    
}

final class RandomizeRouter: BaseRouter {
    weak var output: RandomizeOutputProtocol?
}

extension RandomizeRouter: RandomizeRouterProtocol {
    
}
