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
	
	@IBOutlet weak var restoreBarButtonItem: UIBarButtonItem!
	
	var fontDefaults = AppDefaults.shared.outlineFonts

	var dataSource: UICollectionViewDiffableDataSource<Section, OutlineFontField>!
	private let dataSourceQueue = MainThreadOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
		updateUI()
    }

	@IBAction func restoreDefaults(_ sender: Any) {
		let alertController = UIAlertController(title: L10n.restoreDefaultsMessage, message: L10n.restoreDefaultsInformative, preferredStyle: .alert)
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
		alertController.addAction(cancelAction)
		
		let restoreAction = UIAlertAction(title: L10n.restore, style: .default) { [weak self] action in
			guard let self = self else { return }
			self.fontDefaults = OutlineFontDefaults.defaults
			AppDefaults.shared.outlineFonts = self.fontDefaults
			self.applySnapshot()
			self.collectionView.reloadData()
			self.updateUI()
		}
		alertController.addAction(restoreAction)
		alertController.preferredAction = restoreAction
		
		present(alertController, animated: true)
	}
	
	// MARK: UICollectionView

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let field = dataSource.itemIdentifier(for: indexPath),
			  let config = fontDefaults?.rowFontConfigs[field] else { return }
		
		let navController = UIStoryboard.settings.instantiateViewController(identifier: "SettingsFontConfigViewControllerNav") as! UINavigationController
		navController.modalPresentationStyle = .formSheet
		let controller = navController.topViewController as! SettingsFontConfigViewController
		controller.field = field
		controller.config = config
		controller.delegate = self
		present(navController, animated: true)
		
		collectionView.deselectItem(at: indexPath, animated: true)
	}

	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}

	private func configureDataSource() {

		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineFontField> { [weak self] (cell, indexPath, field) in
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			contentConfiguration.text = field.displayName
			contentConfiguration.secondaryText = self?.fontDefaults?.rowFontConfigs[field]?.displayName
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<Section, OutlineFontField>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}

	private func applySnapshot() {
		applySnapshot(snapshot(), section: .fonts, animated: true)
	}

	private func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<OutlineFontField>, section: Section, animated: Bool) {
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)
		dataSourceQueue.add(operation)
	}
	
	private func snapshot() -> NSDiffableDataSourceSectionSnapshot<OutlineFontField> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<OutlineFontField>()
		let fields = fontDefaults?.sortedFields ?? [OutlineFontField]()
		snapshot.append(fields)
		return snapshot
	}

}

// MARK: SettingsFontConfigViewControllerDelegate

extension SettingsFontViewController: SettingsFontConfigViewControllerDelegate {
	
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig) {
		fontDefaults?.rowFontConfigs[field] = config
		AppDefaults.shared.outlineFonts = fontDefaults
		collectionView.reloadData()
		updateUI()
	}

}

// MARK: Helpers

extension SettingsFontViewController {
	
	private func updateUI() {
		restoreBarButtonItem.isEnabled = fontDefaults != OutlineFontDefaults.defaults
	}
	
}
