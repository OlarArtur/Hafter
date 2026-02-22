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
    
    private let underlayButtonView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.borderColor = UIColor(red: 0.26, green: 0.32, blue: 0.72, alpha: 0.3).cgColor
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 18
        return v
    }()
    
    private let lightShadowButtonView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let darkShadowButtonView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let startButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .white
        config.attributedTitle = AttributedString("Let's Go", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 24)]))
        config.background.backgroundColor = UIColor(red: 0.51, green: 0.58, blue: 0.99, alpha: 1)
        config.background.cornerRadius = 18
        b.configuration = config
        return b
    }()
    
    private let questionImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        v.image = UIImage(named: "user_choosing_question")
        return v
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
        l.text = "Too Many Movies."
        l.font = .systemFont(ofSize: 38, weight: .semibold)
        l.textColor = UIColor(red: 0.26, green: 0.32, blue: 0.72, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Zero Decisions."
        l.font = .systemFont(ofSize: 36, weight: .semibold)
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
        v.image = UIImage(named: "onboardingBackground")
        return v
    }()

    private let images = [UIImage(named: "user_choosing")!, UIImage(named: "user_choosing")!]
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
//        setupWaveAnimation()
        animateUserImageView()
        underlayButtonView.startPulseAnimation()
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
        view.addSubview(subtitleLabel)
        view.addSubview(userImageView)
        view.addSubview(questionImageView)
        setup(shadowView: lightShadowButtonView, backgroundColor: .white, shadowColor: .white)
        view.addSubview(lightShadowButtonView)
        setup(shadowView: darkShadowButtonView,
              backgroundColor: UIColor(red: 0.26, green: 0.32, blue: 0.72, alpha: 1),
              shadowColor: UIColor(red: 0.26, green: 0.32, blue: 0.72, alpha: 1))
        view.addSubview(darkShadowButtonView)
        view.addSubview(underlayButtonView)
        underlayButtonView.addSubview(startButton)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            underlayButtonView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            underlayButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            underlayButtonView.widthAnchor.constraint(equalToConstant: 222),
            underlayButtonView.heightAnchor.constraint(equalToConstant: 56),
            
            lightShadowButtonView.topAnchor.constraint(equalTo: underlayButtonView.topAnchor, constant: -2),
            lightShadowButtonView.leadingAnchor.constraint(equalTo: underlayButtonView.leadingAnchor, constant: 20),
            lightShadowButtonView.trailingAnchor.constraint(equalTo: underlayButtonView.trailingAnchor, constant: -20),
            lightShadowButtonView.heightAnchor.constraint(equalToConstant: 28),
            
            darkShadowButtonView.bottomAnchor.constraint(equalTo: underlayButtonView.bottomAnchor, constant: -2),
            darkShadowButtonView.leadingAnchor.constraint(equalTo: underlayButtonView.leadingAnchor, constant: 20),
            darkShadowButtonView.trailingAnchor.constraint(equalTo: underlayButtonView.trailingAnchor, constant: -20),
            darkShadowButtonView.heightAnchor.constraint(equalToConstant: 28),

            startButton.bottomAnchor.constraint(equalTo: underlayButtonView.bottomAnchor, constant: -2),
            startButton.topAnchor.constraint(equalTo: underlayButtonView.topAnchor, constant: 2),
            startButton.leadingAnchor.constraint(equalTo: underlayButtonView.leadingAnchor, constant: 2),
            startButton.trailingAnchor.constraint(equalTo: underlayButtonView.trailingAnchor, constant: -2),

            userImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            userImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: 400),
            userImageView.heightAnchor.constraint(equalToConstant: 500),
            
            questionImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            questionImageView.bottomAnchor.constraint(equalTo: userImageView.topAnchor, constant: 250),
            questionImageView.widthAnchor.constraint(equalToConstant: 200),
            questionImageView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    func animateUserImageView() {
        currentImageIndex = (currentImageIndex + 1) % images.count

        UIView.transition(with: userImageView,
                          duration: 0.3,
                          options: [.transitionCrossDissolve],
                          animations: {
            self.userImageView.image = self.images[self.currentImageIndex]
            self.questionImageView.alpha = self.currentImageIndex == 0 ? 1 : 0.8
        },
                          completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
    
    func setup(shadowView: UIView, backgroundColor: UIColor, shadowColor: UIColor) {
        shadowView.backgroundColor = backgroundColor
        shadowView.layer.cornerRadius = 24
        shadowView.layer.shadowColor = shadowColor.cgColor
        shadowView.layer.shadowOpacity = 0.8
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowView.layer.shadowRadius = 20
        shadowView.clipsToBounds = false
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

fileprivate extension UIView {

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
