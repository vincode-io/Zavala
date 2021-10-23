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

protocol TimelineDelegate: AnyObject  {
	func documentSelectionDidChange(_: TimelineViewController, documentContainer: DocumentContainer, document: Document?, isNew: Bool, animated: Bool)
	func showGetInfo(_: TimelineViewController, outline: Outline)
	func exportPDFDoc(_: TimelineViewController, outline: Outline)
	func exportPDFList(_: TimelineViewController, outline: Outline)
	func exportMarkdownDoc(_: TimelineViewController, outline: Outline)
	func exportMarkdownList(_: TimelineViewController, outline: Outline)
	func exportOPML(_: TimelineViewController, outline: Outline)
}

class TimelineViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .timeline }

	weak var delegate: TimelineDelegate?

	var currentDocument: Document? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first else { return nil }
		return timelineDocuments[indexPath.row]
	}
	
	var timelineDocuments = [Document]()

	override var canBecomeFirstResponder: Bool { return true }

	private(set) var documentContainer: DocumentContainer?
	private var heldDocumentContainer: DocumentContainer?

	private let searchController = UISearchController(searchResultsController: nil)
	private var addBarButtonItem: UIBarButtonItem?
	private var importBarButtonItem: UIBarButtonItem?

	private var coalescingQueue = CoalescingQueue(name: "Load Documents", interval: 0.5)
	private var applySnapshotWorkItem: DispatchWorkItem?

	private var rowRegistration: UICollectionView.CellRegistration<ConsistentCollectionViewListCell, Document>!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
			importBarButtonItem = UIBarButtonItem(image: AppAssets.importDocument, style: .plain, target: self, action: #selector(importOPML(_:)))
			
			searchController.delegate = self
			searchController.searchResultsUpdater = self
			searchController.obscuresBackgroundDuringPresentation = false
			searchController.searchBar.placeholder = L10n.search
			navigationItem.searchController = searchController
			definesPresentationContext = true

			addBarButtonItem!.title = L10n.add
			importBarButtonItem!.title = L10n.importOPML
			navigationItem.rightBarButtonItems = [addBarButtonItem!, importBarButtonItem!]

			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
		}
		
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		collectionView.reloadData()
		
		rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, Document> { [weak self] (cell, indexPath, document) in
			guard let self = self else { return }
			
			let title = (document.title?.isEmpty ?? true) ? L10n.noTitle : document.title!
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			if document.isCollaborating {
				let attrText = NSMutableAttributedString(string: "\(title) ")
				let shareAttachement = NSTextAttachment(image: AppAssets.collaborating)
				attrText.append(NSAttributedString(attachment: shareAttachement))
				contentConfiguration.attributedText = attrText
			} else {
				contentConfiguration.text = title
			}
			contentConfiguration.secondaryText = Self.dateString(document.updated)
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				cell.insetBackground = true
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
				contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
			}
			
			cell.contentConfiguration = contentConfiguration
			
			let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.selectDocument(gesture:)))
			cell.addGestureRecognizer(singleTap)
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.openDocumentInNewWindow(gesture:)))
				doubleTap.numberOfTapsRequired = 2
				cell.addGestureRecognizer(doubleTap)
			}
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTagsDidChange(_:)), name: .OutlineTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentUpdatedDidChange(_:)), name: .DocumentUpdatedDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentSharingDidChange(_:)), name: .DocumentSharingDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncDidComplete(_:)), name: .CloudKitSyncDidComplete, object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateUI()
	}
	
	// MARK: API
	
	func setDocumentContainer(_ documentContainer: DocumentContainer?, completion: (() -> Void)? = nil) {
		self.documentContainer = documentContainer
		updateUI()
		collectionView.deselectAll()
		loadDocuments(animated: false, completion: completion)
	}

	func selectDocument(_ document: Document?, isNew: Bool = false, animated: Bool) {
		guard let documentContainer = documentContainer else { return }
		if let document = document, let index = timelineDocuments.firstIndex(of: document) {
			collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .centeredVertically)
		} else {
			collectionView.deselectAll()
		}
		delegate?.documentSelectionDidChange(self, documentContainer: documentContainer, document: document, isNew: isNew, animated: animated)
	}
	
	func deleteCurrentDocument() {
		guard let document = currentDocument else { return }
		deleteDocument(document)
	}
	
	func importOPMLs(urls: [URL]) {
		guard let account = documentContainer?.account else { return }

		var document: Document?
		for url in urls {
			do {
				let tag = (documentContainer as? TagDocuments)?.tag
				document = try account.importOPML(url, tag: tag)
				DocumentIndexer.updateIndex(forDocument: document!)
			} catch {
				self.presentError(title: L10n.importFailed, message: error.localizedDescription)
			}
		}
		
		if let document = document {
			selectDocument(document, animated: true)
		}
	}
	
	// MARK: Notifications
	
	@objc func accountDocumentsDidChange(_ note: Notification) {
		queueLoadDocuments()
	}
	
	@objc func outlineTagsDidChange(_ note: Notification) {
		queueLoadDocuments()
	}
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)

		applySnapshotWorkItem?.cancel()
		applySnapshotWorkItem = DispatchWorkItem { [weak self] in
			self?.loadDocuments(animated: true)
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: applySnapshotWorkItem!)
	}
	
	@objc func documentUpdatedDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)
	}
	
	@objc func documentSharingDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)
	}
	
	@objc func cloudKitSyncDidComplete(_ note: Notification) {
		collectionView?.refreshControl?.endRefreshing()
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if AccountManager.shared.isSyncAvailable {
			AccountManager.shared.sync()
		} else {
			collectionView?.refreshControl?.endRefreshing()
		}
	}
	
	@objc func createOutline(_ sender: Any? = nil) {
		guard let account = documentContainer?.account else { return }
		let document = account.createOutline(tag: (documentContainer as? TagDocuments)?.tag)
		if case .outline(let outline) = document {
			outline.update(ownerName: AppDefaults.shared.ownerName, ownerEmail: AppDefaults.shared.ownerEmail, ownerURL: AppDefaults.shared.ownerURL)
		}
		loadDocuments(animated: true) {
			self.selectDocument(document, isNew: true, animated: true)
		}
	}

	@objc func importOPML(_ sender: Any? = nil) {
		let opmlType = UTType(exportedAs: "org.opml.opml")
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [opmlType, .xml])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = true
		self.present(docPicker, animated: true)
	}

}

// MARK: UIDocumentPickerDelegate

extension TimelineViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		importOPMLs(urls: urls)
	}
	
}

// MARK: Collection View

extension TimelineViewController {
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return timelineDocuments.count
	}
		
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		return makeOutlineContextMenu(rowIdentifier: GenericRowIdentifier(indexPath: indexPath))
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: timelineDocuments[indexPath.row])
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let isMac = layoutEnvironment.traitCollection.userInterfaceIdiom == .mac
			var configuration = UICollectionLayoutListConfiguration(appearance: isMac ? .plain : .sidebar)
			configuration.showsSeparators = false

			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let self = self else { return nil }
				return UISwipeActionsConfiguration(actions: [self.deleteContextualAction(indexPath: indexPath)])
			}

			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
		
	@objc func selectDocument(gesture: UITapGestureRecognizer) {
		guard let documentContainer = documentContainer,
			  let cell = gesture.view as? UICollectionViewCell,
			  let indexPath = collectionView.indexPath(for: cell) else { return }

		collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
		let document = timelineDocuments[indexPath.row]
		delegate?.documentSelectionDidChange(self, documentContainer: documentContainer, document: document, isNew: false, animated: true)
	}
	
	@objc func openDocumentInNewWindow(gesture: UITapGestureRecognizer) {
		guard let cell = gesture.view as? UICollectionViewCell,
			  let indexPath = collectionView.indexPath(for: cell) else { return }

		let document = timelineDocuments[indexPath.row]
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [UserInfoKeys.documentID: document.id.userInfo]
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}
	
	func reload(document: Document) {
		let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
		if let index = timelineDocuments.firstIndex(of: document) {
			collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
		}
		if let selectedItem = selectedIndexPaths?.first {
			collectionView.selectItem(at: selectedItem, animated: false, scrollPosition: [])
		}
	}
	
	func loadDocuments(animated: Bool, completion: (() -> Void)? = nil) {
		guard let documentContainer = documentContainer else {
			completion?()
			return
		}
		
		documentContainer.sortedDocuments { [weak self] result in
			guard let self = self, let documents = try? result.get() else { return }

			guard animated else {
				self.timelineDocuments = documents
				self.collectionView.reloadData()
				return
			}
			
			let prevSelectedDoc = self.collectionView.indexPathsForSelectedItems?.map({ self.timelineDocuments[$0.row] }).first

			let diff = documents.difference(from: self.timelineDocuments).inferringMoves()
			self.timelineDocuments = documents

			self.collectionView.performBatchUpdates {
				for change in diff {
					switch change {
					case .insert(let offset, _, let associated):
						if let associated = associated {
							self.collectionView.moveItem(at: IndexPath(row: associated, section: 0), to: IndexPath(row: offset, section: 0))
						} else {
							self.collectionView.insertItems(at: [IndexPath(row: offset, section: 0)])
						}
					case .remove(let offset, _, let associated):
						if let associated = associated {
							self.collectionView.moveItem(at: IndexPath(row: offset, section: 0), to: IndexPath(row: associated, section: 0))
						} else {
							self.collectionView.deleteItems(at: [IndexPath(row: offset, section: 0)])
						}
					}
				}
			}
			
			if let prevSelectedDoc = prevSelectedDoc, let index = self.timelineDocuments.firstIndex(of: prevSelectedDoc) {
				self.collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: [])
			} else {
				self.delegate?.documentSelectionDidChange(self, documentContainer: documentContainer, document: nil, isNew: false, animated: true)
			}
			
			completion?()
		}
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
	
	private func queueLoadDocuments() {
		coalescingQueue.add(self, #selector(loadDocumentsAnimated))
	}
	
	@objc private func loadDocumentsAnimated() {
		loadDocuments(animated: true)
	}
	
	private func updateUI() {
		navigationItem.title = documentContainer?.name
		view.window?.windowScene?.title = documentContainer?.name
		
		if traitCollection.userInterfaceIdiom != .mac {
			if documentContainer?.account == nil {
				navigationItem.rightBarButtonItems = nil
			} else {
				navigationItem.rightBarButtonItems = [addBarButtonItem!, importBarButtonItem!]
			}
		}
	}
	
	private func makeOutlineContextMenu(rowIdentifier: GenericRowIdentifier) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: rowIdentifier as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }
			let document = self.timelineDocuments[rowIdentifier.indexPath.row]
			
			var menuItems = [UIMenu]()

			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.showGetInfoAction(document: document)]))
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.duplicateAction(document: document)]))
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.copyLinkAction(document: document)]))

			if let outline = document.outline {
				var exportActions = [UIAction]()
				exportActions.append(self.exportPDFDocOutlineAction(outline: outline))
				exportActions.append(self.exportPDFListOutlineAction(outline: outline))
				exportActions.append(self.exportMarkdownDocOutlineAction(outline: outline))
				exportActions.append(self.exportMarkdownListOutlineAction(outline: outline))
				exportActions.append(self.exportOPMLAction(outline: outline))
				menuItems.append(UIMenu(title: L10n.export, image: AppAssets.export, children: exportActions))
			}
			
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.deleteOutlineAction(document: document)]))
			
			return UIMenu(title: "", children: menuItems)
		})
	}

	private func showGetInfoAction(document: Document) -> UIAction {
		let action = UIAction(title: L10n.getInfo, image: AppAssets.getInfo) { [weak self] action in
			guard let self = self, let outline = document.outline else { return }
			self.delegate?.showGetInfo(self, outline: outline)
		}
		return action
	}
	
	private func duplicateAction(document: Document) -> UIAction {
		let action = UIAction(title: L10n.duplicate, image: AppAssets.duplicate) { action in
			document.load()
			let newDocument = document.duplicate()
			document.account?.createDocument(newDocument)
			newDocument.forceSave()
			newDocument.unload()
			document.unload()
		}
		return action
	}
	
	private func copyLinkAction(document: Document) -> UIAction {
		let action = UIAction(title: L10n.copyDocumentLink, image: AppAssets.link) { action in
			let documentURL = document.id.url
			UIPasteboard.general.url = documentURL
		}
		return action
	}
	
	private func exportPDFDocOutlineAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportPDFDocEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportPDFDoc(self, outline: outline)
		}
		return action
	}
	
	private func exportPDFListOutlineAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportPDFListEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportPDFList(self, outline: outline)
		}
		return action
	}
	
	private func exportMarkdownDocOutlineAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportMarkdownDocEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportMarkdownDoc(self, outline: outline)
		}
		return action
	}
	
	private func exportMarkdownListOutlineAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportMarkdownListEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportMarkdownList(self, outline: outline)
		}
		return action
	}
	
	private func exportOPMLAction(outline: Outline) -> UIAction {
		let action = UIAction(title: L10n.exportOPMLEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportOPML(self, outline: outline)
		}
		return action
	}
	
	private func deleteContextualAction(indexPath: IndexPath) -> UIContextualAction {
		return UIContextualAction(style: .destructive, title: L10n.delete) { [weak self] _, _, completion in
			guard let self = self else { return }
			let document = self.timelineDocuments[indexPath.row]
			self.deleteDocument(document, completion: completion)
		}
	}
	
	private func deleteOutlineAction(document: Document) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteDocument(document)
		}
		
		return action
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
