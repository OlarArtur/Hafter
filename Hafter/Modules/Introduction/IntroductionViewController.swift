//
//  IntroductionViewController.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

protocol IntroductionViewProtocol: AnyObject {
    
}

final class IntroductionViewController: BaseViewController<IntroductionViewModelProtocol> {
    
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var userImageView: UIImageView!
    
    private let moviesCount = 24
    
    lazy var moviesGroup: [UIImageView] = {
        var moviesGroup: [UIImageView] = []
        for index in 1...moviesCount {
            let calcX = index - (6 * (index / 6))
            let moviewNumber = calcX == 0 ? 6 : calcX
            let calc = index - (4 * (index / 4))
            let imageNumber = calc == 0 ? 4 : calc
            let imageView = UIImageView(frame: CGRect(x: moviewNumber * 60, y: (index / 6) * 40, width: 60, height: 40))
            imageView.image = UIImage(named: "movie-\(imageNumber)")
            moviesGroup.append(imageView)
        }
        return moviesGroup
    }()
    
    var animator: UIDynamicAnimator?
    var gravityBehavior: UIGravityBehavior?
    var pushBehavior: UIPushBehavior?
    var collisionBehavior: UICollisionBehavior?
    var flyBehavior: UIDynamicItemBehavior?
    var attachmentBehavior: UIAttachmentBehavior?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupView()
        setupWaveAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        setupMoviesBehaviors()
    }
    
    @IBAction func getStartedAction(_ sender: Any) {
        viewModel?.getStarted()
    }
}

private extension IntroductionViewController {
    
    func setupView() {
        for movie in moviesGroup {
            view.addSubview(movie)
        }
    }
    
    func setupMoviesBehaviors() {
        animator = UIDynamicAnimator(referenceView: view)
        
//        gravityBehavior = UIGravityBehavior(items: moviesGroup)
//        gravityBehavior?.gravityDirection = CGVector(dx: 0, dy: 0.8)
//        animator?.addBehavior(gravityBehavior!)
        
        for movie in moviesGroup {
            let snap = UISnapBehavior(item: movie, snapTo: CGPoint(x: userImageView.frame.midX, y: userImageView.frame.minY))
            snap.damping = 0
            animator?.addBehavior(snap)
        }
        
        attachmentBehavior = UIAttachmentBehavior(item: userImageView, offsetFromCenter: UIOffset(horizontal: 0, vertical: 150), attachedToAnchor: CGPoint(x: view.bounds.midX, y: view.bounds.maxY))
        attachmentBehavior?.attachmentRange = UIFloatRange(minimum: 0, maximum: 5)
        animator?.addBehavior(attachmentBehavior!)
        
        for movie in moviesGroup {
//          collisionBehavior = UICollisionBehavior(items: moviesGroup)
            let collisionBehavior = UICollisionBehavior(items: [movie])
            collisionBehavior.addItem(userImageView)
            collisionBehavior.translatesReferenceBoundsIntoBoundary = true
            collisionBehavior.collisionMode = .everything
            collisionBehavior.collisionDelegate = self
            animator?.addBehavior(collisionBehavior)
        }
        
        
        flyBehavior = UIDynamicItemBehavior(items: moviesGroup)
        flyBehavior?.allowsRotation = true
        flyBehavior?.density = 1000
        flyBehavior?.elasticity = 1
        flyBehavior?.friction = 0
        flyBehavior?.resistance = 0
        animator?.addBehavior(flyBehavior!)
    }
    
    func setupWaveAnimation() {
        for movie in moviesGroup {
            
            movie.frame = CGRect(x: -160, y: 300, width: 60, height: 50)
            self.view.addSubview(movie)
            
            let randomYOffset = CGFloat( arc4random_uniform(350))
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 16, y: 239 + randomYOffset))
            path.addCurve(to: CGPoint(x: view.frame.maxX + 60, y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
            
            let anim = CAKeyframeAnimation(keyPath: "position")
            anim.path = path.cgPath
            anim.rotationMode = .rotateAuto
            anim.repeatCount = Float.infinity
            anim.duration = Double(arc4random_uniform(40) + 30) / 10
            anim.timeOffset = Double(arc4random_uniform(290))
            
            movie.layer.add(anim, forKey: "animate position along path")
        }
    }
}

extension IntroductionViewController: IntroductionViewProtocol {
    
}

extension IntroductionViewController: UICollisionBehaviorDelegate {
    
}
