//
//  VerticalLabelView.swift
//  Hafter
//
//  Created by Artur Olar on 15.11.2023.
//

import UIKit

final class VerticalLabelView: UIView {
    
    var numberOfLines: Int = 1 {
        didSet {
            label.numberOfLines = numberOfLines
        }
    }
    
    var text: String = "" {
        didSet {
            label.text = text
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            guard oldValue != isSelected else {
                return
            }
            convex()
        }
    }
    
    override func setContentHuggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        label.setContentHuggingPriority(priority, for: axis == .horizontal ? .vertical : .horizontal)
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = #colorLiteral(red: 0.3568627451, green: 0.3254901961, blue: 0.5411764706, alpha: 1)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        addSubview(label)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // rotate 90-degrees
        let angle = -CGFloat.pi / 2
        label.transform = CGAffineTransform(rotationAngle: angle)
        
        label.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -10).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        convex()
    }
    
    func convex() {
        if isSelected {
            let width = bounds.width
            let height = bounds.height
            
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: width - 20, y: 0))
            path.addQuadCurve(to: CGPoint(x: width - 10, y: 2/6 * height), controlPoint: CGPoint(x: width - 20, y: 1/6 * height))
            path.addQuadCurve(to: CGPoint(x: width - 10, y: 4/6 * height), controlPoint: CGPoint(x: width, y: height / 2))
            path.addQuadCurve(to: CGPoint(x: width - 20, y: height), controlPoint: CGPoint(x: width - 20, y: 5/6 * height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: .zero)
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        } else {
            let width = bounds.width
            let height = bounds.height
            
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: width - 20, y: 0))
            path.addLine(to: CGPoint(x: width - 20, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: .zero)
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }
}
