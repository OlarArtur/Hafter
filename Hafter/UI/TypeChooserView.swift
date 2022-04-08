//
//  TypeChooserView.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

final class TypeChooserView: UIView, AlertViewOutput {
    
    var outputAction: (() -> Void)?
    
    private let formostImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.image(named: ImageConstants.foremostLarge)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let possiblyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.image(named: ImageConstants.possiblyLarge)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let ifNothingElseImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.image(named: ImageConstants.ifNothingElseLarge)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var completion: ((HereafterMovieType) -> Void)?
    
    init(completion: @escaping (HereafterMovieType) -> Void) {
        super.init(frame: .zero)
        self.completion = completion
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = #colorLiteral(red: 0.9529411765, green: 0.968627451, blue: 0.9882352941, alpha: 1)
        addSubview(formostImageView)
        addSubview(possiblyImageView)
        addSubview(ifNothingElseImageView)
        setupConstraints()
        
        let formostTap = UITapGestureRecognizer(target: self, action: #selector(formostAction))
        formostImageView.addGestureRecognizer(formostTap)
        let possiblyTap = UITapGestureRecognizer(target: self, action: #selector(possiblyAction))
        possiblyImageView.addGestureRecognizer(possiblyTap)
        let ifNothingElseTap = UITapGestureRecognizer(target: self, action: #selector(ifNothingElseAction))
        ifNothingElseImageView.addGestureRecognizer(ifNothingElseTap)
    }
    
    @objc private func formostAction() {
        completion?(.foremost)
        outputAction?()
    }
    
    @objc private func possiblyAction() {
        completion?(.possibly)
        outputAction?()
    }
    
    @objc private func ifNothingElseAction() {
        completion?(.ifNothingElse)
        outputAction?()
    }
    
    private func setupConstraints() {
        formostImageView.translatesAutoresizingMaskIntoConstraints = false
        possiblyImageView.translatesAutoresizingMaskIntoConstraints = false
        ifNothingElseImageView.translatesAutoresizingMaskIntoConstraints = false
        
        formostImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        formostImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        formostImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        possiblyImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        possiblyImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        possiblyImageView.topAnchor.constraint(equalTo: formostImageView.bottomAnchor, constant: 3).isActive = true
        possiblyImageView.heightAnchor.constraint(equalTo: formostImageView.heightAnchor).isActive = true
        
        ifNothingElseImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        ifNothingElseImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        ifNothingElseImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        ifNothingElseImageView.topAnchor.constraint(equalTo: possiblyImageView.bottomAnchor, constant: 3).isActive = true
        ifNothingElseImageView.heightAnchor.constraint(equalTo: possiblyImageView.heightAnchor).isActive = true
    }
}
