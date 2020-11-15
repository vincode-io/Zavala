//
//  SidebarViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import RSCore
import Combine
import Templeton

protocol SidebarDelegate: class {
	func outlineProviderSelectionDidChange(_: SidebarViewController, outlineProvider: OutlineProvider?)
}

class SidebarViewController: UICollectionViewController {

	
	weak var delegate: SidebarDelegate?
	
	var isCreateFolderUnavailable: Bool {
		return currentAccount == nil
	}

	var isDeleteEntityUnavailable: Bool {
		return currentFolder == nil
	}

	private let dataSourceQueue = MainThreadOperationQueue()
	private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

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
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountFoldersDidChange(_:)), name: .AccountFoldersDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(folderMetaDataDidChange(_:)), name: .FolderMetaDataDidChange, object: nil)
	}
	
	// MARK: API
	
	func startUp() {
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
	}
	
	func selectOutlineProvider(_ outlineProvider: OutlineProvider?, animated: Bool) {
		var sidebarItem: SidebarItem? = nil
		if let outlineProvider = outlineProvider {
			sidebarItem = SidebarItem.sidebarItem(outlineProvider)
		}
		
		updateSelection(item: sidebarItem, animated: animated)
		delegate?.outlineProviderSelectionDidChange(self, outlineProvider: outlineProvider)
	}
	
	func deleteCurrentFolder() {
		guard let folder = currentFolder else { return }
		deleteFolder(folder)
	}
	
	// MARK: Notifications
	
	@objc func accountFoldersDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func folderMetaDataDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	// MARK: Actions
	
	@IBAction func createFolder(_ sender: Any?) {
		guard let account = currentAccount else { return }

		let addNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "AddFolderViewControllerNav") as! UINavigationController
		let addViewController = addNavViewController.topViewController as! AddFolderViewController

		addViewController.account = account
		present(addNavViewController, animated: true)
	}
	
}

// MARK: Collection View

extension SidebarViewController {
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		if case .outlineProvider(let entityID) = sidebarItem.id {
			let outlineProvider = AccountManager.shared.findOutlineProvider(entityID)
			delegate?.outlineProviderSelectionDidChange(self, outlineProvider: outlineProvider)
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
		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {	(cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarHeader()
			contentConfiguration.text = item.title
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.image = item.image
			
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			switch item.id {
			case .header:
				return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
			default:
				return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
			}
		}
	}
	
	private func librarySnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(title: "Library", id: .header(.library))
		let items: [SidebarItem] = [
			.sidebarItem(AccountManager.shared.allOutlineProvider),
			.sidebarItem(AccountManager.shared.favoritesOutlineProvider),
			.sidebarItem(AccountManager.shared.recentsOutlineProvider)
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
		
		let title = NSLocalizedString("Delete", comment: "Delete")
		let action = UIContextualAction(style: .destructive, title: title) { [weak self] _, _, completion in
			if let folder = AccountManager.shared.findFolder(entityID) {
				self?.deleteFolder(folder, completion: completion)
			}
		}
		
		return action
	}
	
	private func getInfoFolderAction(item: SidebarItem) -> UIAction {
		let title = NSLocalizedString("Get Info", comment: "Get Info")
		let action = UIAction(title: title, image: AppAssets.getInfoEntity) { [weak self] action in
			if let folder = AccountManager.shared.findFolder(item.entityID!) {
				self?.getInfoForFolder(folder)
			}
		}
		return action
	}
	
	private func deleteFolderAction(item: SidebarItem) -> UIAction {
		let title = NSLocalizedString("Delete", comment: "Delete")
		let action = UIAction(title: title, image: AppAssets.removeEntity, attributes: .destructive) { [weak self] action in
			if let folder = AccountManager.shared.findFolder(item.entityID!) {
				self?.deleteFolder(folder)
			}
		}
		
		return action
	}
	
	private func deleteFolder(_ folder: Folder, completion: ((Bool) -> Void)? = nil) {
		func deleteFolder() {
			if self.currentFolder == folder {
				self.delegate?.outlineProviderSelectionDidChange(self, outlineProvider: nil)
			}
			folder.account?.removeFolder(folder) { result in
				if case .failure(let error) = result {
					self.presentError(error)
					completion?(true)
				} else {
					completion?(true)
				}
			}
		}
		
		guard !(folder.outlines?.isEmpty ?? true) else {
			deleteFolder()
			return
		}
		
		let deleteTitle = NSLocalizedString("Delete", comment: "Delete")
		let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { _ in
			deleteFolder()
		}
		
		let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
			completion?(true)
		}
		
		let localizedInformativeText = NSLocalizedString("Are you sure you want to delete the “%@” folder?", comment: "Folder delete text")
		let formattedInformativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, folder.name ?? "") as String
		let localizedMessageText = NSLocalizedString("Any Outlines in this folder will also be deleted and unrecoverable.", comment: "Delete Message")
		
		let alert = UIAlertController(title: formattedInformativeText, message: localizedMessageText, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	private func getInfoForFolder(_ folder: Folder, completion: ((Bool) -> Void)? = nil) {
		let getInfoNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "GetInfoFolderViewControllerNav") as! UINavigationController
		let getInfoViewController = getInfoNavViewController.topViewController as! GetInfoFolderViewController
		getInfoViewController.folder = folder
		present(getInfoNavViewController, animated: true) {
			completion?(true)
		}

	}
	
}
