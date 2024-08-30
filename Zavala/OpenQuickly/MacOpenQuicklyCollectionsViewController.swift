//
//  MacOpenQuicklyCollectionsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/19/21.
//

import UIKit
import VinOutlineKit
import VinUtility

@MainActor
protocol MacOpenQuicklyCollectionsDelegate: AnyObject {
	func documentContainerSelectionsDidChange(_: MacOpenQuicklyCollectionsViewController, documentContainers: [DocumentContainer])
}

class MacOpenQuicklyCollectionsViewController: UICollectionViewController {

	weak var delegate: MacOpenQuicklyCollectionsDelegate?
	
	var dataSource: UICollectionViewDiffableDataSource<CollectionsSection, CollectionsItem>!

	override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.layer.borderWidth = 1
		collectionView.layer.borderColor = UIColor.systemGray2.cgColor
		collectionView.layer.cornerRadius = 3
		collectionView.allowsMultipleSelection = true
		
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
    }

    // MARK: UICollectionView

	override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		updateSelections()
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		updateSelections()
	}
	
}

// MARK: Helpers

private extension MacOpenQuicklyCollectionsViewController {
	
	func updateSelections() {
		guard let selectedIndexes = collectionView.indexPathsForSelectedItems else { return }
		let items = selectedIndexes.compactMap { dataSource.itemIdentifier(for: $0) }
		delegate?.documentContainerSelectionsDidChange(self, documentContainers: items.toContainers())
	}
	
	func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			configuration.showsSeparators = false
			configuration.headerMode = .firstItemInSection
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}

	func configureDataSource() {

		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CollectionsItem> {	(cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.header()
			contentConfiguration.text = item.id.name
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, CollectionsItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.subtitleCell()

			if case .documentContainer(let entityID) = item.id, let container = AccountManager.shared.findDocumentContainer(entityID) {
				contentConfiguration.text = container.partialName
				contentConfiguration.image = container.image

				if container.children.isEmpty {
					cell.accessories = [.outlineDisclosure(options: .init(isHidden: true, reservedLayoutWidth: .custom(6)))]
				} else {
					cell.accessories = [.outlineDisclosure(options: .init(isHidden: false, reservedLayoutWidth: .custom(6)))]
				}
			}

			cell.backgroundConfiguration?.backgroundColor = .systemBackground
			cell.contentConfiguration = contentConfiguration

			cell.configurationUpdateHandler = { cell, state in
				guard var config = cell.contentConfiguration?.updated(for: state) as? UIListContentConfiguration else { return }
				if state.isSelected || state.isHighlighted {
					config.imageProperties.tintColor = .label
				} else {
					config.imageProperties.tintColor = nil
				}
				cell.contentConfiguration = config
			}
		}
		
		dataSource = UICollectionViewDiffableDataSource<CollectionsSection, CollectionsItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			switch item.id {
			case .header:
				return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
			default:
				return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
			}
		}
	}

	func applySnapshot() {
		if let snapshot = localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: true)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<CollectionsItem>(), section: .localAccount, animated: true)
		}

		if let snapshot = self.cloudKitAccountSnapshot() {
			applySnapshot(snapshot, section: .cloudKitAccount, animated: false)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<CollectionsItem>(), section: .cloudKitAccount, animated: false)
		}
	}

	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<CollectionsItem>, section: CollectionsSection, animated: Bool) {
		let selectedItems = collectionView.indexPathsForSelectedItems?.compactMap({ dataSource.itemIdentifier(for: $0) })
		
		dataSource.apply(snapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self else { return }
			let selectedIndexPaths = selectedItems?.compactMap { self.dataSource.indexPath(for: $0) }
			for selectedIndexPath in selectedIndexPaths ?? [IndexPath]() {
				self.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
			}
		}
	}
	
	func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem>? {
		guard let localAccount = AccountManager.shared.localAccount, localAccount.isActive else { return nil }
		
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
		
		return snapshot
	}
	
	func cloudKitAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem>? {
		guard let cloudKitAccount = AccountManager.shared.cloudKitAccount else { return nil }
		
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

		return snapshot
	}

}
