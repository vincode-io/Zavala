//
//  TimelineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import Templeton

protocol TimelineDelegate: class  {
	func outlineSelectionDidChange(_: TimelineViewController, outline: Outline)
}

class TimelineViewController: UICollectionViewController {
	
	private struct TimelineItem: Hashable, Identifiable {
		let id: EntityID
		let title: String?
//		let updateDate: String?
		
		static func timelineItem(_ outline: Outline) -> Self {
			return TimelineItem(id: outline.id!, title: outline.name)
		}
	}

	private var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!

	private var currentOutline: Outline? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
			  
		return AccountManager.shared.findOutline(item.id)
	}
	
	weak var delegate: TimelineDelegate?
	var outlineProvider: OutlineProvider? {
		didSet {
			applySnapshot()
			updateUI()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
		
		NotificationCenter.default.addObserver(self, selector: #selector(outlinesDidChange(_:)), name: .OutlinesDidChange, object: nil)

		updateUI()
	}

	// MARK: Notifications
	
	@objc func outlinesDidChange(_ note: Notification) {
		guard let op = outlineProvider, !op.isSmartProvider else {
			applySnapshot()
			return
		}
		
		guard let noteOP = note.object as? OutlineProvider, op.id == noteOP.id else { return }
		applySnapshot()
	}
	
	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
		let addNavViewController = UIStoryboard.add.instantiateViewController(withIdentifier: "AddOutlineViewControllerNav") as! UINavigationController
		present(addNavViewController, animated: true)
	}

}

extension TimelineViewController {
	
	private func updateUI() {
		guard isViewLoaded else { return }
		navigationItem.title = outlineProvider?.name
		view.window?.windowScene?.title = outlineProvider?.name
	}
	
}

extension TimelineViewController {
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TimelineItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			contentConfiguration.text = item.title
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<Int, TimelineItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}
	
	private func snapshot() -> NSDiffableDataSourceSectionSnapshot<TimelineItem>? {
		var snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
		let outlines = outlineProvider?.sortedOutlines ?? [Outline]()
		let items = outlines.map { TimelineItem.timelineItem($0) }
		snapshot.append(items)
		return snapshot
	}
	
	private func applySnapshot() {
		if let snapshot = snapshot() {
			dataSource.apply(snapshot, to: 0, animatingDifferences: true)
		}
	}
	
}


