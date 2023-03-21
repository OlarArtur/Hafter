//
//  DropListView.swift
//  Hafter
//
//  Created by Artur Olar on 03.04.2022.
//

import UIKit

open class DropListView: UIView {
    
    private var table: UITableView!
    public var selectedIndex: Int?
    
    private var leftImageView: UIImageView?
    private var reuseIdentifier = "DropListCell"
    
    private var rowHeight: CGFloat {
        return bounds.height
    }
    
    //Variables
    private var tableheightX: CGFloat = 120
    private var dataArray: [UIImage] = []
    private var parentController: UIViewController?
    private var pointToParent = CGPoint(x: 0, y: 0)
    private var backgroundView = UIView()
    
    private var isSelected: Bool = false
    
    public var optionArray: [UIImage] = [] {
        didSet {
            leftImageView?.image = optionArray.first
            dataArray = optionArray
        }
    }
    
    public var optionIds: [Int]?
    
    // Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    //MARK: Closures
    private var didSelectCompletion: (Int ,Int) -> () = { index, id  in }
    
    func setupUI() {
        let size = frame.height
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width / 2, height: size))
        addSubview(leftView)
        let leftImage = UIImage.image(named: ImageConstants.foremost)
        let leftImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        leftImageView.contentMode = .scaleAspectFit
        leftImageView.image = leftImage
        self.leftImageView = leftImageView
        leftView.addSubview(leftImageView)
        
        let rightView = UIView(frame: CGRect(x: frame.width / 2, y: 0, width: frame.width / 2, height: size))
        addSubview(rightView)
        let image = UIImage.image(named: ImageConstants.dropListArrow)
        let imageView = UIImageView(frame: CGRect(x: ((size / 2) - ((image?.size.width ?? 0) / 2)), y: ((size / 2) - ((image?.size.height ?? 0) / 2)), width: 10, height: 7))
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        rightView.addSubview(imageView)
        
        backgroundView = UIView(frame: .zero)
        backgroundView.backgroundColor = .clear
        addGesture()
    }
    
    private func addGesture() {
        let gesture =  UITapGestureRecognizer(target: self, action:  #selector(touchAction))
        addGestureRecognizer(gesture)
        let gesture2 =  UITapGestureRecognizer(target: self, action:  #selector(touchAction))
        backgroundView.addGestureRecognizer(gesture2)
    }
    
    func getConvertedPoint(_ targetView: UIView, baseView: UIView?) -> CGPoint {
        var pnt = targetView.frame.origin
        if targetView.superview == nil {
            return pnt
        }
        var superView = targetView.superview
        while superView != baseView{
            pnt = superView!.convert(pnt, to: superView!.superview)
            if nil == superView!.superview{
                break
            } else {
                superView = superView!.superview
            }
        }
        return superView!.convert(pnt, to: baseView)
    }
    
    public func showList() {
        if parentController == nil {
            parentController = parentViewController
        }
        backgroundView.frame = parentController?.view.frame ?? backgroundView.frame
        pointToParent = getConvertedPoint(self, baseView: parentController?.view)
        parentController?.view.insertSubview(backgroundView, aboveSubview: self)
        tableheightX = (rowHeight + 6) * CGFloat(dataArray.count)
        table = UITableView(frame: CGRect(x: pointToParent.x ,
                                          y: pointToParent.y + frame.height ,
                                          width: frame.width,
                                          height: frame.height))
        table.dataSource = self
        table.delegate = self
        table.alpha = 0
        table.separatorStyle = .none
        table.layer.cornerRadius = 10
        table.backgroundColor = backgroundColor
        table.rowHeight = rowHeight + 6
        table.isScrollEnabled = false
        table.register(DropListCell.self, forCellReuseIdentifier: reuseIdentifier)
        parentController?.view.addSubview(table)
        isSelected = true
        let y = pointToParent.y + frame.height + 5
        
        UIView.animate(withDuration: 0.3,
                       animations: { () -> Void in
                        
                        self.table.frame = CGRect(x: self.pointToParent.x,
                                                  y: y,
                                                  width: self.frame.width,
                                                  height: self.tableheightX)
                        self.table.alpha = 1
                       },
                       completion: { (finish) -> Void in
                        self.layoutIfNeeded()
                       })
    }
    
    public func hideList() {
        UIView.animate(withDuration: 0.3,
                       animations: { () -> Void in
                        self.table.frame = CGRect(x: self.pointToParent.x,
                                                  y: self.pointToParent.y+self.frame.height,
                                                  width: self.frame.width,
                                                  height: 0)
                       },
                       completion: { (didFinish) -> Void in
                        self.table.removeFromSuperview()
                        self.backgroundView.removeFromSuperview()
                        self.isSelected = false
                       })
    }
    
    @objc public func touchAction() {
        isSelected ? hideList() : showList()
    }
    
    func reSizeTable() {
        tableheightX = (rowHeight + 6) * CGFloat(dataArray.count)
        let y = pointToParent.y + frame.height + 5

        UIView.animate(withDuration: 0.2,
                       animations: { () -> Void in
                        self.table.frame = CGRect(x: self.pointToParent.x,
                                                  y: y,
                                                  width: self.frame.width,
                                                  height: self.tableheightX)
                       },
                       completion: { (didFinish) -> Void in
                        self.layoutIfNeeded()
                        
                       })
    }
    
    //MARK: Actions Methods
    public func didSelect(completion: @escaping (_ index: Int, _ id: Int) -> ()) {
        didSelectCompletion = completion
    }
}

///MARK: UITableViewDataSource
extension DropListView: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as? DropListCell else { return UITableViewCell() }
        cell.configure(image: dataArray[indexPath.row])
        return cell
    }
}

//MARK: UITableViewDelegate
extension DropListView: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = (indexPath as NSIndexPath).row
        let selectedImage = dataArray[selectedIndex!]
        leftImageView?.image = selectedImage
        touchAction()
        endEditing(true)
        if let selected = optionArray.firstIndex(where: { $0 == selectedImage} ) {
            if let id = optionIds?[selected] {
                didSelectCompletion(selected, id)
            } else {
                didSelectCompletion(selected, 0)
            }
        }
    }
}

extension UIView {
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}


class MyContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration
    init(_ configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame:.zero)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct MyContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return MyContentView(self)
    }
    func updated(for state: UIConfigurationState) -> MyContentConfiguration {
        return self
    }
}
