//
//  ItemDetailViewController.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import UIKit

// MARK: - Tag chip cell

private final class TagChipCell: UICollectionViewCell {

    static let reuseId = "TagChipCell"

    var removeAction: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.caption
        l.textColor = DS.Color.labelMuted
        return l
    }()

    private let removeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = DS.Color.labelMuted
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = DS.Color.accentDim
        contentView.layer.cornerRadius = DS.Radius.chip / 2
        contentView.clipsToBounds = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(removeButton)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.xs),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            removeButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.xs),
            removeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 14),
            removeButton.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, removeAction: @escaping () -> Void) {
        titleLabel.text = title
        self.removeAction = removeAction
    }

    @objc private func removeTapped() { removeAction?() }
}

// MARK: - Add tag cell

private final class AddTagCell: UICollectionViewCell {

    static let reuseId = "AddTagCell"

    private let label: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "+ tag"
        l.font = DS.Typography.caption
        l.textColor = DS.Color.accent
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = DS.Radius.chip / 2
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = DS.Color.accent.cgColor
        contentView.clipsToBounds = true
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.xs),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.xs),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - ItemDetailViewController

final class ItemDetailViewController: BaseViewController<ItemDetailViewModelProtocol>, CustomAlertRouterProtocol {

    // MARK: - Poster

    private let posterContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.30
        v.layer.shadowRadius = 20
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        return v
    }()

    private let posterImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = DS.Radius.card
        v.image = UIImage(named: ImageConstants.posterholder)
        return v
    }()

    // MARK: - Close button

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = DS.Color.navIconDark
        b.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        b.layer.cornerRadius = 16
        return b
    }()

    // MARK: - Detail sheet

    private let detailContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = DS.Radius.sheet
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()

    private let scrollContentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Content

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.title1
        l.numberOfLines = 0
        l.textColor = .label
        return l
    }()

    private let genresCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = DS.Spacing.xs
        layout.minimumInteritemSpacing = DS.Spacing.xs
        layout.scrollDirection = .horizontal
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.translatesAutoresizingMaskIntoConstraints = false
        c.backgroundColor = .clear
        c.showsHorizontalScrollIndicator = false
        c.contentInset = UIEdgeInsets(top: 0, left: DS.Spacing.m, bottom: 0, right: DS.Spacing.m)
        return c
    }()

    private let budgetRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let budgetIcon: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.image = UIImage(named: "money")
        v.tintColor = .secondaryLabel
        return v
    }()

    private let budgetLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.callout
        l.textColor = .secondaryLabel
        return l
    }()

    private let tagsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = DS.Spacing.xs
        layout.minimumInteritemSpacing = DS.Spacing.xs
        layout.scrollDirection = .horizontal
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.translatesAutoresizingMaskIntoConstraints = false
        c.backgroundColor = .clear
        c.showsHorizontalScrollIndicator = false
        return c
    }()

    private let overviewHeaderLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Overview"
        l.font = DS.Typography.footnote
        l.textColor = .secondaryLabel
        return l
    }()

    private let overviewLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.callout
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    private let reuseIdentifier = "GenresCollectionViewCell"

    // Constraint pair to collapse budget row when absent
    private var tagsTopBudgetVisible: NSLayoutConstraint!
    private var tagsTopBudgetHidden: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        setupUI()
        setupGenresCollectionView()
        setupTagsCollectionView()
    }

    @objc private func closeAction() {
        hide(animated: true)
    }
}

private extension ItemDetailViewController {

    func setupLayout() {
        view.addSubview(posterContainerView)
        posterContainerView.addSubview(posterImageView)
        view.addSubview(detailContainer)
        view.addSubview(closeButton)

        detailContainer.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)

        scrollContentView.addSubview(titleLabel)
        scrollContentView.addSubview(genresCollectionView)
        budgetRow.addSubview(budgetIcon)
        budgetRow.addSubview(budgetLabel)
        scrollContentView.addSubview(budgetRow)
        scrollContentView.addSubview(tagsCollectionView)
        scrollContentView.addSubview(overviewHeaderLabel)
        scrollContentView.addSubview(overviewLabel)

        tagsTopBudgetVisible = tagsCollectionView.topAnchor.constraint(equalTo: budgetRow.bottomAnchor, constant: DS.Spacing.m)
        tagsTopBudgetHidden  = tagsCollectionView.topAnchor.constraint(equalTo: genresCollectionView.bottomAnchor, constant: DS.Spacing.xs)

        NSLayoutConstraint.activate([
            // Poster shadow container
            posterContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.l),
            posterContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            posterContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.44),
            posterContainerView.widthAnchor.constraint(equalTo: posterContainerView.heightAnchor, multiplier: 0.65),
            posterContainerView.bottomAnchor.constraint(lessThanOrEqualTo: detailContainer.topAnchor, constant: 60),

            posterImageView.topAnchor.constraint(equalTo: posterContainerView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: posterContainerView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: posterContainerView.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: posterContainerView.bottomAnchor),

            // Close button
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DS.Spacing.s),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.s),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Detail container
            detailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            detailContainer.topAnchor.constraint(equalTo: posterContainerView.bottomAnchor, constant: -40),

            // Scroll view fills detail container
            scrollView.topAnchor.constraint(equalTo: detailContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: detailContainer.bottomAnchor),

            // Scroll content — vertical scroll only
            scrollContentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: DS.Spacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: DS.Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -DS.Spacing.m),

            // Genres (full width, own horizontal inset)
            genresCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DS.Spacing.xs),
            genresCollectionView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            genresCollectionView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            genresCollectionView.heightAnchor.constraint(equalToConstant: 26),

            // Budget row
            budgetRow.topAnchor.constraint(equalTo: genresCollectionView.bottomAnchor, constant: DS.Spacing.xs),
            budgetRow.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: DS.Spacing.m),
            budgetRow.trailingAnchor.constraint(lessThanOrEqualTo: scrollContentView.trailingAnchor, constant: -DS.Spacing.m),
            budgetRow.heightAnchor.constraint(equalToConstant: 20),

            budgetIcon.leadingAnchor.constraint(equalTo: budgetRow.leadingAnchor),
            budgetIcon.centerYAnchor.constraint(equalTo: budgetRow.centerYAnchor),
            budgetIcon.widthAnchor.constraint(equalToConstant: 16),
            budgetIcon.heightAnchor.constraint(equalToConstant: 16),

            budgetLabel.leadingAnchor.constraint(equalTo: budgetIcon.trailingAnchor, constant: 4),
            budgetLabel.centerYAnchor.constraint(equalTo: budgetRow.centerYAnchor),
            budgetLabel.trailingAnchor.constraint(equalTo: budgetRow.trailingAnchor),

            // Tags
            tagsCollectionView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: DS.Spacing.m),
            tagsCollectionView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -DS.Spacing.m),
            tagsCollectionView.heightAnchor.constraint(equalToConstant: 28),

            // Overview
            overviewHeaderLabel.topAnchor.constraint(equalTo: tagsCollectionView.bottomAnchor, constant: DS.Spacing.m),
            overviewHeaderLabel.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: DS.Spacing.m),
            overviewHeaderLabel.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -DS.Spacing.m),

            overviewLabel.topAnchor.constraint(equalTo: overviewHeaderLabel.bottomAnchor, constant: 4),
            overviewLabel.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: DS.Spacing.m),
            overviewLabel.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -DS.Spacing.m),
            overviewLabel.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -DS.Spacing.xl)
        ])
    }

    func setupUI() {
        viewModel?.getPoster { [weak self] image in
            self?.posterImageView.image = image
        }
        titleLabel.text = viewModel?.title
        overviewLabel.text = viewModel?.overview
        view.backgroundColor = viewModel?.color

        let budget = viewModel?.budget ?? "0"
        let hasBudget = budget != "0"
        budgetLabel.text = budget
        budgetRow.isHidden = !hasBudget
        tagsTopBudgetVisible.isActive = hasBudget
        tagsTopBudgetHidden.isActive = !hasBudget

        viewModel?.onTagsUpdated = { [weak self] in
            self?.tagsCollectionView.reloadData()
        }
    }

    func setupGenresCollectionView() {
        genresCollectionView.dataSource = self
        genresCollectionView.registerCell(GenresCollectionViewCell.self)
    }

    func setupTagsCollectionView() {
        tagsCollectionView.dataSource = self
        tagsCollectionView.delegate = self
        tagsCollectionView.register(TagChipCell.self, forCellWithReuseIdentifier: TagChipCell.reuseId)
        tagsCollectionView.register(AddTagCell.self, forCellWithReuseIdentifier: AddTagCell.reuseId)
    }

    func presentAddTagAlert() {
        let alert = UIAlertController(title: "Add tag", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g. with friends, friday"
            tf.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let text = alert?.textFields?.first?.text else { return }
            self?.viewModel?.addTag(text)
            self?.tagsCollectionView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension ItemDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === genresCollectionView {
            return viewModel?.genres.count ?? 0
        }
        return (viewModel?.tags.count ?? 0) + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === genresCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? GenresCollectionViewCell,
                  let viewModel = viewModel else { return UICollectionViewCell() }
            cell.setup(title: viewModel.genres[indexPath.row])
            return cell
        }

        let tags = viewModel?.tags ?? []
        if indexPath.row < tags.count {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagChipCell.reuseId, for: indexPath) as? TagChipCell else {
                return UICollectionViewCell()
            }
            let index = indexPath.row
            cell.configure(title: tags[index]) { [weak self] in
                self?.viewModel?.removeTag(at: index)
                self?.tagsCollectionView.reloadData()
            }
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AddTagCell.reuseId, for: indexPath)
        }
    }
}

extension ItemDetailViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === tagsCollectionView else { return }
        let tags = viewModel?.tags ?? []
        if indexPath.row == tags.count {
            presentAddTagAlert()
        }
    }
}
