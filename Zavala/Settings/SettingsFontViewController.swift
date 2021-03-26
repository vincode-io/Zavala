//
//  SettingsFontViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/26/21.
//

import UIKit
import RSCore

class SettingsFontViewController: UICollectionViewController {
	
	enum Section {
		case fonts
	}
	
	var outlineFonts = AppDefaults.shared.outlineFonts

	var dataSource: UICollectionViewDiffableDataSource<Section, OutlineFontField?>!
	private let dataSourceQueue = MainThreadOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
    }

	// MARK: UICollectionView

//	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
//
//		if case .documentContainer(let entityID) = sidebarItem.id {
//			AppDefaults.shared.openQuicklyDocumentContainerID = entityID.userInfo
//			let documentContainer = AccountManager.shared.findDocumentContainer(entityID)
//			delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer)
//		}
//	}

	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}

	private func configureDataSource() {

		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineFontField?> { [weak self] (cell, indexPath, field) in
			if let field = field {
				var contentConfiguration = UIListContentConfiguration.subtitleCell()
				contentConfiguration.prefersSideBySideTextAndSecondaryText = true
				contentConfiguration.text = field.displayName
				contentConfiguration.secondaryText = self?.outlineFonts?.rowFontConfigs[field]?.displayName
				cell.contentConfiguration = contentConfiguration
			}
		}
		
		dataSource = UICollectionViewDiffableDataSource<Section, OutlineFontField?>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}

	private func applySnapshot() {
		applySnapshot(snapshot(), section: .fonts, animated: true)
	}

	private func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<OutlineFontField?>, section: Section, animated: Bool) {
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)
		dataSourceQueue.add(operation)
	}
	
	private func snapshot() -> NSDiffableDataSourceSectionSnapshot<OutlineFontField?> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<OutlineFontField?>()
		let fields = outlineFonts?.sortedFields ?? [OutlineFontField]()
		snapshot.append(fields)
		return snapshot
	}

}
