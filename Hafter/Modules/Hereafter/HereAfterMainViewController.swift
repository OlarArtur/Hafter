//
//  HereAfterMainViewController.swift
//  Hafter
//
//  Created by Artur Olar on 15.11.2023.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol HereafterViewProtocol: AnyObject {
    func reloadData()
    func updateUI()
    func showError(error: Error)
}

final class HereAfterMainViewController: BaseViewController<HereafterViewModelProtocol> {

    var localService: LocalServiceProtocol?
    private var socialCoordinator: SocialCoordinator?

    private let backgroundImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.image = UIImage(named: "background_image")
        return v
    }()

    private let sidebarView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = DS.Color.sidebarBackground
        return v
    }()

    private let addView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let addImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.image = UIImage(named: "add_plus")
        return v
    }()

    private let randomizeView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let randomizeImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.image = UIImage(named: "randomize")
        return v
    }()

    private let foremostView = VerticalLabelView()
    private let possiblyView = VerticalLabelView()
    private let ifNothingElseView = VerticalLabelView()

    private let listTableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .clear
        t.separatorStyle = .singleLine
        return t
    }()

    private let imageLoader = ImageLoader()
    private var tonightListener: ListenerRegistration?
    private var friendAlreadyWatched = false

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Search saved movies"
        sc.searchBar.tintColor = DS.Color.accent
        return sc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        foremostView.backgroundColor = ColorConstants.formost
        possiblyView.backgroundColor = ColorConstants.possibly
        ifNothingElseView.backgroundColor = ColorConstants.ifNothingElse

        foremostView.text = HereafterMovieType.foremost.title
        possiblyView.text = HereafterMovieType.possibly.title
        ifNothingElseView.text = HereafterMovieType.ifNothingElse.title

        setupLayout()
        setupNavigationController()
        setupGestures()
        setupTableView()

        foremostAction()
        viewModel?.onNeedsViewedDetails = { [weak self] finish in
            guard let self else { return }
            ViewedDetailsEditor.present(on: self, completion: finish)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTonightBanner()
        watchTonightSession()
    }

    deinit { tonightListener?.remove() }

    @objc private func addAction() {
        viewModel?.add()
    }

    @objc private func randomizeAction() {
        viewModel?.randomize()
    }

    @objc private func viewedTapped() {
        viewModel?.openViewed()
    }

    @objc private func friendsTapped() {
        guard let localService else { return }
        socialCoordinator = SocialCoordinator(presenter: self, localService: localService)
        socialCoordinator?.start()
    }

    @objc private func foremostAction() {
        select(type: .foremost)
        viewModel?.select(type: .foremost, rect: .zero)
    }

    @objc private func possiblyAction() {
        select(type: .possibly)
        viewModel?.select(type: .possibly, rect: .zero)
    }

    @objc private func ifNothingElseAction() {
        select(type: .ifNothingElse)
        viewModel?.select(type: .ifNothingElse, rect: .zero)
    }
}

private extension HereAfterMainViewController {

    func setupLayout() {
        view.addSubview(backgroundImageView)
        view.addSubview(sidebarView)
        view.addSubview(listTableView)

        sidebarView.addSubview(addView)
        addView.addSubview(addImageView)
        sidebarView.addSubview(randomizeView)
        randomizeView.addSubview(randomizeImageView)
        sidebarView.addSubview(foremostView)
        sidebarView.addSubview(possiblyView)
        sidebarView.addSubview(ifNothingElseView)

        foremostView.translatesAutoresizingMaskIntoConstraints = false
        possiblyView.translatesAutoresizingMaskIntoConstraints = false
        ifNothingElseView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
            sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebarView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),

            addView.topAnchor.constraint(equalTo: sidebarView.topAnchor, constant: 105),
            addView.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor),
            addView.widthAnchor.constraint(equalToConstant: 60),
            addView.heightAnchor.constraint(equalToConstant: 60),

            addImageView.topAnchor.constraint(equalTo: addView.topAnchor),
            addImageView.leadingAnchor.constraint(equalTo: addView.leadingAnchor),
            addImageView.trailingAnchor.constraint(equalTo: addView.trailingAnchor),
            addImageView.bottomAnchor.constraint(equalTo: addView.bottomAnchor),

            randomizeView.topAnchor.constraint(equalTo: addView.bottomAnchor, constant: 20),
            randomizeView.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor),
            randomizeView.widthAnchor.constraint(equalToConstant: 60),
            randomizeView.heightAnchor.constraint(equalToConstant: 60),

            randomizeImageView.leadingAnchor.constraint(equalTo: randomizeView.leadingAnchor),
            randomizeImageView.trailingAnchor.constraint(equalTo: randomizeView.trailingAnchor),
            randomizeImageView.topAnchor.constraint(equalTo: randomizeView.topAnchor),
            randomizeImageView.bottomAnchor.constraint(equalTo: randomizeView.bottomAnchor),

            foremostView.topAnchor.constraint(equalTo: randomizeView.bottomAnchor, constant: 40),
            foremostView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            foremostView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: 20),
            foremostView.heightAnchor.constraint(equalTo: possiblyView.heightAnchor),

            possiblyView.topAnchor.constraint(equalTo: foremostView.bottomAnchor),
            possiblyView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            possiblyView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: 20),
            possiblyView.heightAnchor.constraint(equalTo: ifNothingElseView.heightAnchor),

            ifNothingElseView.topAnchor.constraint(equalTo: possiblyView.bottomAnchor),
            ifNothingElseView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            ifNothingElseView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: 20),
            ifNothingElseView.bottomAnchor.constraint(equalTo: sidebarView.bottomAnchor, constant: -100),
            ifNothingElseView.heightAnchor.constraint(equalTo: foremostView.heightAnchor),

            listTableView.topAnchor.constraint(equalTo: view.topAnchor),
            listTableView.leadingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            listTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupGestures() {
        let addTap = UITapGestureRecognizer(target: self, action: #selector(addAction))
        addView.addGestureRecognizer(addTap)
        let randomizeTap = UITapGestureRecognizer(target: self, action: #selector(randomizeAction))
        randomizeView.addGestureRecognizer(randomizeTap)
        foremostView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(foremostAction)))
        possiblyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(possiblyAction)))
        ifNothingElseView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ifNothingElseAction)))
    }

    func setupTableView() {
        listTableView.registerCell(ListTableViewCell.self)
        listTableView.separatorStyle = .none
        listTableView.rowHeight = 160
        listTableView.dataSource = self
        listTableView.delegate = self
    }

    func setupNavigationController() {
        let viewedButton = UIBarButtonItem(
            image: UIImage.image(named: ImageConstants.viewed),
            style: .plain,
            target: self,
            action: #selector(viewedTapped)
        )
        viewedButton.tintColor = DS.Color.navIconDark

        let friendsButton = UIBarButtonItem(
            image: UIImage(systemName: "person.2"),
            style: .plain,
            target: self,
            action: #selector(friendsTapped)
        )
        friendsButton.tintColor = DS.Color.navIconDark

        navigationItem.rightBarButtonItems = [viewedButton, friendsButton]
        navigationItem.leftBarButtonItem = makeSortBarButton()

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }

    func makeSortBarButton() -> UIBarButtonItem {
        let currentOrder = viewModel?.sortOrder ?? .alphabetical
        let actions = MovieSortOrder.allCases.map { order in
            UIAction(
                title: order.title,
                image: UIImage(systemName: order.systemImage),
                state: order == currentOrder ? .on : .off
            ) { [weak self] _ in
                self?.viewModel?.applySort(order: order)
                self?.navigationItem.leftBarButtonItem = self?.makeSortBarButton()
            }
        }
        let menu = UIMenu(title: "Sort by", children: actions)
        return UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            menu: menu
        )
    }

    func select(type: HereafterMovieType) {
        foremostView.isSelected = (type == .foremost)
        possiblyView.isSelected = (type == .possibly)
        ifNothingElseView.isSelected = (type == .ifNothingElse)
    }

    func refreshTonightBanner() {
        guard let tonight = WidgetDataBridge.readTonight() else {
            listTableView.tableHeaderView = nil
            friendAlreadyWatched = false
            return
        }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: listTableView.bounds.width, height: 96))
        header.backgroundColor = DS.Color.accentDim
        let title = UILabel(frame: CGRect(x: 16, y: 10, width: header.bounds.width - 32, height: 22))
        title.font = DS.Typography.caption
        title.textColor = DS.Color.brandIndigo
        title.text = friendAlreadyWatched ? "A friend marked tonight's movie as watched" : "Watching tonight"
        let name = UILabel(frame: CGRect(x: 16, y: 32, width: header.bounds.width - 32, height: 22))
        name.font = DS.Typography.title2
        name.text = tonight.title
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 16, y: 58, width: 160, height: 30)
        button.setTitle("Mark as watched", for: .normal)
        button.titleLabel?.font = DS.Typography.caption
        button.addTarget(self, action: #selector(markTonightWatched), for: .touchUpInside)
        header.addSubview(title)
        header.addSubview(name)
        header.addSubview(button)
        listTableView.tableHeaderView = header
    }

    func watchTonightSession() {
        tonightListener?.remove()
        tonightListener = nil
        guard let tonight = WidgetDataBridge.readTonight(), Auth.auth().currentUser != nil else { return }
        tonightListener = FirestoreService.shared.observeSession(id: tonight.sessionID) { [weak self] result in
            guard let self, case .success(let session?) = result else { return }
            let uid = Auth.auth().currentUser?.uid
            let others = session.watchedBy.filter { $0 != uid }
            let changed = others.isEmpty == false
            if changed != self.friendAlreadyWatched {
                self.friendAlreadyWatched = changed
                self.refreshTonightBanner()
            }
        }
    }

    @objc func markTonightWatched() {
        guard let tonight = WidgetDataBridge.readTonight(), let localService else { return }
        ViewedDetailsEditor.present(on: self) { [weak self] rating, date in
            localService.moveToViewed(id: tonight.movieID, rating: rating, watchedDate: date) { _ in
                WidgetDataBridge.writeTonight(nil)
                if let uid = Auth.auth().currentUser?.uid {
                    FirestoreService.shared.markWatched(sessionID: tonight.sessionID, uid: uid) { _ in }
                }
                self?.friendAlreadyWatched = false
                self?.refreshTonightBanner()
                self?.viewModel?.reloadLists()
            }
        }
    }
}

extension HereAfterMainViewController: HereafterViewProtocol {

    func reloadData() {
        listTableView.reloadData()
    }

    func updateUI() {
    }

    func showError(error: Error) {
        showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
    }
}

extension HereAfterMainViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfItems() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel,
              let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as? ListTableViewCell else {
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        let movie = viewModel.itemFor(index: indexPath.row)
        if let posterURL = movie.posterImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { image in
                if cell.tag == indexPath.row {
                    cell.posterImageView.transition(to: image)
                }
            }
        } else {
            if cell.tag == indexPath.row {
                cell.posterImageView.transition(to: UIImage.image(named: ImageConstants.posterholder))
            }
        }
        cell.setup(movie: movie, caption: viewModel.viewedCaption(index: indexPath.row))
        return cell
    }
}

extension HereAfterMainViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        viewModel?.applySearch(query: query)
    }
}

extension HereAfterMainViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.didSelect(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        var actions: [UIContextualAction] = []
        for type in viewModel.swipeLeftTypes() {
            let action = UIContextualAction(style: .normal, title: type.title) { [weak self] (_, _, completionHandler) in
                self?.viewModel?.updateType(index: indexPath.row, type: type)
                completionHandler(true)
            }
            action.backgroundColor = type.typeColor
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        var actions: [UIContextualAction] = []
        for type in viewModel.swipeRightTypes() {
            let action = UIContextualAction(style: .normal, title: type.title) { [weak self] (_, _, completionHandler) in
                self?.viewModel?.updateType(index: indexPath.row, type: type)
                completionHandler(true)
            }
            action.backgroundColor = type.typeColor
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
}
