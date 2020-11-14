//
//  TimelineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import RSCore
import Templeton

protocol TimelineDelegate: class  {
	func outlineSelectionDidChange(_: TimelineViewController, outlineProvider: OutlineProvider, outline: Outline?)
}

class TimelineViewController: UICollectionViewController {

	private var addBarButtonItem: UIBarButtonItem?
	
	private let dataSourceQueue = MainThreadOperationQueue()
	private var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!

	private var currentOutline: Outline? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
			  
		return AccountManager.shared.findOutline(item.id)
	}
	
	weak var delegate: TimelineDelegate?
	var outlineProvider: OutlineProvider?
	
	var isCreateOutlineUnavailable: Bool {
		return !(outlineProvider is Folder)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
		}

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot(animated: false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(folderOutlinesDidChange(_:)), name: .FolderOutlinesDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineMetaDataDidChange(_:)), name: .OutlineMetaDataDidChange, object: nil)

		updateUI()
	}
	
	// MARK: API
	func changeOutlineProvider(_ outlineProvider: OutlineProvider?) {
		self.outlineProvider = outlineProvider
		updateUI()
		applySnapshot(animated: false)
	}

	func selectOutline(_ outline: Outline?, animated: Bool) {
		guard let outlineProvider = outlineProvider else { return }

		var timelineItem: TimelineItem? = nil
		if let outline = outline {
			timelineItem = TimelineItem.timelineItem(outline)
		}

		updateSelection(item: timelineItem, animated: animated)
		delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: outline)
	}
	
	// MARK: Notifications
	
	@objc func folderOutlinesDidChange(_ note: Notification) {
		guard let op = outlineProvider, !op.isSmartProvider else {
			applySnapshot(animated: true)
			return
		}
		
		guard let noteOP = note.object as? OutlineProvider, op.id == noteOP.id else { return }
		applySnapshot(animated: true)
	}
	
	@objc func outlineMetaDataDidChange(_ note: Notification) {
		applySnapshot(animated: true)
	}
	
	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
		guard let folder = outlineProvider as? Folder else { return }

		let addNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "AddOutlineViewControllerNav") as! UINavigationController
		let addViewController = addNavViewController.topViewController as! AddOutlineViewController
		addViewController.folder = folder

		present(addNavViewController, animated: true)
	}

}

// MARK: Collection View

extension TimelineViewController {
		
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let outlineProvider = outlineProvider else { return }
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		let outline = AccountManager.shared.findOutline(timelineItem.id)
		delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: outline)
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return makeOutlineContextMenu(item: timelineItem)
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .plain)

			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let timelineItem = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
				let actions = [
					self.deleteContextualAction(item: timelineItem)
				]
				return UISwipeActionsConfiguration(actions: actions.compactMap { $0 })
			}

			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TimelineItem> { [weak self] (cell, indexPath, item) in
			guard let self = self else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.secondaryText = item.updateDate
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
				contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
			}
			
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
	
	private func applySnapshot(animated: Bool) {
		if let snapshot = snapshot() {
			applySnapshot(snapshot, animated: animated)
		}
	}

	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<TimelineItem>, animated: Bool) {
		dataSourceQueue.add(ApplySnapshotOperation(dataSource: dataSource, section: 0, snapshot: snapshot, animated: animated))
	}
	
	func updateSelection(item: TimelineItem?, animated: Bool) {
		dataSourceQueue.add(UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, item: item, animated: animated))
	}
}

// MARK: Helper Functions

extension TimelineViewController {
	
	private func updateUI() {
		navigationItem.title = outlineProvider?.name
		view.window?.windowScene?.title = outlineProvider?.name
		
		if isCreateOutlineUnavailable {
			navigationItem.rightBarButtonItem = nil
		} else {
			navigationItem.rightBarButtonItem = addBarButtonItem
		}
	}
	
	private func makeOutlineContextMenu(item: TimelineItem) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: item as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }
			
			let menuItems = [
				UIMenu(title: "", options: .displayInline, children: [self.getInfoOutlineAction(item: item)]),
				UIMenu(title: "", options: .displayInline, children: [self.deleteOutlineAction(item: item)])
			]

			return UIMenu(title: "", children: menuItems.compactMap { $0 })
		})
	}
	
	private func deleteContextualAction(item: TimelineItem) -> UIContextualAction? {
		let title = NSLocalizedString("Delete", comment: "Delete")
		let action = UIContextualAction(style: .destructive, title: title) { [weak self] _, _, completion in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.deleteOutline(outline, completion: completion)
			}
		}
		
		return action
	}
	
	private func getInfoOutlineAction(item: TimelineItem) -> UIAction {
		let title = NSLocalizedString("Get Info", comment: "Get Info")
		let action = UIAction(title: title, image: AppAssets.getInfoEntity) { [weak self] action in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.getInfoForOutline(outline)
			}
		}
		return action
	}
	
	private func deleteOutlineAction(item: TimelineItem) -> UIAction {
		let title = NSLocalizedString("Delete", comment: "Delete")
		let action = UIAction(title: title, image: AppAssets.removeEntity, attributes: .destructive) { [weak self] action in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.deleteOutline(outline)
			}
		}
		
		return action
	}
	
	private func deleteOutline(_ outline: Outline, completion: ((Bool) -> Void)? = nil) {
		func deleteOutline() {
			outline.folder?.removeOutline(outline) { result in
				if case .failure(let error) = result {
					self.presentError(error)
					completion?(true)
				} else {
					completion?(true)
				}
			}
		}
		
		let deleteTitle = NSLocalizedString("Delete", comment: "Delete")
		let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { _ in
			deleteOutline()
		}
		
		let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
			completion?(true)
		}
		
		let localizedInformativeText = NSLocalizedString("Are you sure you want to delete the “%@” outline?", comment: "Folder delete text")
		let formattedInformativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, outline.name ?? "") as String
		let localizedMessageText = NSLocalizedString("The outline be deleted and unrecoverable.", comment: "Delete Message")
		
		let alert = UIAlertController(title: formattedInformativeText, message: localizedMessageText, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	private func getInfoForOutline(_ outline: Outline, completion: ((Bool) -> Void)? = nil) {
		let getInfoNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "GetInfoOutlineViewControllerNav") as! UINavigationController
		let getInfoViewController = getInfoNavViewController.topViewController as! GetInfoOutlineViewController
		getInfoViewController.outline = outline
		present(getInfoNavViewController, animated: true) {
			completion?(true)
		}

	}
	
	
}
