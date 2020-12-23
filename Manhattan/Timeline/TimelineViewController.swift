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
	func outlineSelectionDidChange(_: TimelineViewController, outlineProvider: OutlineProvider, outline: Outline?, isNew: Bool, animated: Bool)
}

class TimelineViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .timeline }

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
	
	var isDeleteCurrentOutlineUnavailable: Bool {
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
	var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!

	override var canBecomeFirstResponder: Bool { return true }
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}

		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot(animated: false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(folderOutlinesDidChange(_:)), name: .FolderOutlinesDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTitleDidChange(_:)), name: .OutlineTitleDidChange, object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateUI()
	}
	
	// MARK: API

	func selectOutline(_ outline: Outline?, isNew: Bool = false, animated: Bool) {
		guard let outlineProvider = outlineProvider else { return }

		var timelineItem: TimelineItem? = nil
		if let outline = outline {
			timelineItem = TimelineItem.timelineItem(outline)
		}

		updateSelection(item: timelineItem, animated: animated)
		delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: outline, isNew: isNew, animated: animated)
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
	
	@objc func outlineTitleDidChange(_ note: Notification) {
		guard let outline = note.object as? Outline else { return }
		reload(outline: outline)
	}
	
	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
		guard let folder = outlineProvider as? Folder else { return }
		let outline = folder.createOutline()
		selectOutline(outline, isNew: true, animated: true)
	}

	@objc func importOPML(_ sender: Any?) {
		let opmlType = UTType(exportedAs: "org.opml.opml")
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [opmlType, .xml])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = true
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
		delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: outline, isNew: false, animated: true)
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return makeOutlineContextMenu(item: timelineItem)
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let isMac = layoutEnvironment.traitCollection.userInterfaceIdiom == .mac
			var configuration = UICollectionLayoutListConfiguration(appearance: isMac ? .plain : .sidebar)
			configuration.showsSeparators = false

			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let self = self, let timelineItem = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
				return UISwipeActionsConfiguration(actions: [self.deleteContextualAction(item: timelineItem)])
			}

			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, TimelineItem> { [weak self] (cell, indexPath, item) in
			guard let self = self, let outline = AccountManager.shared.findOutline(item.id) else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.text = outline.title ?? ""
			contentConfiguration.secondaryText = Self.dateString(outline.updated)
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				cell.insetBackground = true
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
				contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
			}
			
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<Int, TimelineItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}
	
	func reload(outline: Outline) {
		let timelineItem = TimelineItem.timelineItem(outline)
		dataSourceQueue.add(ReloadItemsOperation(dataSource: dataSource, section: 0, items: [timelineItem], animated: true))
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
			guard let self = self, let outline = AccountManager.shared.findOutline(item.id) else { return nil }
			
			let menuItems = [
				UIMenu(title: "", options: .displayInline, children: [self.toggleFavoriteAction(outline: outline)]),
				UIMenu(title: "", options: .displayInline, children: [self.exportMarkdownAction(outline: outline), self.exportOPMLAction(outline: outline)]),
				UIMenu(title: "", options: .displayInline, children: [self.deleteOutlineAction(outline: outline)])
			]

			return UIMenu(title: "", children: menuItems)
		})
	}
	
	private func toggleFavoriteAction(outline: Outline) -> UIAction {
		let title = outline.isFavorite ?? false ? L10n.unmarkAsFavorite : L10n.markAsFavorite
		let image = outline.isFavorite ?? false ? AppAssets.favoriteUnselected : AppAssets.favoriteSelected
		let action = UIAction(title: title, image: image) { action in
			outline.toggleFavorite()
		}
		return action
	}
	
	private func exportMarkdownAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportMarkdown, image: AppAssets.exportMarkdown) { [weak self] action in
			self?.exportMarkdownForOutline(outline)
		}
		return action
	}
	
	private func exportOPMLAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportOPML, image: AppAssets.exportOPML) { [weak self] action in
			self?.exportOPMLForOutline(outline)
		}
		return action
	}
	
	private func deleteContextualAction(item: TimelineItem) -> UIContextualAction {
		return UIContextualAction(style: .destructive, title: L10n.delete) { [weak self] _, _, completion in
			if let outline = AccountManager.shared.findOutline(item.id) {
				self?.deleteOutline(outline, completion: completion)
			}
		}
	}
	
	private func deleteOutlineAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.removeEntity, attributes: .destructive) { [weak self] action in
			self?.deleteOutline(outline)
		}
		
		return action
	}
	
	private func exportMarkdownForOutline(_ outline: Outline) {
		let markdown = outline.markdown()
		export(markdown, title: outline.title, fileSuffix: "md")
	}
	
	private func exportOPMLForOutline(_ outline: Outline) {
		let opml = outline.opml()
		export(opml, title: outline.title, fileSuffix: "opml")
	}
	
	private func export(_ string: String, title: String?, fileSuffix: String) {
		var filename = title ?? "Outline"
		filename = filename.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
		filename = "\(filename).\(fileSuffix)"
		let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
		
		do {
			try string.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
		} catch {
			self.presentError(title: "Export Error", message: error.localizedDescription)
		}
		
		let docPicker = UIDocumentPickerViewController(forExporting: [tempFile])
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	private func deleteOutline(_ outline: Outline, completion: ((Bool) -> Void)? = nil) {
		func delete() {
			if outline == self.currentOutline, let outlineProvider = self.outlineProvider {
				self.delegate?.outlineSelectionDidChange(self, outlineProvider: outlineProvider, outline: nil, isNew: false, animated: true)
			}
			outline.folder?.deleteOutline(outline)
		}

		guard !outline.isEmpty else {
			delete()
			return
		}
		
		let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			completion?(true)
		}
		
		let alert = UIAlertController(title: L10n.deleteOutlinePrompt(outline.title ?? ""), message: L10n.deleteOutlineMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
		
	private static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()

	private static let timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .short
		return formatter
	}()
	
	private static func dateString(_ date: Date?) -> String {
		guard let date = date else {
			return L10n.notAvailable
		}
		
		if Calendar.dateIsToday(date) {
			return timeFormatter.string(from: date)
		}
		return dateFormatter.string(from: date)
	}
	
}
