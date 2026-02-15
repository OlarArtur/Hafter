//
//  IntroductionViewController.swift
//  Hafter
//
//  Created by Artur Olar on 28.03.2022.
//

import UIKit

protocol IntroductionViewProtocol: AnyObject {

}

final class IntroductionViewController: BaseViewController<IntroductionViewModelProtocol> {

    private let startButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Let's Go", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 20)
        b.backgroundColor = UIColor(red: 0.51, green: 0.58, blue: 0.99, alpha: 1)
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        b.layer.cornerRadius = 18
        return b
    }()

    private let userImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        v.image = UIImage(named: "user_choosing_right")
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Forget the 'What to watch?' \nstruggle"
        l.font = .boldSystemFont(ofSize: 27)
        l.textColor = UIColor(red: 0.51, green: 0.58, blue: 0.99, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let backgroundImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.image = UIImage(named: "choose_background")
        return v
    }()

    private let images = [UIImage(named: "user_choosing_right")!, UIImage(named: "user_choosing_left")!]
    private var currentImageIndex = 0

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
        view.backgroundColor = .systemBackground
        setupLayout()
        startButton.addTarget(self, action: #selector(getStartedAction), for: .touchUpInside)
        setupWaveAnimation()
        animateUserImageView()
        startButton.startPulseAnimation()
        startButton.layer.zPosition = 10
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc private func getStartedAction() {
        viewModel?.getStarted()
    }
}

private extension IntroductionViewController {

    func setupLayout() {
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(startButton)
        view.addSubview(userImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            startButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 54),

            userImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            userImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: 200),
            userImageView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    func animateUserImageView() {
        currentImageIndex = (currentImageIndex + 1) % images.count

        UIView.transition(with: userImageView,
                          duration: 0.5,
                          options: [.transitionCrossDissolve],
                          animations: {
                              self.userImageView.image = self.images[self.currentImageIndex]
                          },
                          completion: { _ in
                              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                  self.animateUserImageView()
                              }
                          })
    }

    func setupMoviesBehaviors() {
        animator = UIDynamicAnimator(referenceView: view)

        for movie in moviesGroup {
            let snap = UISnapBehavior(item: movie, snapTo: CGPoint(x: userImageView.frame.midX, y: userImageView.frame.minY))
            snap.damping = 0
            animator?.addBehavior(snap)
        }

        attachmentBehavior = UIAttachmentBehavior(item: userImageView, offsetFromCenter: UIOffset(horizontal: 0, vertical: 150), attachedToAnchor: CGPoint(x: view.bounds.midX, y: view.bounds.maxY))
        attachmentBehavior?.attachmentRange = UIFloatRange(minimum: 0, maximum: 5)
        if let attachmentBehavior = attachmentBehavior {
            animator?.addBehavior(attachmentBehavior)
        }

        for movie in moviesGroup {
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
        if let flyBehavior = flyBehavior {
            animator?.addBehavior(flyBehavior)
        }
    }

    func setupWaveAnimation() {
        for movie in moviesGroup {

            movie.frame = CGRect(x: -160, y: 300, width: 60, height: 50)
            view.addSubview(movie)

            let randomYOffset = CGFloat(arc4random_uniform(350))

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

fileprivate extension UIButton {

    func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 0.6
        pulse.fromValue = 1.0
        pulse.toValue = 1.05
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity

        layer.add(pulse, forKey: "pulse")
    }
}
