//
//  TimelineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import UniformTypeIdentifiers
import RSCore
import Templeton

protocol TimelineDelegate: class  {
	func outlineSelectionDidChange(_: TimelineViewController, outlineProvider: OutlineProvider, outline: Outline?)
}

class TimelineViewController: UICollectionViewController {

	weak var delegate: TimelineDelegate?
	var outlineProvider: OutlineProvider? {
		didSet {
			updateUI()
			applySnapshot(animated: false)
		}
	}
	
	var isCreateOutlineUnavailable: Bool {
		return !(outlineProvider is Folder)
	}
	
	var isExportOutlineUnavailable: Bool {
		return currentOutline == nil
	}
	
	var isDeleteEntityUnavailable: Bool {
		return currentOutline == nil
	}
	
	var currentOutline: Outline? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
			  
		return AccountManager.shared.findOutline(item.id)
	}
	
	private var addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
	private var importBarButtonItem = UIBarButtonItem(image: AppAssets.importEntity, style: .plain, target: self, action: #selector(importOPML(_:)))

	private let dataSourceQueue = MainThreadOperationQueue()
	private var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!

    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}

		collectionView.dragDelegate = self
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot(animated: false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(folderOutlinesDidChange(_:)), name: .FolderOutlinesDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineNameDidChange(_:)), name: .OutlineNameDidChange, object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateUI()
	}
	
	// MARK: API

	func selectOutline(_ outline: Outline?, animated: Bool) {
		guard let outlineProvider = outlineProvider else { return }

		var timelineItem: TimelineItem? = nil
		if let outline = outline {
			timelineItem = TimelineItem.timelineItem(outline)
		}

		updateSelection(item: timelineItem, animated: animated)
		delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: outline)
	}
	
	func deleteCurrentOutline() {
		guard let outline = currentOutline else { return }
		deleteOutline(outline)
	}
	
	// MARK: Notifications
	
	@objc func folderOutlinesDidChange(_ note: Notification) {
		guard let op = outlineProvider, !op.isSmartProvider else {
			applySnapshot(animated: true)
			return
		}
		
		guard let noteOP = note.object as? OutlineProvider, op.id == noteOP.id else { return }
		applySnapshot(animated: true)
	}
	
	@objc func outlineNameDidChange(_ note: Notification) {
		applySnapshot(animated: true)
	}
	
	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
		guard let folder = outlineProvider as? Folder else { return }

		let addNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "AddOutlineViewControllerNav") as! UINavigationController
		addNavViewController.preferredContentSize = AddOutlineViewController.preferredContentSize
		addNavViewController.modalPresentationStyle = .formSheet
		let addViewController = addNavViewController.topViewController as! AddOutlineViewController
		addViewController.folder = folder

		present(addNavViewController, animated: true)
	}

	@objc func importOPML(_ sender: Any?) {
		let opmlType = UTType(exportedAs: "org.opml.opml")
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [opmlType, .xml])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}

	@objc func exportMarkdown(_ sender: Any?) {
		guard let currentOutline = currentOutline else { return }
		exportMarkdownForOutline(currentOutline)
	}

	@objc func exportOPML(_ sender: Any?) {
		guard let currentOutline = currentOutline else { return }
		exportOPMLForOutline(currentOutline)
	}

}

// MARK: UIDocumentPickerDelegate

extension TimelineViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let folder = outlineProvider as? Folder else { return }

		var outline: Outline?
		for url in urls {
			do {
				outline = try folder.importOPML(url)
			} catch {
				self.presentError(title: L10n.importFailed, message: error.localizedDescription)
			}
		}
		
		if let outline = outline {
			selectOutline(outline, animated: false)
		}
	}
	
}

// MARK: Collection View

extension TimelineViewController {
		
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let outlineProvider = outlineProvider else { return }
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		let outline = AccountManager.shared.findOutline(timelineItem.id)
		delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: outline)
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return makeOutlineContextMenu(item: timelineItem)
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			configuration.showsSeparators = false

			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let timelineItem = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
				let actions = [
					self.deleteContextualAction(item: timelineItem)
				]
				return UISwipeActionsConfiguration(actions: actions.compactMap { $0 })
			}

			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TimelineItem> { [weak self] (cell, indexPath, item) in
			guard let self = self else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.secondaryText = item.updateDate
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
				contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
			}
			
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<Int, TimelineItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}
	
	func applySnapshot(animated: Bool) {
		var snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
		let outlines = outlineProvider?.sortedOutlines ?? [Outline]()
		let items = outlines.map { TimelineItem.timelineItem($0) }
		snapshot.append(items)
		
		dataSourceQueue.add(ApplySnapshotOperation(dataSource: dataSource, section: 0, snapshot: snapshot, animated: animated))
	}
	
	func updateSelection(item: TimelineItem?, animated: Bool) {
		dataSourceQueue.add(UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, item: item, animated: animated))
	}
}

// MARK: Helper Functions

extension TimelineViewController {
	
	private func updateUI() {
		navigationItem.title = outlineProvider?.name
		view.window?.windowScene?.title = outlineProvider?.name
		
		if traitCollection.userInterfaceIdiom != .mac {
			if isCreateOutlineUnavailable {
				navigationItem.rightBarButtonItems = nil
			} else {
				navigationItem.rightBarButtonItems = [addBarButtonItem, importBarButtonItem]
			}
		}
	}
	
	private func makeOutlineContextMenu(item: TimelineItem) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: item as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }
			
			let menuItems = [
				UIMenu(title: "", options: .displayInline, children: [self.getInfoOutlineAction(item: item)]),
				UIMenu(title: "", options: .displayInline, children: [self.getExportMarkdownAction(item: item), self.getExportOPMLAction(item: item)]),
				UIMenu(title: "", options: .displayInline, children: [self.deleteOutlineAction(item: item)])
			]

			return UIMenu(title: "", children: menuItems.compactMap { $0 })
		})
	}
	
	private func getInfoOutlineAction(item: TimelineItem) -> UIAction {
		let action = UIAction(title: L10n.getInfo, image: AppAssets.getInfoEntity) { [weak self] action in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.getInfoForOutline(outline)
			}
		}
		return action
	}

	private func getExportMarkdownAction(item: TimelineItem) -> UIAction {
		let action = UIAction(title: L10n.exportMarkdown, image: AppAssets.exportMarkdown) { [weak self] action in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.exportMarkdownForOutline(outline)
			}
		}
		return action
	}
	
	private func getExportOPMLAction(item: TimelineItem) -> UIAction {
		let action = UIAction(title: L10n.exportOPML, image: AppAssets.exportOPML) { [weak self] action in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.exportOPMLForOutline(outline)
			}
		}
		return action
	}
	
	private func deleteContextualAction(item: TimelineItem) -> UIContextualAction? {
		let action = UIContextualAction(style: .destructive, title: L10n.delete) { [weak self] _, _, completion in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.deleteOutline(outline, completion: completion)
			}
		}
		
		return action
	}
	
	private func deleteOutlineAction(item: TimelineItem) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.removeEntity, attributes: .destructive) { [weak self] action in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.deleteOutline(outline)
			}
		}
		
		return action
	}
	
	private func exportMarkdownForOutline(_ outline: Outline) {
		print("Export Markdown")
	}
	
	private func exportOPMLForOutline(_ outline: Outline) {
		print("Export OPML")
	}
	
	private func getInfoForOutline(_ outline: Outline, completion: ((Bool) -> Void)? = nil) {
		let getInfoNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "GetInfoOutlineViewControllerNav") as! UINavigationController
		getInfoNavViewController.preferredContentSize = GetInfoOutlineViewController.preferredContentSize
		getInfoNavViewController.modalPresentationStyle = .formSheet
		let getInfoViewController = getInfoNavViewController.topViewController as! GetInfoOutlineViewController
		getInfoViewController.outline = outline
		present(getInfoNavViewController, animated: true) {
			completion?(true)
		}

	}
	
	private func deleteOutline(_ outline: Outline, completion: ((Bool) -> Void)? = nil) {
		let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
			if outline == self.currentOutline, let outlineProvider = self.outlineProvider {
				self.delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: nil)
			}
			outline.folder?.deleteOutline(outline)
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			completion?(true)
		}
		
		let alert = UIAlertController(title: L10n.deleteOutlinePrompt(outline.title ?? ""), message: L10n.deleteOutlineMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
		
}
