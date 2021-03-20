//
//  MacOpenQuicklySidebarViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/19/21.
//

import UIKit
import RSCore
import Templeton

class MacOpenQuicklySidebarViewController: UICollectionViewController {

	var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private let dataSourceQueue = MainThreadOperationQueue()

	override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.layer.borderWidth = 1
		collectionView.layer.borderColor = UIColor.systemGray2.cgColor
		collectionView.layer.cornerRadius = 5
		
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
    }

    // MARK: UICollectionView

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
			cell.backgroundView = UIImageView(image: UIColor.systemBackground.asImage())
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

	private func applySnapshot() {
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

	private func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>, section: SidebarSection, animated: Bool) {
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)
		dataSourceQueue.add(operation)
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

}
