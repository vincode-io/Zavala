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
	func documentSelectionDidChange(_: TimelineViewController, documentContainers: [DocumentContainer], documents: [Document], isNew: Bool, isNavigationBranch: Bool, animated: Bool)
	func showGetInfo(_: TimelineViewController, outline: Outline)
	func exportPDFDocs(_: TimelineViewController, outlines: [Outline])
	func exportPDFLists(_: TimelineViewController, outlines: [Outline])
	func exportMarkdownDocs(_: TimelineViewController, outlines: [Outline])
	func exportMarkdownLists(_: TimelineViewController, outlines: [Outline])
	func exportOPMLs(_: TimelineViewController, outlines: [Outline])
}

class TimelineViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .timeline }

	weak var delegate: TimelineDelegate?

	var currentDocuments: [Document]? {
		guard let indexPaths = collectionView.indexPathsForSelectedItems else { return nil }
        return indexPaths.map { timelineDocuments[$0.row] }
	}
	
	var timelineDocuments = [Document]()

	override var canBecomeFirstResponder: Bool { return true }

	private(set) var documentContainers: [DocumentContainer]?
	private var heldDocumentContainers: [DocumentContainer]?

	private let searchController = UISearchController(searchResultsController: nil)
	private var addBarButtonItem: UIBarButtonItem?
	private var importBarButtonItem: UIBarButtonItem?

	private var loadDocumentsQueue = CoalescingQueue(name: "Load Documents", interval: 0.5)
	private var applySnapshotWorkItem: DispatchWorkItem?
    
    private var lastClick: TimeInterval = Date().timeIntervalSince1970
    private var lastIndexPath: IndexPath? = nil

	private var rowRegistration: UICollectionView.CellRegistration<ConsistentCollectionViewListCell, Document>!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
			collectionView.allowsMultipleSelection = true
		} else {
			addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline))
			importBarButtonItem = UIBarButtonItem(image: AppAssets.importDocument, style: .plain, target: self, action: #selector(importOPML))
			
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
	
	func setDocumentContainers(_ documentContainers: [DocumentContainer], isNavigationBranch: Bool, completion: (() -> Void)? = nil) {
		func updateContainer() {
			self.documentContainers = documentContainers
			updateUI()
			collectionView.deselectAll()
			loadDocuments(animated: false, isNavigationBranch: isNavigationBranch, completion: completion)
		}
		
        if documentContainers.count == 1, documentContainers.first is Search {
			updateContainer()
		} else {
			searchController.searchBar.text = ""
			heldDocumentContainers = nil
			searchController.dismiss(animated: false) {
				updateContainer()
			}
		}
	}

	func selectDocument(_ document: Document?, isNew: Bool = false, isNavigationBranch: Bool = true, animated: Bool) {
		guard let documentContainers = documentContainers else { return }
		if let document = document, let index = timelineDocuments.firstIndex(of: document) {
			collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .centeredVertically)
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [document], isNew: isNew, isNavigationBranch: isNavigationBranch, animated: animated)
		} else {
			collectionView.deselectAll()
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: isNew, isNavigationBranch: isNavigationBranch, animated: animated)
		}
	}
	
	func deleteCurrentDocuments() {
		guard let documents = currentDocuments else { return }
		deleteDocuments(documents)
	}
	
	func importOPMLs(urls: [URL]) {
        guard let documentContainers = documentContainers,
              let account = documentContainers.uniqueAccount else { return }

		var document: Document?
		for url in urls {
			do {
                let tags = documentContainers.compactMap { ($0 as? TagDocuments)?.tag }
				document = try account.importOPML(url, tags: tags)
				DocumentIndexer.updateIndex(forDocument: document!)
			} catch {
				self.presentError(title: L10n.importFailed, message: error.localizedDescription)
			}
		}
        
        if let document = document {
            loadDocuments(animated: true) {
                self.selectDocument(document, animated: true)
            }
        }
	}
	
	func createOutlineDocument(title: String) -> Document? {
        guard let documentContainers = documentContainers,
              let account = documentContainers.uniqueAccount else { return nil }

        let document = account.createOutline(title: title, tags: documentContainers.tags)
		document.outline?.update(ownerName: AppDefaults.shared.ownerName, ownerEmail: AppDefaults.shared.ownerEmail, ownerURL: AppDefaults.shared.ownerURL)
		return document
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
			guard let self = self else { return }
			self.loadDocuments(animated: true)
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
	
	@objc func createOutline() {
		guard let document = createOutlineDocument(title: "") else { return }
		loadDocuments(animated: true) {
			self.selectDocument(document, isNew: true, animated: true)
		}
	}

	@objc func importOPML() {
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
		// If we don't force the text view to give up focus, we get its additional context menu items
		if let textView = UIResponder.currentFirstResponder as? UITextView {
			textView.resignFirstResponder()
		}
        
        if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
            collectionView.deselectAll()
        }
        
        let allRowIDs: [GenericRowIdentifier]
        if let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty {
            allRowIDs = selected.compactMap { GenericRowIdentifier(indexPath: $0)}
        } else {
            allRowIDs = [GenericRowIdentifier(indexPath: indexPath)]
        }
        
        return makeOutlineContextMenu(mainRowID: GenericRowIdentifier(indexPath: indexPath), allRowIDs: allRowIDs)
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: timelineDocuments[indexPath.row])
	}

	override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		guard let documentContainers = documentContainers else { return }
		
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: false, isNavigationBranch: false, animated: true)
			return
		}
		
		let documents = selectedIndexPaths.map { timelineDocuments[$0.row] }
		delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: documents, isNew: false, isNavigationBranch: true, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let documentContainers = documentContainers else { return }

		// We have to figure out double clicks for ourselves
        let now: TimeInterval = Date().timeIntervalSince1970
        if now - lastClick < 0.3 && lastIndexPath?.row == indexPath.row {
            openDocumentInNewWindow(indexPath: indexPath)
        }
        lastClick = now
        lastIndexPath = indexPath
        
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: false, isNavigationBranch: false, animated: true)
			return
		}
		
		let documents = selectedIndexPaths.map { timelineDocuments[$0.row] }
		delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: documents, isNew: false, isNavigationBranch: true, animated: true)
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
	
	func openDocumentInNewWindow(indexPath: IndexPath) {
        collectionView.deselectAll()
		let document = timelineDocuments[indexPath.row]
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [UserInfoKeys.pin: Pin(document: document).userInfo]
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
	
	func loadDocuments(animated: Bool, isNavigationBranch: Bool = false, completion: (() -> Void)? = nil) {
		guard let documentContainers = documentContainers else {
			completion?()
			return
		}
		
        let tags = documentContainers.tags
        var selectionContainers: [DocumentProvider]
        if !tags.isEmpty {
            selectionContainers = [TagsDocuments(tags: tags)]
        } else {
            selectionContainers = documentContainers
        }
        
        var documents = Set<Document>()
        let group = DispatchGroup()
        
        for container in selectionContainers {
            group.enter()
            container.documents { result in
                if let containerDocuments = try? result.get() {
                    documents.formUnion(containerDocuments)
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            let sortedDocuments = documents.sorted(by: { $0.title ?? "" < $1.title ?? "" })

            guard animated else {
                self.timelineDocuments = sortedDocuments
				self.collectionView.reloadData()
				self.delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: false, isNavigationBranch: isNavigationBranch, animated: true)
				completion?()
				return
			}
			
			let prevSelectedDoc = self.collectionView.indexPathsForSelectedItems?.map({ self.timelineDocuments[$0.row] }).first

			let diff = sortedDocuments.difference(from: self.timelineDocuments).inferringMoves()
            self.timelineDocuments = sortedDocuments

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
				let indexPath = IndexPath(row: index, section: 0)
				self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
				self.collectionView.scrollToItem(at: indexPath, at: [], animated: true)
			} else {
				self.delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: false, isNavigationBranch: isNavigationBranch, animated: true)
			}
			
			completion?()
		}
	}
	
}

// MARK: UISearchControllerDelegate

extension TimelineViewController: UISearchControllerDelegate {

	func willPresentSearchController(_ searchController: UISearchController) {
		heldDocumentContainers = documentContainers
		setDocumentContainers([Search(searchText: "")], isNavigationBranch: false)
	}

	func didDismissSearchController(_ searchController: UISearchController) {
		if let heldDocumentContainers = heldDocumentContainers {
			setDocumentContainers(heldDocumentContainers, isNavigationBranch: false)
			self.heldDocumentContainers = nil
		}
	}

}

// MARK: UISearchResultsUpdating

extension TimelineViewController: UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		setDocumentContainers([Search(searchText: searchController.searchBar.text!)], isNavigationBranch: false)
	}

}

// MARK: Helper Functions

extension TimelineViewController {
	
	private func queueLoadDocuments() {
		loadDocumentsQueue.add(self, #selector(executeQueuedLoadDocuments))
	}
	
	@objc private func executeQueuedLoadDocuments() {
		loadDocuments(animated: true)
	}
	
	private func updateUI() {
        let title = documentContainers?.title ?? ""
        navigationItem.title = title
        view.window?.windowScene?.title = title
        
        var defaultAccount: Account? = nil
        if let containers = documentContainers {
            if containers.count == 1, let onlyContainer = containers.first {
                defaultAccount = onlyContainer.account
            }
        }
        
		if traitCollection.userInterfaceIdiom != .mac {
			if defaultAccount == nil {
				navigationItem.rightBarButtonItems = nil
			} else {
				navigationItem.rightBarButtonItems = [addBarButtonItem!, importBarButtonItem!]
			}
		}
	}
	
    private func makeOutlineContextMenu(mainRowID: GenericRowIdentifier, allRowIDs: [GenericRowIdentifier]) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: mainRowID as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }
            let documents = allRowIDs.map { self.timelineDocuments[$0.indexPath.row] }
			
			var menuItems = [UIMenu]()

            if documents.count == 1, let document = documents.first {
                menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.showGetInfoAction(document: document)]))
            }
            
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.duplicateAction(documents: documents)]))

            if documents.count == 1, let document = documents.first {
                menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.copyLinkAction(document: document)]))
            }

            let outlines = documents.compactMap { $0.outline }
            if !outlines.isEmpty {
				var exportActions = [UIAction]()
				exportActions.append(self.exportPDFDocsOutlineAction(outlines: outlines))
				exportActions.append(self.exportPDFListsOutlineAction(outlines: outlines))
				exportActions.append(self.exportMarkdownDocsOutlineAction(outlines: outlines))
				exportActions.append(self.exportMarkdownListsOutlineAction(outlines: outlines))
				exportActions.append(self.exportOPMLsAction(outlines: outlines))
				menuItems.append(UIMenu(title: L10n.export, image: AppAssets.export, children: exportActions))
			}
			
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.deleteDocumentsAction(documents: documents)]))
			
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
	
	private func duplicateAction(documents: [Document]) -> UIAction {
		let action = UIAction(title: L10n.duplicate, image: AppAssets.duplicate) { action in
            for document in documents {
                document.load()
                let newDocument = document.duplicate()
                document.account?.createDocument(newDocument)
                newDocument.forceSave()
                newDocument.unload()
                document.unload()
            }
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
	
	private func exportPDFDocsOutlineAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: L10n.exportPDFDocEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportPDFDocs(self, outlines: outlines)
		}
		return action
	}
	
	private func exportPDFListsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: L10n.exportPDFListEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportPDFLists(self, outlines: outlines)
		}
		return action
	}
	
	private func exportMarkdownDocsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: L10n.exportMarkdownDocEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportMarkdownDocs(self, outlines: outlines)
		}
		return action
	}
	
	private func exportMarkdownListsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: L10n.exportMarkdownListEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportMarkdownLists(self, outlines: outlines)
		}
		return action
	}
	
	private func exportOPMLsAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: L10n.exportOPMLEllipsis) { [weak self] action in
			guard let self = self else { return }
			self.delegate?.exportOPMLs(self, outlines: outlines)
		}
		return action
	}
	
	private func deleteContextualAction(indexPath: IndexPath) -> UIContextualAction {
		return UIContextualAction(style: .destructive, title: L10n.delete) { [weak self] _, _, completion in
			guard let self = self else { return }
			let document = self.timelineDocuments[indexPath.row]
			self.deleteDocuments([document], completion: completion)
		}
	}
	
	private func deleteDocumentsAction(documents: [Document]) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteDocuments(documents)
		}
		
		return action
	}
	
	private func deleteDocuments(_ documents: [Document], completion: ((Bool) -> Void)? = nil) {
		func delete() {
            let deselect = !(currentDocuments?.filter({ documents.contains($0) }).isEmpty ?? true)
            if deselect, let documentContainers = self.documentContainers {
				self.delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: false, isNavigationBranch: true, animated: true)
			}
            for document in documents {
                document.account?.deleteDocument(document)
            }
		}

        // We insta-delete anytime we don't have any document content
        guard !documents.filter({ !$0.isEmpty }).isEmpty else {
			delete()
			return
		}
		
		let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			completion?(true)
		}
		
        let title: String
        let message: String
        if documents.count > 1 {
            title = L10n.deleteOutlinesPrompt(documents.count)
            message = L10n.deleteOutlinesMessage
        } else {
            title = L10n.deleteOutlinePrompt(documents.first?.title ?? "")
            message = L10n.deleteOutlineMessage
        }
        
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
