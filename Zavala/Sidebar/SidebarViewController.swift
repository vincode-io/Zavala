//
//  SidebarViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import UniformTypeIdentifiers
import RSCore
import Combine
import Templeton

protocol SidebarDelegate: AnyObject {
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)?)
}

enum SidebarSection: Int {
	case search, localAccount, cloudKitAccount
}

class SidebarViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .sidebar }
	
	weak var delegate: SidebarDelegate?
	
	var selectedAccount: Account? {
		return currentDocumentContainer?.account
	}
	
	var currentTag: Tag? {
		return (currentDocumentContainer as? TagDocuments)?.tag
	}
	
	var currentDocumentContainer: DocumentContainer? {
		guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first,
			  let entityID = dataSource.itemIdentifier(for: selectedIndexPath)?.entityID else {
			return nil
		}
		return AccountManager.shared.findDocumentContainer(entityID)
	}

	var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private let dataSourceQueue = MainThreadOperationQueue()
	private var applyCoalescingQueue = CoalescingQueue(name: "Apply Snapshot", interval: 0.5)
	private var reloadCoalescingQueue = CoalescingQueue(name: "Reload Visible", interval: 0.5)

	private var mainSplitViewController: MainSplitViewController? {
		return splitViewController as? MainSplitViewController
	}
	
	private var addBarButtonItem: UIBarButtonItem!
	private var importBarButtonItem: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()

		addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
		importBarButtonItem = UIBarButtonItem(image: AppAssets.importDocument, style: .plain, target: self, action: #selector(importOPML(_:)))
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			addBarButtonItem.title = L10n.add
			importBarButtonItem.title = L10n.importOPML
			
			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
		}

		if traitCollection.userInterfaceIdiom == .phone {
			navigationItem.rightBarButtonItems = [addBarButtonItem, importBarButtonItem]
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountManagerAccountsDidChange(_:)), name: .AccountManagerAccountsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidInitialize(_:)), name: .AccountDidInitialize, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountTagsDidChange(_:)), name: .AccountTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTagsDidChange(_:)), name: .OutlineTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncDidComplete(_:)), name: .CloudKitSyncDidComplete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
	}
	
	// MARK: API
	
	func startUp() {
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.dropDelegate = self
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
	}
	
	func selectDocumentContainer(_ documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)? = nil) {
		guard currentDocumentContainer?.id != documentContainer?.id else {
			completion?()
			return
		}
		
		if let search = documentContainer as? Search {
			DispatchQueue.main.async {
				if let searchCellIndexPath = self.dataSource.indexPath(for: SidebarItem.searchSidebarItem()) {
					if let searchCell = self.collectionView.cellForItem(at: searchCellIndexPath) as? SidebarSearchCell {
						searchCell.setSearchField(searchText: search.searchText)
					}
				}
			}
		}

		updateSelection(documentContainer, animated: animated, completion: completion)
	}
	
	// MARK: Notifications
	
	@objc func accountManagerAccountsDidChange(_ note: Notification) {
		queueApplyChangeSnapshot()
	}

	@objc func accountDidInitialize(_ note: Notification) {
		queueApplyChangeSnapshot()
	}
	
	@objc func accountMetadataDidChange(_ note: Notification) {
		queueApplyChangeSnapshot()
	}
	
	@objc func accountTagsDidChange(_ note: Notification) {
		queueApplyChangeSnapshot()
		queueReloadChangeSnapshot()
	}

	@objc func outlineTagsDidChange(_ note: Notification) {
		queueReloadChangeSnapshot()
	}

	@objc func accountDocumentsDidChange(_ note: Notification) {
		queueReloadChangeSnapshot()
	}

	@objc func cloudKitSyncDidComplete(_ note: Notification) {
		collectionView?.refreshControl?.endRefreshing()
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if AccountManager.shared.isSyncAvailable {
			AccountManager.shared.sync()
		} else {
			collectionView?.refreshControl?.endRefreshing()
		}
	}
	
	@IBAction func showSettings(_ sender: Any) {
		mainSplitViewController?.showSettings()
	}
	
	@objc func importOPML(_ sender: Any) {
		mainSplitViewController?.importOPML()
	}

	@objc func createOutline(_ sender: Any) {
		mainSplitViewController?.createOutline()
	}
	
	// MARK: API
	
	func beginDocumentSearch() {
		if let searchCellIndexPath = self.dataSource.indexPath(for: SidebarItem.searchSidebarItem()) {
			if let searchCell = self.collectionView.cellForItem(at: searchCellIndexPath) as? SidebarSearchCell {
				searchCell.setSearchField(searchText: "")
			}
		}
	}
	
}

// MARK: Collection View

extension SidebarViewController {
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		// If we don't force the text view to give up focus, we get its additional context menu items
		if let textView = UIResponder.currentFirstResponder as? UITextView {
			textView.resignFirstResponder()
		}
		
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return makeDocumentContainerContextMenu(item: sidebarItem)
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let searchCellIndexPath = dataSource.indexPath(for: SidebarItem.searchSidebarItem()) {
			if let searchCell = collectionView.cellForItem(at: searchCellIndexPath) as? SidebarSearchCell {
				searchCell.clearSearchField()
			}
		}
		
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		if case .documentContainer(let entityID) = sidebarItem.id {
			let documentContainer = AccountManager.shared.findDocumentContainer(entityID)
			delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer, animated: true, completion: nil)
		}
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			configuration.showsSeparators = false
			configuration.headerMode = .firstItemInSection
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let searchRegistration = UICollectionView.CellRegistration<SidebarSearchCell, SidebarItem> { (cell, indexPath, item) in
			var contentConfiguration = SidebarSearchContentConfiguration(searchText: nil)
			contentConfiguration.delegate = self
			cell.contentConfiguration = contentConfiguration
		}

		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {	(cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarHeader()
			
			contentConfiguration.text = item.id.name
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			
			if case .documentContainer(let entityID) = item.id, let container = AccountManager.shared.findDocumentContainer(entityID) {
				contentConfiguration.text = container.name
				contentConfiguration.image = container.image
				if let count = container.itemCount {
					contentConfiguration.secondaryText = String(count)
				}
			}

			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			switch item.id {
			case .search:
				return collectionView.dequeueConfiguredReusableCell(using: searchRegistration, for: indexPath, item: item)
			case .header:
				return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
			default:
				return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
			}
		}
	}
	
	private func searchSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		snapshot.append([SidebarItem.searchSidebarItem()])
		return snapshot
	}
	
	private func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem>? {
		let localAccount = AccountManager.shared.localAccount
		
		guard localAccount.isActive else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(id: .header(.localAccount))
		
		let items = localAccount.documentContainers.map { SidebarItem.sidebarItem($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func cloudKitAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem>? {
		guard let cloudKitAccount = AccountManager.shared.cloudKitAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(id: .header(.cloudKitAccount))
		
		let items = cloudKitAccount.documentContainers.map { SidebarItem.sidebarItem($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func applyInitialSnapshot() {
		if traitCollection.userInterfaceIdiom == .mac {
			applySnapshot(searchSnapshot(), section: .search, animated: false)
		}
		applyChangeSnapshot()
	}
	
	private func applyChangeSnapshot() {
		if let snapshot = localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: true)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<SidebarItem>(), section: .localAccount, animated: true)
		}

		if let snapshot = self.cloudKitAccountSnapshot() {
			applySnapshot(snapshot, section: .cloudKitAccount, animated: true)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<SidebarItem>(), section: .cloudKitAccount, animated: true)
		}
	}
	
	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>, section: SidebarSection, animated: Bool) {
		let selectedItems = collectionView.indexPathsForSelectedItems?.compactMap({ dataSource.itemIdentifier(for: $0) })
		
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)

		operation.completionBlock = { [weak self] _ in
			guard let self = self else { return }
			let selectedIndexPaths = selectedItems?.compactMap { self.dataSource.indexPath(for: $0) }
			for selectedIndexPath in selectedIndexPaths ?? [IndexPath]() {
				self.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
			}
		}
		
		dataSourceQueue.add(operation)
	}
	
	func updateSelection(_ documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)?) {
		var sidebarItem: SidebarItem? = nil
		if let documentContainer = documentContainer {
			sidebarItem = SidebarItem.sidebarItem(documentContainer)
		}

		let operation = UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, item: sidebarItem, animated: animated)
		
		operation.completionBlock = { [weak self] _ in
			guard let self = self else { return }
			self.delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer, animated: animated, completion: completion)
		}
		dataSourceQueue.add(operation)
	}
	
	func reloadVisible() {
		dataSourceQueue.add(ReloadVisibleItemsOperation(dataSource: dataSource, collectionView: collectionView))
	}
	
}

// MARK: SidebarSearchCellDelegate

extension SidebarViewController: SidebarSearchCellDelegate {

	func sidebarSearchDidBecomeActive() {
		selectDocumentContainer(Search(searchText: ""), animated: false)
	}

	func sidebarSearchDidUpdate(searchText: String?) {
		if let searchText = searchText {
			selectDocumentContainer(Search(searchText: searchText), animated: true)
		} else {
			selectDocumentContainer(Search(searchText: ""), animated: false)
		}
	}
	
}

// MARK: Helper Functions

extension SidebarViewController {
	
	private func queueApplyChangeSnapshot() {
		applyCoalescingQueue.add(self, #selector(applyQueuedChangeSnapshot))
	}
	
	@objc private func applyQueuedChangeSnapshot() {
		applyChangeSnapshot()
	}
	
	private func queueReloadChangeSnapshot() {
		reloadCoalescingQueue.add(self, #selector(reloadQueuedChangeSnapshot))
	}
	
	@objc private func reloadQueuedChangeSnapshot() {
		reloadVisible()
	}
	
	private func makeDocumentContainerContextMenu(item: SidebarItem) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: item as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self,
				  case .documentContainer(let entityID) = item.id,
				  let container = AccountManager.shared.findDocumentContainer(entityID) else {
					  return nil
				  }

			var menuItems = [UIMenu]()
			
			if let renameTagAction = self.renameTagAction(container: container) {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [renameTagAction]))
			}
			
			if let deleteTagAction = self.deleteTagAction(container: container) {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [deleteTagAction]))
			}
			
			return UIMenu(title: "", children: menuItems)
		})
	}

	private func renameTagAction(container: DocumentContainer) -> UIAction? {
		guard let tagDocuments = container as? TagDocuments else { return nil }
		
		let action = UIAction(title: L10n.rename, image: AppAssets.rename) { [weak self] action in
			guard let self = self else { return }
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				let renameTagViewController = UIStoryboard.dialog.instantiateController(ofType: MacRenameTagViewController.self)
				renameTagViewController.preferredContentSize = CGSize(width: 400, height: 80)
				renameTagViewController.tagDocuments = tagDocuments
				self.present(renameTagViewController, animated: true)
			} else {
				let renameTagNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "RenameTagViewControllerNav") as! UINavigationController
				renameTagNavViewController.preferredContentSize = CGSize(width: 400, height: 100)
				renameTagNavViewController.modalPresentationStyle = .formSheet
				let renameTagViewController = renameTagNavViewController.topViewController as! RenameTagViewController
				renameTagViewController.tagDocuments = tagDocuments
				self.present(renameTagNavViewController, animated: true)
			}
		}
		
		return action
	}

	private func deleteTagAction(container: DocumentContainer) -> UIAction? {
		guard let tagDocuments = container as? TagDocuments, let tag = tagDocuments.tag else { return nil }
		
		let action = UIAction(title: L10n.delete, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
				tagDocuments.account?.forceDeleteTag(tag)
			}
			
			let alert = UIAlertController(title: L10n.deleteTagPrompt(tag.name), message: L10n.deleteTagMessage, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
			alert.addAction(deleteAction)
			alert.preferredAction = deleteAction
			self?.present(alert, animated: true, completion: nil)
		}
		
		return action
	}

}
