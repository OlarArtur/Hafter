//
//  TypeChooserView.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

final class TypeChooserView: UIView, AlertViewOutput {
    
    typealias OutputResult = HereafterMovieType
    var outputAction: ((HereafterMovieType) -> Void)?
    
    private let types: [HereafterMovieType] = [.foremost, .possibly, .ifNothingElse]
    private var selectedType: HereafterMovieType = .foremost
    
    private let pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()
    
    private let setButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Set"
        config.baseBackgroundColor = #colorLiteral(red: 0.2862745098, green: 0.3058823529, blue: 0.3764705882, alpha: 1)
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        let setButton = UIButton(configuration: config, primaryAction: nil)
        setButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        setButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        return setButton
    }()
    
    
    private var completion: ((HereafterMovieType) -> Void)?
    
    init(completion: ((HereafterMovieType) -> Void)?) {
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
        addSubview(pickerView)
        addSubview(setButton)
        setupConstraints()
        
        setButton.addTarget(self, action: #selector(tapAction(_:)), for: .touchUpInside)
        
        pickerView.dataSource = self
        pickerView.delegate = self
    }
    
    @objc func tapAction(_ sender: UIButton) {
        completion?(selectedType)
        outputAction?(selectedType)
    }
    
    private func setupConstraints() {
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        setButton.translatesAutoresizingMaskIntoConstraints = false
        
        pickerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        pickerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        pickerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        setButton.topAnchor.constraint(equalTo: pickerView.bottomAnchor).isActive = true
        setButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        setButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        setButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
}

extension TypeChooserView: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return types.count
    }
}

extension TypeChooserView: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return types[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedType = types[row]
    }
}
