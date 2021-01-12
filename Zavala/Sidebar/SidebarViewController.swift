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
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, animated: Bool)
}

class SidebarViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .sidebar }
	
	weak var delegate: SidebarDelegate?
	
	var isCreateFolderUnavailable: Bool {
		return currentAccount == nil
	}

	var isDeleteCurrentFolderUnavailable: Bool {
		return currentFolder == nil
	}

	var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private let dataSourceQueue = MainThreadOperationQueue()

	private var currentAccount: Account? {
		let activeAccounts = AccountManager.shared.activeAccounts
		guard activeAccounts.count != 1 else {
			return activeAccounts.first
		}
		return currentFolder?.account
	}
	
	private var currentFolder: Folder? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath),
			  let entityID = item.entityID else { return nil }
			  
		return AccountManager.shared.findFolder(entityID)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidInitialize(_:)), name: .AccountDidInitialize, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountFoldersDidChange(_:)), name: .AccountFoldersDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(folderMetaDataDidChange(_:)), name: .FolderMetaDataDidChange, object: nil)
	}
	
	// MARK: API
	
	func startUp() {
		collectionView.dropDelegate = self
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()

		// Select the first folder.  This will be changed by state restoration, but in the case that it isn't, this
		// is probably the first run.  Selecting a folder will make it easier to figure out how to add an initial Outline.
		if !(splitViewController?.isCollapsed ?? false) {
			if let localAccount = AccountManager.shared.localAccount, let folder = localAccount.folders?.first {
				selectDocumentContainer(folder, animated: false)
			}
		}
	}
	
	func selectDocumentContainer(_ documentContainer: DocumentContainer?, animated: Bool) {
		var sidebarItem: SidebarItem? = nil
		if let outlineProvider = documentContainer {
			sidebarItem = SidebarItem.sidebarItem(outlineProvider)
		}
		
		updateSelection(item: sidebarItem, animated: animated)
		delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer, animated: animated)
	}
	
	func deleteCurrentFolder() {
		guard let folder = currentFolder else { return }
		deleteFolder(folder)
	}
	
	func restoreArchive() {
		let zalarcType = UTType(exportedAs: "io.vincode.Zavala.archive")
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [zalarcType])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = false
		self.present(docPicker, animated: true)
	}
	
	func restoreArchive(url: URL) {
		let unpackResult : (AccountType, URL)
		do {
			unpackResult = try AccountManager.shared.unpackArchive(url)
		} catch {
			presentError(error)
			return
		}
		
		let restoreAction = UIAlertAction(title: L10n.restore, style: .default) { [weak self] _ in
			guard let self = self else { return }
			self.collectionView.selectItem(at: nil, animated: true, scrollPosition: .top)
			self.delegate?.documentContainerSelectionDidChange(self, documentContainer: nil, animated: true)
			AccountManager.shared.restoreArchive(accountType: unpackResult.0, unpackURL: unpackResult.1)
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			AccountManager.shared.cleanUpArchive(unpackURL: unpackResult.1)
		}
		
		let title = L10n.restoreAccountPrompt(unpackResult.0.name)
		let alert = UIAlertController(title: title, message: L10n.restoreAccountMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(restoreAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	func archiveAccount(type: AccountType) {
		guard let archiveFile = AccountManager.shared.archiveAccount(type: type) else { return }
		
		let docPicker = UIDocumentPickerViewController(forExporting: [archiveFile])
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	// MARK: Notifications
	
	@objc func accountDidInitialize(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func accountMetadataDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func accountFoldersDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func folderMetaDataDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	// MARK: Actions
	
	@IBAction func createFolder(_ sender: Any?) {
		guard let account = currentAccount else { return }

		if traitCollection.userInterfaceIdiom == .mac {
			
			let addViewController = UIStoryboard.dialog.instantiateController(ofType: AddFolderViewController.self)
			addViewController.preferredContentSize = AddFolderViewController.preferredContentSize
			addViewController.account = account
			present(addViewController, animated: true)
			
		} else {
			
			let addNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "AddFolderViewControllerNav") as! UINavigationController
			addNavViewController.preferredContentSize = AddFolderViewController.preferredContentSize
			addNavViewController.modalPresentationStyle = .formSheet

			let addViewController = addNavViewController.topViewController as! AddFolderViewController
			addViewController.account = account
			present(addNavViewController, animated: true)
		}
	}
	
}

// MARK: Collection View

extension SidebarViewController {
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		if case .documentContainer(let entityID) = sidebarItem.id {
			let documentContainer = AccountManager.shared.findDocumentContainer(entityID)
			delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer, animated: true)
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath), sidebarItem.isFolder else { return nil }
		return makeFolderContextMenu(item: sidebarItem)
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			configuration.showsSeparators = false
			configuration.headerMode = .firstItemInSection
			
			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let sidebarItem = self.dataSource.itemIdentifier(for: indexPath), sidebarItem.isFolder else { return nil }
				let actions = [
					self.deleteFolderContextualAction(item: sidebarItem)
				]
				return UISwipeActionsConfiguration(actions: actions.compactMap { $0 })
			}
			
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
	
	private func librarySnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(title: "Library", id: .header(.library))
		let items: [SidebarItem] = [
			.sidebarItem(AccountManager.shared.allDocumentContainer),
			.sidebarItem(AccountManager.shared.favoritesDocumentContainer),
			.sidebarItem(AccountManager.shared.recentsDocumentContainer)
		]
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem>? {
		guard let localAccount = AccountManager.shared.localAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(title: AccountType.local.name, id: .header(.localAccount))
		
		let items = localAccount.sortedFolders.map { SidebarItem.sidebarItem($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func applyInitialSnapshot() {
		if traitCollection.userInterfaceIdiom == .mac {
			applySnapshot(searchSnapshot(), section: .search, animated: false)
		}
		
		applySnapshot(librarySnapshot(), section: .library, animated: false)
		
		if let snapshot = self.localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: false)
		}
	}
	
	private func applyChangeSnapshot() {
		if let snapshot = localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: true)
		}
	}
	
	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>, section: SidebarSection, animated: Bool) {
		dataSourceQueue.add(ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated))
	}
	
	func updateSelection(item: SidebarItem?, animated: Bool) {
		dataSourceQueue.add(UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, item: item, animated: animated))
	}
}

// MARK: UIDocumentPickerDelegate

extension SidebarViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		restoreArchive(url: urls[0])
	}
	
}

// MARK: SidebarSearchCellDelegate

extension SidebarViewController: SidebarSearchCellDelegate {

	func sidebarSearchDidBecomeActive() {
		selectDocumentContainer(nil, animated: false)
	}

	func sidebarSearchDidUpdate(searchText: String?) {
		print(searchText ?? "")
	}
	
}

// MARK: Helper Functions

extension SidebarViewController {
	
	private func makeFolderContextMenu(item: SidebarItem) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: item as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }
			
			let menuItems = [
				UIMenu(title: "", options: .displayInline, children: [self.getInfoFolderAction(item: item)]),
				UIMenu(title: "", options: .displayInline, children: [self.deleteFolderAction(item: item)])
			]

			return UIMenu(title: "", children: menuItems)
		})
	}
	
	private func deleteFolderContextualAction(item: SidebarItem) -> UIContextualAction? {
		guard let entityID = item.entityID else { return nil }
		
		let action = UIContextualAction(style: .destructive, title: L10n.delete) { [weak self] _, _, completion in
			if let folder = AccountManager.shared.findFolder(entityID) {
				self?.deleteFolder(folder, completion: completion)
			}
		}
		
		return action
	}
	
	private func getInfoFolderAction(item: SidebarItem) -> UIAction {
		let action = UIAction(title: L10n.getInfo, image: AppAssets.getInfoEntity) { [weak self] action in
			if let folder = AccountManager.shared.findFolder(item.entityID!) {
				self?.getInfoForFolder(folder)
			}
		}
		return action
	}
	
	private func deleteFolderAction(item: SidebarItem) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.removeEntity, attributes: .destructive) { [weak self] action in
			if let folder = AccountManager.shared.findFolder(item.entityID!) {
				self?.deleteFolder(folder)
			}
		}
		
		return action
	}
	
	private func deleteFolder(_ folder: Folder, completion: ((Bool) -> Void)? = nil) {
		func deleteFolder() {
			if self.currentFolder == folder {
				self.delegate?.documentContainerSelectionDidChange(self, documentContainer: nil, animated: true)
			}
			folder.account?.deleteFolder(folder)
			completion?(true)
		}
		
		guard !(folder.documents?.isEmpty ?? true) else {
			deleteFolder()
			return
		}
		
		let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
			deleteFolder()
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			completion?(true)
		}
		
		let alert = UIAlertController(title: L10n.deleteFolderPrompt(folder.name ?? ""), message: L10n.deleteFolderMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	private func getInfoForFolder(_ folder: Folder) {
		
		if traitCollection.userInterfaceIdiom == .mac {
			
			let getInfoViewController = UIStoryboard.dialog.instantiateController(ofType: GetInfoFolderViewController.self)
			getInfoViewController.preferredContentSize = GetInfoFolderViewController.preferredContentSize
			getInfoViewController.folder = folder
			present(getInfoViewController, animated: true)
			
		} else {
			
			let getInfoNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "GetInfoFolderViewControllerNav") as! UINavigationController
			getInfoNavViewController.preferredContentSize = GetInfoFolderViewController.preferredContentSize
			getInfoNavViewController.modalPresentationStyle = .formSheet

			let getInfoViewController = getInfoNavViewController.topViewController as! GetInfoFolderViewController
			getInfoViewController.folder = folder
			present(getInfoNavViewController, animated: true)

		}
	}
	
}
