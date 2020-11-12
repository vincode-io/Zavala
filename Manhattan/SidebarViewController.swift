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
	func sidebarSelectionDidChange(_: SidebarViewController, outlineProvider: OutlineProvider?)
}

class SidebarViewController: UICollectionViewController {

	private enum SidebarSection: Int {
		case library, localAccount, cloudKitAccount
	}
	
	private struct SidebarItem: Hashable, Identifiable {
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
		
		static func sidebarItem(title: String, id: ID) -> Self {
			return SidebarItem(id: id, title: title, image: nil)
		}
		
		static func sidebarItem(_ outlineProvider: OutlineProvider) -> Self {
			let id = SidebarItem.ID.outlineProvider(outlineProvider.id)
			return SidebarItem(id: id, title: outlineProvider.name, image: outlineProvider.image)
		}
	}

	private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

	private var currentFolder: Folder? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath),
			  let entityID = item.entityID else { return nil }
			  
		return AccountManager.shared.findFolder(entityID)
	}
	
	weak var delegate: SidebarDelegate?
	
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange(_:)), name: .AccountDidChange, object: nil)
	}
	
	// MARK: Notifications
	
	@objc func accountDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	// MARK: Actions
	
	@IBAction func createFolder(_ sender: Any?) {
		let addNavViewController = UIStoryboard.add.instantiateViewController(withIdentifier: "AddFolderViewControllerNav") as! UINavigationController
		present(addNavViewController, animated: true)
	}
	
	override func delete(_ sender: Any?) {
		guard let folder = self.currentFolder else { return }
		deleteFolder(folder)
	}
	
}

// MARK: Collection View

extension SidebarViewController {
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		if case .outlineProvider(let entityID) = sidebarItem.id {
			let outlineProvider = AccountManager.shared.findOutlineProvider(entityID)
			delegate?.sidebarSelectionDidChange(self, outlineProvider: outlineProvider)
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
		dataSource.apply(librarySnapshot(), to: .library, animatingDifferences: false)
		if let snapshot = localAccountSnapshot() {
			dataSource.apply(snapshot, to: .localAccount, animatingDifferences: false)
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
	
	private func deleteFolder(_ folder: Folder) {
		let deleteTitle = NSLocalizedString("Delete", comment: "Delete")
		let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { (action) in
			folder.account?.removeFolder(folder) { result in
				if case .failure(let error) = result {
					self.presentError(error)
				}
			}
		}
		
		let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
		
		let localizedInformativeText = NSLocalizedString("Are you sure you want to delete the “%@” folder?", comment: "Folder delete text")
		let formattedInformativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, folder.name ?? "") as String
		let localizedMessageText = NSLocalizedString("Any Outlines in this folder will also be deleted and unrecoverable.", comment: "Delete Message")
		
		let alert = UIAlertController(title: formattedInformativeText, message: localizedMessageText, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
	
}

