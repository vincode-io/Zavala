//
//  SidebarViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import Combine
import Templeton

protocol SidebarDelegate: class {
	func outlineProviderSelectionDidChange(_: SidebarViewController, outlineProvider: OutlineProvider?)
}

class SidebarViewController: UICollectionViewController {

	private enum SidebarSection: Int {
		case library, localAccount, cloudKitAccount
	}
	
	private final class SidebarItem: NSObject, NSCopying, Identifiable {
		
		enum ID: Hashable {
			case header(SidebarSection)
			case outlineProvider(EntityID)
		}
		
		let id: SidebarItem.ID
		let title: String?
		let image: UIImage?
		
		var entityID: EntityID? {
			if case .outlineProvider(let entityID) = id {
				return entityID
			}
			return nil
		}
		
		var isFolder: Bool {
			guard let entityID = entityID else { return false }
			switch entityID {
			case .folder(_, _):
				return true
			default:
				return false
			}
		}
		
		init(id: ID, title: String?, image: UIImage?) {
			self.id = id
			self.title = title
			self.image = image
		}
		
		static func sidebarItem(title: String, id: ID) -> SidebarViewController.SidebarItem {
			return SidebarItem(id: id, title: title, image: nil)
		}
		
		static func sidebarItem(_ outlineProvider: OutlineProvider) -> SidebarViewController.SidebarItem {
			let id = SidebarItem.ID.outlineProvider(outlineProvider.id)
			return SidebarItem(id: id, title: outlineProvider.name, image: outlineProvider.image)
		}

		override func isEqual(_ object: Any?) -> Bool {
			guard let other = object as? SidebarItem else { return false }
			if self === other { return true }
			return id == other.id && title == other.title
		}
		
		override var hash: Int {
			var hasher = Hasher()
			hasher.combine(id)
			hasher.combine(title)
			return hasher.finalize()
		}
		
		func copy(with zone: NSZone? = nil) -> Any {
			return self
		}
		
	}

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
	
	weak var delegate: SidebarDelegate?
	
	var isCreateFolderUnavailable: Bool {
		return currentAccount == nil
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
	
	func startUp(completion: @escaping (() -> Void)) {
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot(completion: completion)
	}
	
	func selectOutlineProvider(_ id: EntityID) {
		guard let outlineProvider = AccountManager.shared.findOutlineProvider(id) else { return }
		let sidebarItem = SidebarItem.sidebarItem(outlineProvider)
		let indexPath = dataSource.indexPath(for: sidebarItem)
		self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredVertically)
		delegate?.outlineProviderSelectionDidChange(self, outlineProvider: outlineProvider)
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
	
	private func applyInitialSnapshot(completion: @escaping (() -> Void)) {
		dataSource.apply(librarySnapshot(), to: .library, animatingDifferences: false) {
			DispatchQueue.main.async {
				if let snapshot = self.localAccountSnapshot() {
					self.dataSource.apply(snapshot, to: .localAccount, animatingDifferences: false, completion: completion)
				}
			}
		}
	}
	
	private func applyChangeSnapshot() {
		if let snapshot = localAccountSnapshot() {
			dataSource.apply(snapshot, to: .localAccount, animatingDifferences: true)
		}
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

