//
//  CollectionsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import UniformTypeIdentifiers
import AsyncAlgorithms
import Semaphore
import VinOutlineKit
import VinUtility

@MainActor
protocol CollectionsDelegate: AnyObject {
	func documentContainerSelectionsDidChange(_: CollectionsViewController, documentContainers: [DocumentContainer], isNavigationBranch: Bool, animated: Bool) async
}

enum CollectionsSection: Int {
	case search, localAccount, cloudKitAccount
}

class CollectionsViewController: UICollectionViewController, MainControllerIdentifiable {
	nonisolated var mainControllerIdentifer: MainControllerIdentifier { return .collections }
	
	weak var delegate: CollectionsDelegate?
	
	var selectedAccount: Account? {
        selectedDocumentContainers?.uniqueAccount
	}
	
	var selectedTags: [Tag]? {
        return selectedDocumentContainers?.compactMap { ($0 as? TagDocuments)?.tag }
	}
	
	var selectedDocumentContainers: [DocumentContainer]? {
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			return nil
		}
        
        return selectedIndexPaths.compactMap { indexPath in
            if let entityID = dataSource.itemIdentifier(for: indexPath)?.entityID {
                return appDelegate.accountManager.findDocumentContainer(entityID)
            }
            return nil
        }
	}
	
	var expandedState: [[AnyHashable: AnyHashable]] {
		get {
			return expandedItems.compactMap { $0.entityID?.userInfo }
		}
		set {
			var items = Set<CollectionsItem>()
			for userInfo in newValue {
				if let id = EntityID(userInfo: userInfo) {
					items.insert(CollectionsItem.item(id))
				}
			}
			expandedItems = items
			
			applyChangeSnapshot(animated: false)
		}
	}

	var dataSource: UICollectionViewDiffableDataSource<CollectionsSection, CollectionsItem>!
	private var dataSourceSemaphore = AsyncSemaphore(value: 1)
	private var applyChangeChannel = AsyncChannel<Void>()
	private var reloadVisibleChannel = AsyncChannel<Void>()

	private var expandedItems = Set<CollectionsItem>()
	
	private var addButton: UIButton!
	private var importButton: UIButton!

	private var settingsBarButtonItem: UIBarButtonItem!
    private var selectBarButtonItem: UIBarButtonItem!
    private var selectDoneBarButtonItem: UIBarButtonItem!
	
	private let iCloudActivityIndicatorView = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
		super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
			collectionView.allowsMultipleSelection = true
		} else {
			settingsBarButtonItem = UIBarButtonItem(image: .settings, style: .plain, target: nil, action: .showSettings)
			settingsBarButtonItem.accessibilityLabel = .settingsControlLabel
			navigationItem.leftBarButtonItem = settingsBarButtonItem
			
			if traitCollection.userInterfaceIdiom == .pad {
				selectBarButtonItem = UIBarButtonItem(title: .selectControlLabel, style: .plain, target: self, action: #selector(multipleSelect))
				selectDoneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(multipleSelectDone))

				navigationItem.rightBarButtonItem = selectBarButtonItem
			} else {
				let navButtonGroup = ButtonGroup(hostController: self, containerType: .standard, alignment: .right)
				importButton = navButtonGroup.addButton(label: .importOPMLControlLabel, image: .importDocument, selector: .importOPML)
				addButton = navButtonGroup.addButton(label: .addControlLabel, image: .createEntity, selector: .createOutline)
				let navButtonsBarButtonItem = navButtonGroup.buildBarButtonItem()

				navigationItem.rightBarButtonItem = navButtonsBarButtonItem
			}
			
			navigationItem.title = .collectionsControlLabel

			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
			collectionView.refreshControl!.tintColor = .clear
		}
        
		NotificationCenter.default.addObserver(self, selector: #selector(accountManagerAccountsDidChange(_:)), name: .AccountManagerAccountsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidReload(_:)), name: .AccountDidReload, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountTagsDidChange(_:)), name: .AccountTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTagsDidChange(_:)), name: .OutlineTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncWillBegin(_:)), name: .CloudKitSyncWillBegin, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncDidComplete(_:)), name: .CloudKitSyncDidComplete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
		
		// Using a semaphore here to make sure these two debouncers don't overlap when doing a lot of fast hits like when doing an account restore
		Task {
			for await _ in applyChangeChannel.debounce(for: .seconds(0.5)) {
				await dataSourceSemaphore.wait()
				defer { dataSourceSemaphore.signal() }
				applyChangeSnapshot(animated: true)
			}
		}
		
		Task {
			for await _ in reloadVisibleChannel.debounce(for: .seconds(0.5)) {
				await dataSourceSemaphore.wait()
				defer { dataSourceSemaphore.signal() }
				reloadVisible()
			}
		}
	}
	
	// MARK: API
	
	func startUp() {
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
	}
	
	func selectDocumentContainers(_ containers: [DocumentContainer]?, isNavigationBranch: Bool, animated: Bool) async {
        collectionView.deselectAll()
        
        if let containers, containers.count > 1, traitCollection.userInterfaceIdiom == .pad {
            multipleSelect()
        }
        
        if let containers, containers.count == 1, let search = containers.first as? Search {
			Task { @MainActor in
				if let searchCellIndexPath = self.dataSource.indexPath(for: CollectionsItem.searchItem()) {
					if let searchCell = self.collectionView.cellForItem(at: searchCellIndexPath) as? CollectionsSearchCell {
						searchCell.setSearchField(searchText: search.searchText)
					}
				}
			}
		} else {
			clearSearchField()
		}

		await updateSelections(containers, isNavigationBranch: isNavigationBranch, animated: animated)
	}
	
	// MARK: Notifications
	
	@objc func accountManagerAccountsDidChange(_ note: Notification) {
		debounceApplyChangeSnapshot()
	}

	@objc func accountDidReload(_ note: Notification) {
		debounceApplyChangeSnapshot()
		debounceReloadVisible()
	}
	
	@objc func accountMetadataDidChange(_ note: Notification) {
		debounceApplyChangeSnapshot()
	}
	
	@objc func accountTagsDidChange(_ note: Notification) {
		debounceApplyChangeSnapshot()
		debounceReloadVisible()
	}

	@objc func outlineTagsDidChange(_ note: Notification) {
		debounceReloadVisible()
	}

	@objc func accountDocumentsDidChange(_ note: Notification) {
		debounceReloadVisible()
	}

	@objc func cloudKitSyncWillBegin(_ note: Notification) {
		// Let any pending UI things like adding the account happen so that we have something to put the spinner on
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(0.2))
			self.iCloudActivityIndicatorView.startAnimating()
		}
	}
	
	@objc func cloudKitSyncDidComplete(_ note: Notification) {
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(0.2))
			self.iCloudActivityIndicatorView.stopAnimating()
		}
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if appDelegate.accountManager.isSyncAvailable {
			Task {
				await appDelegate.accountManager.sync()
			}
		}
		collectionView?.refreshControl?.endRefreshing()
	}
		
    @objc func multipleSelect() {
		Task {
			await selectDocumentContainers(nil, isNavigationBranch: true, animated: true)
			collectionView.allowsMultipleSelection = true
			navigationItem.rightBarButtonItem = selectDoneBarButtonItem
		}
    }

    @objc func multipleSelectDone() {
		Task {
			await selectDocumentContainers(nil, isNavigationBranch: true, animated: true)
			collectionView.allowsMultipleSelection = false
			navigationItem.rightBarButtonItem = selectBarButtonItem
		}
    }

}

// MARK: Collection View

extension CollectionsViewController {
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		// If we don't force the text view to give up focus, we get its additional context menu items
		if let textView = UIResponder.currentFirstResponder as? UITextView {
			textView.resignFirstResponder()
		}
		
		if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
			collectionView.deselectAll()
		}
		
		let items: [CollectionsItem]
		if let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty {
			items = selected.compactMap { dataSource.itemIdentifier(for: $0) }
		} else {
			if let item = dataSource.itemIdentifier(for: indexPath) {
				items = [item]
			} else {
				items = [CollectionsItem]()
			}
		}
		
		guard let mainItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return makeDocumentContainerContextMenu(mainItem: mainItem, items: items)
	}
    
	override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		if traitCollection.userInterfaceIdiom == .pad {
			if collectionView.allowsMultipleSelection {
				return !(dataSource.itemIdentifier(for: indexPath)?.entityID?.isSystemCollection ?? false)
			}

		}
		return true
	}
		
	override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateSelections()
    }

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		clearSearchField()
        updateSelections()
	}
    
    private func updateSelections() {
        guard let selectedIndexes = collectionView.indexPathsForSelectedItems else { return }
        let items = selectedIndexes.compactMap { dataSource.itemIdentifier(for: $0) }
		let containers = items.toContainers()
        
		Task {
			await delegate?.documentContainerSelectionsDidChange(self, documentContainers: containers, isNavigationBranch: true, animated: true)
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
		let searchRegistration = UICollectionView.CellRegistration<CollectionsSearchCell, CollectionsItem> { (cell, indexPath, item) in
			var contentConfiguration = CollectionsSearchContentConfiguration(searchText: nil)
			contentConfiguration.delegate = self
			cell.contentConfiguration = contentConfiguration
		}

		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CollectionsItem> { [weak self]	(cell, indexPath, item) in
			guard let self else { return }
			
			var contentConfiguration = UIListContentConfiguration.sidebarHeader()
			
			contentConfiguration.text = item.id.name
			if self.traitCollection.userInterfaceIdiom == .mac {
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
				contentConfiguration.textProperties.color = .secondaryLabel
			} else {
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .title2).with(traits: .traitBold)
				contentConfiguration.textProperties.color = .label
			}
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
			
			if item.id.accountType == .cloudKit, let textLayoutGuide = (cell.contentView as? UIListContentView)?.textLayoutGuide {
				self.iCloudActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
				
				let trailingAnchorAdjustment: CGFloat
				if self.traitCollection.userInterfaceIdiom == .mac {
					self.iCloudActivityIndicatorView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
					trailingAnchorAdjustment = 4
				} else {
					trailingAnchorAdjustment = 8
				}
				
				cell.contentView.addSubview(self.iCloudActivityIndicatorView)
				
				NSLayoutConstraint.activate([
					self.iCloudActivityIndicatorView.centerYAnchor.constraint(equalTo: textLayoutGuide.centerYAnchor),
					self.iCloudActivityIndicatorView.leadingAnchor.constraint(equalTo: textLayoutGuide.trailingAnchor, constant: trailingAnchorAdjustment),
				])
			}
		}
		
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, CollectionsItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			
			if case .documentContainer(let entityID) = item.id, let container = appDelegate.accountManager.findDocumentContainer(entityID) {
				contentConfiguration.text = container.partialName
				contentConfiguration.image = container.image
				contentConfiguration.textProperties.lineBreakMode = .byTruncatingMiddle
				
				if let count = container.itemCount {
					contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .body)
					contentConfiguration.secondaryText = String(count)
				}

				if UIDevice.current.userInterfaceIdiom == .mac {
					if container.children.isEmpty {
						cell.accessories = [.outlineDisclosure(options: .init(isHidden: true, reservedLayoutWidth: .custom(6)))]
					} else {
						cell.accessories = [.outlineDisclosure(options: .init(isHidden: false, reservedLayoutWidth: .custom(6)))]
					}
				} else {
					cell.configurationUpdateHandler = { cell, state in
						guard let cell = cell as? ConsistentCollectionViewListCell,
							  var config = cell.contentConfiguration?.updated(for: state) as? UIListContentConfiguration else { return }
						
						if state.isSelected || state.isHighlighted {
							config.imageProperties.tintColor = .white

							if container.children.isEmpty {
								cell.accessories = [.outlineDisclosure(options: .init(isHidden: true))]
							} else {
								cell.accessories = [.outlineDisclosure(options: .init(isHidden: false, tintColor: .lightGray))]
							}
						} else {
							config.imageProperties.tintColor = nil

							if container.children.isEmpty {
								cell.accessories = [.outlineDisclosure(options: .init(isHidden: true))]
							} else {
								cell.accessories = [.outlineDisclosure(options: .init(isHidden: false))]
							}
						}
						
						cell.contentConfiguration = config
					}
				}
			}

			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<CollectionsSection, CollectionsItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			switch item.id {
			case .search:
				return collectionView.dequeueConfiguredReusableCell(using: searchRegistration, for: indexPath, item: item)
			case .header:
				return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
			default:
				return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
			}
		}
		
		dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] item in
			self?.expandedItems.insert(item)
		}
		
		dataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] item in
			guard let self else { return }
			
			self.expandedItems.remove(item)
			
			// The collection view should deselect collapsed items on its own in my opinion, but it doesn't 🤷🏼‍♂️
			guard let entityID = item.entityID,
				  let collapsingDocumentContainer = appDelegate.accountManager.findDocumentContainer(entityID),
				  let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems else {
				return
			}
			
			for selectedIndexPath in selectedIndexPaths {
				guard let entityID = self.dataSource.itemIdentifier(for: selectedIndexPath)?.entityID else { continue }
				
				if collapsingDocumentContainer.hasDecendent(entityID) {
					self.collectionView.deselectItem(at: selectedIndexPath, animated: true)
					self.updateSelections()
				}
			}
		}
		
	}
	
	private func searchSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<CollectionsItem>()
		snapshot.append([CollectionsItem.searchItem()])
		return snapshot
	}
	
	private func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem>? {
		guard let localAccount = appDelegate.accountManager.localAccount, localAccount.isActive else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<CollectionsItem>()

		let header = CollectionsItem.item(id: .header(.localAccount))
		snapshot.append([header])
		snapshot.expand([header])

		func appendToSnapshot(_ docContainer: DocumentContainer, to: CollectionsItem) {
			let item = CollectionsItem.item(docContainer)
			snapshot.append([item], to: to)
			for child in docContainer.children {
				appendToSnapshot(child, to: item)
			}
		}
		
		let documentContainers = localAccount.documentContainers
		for docContainer in documentContainers {
			appendToSnapshot(docContainer, to: header)
		}
		
		snapshot.expand(Array(expandedItems))

		return snapshot
	}
	
	private func cloudKitAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem>? {
		guard let cloudKitAccount = appDelegate.accountManager.cloudKitAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<CollectionsItem>()

		let header = CollectionsItem.item(id: .header(.cloudKitAccount))
		snapshot.append([header])
		snapshot.expand([header])

		func appendToSnapshot(_ docContainer: DocumentContainer, to: CollectionsItem) {
			let item = CollectionsItem.item(docContainer)
			snapshot.append([item], to: to)
			for child in docContainer.children {
				appendToSnapshot(child, to: item)
			}
		}
		
		let documentContainers = cloudKitAccount.documentContainers
		for docContainer in documentContainers {
			appendToSnapshot(docContainer, to: header)
		}
		
		snapshot.expand(Array(expandedItems))

		return snapshot
	}
	
	private func applyInitialSnapshot() {
		if traitCollection.userInterfaceIdiom == .mac {
			applySnapshot(searchSnapshot(), section: .search, animated: false)
		}
		applyChangeSnapshot(animated: false)
	}
	
	private func applyChangeSnapshot(animated: Bool) {
		if let snapshot = localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: animated)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<CollectionsItem>(), section: .localAccount, animated: animated)
		}

		if let snapshot = self.cloudKitAccountSnapshot() {
			applySnapshot(snapshot, section: .cloudKitAccount, animated: animated)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<CollectionsItem>(), section: .cloudKitAccount, animated: animated)
		}
	}
	
	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<CollectionsItem>, section: CollectionsSection, animated: Bool) {
		let selectedItems = collectionView.indexPathsForSelectedItems?.compactMap({ dataSource.itemIdentifier(for: $0) })
		
		dataSource.apply(snapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self else { return }

			let selectedIndexPaths = selectedItems?.compactMap { self.dataSource.indexPath(for: $0) } ?? [IndexPath]()
			
			if let selectedItems, !selectedItems.isEmpty, selectedIndexPaths.isEmpty {
				Task {
					await self.delegate?.documentContainerSelectionsDidChange(self, documentContainers: [], isNavigationBranch: false, animated: true)
				}
			} else {
				for selectedIndexPath in selectedIndexPaths {
					self.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
				}
			}
		}

	}
	
	func updateSelections(_ containers: [DocumentContainer]?, isNavigationBranch: Bool, animated: Bool) async {
		
		// Expand any parent rows that we need to in order to show the selection. Don't apply the snapshot if unnecessary.
		if let containers {
			let expandCandidates = Set(containers.flatMap({ $0.ancestors }).map({ CollectionsItem.item($0) }))
			let expandNeeded = expandCandidates.subtracting(expandedItems)
			if !expandNeeded.isEmpty {
				expandedItems.formUnion(expandNeeded)
				applyChangeSnapshot(animated: animated)
			}
		}
		
        let items = containers?.map { CollectionsItem.item($0) } ?? [CollectionsItem]()
		let indexPaths = items.compactMap { dataSource.indexPath(for: $0) }

		if !indexPaths.isEmpty {
			for indexPath in indexPaths {
				collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredVertically)
			}
		} else {
			collectionView.deselectAll()
		}
		
		let containers = items.toContainers()
		await delegate?.documentContainerSelectionsDidChange(self, documentContainers: containers, isNavigationBranch: isNavigationBranch, animated: animated)
	}
	
	func reloadVisible() {
		let visibleIndexPaths = collectionView.indexPathsForVisibleItems
		let items = visibleIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
		var snapshot = dataSource.snapshot()
		snapshot.reloadItems(items)
		dataSource.apply(snapshot)
	}
	
}

// MARK: CollectionsSearchCellDelegate

extension CollectionsViewController: CollectionsSearchCellDelegate {

	nonisolated func collectionsSearchDidBecomeActive() {
		Task {
			await selectDocumentContainers([Search(accountManager: appDelegate.accountManager, searchText: "")], isNavigationBranch: false, animated: false)
		}
	}

	nonisolated func collectionsSearchDidUpdate(searchText: String?) {
		Task {
			await collectionView.deselectAll()
			if let searchText {
				await updateSelections([Search(accountManager: appDelegate.accountManager, searchText: searchText)], isNavigationBranch: false, animated: true)
			} else {
				await updateSelections([Search(accountManager: appDelegate.accountManager, searchText: "")], isNavigationBranch: false, animated: true)
			}

		}
	}
	
}

// MARK: Helpers

private extension CollectionsViewController {
	
	func clearSearchField() {
		if let searchCellIndexPath = dataSource.indexPath(for: CollectionsItem.searchItem()) {
			if let searchCell = collectionView.cellForItem(at: searchCellIndexPath) as? CollectionsSearchCell {
				searchCell.clearSearchField()
			}
		}
	}
	
	func debounceApplyChangeSnapshot() {
		Task {
			await applyChangeChannel.send(())
		}
	}
	
	func debounceReloadVisible() {
		Task {
			await reloadVisibleChannel.send(())
		}
	}
	
	func makeDocumentContainerContextMenu(mainItem: CollectionsItem, items: [CollectionsItem]) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: mainItem as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self else { return nil }

			let containers: [DocumentContainer] = items.compactMap { item in
				if case .documentContainer(let entityID) = item.id {
					return appDelegate.accountManager.findDocumentContainer(entityID)
				}
				return nil
			}
			
			var menuItems = [UIMenu]()
			if let renameTagAction = self.renameTagAction(containers: containers) {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [renameTagAction]))
			}
			if let deleteTagAction = self.deleteTagAction(containers: containers) {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [deleteTagAction]))
			}
			return UIMenu(title: "", children: menuItems)
		})
	}

	func renameTagAction(containers: [DocumentContainer]) -> UIAction? {
		guard containers.count == 1, let container = containers.first, let tagDocuments = container as? TagDocuments else { return nil }
		
		let action = UIAction(title: .renameControlLabel, image: .rename) { [weak self] action in
			guard let self else { return }
			
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

	func deleteTagAction(containers: [DocumentContainer]) -> UIAction? {
		let tagDocuments = containers.compactMap { $0 as? TagDocuments }
		guard tagDocuments.count == containers.count else { return nil}
		
		let action = UIAction(title: .deleteControlLabel, image: .delete, attributes: .destructive) { [weak self] action in
			let deleteAction = UIAlertAction(title: .deleteControlLabel, style: .destructive) { _ in
				for tagDocument in tagDocuments {
					if let tag = tagDocument.tag {
						tagDocument.account?.forceDeleteTag(tag)
					}
				}
			}
			
			let title: String
			let message: String
			if tagDocuments.count == 1, let tag = tagDocuments.first?.tag {
				title = .deleteTagPrompt(tagName: tag.name)
				message = .deleteTagMessage
			} else {
				title = .deleteTagsPrompt(tagCount: tagDocuments.count)
				message = .deleteTagsMessage
			}
			
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			alert.addAction(deleteAction)
			alert.addAction(UIAlertAction(title: .cancelControlLabel, style: .cancel))
			alert.preferredAction = deleteAction
			self?.present(alert, animated: true, completion: nil)
		}
		
		return action
	}

}
