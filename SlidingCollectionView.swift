//
//  SlidingCollectionView.swift
//
//  Created by Roman Madyanov on 17/02/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

private protocol SlidingCollectionViewProtocol {
    var delegate: SlidingCollectionViewDelegate? { get set }
    var dataSource: SlidingCollectionViewDataSource? { get set }

    var itemHeight: CGFloat { get set }
    var spacing: CGFloat { get set }
    var maximumNumberOfRows: Int { get set }

    var heightToFit: CGFloat { get }
    var isDragging: Bool { get }
    var isDecelerating: Bool { get }

    func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)
    func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell
    func setNeedsReloadData()
    func reloadData()
}

protocol SlidingCollectionViewDelegate: class {
    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, widthForItemAt index: Int) -> CGFloat
    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, didSelectItemAt index: Int)
    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, willDisplay cell: UICollectionViewCell)
}

extension SlidingCollectionViewDelegate {
    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, willDisplay cell: UICollectionViewCell) {
        guard slidingCollectionView.isDragging else {
            return
        }

        cell.alpha = 0
        cell.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.allowUserInteraction, .curveEaseIn], animations: {
            cell.alpha = 1
            cell.transform = .identity
        }, completion: nil)
    }
}

protocol SlidingCollectionViewDataSource: class {
    func numberOfItems(in slidingCollectionView: SlidingCollectionView) -> Int
    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, cellForItemAt index: Int) -> UICollectionViewCell
}

class SlidingCollectionView: UIView, SlidingCollectionViewProtocol {
    weak var delegate: SlidingCollectionViewDelegate? {
        didSet {
            if delegate !== oldValue {
                setNeedsReloadData()
            }
        }
    }

    weak var dataSource: SlidingCollectionViewDataSource? {
        didSet {
            if dataSource !== oldValue {
                setNeedsReloadData()
            }
        }
    }

    var itemHeight: CGFloat = 44 {
        didSet {
            if itemHeight != oldValue {
                setNeedsReloadData()
            }
        }
    }

    var spacing: CGFloat = 8 {
        didSet {
            if spacing != oldValue {
                setNeedsReloadData()
            }
        }
    }

    var maximumNumberOfRows = 4 {
        didSet {
            if maximumNumberOfRows != oldValue {
                setNeedsReloadData()
            }
        }
    }

    var heightToFit: CGFloat {
        let numberOfRows = itemsGrid.count
        return spacing + CGFloat(numberOfRows) * (itemHeight + spacing)
    }

    var isDragging: Bool {
        return scrollView.isDragging
    }

    var isDecelerating: Bool {
        return scrollView.isDecelerating
    }

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private var isNeedsReloadData = true {
        didSet { setNeedsLayout() }
    }

    private var collectionViews: [UICollectionView] = []
    private var registeredCells: [String: AnyClass?] = [:]
    private var itemsWidth: [CGFloat] = []
    private var itemsGrid: [[Int]] = []
    private var pageOffsets: [Int: [Int: CGFloat]] = [:]
    private var oldBounds = CGRect.zero
    private var contentViewWidthConstraint: NSLayoutConstraint?
    private var stackViewLeftConstraint: NSLayoutConstraint?

    convenience init() {
        self.init(frame: .zero)

        setupSubviews()
        setupConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isNeedsReloadData || bounds != oldBounds {
            isNeedsReloadData = false
            oldBounds = bounds
            reloadData()
        }
    }

    func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        registeredCells[identifier] = cellClass
    }

    func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell {
        for (row, items) in itemsGrid.enumerated() {
            guard let itemIndex = items.index(of: index) else {
                continue
            }

            return collectionViews[row].dequeueReusableCell(withReuseIdentifier: identifier, for: IndexPath(item: itemIndex, section: 0))
        }

        return UICollectionViewCell()
    }

    func setNeedsReloadData() {
        isNeedsReloadData = true
    }

    func reloadData() {
        collectionViews.forEach { $0.removeFromSuperview() }
        collectionViews = []

        scrollView.contentOffset = .zero

        itemsWidth = loadItemsWidth()
        itemsGrid = calculateItemsGrid(itemsWidth: itemsWidth)
        pageOffsets = calculatePageOffsets(itemsGrid: itemsGrid, itemsWidth: itemsWidth)

        let contentWidth = CGFloat(pageOffsets.count + 1) * bounds.width
        contentViewWidthConstraint?.constant = contentWidth

        var constraints: [NSLayoutConstraint] = []

        for index in itemsGrid.indices {
            let collectionView = makeCollectionView(with: contentWidth, center: index == 0)
            stackView.addArrangedSubview(collectionView)
            collectionViews.append(collectionView)

            let collectionViewHeight = itemHeight + spacing * (index == 0 ? 2 : 1)

            constraints += [
                collectionView.widthAnchor.constraint(equalTo: widthAnchor),
                collectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        contentViewWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        contentViewWidthConstraint?.isActive = true

        stackViewLeftConstraint = stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor)
        stackViewLeftConstraint?.isActive = true
    }

    private func loadItemsWidth() -> [CGFloat] {
        guard let delegate = delegate, let dataSource = dataSource else {
            return []
        }

        return (0..<dataSource.numberOfItems(in: self)).map { delegate.slidingCollectionView(self, widthForItemAt: $0) }
    }

    private func calculateItemsGrid(itemsWidth: [CGFloat]) -> [[Int]] {
        let possibleNumberOfRows = Int((bounds.height - spacing) / (itemHeight + spacing))
        let numberOfRows = max(1, min(maximumNumberOfRows, possibleNumberOfRows))
        var itemsGrid: [[Int]] = Array(repeating: [], count: numberOfRows)
        var row = 0
        var rowWidth = spacing

        for (index, itemWidth) in itemsWidth.enumerated() {
            if rowWidth > spacing && rowWidth + itemWidth >= bounds.width {
                if row == numberOfRows - 1 {
                    row = 0
                } else {
                    row += 1
                }

                rowWidth = spacing
            }

            itemsGrid[row].append(index)
            rowWidth += itemWidth + spacing
        }

        return itemsGrid.filter { !$0.isEmpty }
    }

    private func calculatePageOffsets(itemsGrid: [[Int]], itemsWidth: [CGFloat]) -> [Int: [Int: CGFloat]] {
        var pageOffsets: [Int: [Int: CGFloat]] = [:]
        var page = 0
        var rowWidth = spacing

        for (row, items) in itemsGrid.enumerated() {
            for index in items {
                let itemWidth = itemsWidth[index]

                if rowWidth + itemWidth >= bounds.width {
                    if pageOffsets[page] == nil {
                        pageOffsets[page] = [:]
                    }

                    let previousPageOffset = pageOffsets[page - 1]?[row] ?? 0
                    pageOffsets[page]?[row] = previousPageOffset + rowWidth - spacing

                    page += 1
                    rowWidth = spacing
                }

                rowWidth += itemWidth + spacing
            }

            page = 0
            rowWidth = spacing
        }

        return pageOffsets
    }

    private func makeCollectionView(with contentWidth: CGFloat, center: Bool) -> UICollectionView {
        let collectionViewLayout = SlidingCollectionViewLayout()
        collectionViewLayout.itemHeight = itemHeight
        collectionViewLayout.spacing = spacing
        collectionViewLayout.center = center
        collectionViewLayout.contentWidth = contentWidth
        collectionViewLayout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.allowsMultipleSelection = true
        collectionView.clipsToBounds = false

        for (identifier, cellClass) in registeredCells {
            collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
        }

        return collectionView
    }

    private func convert(_ index: Int, from collectionView: UICollectionView) -> Int {
        let row = collectionViews.index(of: collectionView) ?? 0
        return itemsGrid[row][index]
    }
}

extension SlidingCollectionView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }

        stackViewLeftConstraint?.constant = scrollView.contentOffset.x

        let totalProgress = scrollView.contentOffset.x / bounds.width
        let page = Int(totalProgress)
        let pageProgress = totalProgress - CGFloat(page)

        for (row, collectionView) in collectionViews.enumerated() {
            let previousPageOffset = pageOffsets[page - 1]?[row] ?? CGFloat(page) * bounds.width
            let pageOffset = pageOffsets[page]?[row] ?? CGFloat(page + 1) * bounds.width
            let contentOffset = previousPageOffset + min(bounds.width, pageOffset - previousPageOffset) * pageProgress
            collectionView.contentOffset.x = contentOffset
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        delegate?.slidingCollectionView(self, willDisplay: cell)

        if !cell.isSelected || collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false {
            return
        }

        cell.isSelected = false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for selectedItemIndexPath in collectionView.indexPathsForSelectedItems ?? [] where selectedItemIndexPath != indexPath {
            collectionView.deselectItem(at: selectedItemIndexPath, animated: false)
        }

        for otherCollectionView in collectionViews where otherCollectionView != collectionView {
            for selectedItemIndexPath in otherCollectionView.indexPathsForSelectedItems ?? [] {
                otherCollectionView.deselectItem(at: selectedItemIndexPath, animated: false)
            }
        }

        delegate?.slidingCollectionView(self, didSelectItemAt: convert(indexPath.row, from: collectionView))
    }
}

extension SlidingCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let row = collectionViews.index(of: collectionView) ?? 0
        return itemsGrid[row].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return dataSource?.slidingCollectionView(self, cellForItemAt: convert(indexPath.row, from: collectionView)) ?? UICollectionViewCell()
    }
}

extension SlidingCollectionView: SlidingCollectionViewLayoutDelegate {
    fileprivate func slidingCollectionViewLayout(_ slidingCollectionViewLayout: SlidingCollectionViewLayout, widthForItemAt index: Int) -> CGFloat {
        guard let collectionView = slidingCollectionViewLayout.collectionView else {
            return 0
        }

        return itemsWidth[convert(index, from: collectionView)]
    }
}

private protocol SlidingCollectionViewLayoutDelegate: class {
    func slidingCollectionViewLayout(_ slidingCollectionViewLayout: SlidingCollectionViewLayout, widthForItemAt index: Int) -> CGFloat
}

private class SlidingCollectionViewLayout: UICollectionViewLayout {
    weak var delegate: SlidingCollectionViewLayoutDelegate?

    var itemHeight: CGFloat = 40 {
        didSet { invalidateLayout() }
    }

    var spacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    var center = true {
        didSet { invalidateLayout() }
    }

    var contentWidth: CGFloat = 0

    private var attributesCache: [UICollectionViewLayoutAttributes] = []

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }

        return CGSize(width: contentWidth, height: collectionView.bounds.height)
    }

    override func prepare() {
        attributesCache = []

        guard let collectionView = collectionView, let delegate = delegate else {
            return
        }

        var xOffset = spacing

        for index in 0..<collectionView.numberOfItems(inSection: 0) {
            let itemWidth = delegate.slidingCollectionViewLayout(self, widthForItemAt: index)
            let yOffset = center ? (collectionView.bounds.height - itemHeight) / 2 : 0

            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)
            attributesCache.append(attributes)

            xOffset += itemWidth + spacing
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesCache.filter { return rect.intersects($0.frame) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesCache[indexPath.row]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else {
            return false
        }

        return collectionView.bounds.size != newBounds.size
    }
}
