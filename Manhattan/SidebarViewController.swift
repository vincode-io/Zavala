//
//  SidebarViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import Combine
import Templeton

class SidebarViewController: UIViewController {

	private enum SidebarSection: Int {
		case library, localAccount, cloudKitAccount
	}
	
	private struct SidebarItem: Hashable, Identifiable {
		enum ID: Hashable {
			case header(SidebarSection)
			case outlineProvider(OutlineProviderID)
		}
		
		let id: SidebarItem.ID
		let title: String?
		let image: UIImage?
		
		static func header(title: String, id: ID) -> Self {
			return SidebarItem(id: id, title: title, image: nil)
		}
		
		static func outlineProvider(_ outlineProvider: OutlineProvider) -> Self {
			let id = SidebarItem.ID.outlineProvider(outlineProvider.outlineProviderID)
			return SidebarItem(id: id, title: outlineProvider.name, image: outlineProvider.image)
		}
	}

	private var collectionView: UICollectionView!
	private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private var collectionsSubscriber: AnyCancellable?

	private var outlineListViewController: OutlineListViewController? {
		guard
			let splitViewController = self.splitViewController,
			let outlineListViewController = splitViewController.viewController(for: .supplementary)
		else { return nil }
		
		return outlineListViewController as? OutlineListViewController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		configureCollectionView()
		configureDataSource()
		applyInitialSnapshot()
		
		// Select the first item in the Library section.
		let indexPath = IndexPath(item: 1, section: SidebarSection.library.rawValue)
		collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
		self.collectionView(collectionView, didSelectItemAt: indexPath)
		
//		collectionsSubscriber = dataStore.$collections
//			.receive(on: RunLoop.main)
//			.sink { [weak self] _ in
//				guard let self = self else { return }
//				let snapshot = self.collectionsSnapshot()
//				self.dataSource.apply(snapshot, to: .collections, animatingDifferences: true)
//			}
	}
	
}

extension SidebarViewController {
	
	private func configureCollectionView() {
		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		collectionView.backgroundColor = .systemBackground
		collectionView.delegate = self
		view.addSubview(collectionView)
	}
	
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
	
}

extension SidebarViewController: UICollectionViewDelegate {
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
	}
	
}

extension SidebarViewController {
	
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
		
		let folders = localAccount.folders ?? [Folder]()
		let items = folders.map { SidebarItem.outlineProvider($0) }
		
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
	
}

