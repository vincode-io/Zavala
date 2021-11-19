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
	
	struct FieldConfig: Hashable {
		var field: OutlineFontField
		var config: OutlineFontConfig
	}
	
	var fontDefaults = AppDefaults.shared.outlineFonts

	var dataSource: UICollectionViewDiffableDataSource<Section, FieldConfig>!
	private let dataSourceQueue = MainThreadOperationQueue()

	private var restoreBarButtonItem: UIBarButtonItem!
	private var addBarButtonItem: UIBarButtonItem!

	override func viewDidLoad() {
        super.viewDidLoad()

		restoreBarButtonItem = UIBarButtonItem(image: AppAssets.restore, style: .plain, target: self, action: #selector(restoreDefaults(_:)))
		restoreBarButtonItem.title = L10n.restore

		addBarButtonItem = UIBarButtonItem(image: AppAssets.add, style: .plain, target: nil, action: nil)
		addBarButtonItem.title = L10n.add
		addBarButtonItem.menu = buildAddMenu()

		navigationItem.rightBarButtonItems = [addBarButtonItem, restoreBarButtonItem]

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
		updateUI()
    }

	@objc func restoreDefaults(_ sender: Any) {
		let alertController = UIAlertController(title: L10n.restoreDefaultsMessage, message: L10n.restoreDefaultsInformative, preferredStyle: .alert)
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
		alertController.addAction(cancelAction)
		
		let restoreAction = UIAlertAction(title: L10n.restore, style: .default) { [weak self] action in
			guard let self = self else { return }
			self.fontDefaults = OutlineFontDefaults.defaults
			AppDefaults.shared.outlineFonts = self.fontDefaults
			self.applySnapshot()
			self.updateUI()
		}
		alertController.addAction(restoreAction)
		alertController.preferredAction = restoreAction
		
		present(alertController, animated: true)
	}

	// MARK: UICollectionView

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let fieldConfig = dataSource.itemIdentifier(for: indexPath) else { return }
		
		showFontConfig(field: fieldConfig.field, config: fieldConfig.config)
		collectionView.deselectItem(at: indexPath, animated: true)
	}

	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)

			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let self = self,
					  let fieldConfig = self.dataSource.itemIdentifier(for: indexPath),
					  let deleteAction = self.deleteAction(field: fieldConfig.field) else { return nil }
				return UISwipeActionsConfiguration(actions: [deleteAction])
			}

			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}

	private func configureDataSource() {

		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FieldConfig> { (cell, indexPath, fieldConfig) in
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			contentConfiguration.text = fieldConfig.field.displayName
			contentConfiguration.secondaryText = fieldConfig.config.displayName
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<Section, FieldConfig>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}

	private func applySnapshot() {
		applySnapshot(snapshot(), section: .fonts, animated: true)
	}

	private func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<FieldConfig>, section: Section, animated: Bool) {
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)
		dataSourceQueue.add(operation)
	}
	
	private func snapshot() -> NSDiffableDataSourceSectionSnapshot<FieldConfig> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<FieldConfig>()
		
		var fieldConfigs = [FieldConfig]()
		for field in fontDefaults?.sortedFields ?? [OutlineFontField]() {
			if let config = fontDefaults?.rowFontConfigs[field] {
				fieldConfigs.append(FieldConfig(field: field, config: config))
			}
		}
		
		snapshot.append(fieldConfigs)
		return snapshot
	}

}

// MARK: SettingsFontConfigViewControllerDelegate

extension SettingsFontViewController: SettingsFontConfigViewControllerDelegate {
	
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig) {
		fontDefaults?.rowFontConfigs[field] = config
		AppDefaults.shared.outlineFonts = fontDefaults
		applySnapshot()
		updateUI()
	}

}

// MARK: Helpers

private extension SettingsFontViewController {
	
	func updateUI() {
		restoreBarButtonItem.isEnabled = fontDefaults != OutlineFontDefaults.defaults
	}
	
	func buildAddMenu() -> UIMenu {
		let addTopicLevelAction = UIAction(title: L10n.addTopicLevel, image: AppAssets.topicFont) { [weak self] _ in
			guard let (field, config) = self?.fontDefaults?.nextTopicDefault else { return }
			self?.showFontConfig(field: field, config: config)
		}

		let addNoteLevelAction = UIAction(title: L10n.addNoteLevel, image: AppAssets.noteFont) { [weak self] _ in
			guard let (field, config) = self?.fontDefaults?.nextNoteDefault else { return }
			self?.showFontConfig(field: field, config: config)
		}
		
		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [addTopicLevelAction, addNoteLevelAction])
	}
	
	func showFontConfig(field: OutlineFontField, config: OutlineFontConfig) {
		let navController = UIStoryboard.settings.instantiateViewController(identifier: "SettingsFontConfigViewControllerNav") as! UINavigationController
		navController.modalPresentationStyle = .formSheet
		let controller = navController.topViewController as! SettingsFontConfigViewController
		controller.field = field
		controller.config = config
		controller.delegate = self
		present(navController, animated: true)
	}

	func deleteAction(field: OutlineFontField) -> UIContextualAction? {
		let action =  UIContextualAction(style: .destructive, title: L10n.delete) { [weak self] _, _, completion in
			guard let self = self else { return }
			self.fontDefaults?.rowFontConfigs.removeValue(forKey: field)
			AppDefaults.shared.outlineFonts = self.fontDefaults
			self.applySnapshot()
		}

		switch field {
		case .rowTopic(let level):
			if level > 1 && level == fontDefaults?.deepestTopicLevel {
				return action
			}
		case .rowNote(let level):
			if level > 1 && level == fontDefaults?.deepestNoteLevel {
				return action
			}
		default:
			break
		}
		
		return nil
	}
	
}
