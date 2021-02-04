//
//  TimelineViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import UniformTypeIdentifiers
import CoreSpotlight
import RSCore
import Templeton

protocol TimelineDelegate: class  {
	func documentSelectionDidChange(_: TimelineViewController, documentContainer: DocumentContainer, document: Document?, isNew: Bool, animated: Bool)
}

class TimelineViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .timeline }

	weak var delegate: TimelineDelegate?
	
	var isExportOutlineUnavailable: Bool {
		return currentDocument == nil
	}
	
	var isDeleteCurrentOutlineUnavailable: Bool {
		return currentDocument == nil
	}
	
	var currentDocument: Document? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
			  
		return AccountManager.shared.findDocument(item.id)
	}
	
	var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!

	override var canBecomeFirstResponder: Bool { return true }

	private(set) var documentContainer: DocumentContainer?
	private var heldDocumentContainer: DocumentContainer?

	private let searchController = UISearchController(searchResultsController: nil)
	private var addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
	private var importBarButtonItem = UIBarButtonItem(image: AppAssets.importEntity, style: .plain, target: self, action: #selector(importOPML(_:)))

	private let dataSourceQueue = MainThreadOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			searchController.delegate = self
			searchController.searchResultsUpdater = self
			searchController.obscuresBackgroundDuringPresentation = false
			searchController.searchBar.placeholder = L10n.search
			navigationItem.searchController = searchController
			definesPresentationContext = true

			navigationItem.rightBarButtonItems = [addBarButtonItem, importBarButtonItem]
		}
		
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot(animated: false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateUI()
	}
	
	// MARK: API
	
	func setDocumentContainer(_ documentContainer: DocumentContainer?, completion: (() -> Void)? = nil) {
		self.documentContainer = documentContainer
		updateUI()
		applySnapshot(animated: false, completion: completion)
	}

	func selectDocument(_ document: Document?, isNew: Bool = false, animated: Bool) {
		guard let documentContainer = documentContainer else { return }

		var timelineItem: TimelineItem? = nil
		if let document = document {
			timelineItem = TimelineItem.timelineItem(document)
		}

		updateSelection(item: timelineItem, animated: animated)
		delegate?.documentSelectionDidChange(self, documentContainer: documentContainer, document: document, isNew: isNew, animated: animated)
	}
	
	func deleteCurrentDocument() {
		guard let document = currentDocument else { return }
		deleteDocument(document)
	}
	
	// MARK: Notifications
	
	@objc func accountDocumentsDidChange(_ note: Notification) {
		applySnapshot(animated: true)
	}
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)
	}
	
	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
		guard let account = documentContainer?.account else { return }
		let outline = account.createOutline(tag: (documentContainer as? TagDocuments)?.tag)
		selectDocument(outline, isNew: true, animated: true)
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
		guard let currentOutline = currentDocument?.outline else { return }
		exportMarkdownForOutline(currentOutline)
	}

	@objc func exportOPML(_ sender: Any?) {
		guard let currentOutline = currentDocument?.outline else { return }
		exportOPMLForOutline(currentOutline)
	}

}

// MARK: UIDocumentPickerDelegate

extension TimelineViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let account = documentContainer?.account else { return }

		var document: Document?
		for url in urls {
			do {
				let tag = (documentContainer as? TagDocuments)?.tag
				document = try account.importOPML(url, tag: tag)
			} catch {
				self.presentError(title: L10n.importFailed, message: error.localizedDescription)
			}
		}
		
		if let document = document {
			selectDocument(document, animated: true)
		}
	}
	
}

// MARK: Collection View

extension TimelineViewController {
		
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let documentContainer = documentContainer else { return }
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		let document = AccountManager.shared.findDocument(timelineItem.id)
		delegate?.documentSelectionDidChange(self, documentContainer: documentContainer, document: document, isNew: false, animated: true)
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
			guard let self = self, let document = AccountManager.shared.findDocument(item.id) else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.text = document.title ?? ""
			contentConfiguration.secondaryText = Self.dateString(document.updated)
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
	
	func reload(document: Document) {
		let timelineItem = TimelineItem.timelineItem(document)
		dataSourceQueue.add(ReloadItemsOperation(dataSource: dataSource, section: 0, items: [timelineItem], animated: true))
	}
	
	func applySnapshot(animated: Bool, completion: (() -> Void)? = nil) {
		guard let documentContainer = documentContainer else {
			let snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
			self.dataSourceQueue.add(ApplySnapshotOperation(dataSource: self.dataSource, section: 0, snapshot: snapshot, animated: animated))
			return
		}
		
		documentContainer.sortedDocuments { [weak self] result in
			guard let self = self, let documents = try? result.get() else { return }

			let items = documents.map { TimelineItem.timelineItem($0) }
			var snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
			snapshot.append(items)

			let snapshotOp = ApplySnapshotOperation(dataSource: self.dataSource, section: 0, snapshot: snapshot, animated: animated)
			snapshotOp.completionBlock = { _ in completion?() }
			self.dataSourceQueue.add(snapshotOp)
		}
	}
	
	func updateSelection(item: TimelineItem?, animated: Bool) {
		dataSourceQueue.add(UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, item: item, animated: animated))
	}
}

// MARK: UISearchControllerDelegate

extension TimelineViewController: UISearchControllerDelegate {

	func willPresentSearchController(_ searchController: UISearchController) {
		heldDocumentContainer = documentContainer
		setDocumentContainer(Search(searchText: ""))
	}

	func didDismissSearchController(_ searchController: UISearchController) {
		setDocumentContainer(heldDocumentContainer)
		heldDocumentContainer = nil
	}

}

// MARK: UISearchResultsUpdating

extension TimelineViewController: UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		setDocumentContainer(Search(searchText: searchController.searchBar.text!))
	}

}

// MARK: Helper Functions

extension TimelineViewController {
	
	private func updateUI() {
		navigationItem.title = documentContainer?.name
		view.window?.windowScene?.title = documentContainer?.name
	}
	
	private func makeOutlineContextMenu(item: TimelineItem) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: item as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self, let document = AccountManager.shared.findDocument(item.id) else { return nil }
			
			var menuItems = [UIMenu]()

			if let outline = document.outline {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.exportMarkdownAction(outline: outline), self.exportOPMLAction(outline: outline)]))
			}
			
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.deleteOutlineAction(document: document)]))
			
			return UIMenu(title: "", children: menuItems)
		})
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
			if let document = AccountManager.shared.findDocument(item.id) {
				self?.deleteDocument(document, completion: completion)
			}
		}
	}
	
	private func deleteOutlineAction(document: Document) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.removeEntity, attributes: .destructive) { [weak self] action in
			self?.deleteDocument(document)
		}
		
		return action
	}
	
	private func exportMarkdownForOutline(_ outline: Outline) {
		let markdown = outline.markdown()
		export(markdown, fileName: outline.fileName(withSuffix: "md"))
	}
	
	private func exportOPMLForOutline(_ outline: Outline) {
		let opml = outline.opml()
		export(opml, fileName: outline.fileName(withSuffix: "opml"))
	}
	
	private func export(_ string: String, fileName: String) {
		let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
		
		do {
			try string.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
		} catch {
			self.presentError(title: "Export Error", message: error.localizedDescription)
		}
		
		let docPicker = UIDocumentPickerViewController(forExporting: [tempFile], asCopy: true)
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	private func deleteDocument(_ document: Document, completion: ((Bool) -> Void)? = nil) {
		func delete() {
			if document == self.currentDocument, let documentContainer = self.documentContainer {
				self.delegate?.documentSelectionDidChange(self, documentContainer: documentContainer, document: nil, isNew: false, animated: true)
			}
			document.account?.deleteDocument(document)
		}

		guard !document.isEmpty else {
			delete()
			return
		}
		
		let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			completion?(true)
		}
		
		let alert = UIAlertController(title: L10n.deleteOutlinePrompt(document.title ?? ""), message: L10n.deleteOutlineMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		alert.preferredAction = deleteAction
		
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
