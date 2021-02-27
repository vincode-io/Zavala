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

protocol SidebarDelegate: class {
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)?)
}

class SidebarViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .sidebar }
	
	weak var delegate: SidebarDelegate?
	
	var selectedAccount: Account? {
		guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first,
			  let entityID = dataSource.itemIdentifier(for: selectedIndexPath)?.entityID,
			  let documentContainer = AccountManager.shared.findDocumentContainer(entityID) else {
			return nil
		}
		return documentContainer.account
	}
	
	var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private let dataSourceQueue = MainThreadOperationQueue()

	private var mainSplitViewController: MainSplitViewController? {
		return splitViewController as? MainSplitViewController
	}
	
	private var addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
	private var importBarButtonItem = UIBarButtonItem(image: AppAssets.importEntity, style: .plain, target: self, action: #selector(importOPML(_:)))

	override func viewDidLoad() {
		super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
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
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncDidComplete(_:)), name: .CloudKitSyncDidComplete, object: nil)
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
		applyChangeSnapshot()
	}

	@objc func accountDidInitialize(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func accountMetadataDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func accountTagsDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func cloudKitSyncDidComplete(_ note: Notification) {
		collectionView?.refreshControl?.endRefreshing()
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if AccountManager.shared.isSyncAvailable {
			mainSplitViewController?.sync(self)
		} else {
			collectionView?.refreshControl?.endRefreshing()
		}
	}
	
	@IBAction func showSettings(_ sender: Any) {
		mainSplitViewController?.showSettings()
	}
	
	@objc func importOPML(_ sender: Any) {
		mainSplitViewController?.importOPML(sender)
	}

	@objc func createOutline(_ sender: Any) {
		mainSplitViewController?.createOutline(sender)
	}
}

// MARK: Collection View

extension SidebarViewController {
	
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
			contentConfiguration.text = item.title
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.image = item.image
			
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
		let header = SidebarItem.sidebarItem(title: AccountType.local.name, id: .header(.localAccount))
		
		let items = localAccount.documentContainers.map { SidebarItem.sidebarItem($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func cloudKitAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem>? {
		guard let cloudKitAccount = AccountManager.shared.cloudKitAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(title: AccountType.cloudKit.name, id: .header(.cloudKitAccount))
		
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
			applySnapshot(snapshot, section: .cloudKitAccount, animated: false)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<SidebarItem>(), section: .cloudKitAccount, animated: false)
		}
	}
	
	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>, section: SidebarSection, animated: Bool) {
		let selectedItems = collectionView.indexPathsForSelectedItems?.compactMap { dataSource.itemIdentifier(for: $0) }
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)

		operation.completionBlock = { [weak self] _ in
			guard let self = self else { return }
			
			let selectedIndexPaths = selectedItems?.compactMap { self.dataSource.indexPath(for: $0) }
			
			if selectedIndexPaths?.isEmpty ?? true {
				self.delegate?.documentContainerSelectionDidChange(self, documentContainer: nil, animated: true, completion: {})
			} else {
				for selectedIndexPath in selectedIndexPaths ?? [IndexPath]() {
					self.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
				}
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
	
}
