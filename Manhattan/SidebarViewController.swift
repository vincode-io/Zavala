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
		
		static func header(title: String, id: ID) -> Self {
			return SidebarItem(id: id, title: title, image: nil)
		}
		
		static func outlineProvider(_ outlineProvider: OutlineProvider) -> Self {
			let id = SidebarItem.ID.outlineProvider(outlineProvider.id)
			return SidebarItem(id: id, title: outlineProvider.name, image: outlineProvider.image)
		}
	}

	private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private var collectionsSubscriber: AnyCancellable?

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

		navigationItem.title = NSLocalizedString("Folders", comment: "Folders")
		
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange(_:)), name: .AccountDidChange, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: animated)
		}
	}
	
	// MARK: Notifications
	
	@objc func accountDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	// MARK: Collection View
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		if case .outlineProvider(let entityID) = sidebarItem.id {
			let outlineProvider = AccountManager.shared.findOutlineProvider(entityID)
			delegate?.sidebarSelectionDidChange(self, outlineProvider: outlineProvider)
		}
	}

	// MARK: Actions
	
	@IBAction func createFolder(_ sender: Any?) {
		let addNavViewController = UIStoryboard.add.instantiateViewController(withIdentifier: "AddFolderViewControllerNav") as! UINavigationController
//		addNavViewController.modalPresentationStyle = .formSheet
//		addNavViewController.preferredContentSize = AddFolderViewController.preferredSize
		present(addNavViewController, animated: true)
	}
	
	override func delete(_ sender: Any?) {
		guard let folder = self.currentFolder else { return }
		
		let deleteTitle = NSLocalizedString("Delete", comment: "Delete")
		let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { (action) in
			folder.account?.removeFolder(folder) { _ in }
		}
		
		let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
		
		#if targetEnvironment(macCatalyst)
		let preferredStyle = UIAlertController.Style.alert
		#else
		let preferredStyle = UIAlertController.Style.actionSheet
		#endif
		
		let localizedInformativeText = NSLocalizedString("Are you sure you want to delete the “%@” folder?", comment: "Folder delete text")
		let formattedInformativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, folder.name ?? "") as String

		let alert = UIAlertController(title: formattedInformativeText, message: nil, preferredStyle: preferredStyle)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		if let popoverPresentationController = alert.popoverPresentationController {
			popoverPresentationController.barButtonItem = sender as? UIBarButtonItem
		}
		
		present(alert, animated: true, completion: nil)
		
	}
}

extension SidebarViewController {
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			configuration.showsSeparators = false
			configuration.headerMode = .firstItemInSection
			let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
			return section
		}
		return layout
	}
	
	private func configureDataSource() {
		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
			(cell, indexPath, item) in
			
			var contentConfiguration = UIListContentConfiguration.sidebarHeader()
			contentConfiguration.text = item.title
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
			(cell, indexPath, item) in
			
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.image = item.image
			
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) {
			(collectionView, indexPath, item) -> UICollectionViewCell in
			
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
		let header = SidebarItem.header(title: "Library", id: .header(.library))
		let items: [SidebarItem] = [
			.outlineProvider(AccountManager.shared.allOutlineProvider),
			.outlineProvider(AccountManager.shared.favoritesOutlineProvider),
			.outlineProvider(AccountManager.shared.recentsOutlineProvider)
		]
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem>? {
		guard let localAccount = AccountManager.shared.localAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.header(title: AccountType.local.name, id: .header(.localAccount))
		
		let items = localAccount.sortedFolders.map { SidebarItem.outlineProvider($0) }
		
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

