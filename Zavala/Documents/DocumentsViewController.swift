//
//  DocumentsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import UniformTypeIdentifiers
import CoreSpotlight
import VinOutlineKit
import VinUtility

protocol DocumentsDelegate: AnyObject  {
	func documentSelectionDidChange(_: DocumentsViewController, documentContainers: [DocumentContainer], documents: [Document], isNew: Bool, isNavigationBranch: Bool, animated: Bool)
	func showGetInfo(_: DocumentsViewController, outline: Outline)
	func exportPDFDocs(_: DocumentsViewController, outlines: [Outline])
	func exportPDFLists(_: DocumentsViewController, outlines: [Outline])
	func exportMarkdownDocs(_: DocumentsViewController, outlines: [Outline])
	func exportMarkdownLists(_: DocumentsViewController, outlines: [Outline])
	func exportOPMLs(_: DocumentsViewController, outlines: [Outline])
	func printDocs(_: DocumentsViewController, outlines: [Outline])
	func printLists(_: DocumentsViewController, outlines: [Outline])
}

class DocumentsViewController: UICollectionViewController, MainControllerIdentifiable, DocumentsActivityItemsConfigurationDelegate {

	var mainControllerIdentifer: MainControllerIdentifier { return .documents }

	weak var delegate: DocumentsDelegate?

	var selectedDocuments: [Document] {
		guard let indexPaths = collectionView.indexPathsForSelectedItems else { return [] }
		return indexPaths.sorted().map { documents[$0.row] }
	}
	
	var documents = [Document]()

	override var canBecomeFirstResponder: Bool { return true }

	private(set) var documentContainers: [DocumentContainer]?
	private var heldDocumentContainers: [DocumentContainer]?

	private let searchController = UISearchController(searchResultsController: nil)

	private var navButtonsBarButtonItem: UIBarButtonItem!
	private var addButton: UIButton!
	private var importButton: UIButton!

	private let collectionViewQueue = MainThreadOperationQueue()
	private var loadDocumentsDebouncer = Debouncer(duration: 0.5)
    
    private var lastClick: TimeInterval = Date().timeIntervalSince1970
    private var lastIndexPath: IndexPath? = nil

	private var rowRegistration: UICollectionView.CellRegistration<ConsistentCollectionViewListCell, Document>!
	
	private var relativeFormatter: RelativeDateTimeFormatter = {
		let relativeDateTimeFormatter = RelativeDateTimeFormatter()
		relativeDateTimeFormatter.dateTimeStyle = .named
		relativeDateTimeFormatter.unitsStyle = .full
		relativeDateTimeFormatter.formattingContext = .beginningOfSentence
		return relativeDateTimeFormatter
	}()
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
			collectionView.allowsMultipleSelection = true
			collectionView.contentInset = UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 0)
		} else {
			let navButtonGroup = ButtonGroup(hostController: self, containerType: .standard, alignment: .right)
			addButton = navButtonGroup.addButton(label: AppStringAssets.addControlLabel, image: AppImageAssets.createEntity, selector: "createOutline")
			importButton = navButtonGroup.addButton(label: AppStringAssets.importOPMLControlLabel, image: AppImageAssets.importDocument, selector: "importOPML")
			navButtonsBarButtonItem = navButtonGroup.buildBarButtonItem()

			searchController.delegate = self
			searchController.searchResultsUpdater = self
			searchController.obscuresBackgroundDuringPresentation = false
			searchController.searchBar.placeholder = AppStringAssets.searchPlaceholder
			navigationItem.searchController = searchController
			definesPresentationContext = true

			navigationItem.rightBarButtonItem = navButtonsBarButtonItem

			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
			collectionView.refreshControl!.tintColor = .clear
		}
		
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		collectionViewQueue.add(ReloadAllOperation(collectionView: collectionView))
		
		rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, Document> { [weak self] (cell, indexPath, document) in
			guard let self else { return }
			
			let title = (document.title?.isEmpty ?? true) ? AppStringAssets.noTitleLabel : document.title!
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			if document.isCollaborating {
				let attrText = NSMutableAttributedString(string: "\(title) ")
				let shareAttachement = NSTextAttachment(image: AppImageAssets.collaborating)
				attrText.append(NSAttributedString(attachment: shareAttachement))
				contentConfiguration.attributedText = attrText
			} else {
				contentConfiguration.text = title
			}

			if let updated = document.updated {
				contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.secondaryText = self.relativeFormatter.localizedString(for: updated, relativeTo: Date())
			}

			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				cell.insetBackground = true
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
			}
			
			cell.contentConfiguration = contentConfiguration
			cell.setNeedsUpdateConfiguration()
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTagsDidChange(_:)), name: .OutlineTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentUpdatedDidChange(_:)), name: .DocumentUpdatedDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentSharingDidChange(_:)), name: .DocumentSharingDidChange, object: nil)
		
		scheduleReconfigureAll()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateUI()
	}
	
	// MARK: API
	
	func setDocumentContainers(_ documentContainers: [DocumentContainer], isNavigationBranch: Bool, completion: (() -> Void)? = nil) {
		func updateContainer() {
			self.documentContainers = documentContainers
			updateUI()
			collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at: [], scrollPosition: [], animated: true))
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
		guard let documentContainers else { return }

		collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at: [], scrollPosition: [], animated: false))

		if let document = document, let index = documents.firstIndex(of: document) {
			let indexPath = IndexPath(row: index, section: 0)
			collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at: [indexPath], scrollPosition: .centeredVertically, animated: false))
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [document], isNew: isNew, isNavigationBranch: isNavigationBranch, animated: animated)
		} else {
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: isNew, isNavigationBranch: isNavigationBranch, animated: animated)
		}
	}
	
	func selectAllDocuments() {
		guard let documentContainers else { return }

		var indexPaths = [IndexPath]()
		for i in 0..<collectionView.numberOfItems(inSection: 0) {
			indexPaths.append(IndexPath(row: i, section: 0))
		}
		collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at: indexPaths, scrollPosition: [], animated: false))

		
		delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: documents, isNew: false, isNavigationBranch: false, animated: true)
	}
	
	func deleteCurrentDocuments() {
		deleteDocuments(selectedDocuments)
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
				self.presentError(title: AppStringAssets.importFailedTitle, message: error.localizedDescription)
			}
		}
        
        if let document {
            loadDocuments(animated: true) {
                self.selectDocument(document, animated: true)
            }
        }
	}
	
	func createOutline(animated: Bool) {
		guard let document = createOutlineDocument(title: "") else { return }
		loadDocuments(animated: animated) {
			self.selectDocument(document, isNew: true, animated: true)
		}
	}

	func createOutlineDocument(title: String) -> Document? {
        guard let documentContainers = documentContainers,
              let account = documentContainers.uniqueAccount else { return nil }

        let document = account.createOutline(title: title, tags: documentContainers.tags)
		document.outline?.update(autoLinkingEnabled: AppDefaults.shared.autoLinkingEnabled,
								 ownerName: AppDefaults.shared.ownerName, 
								 ownerEmail: AppDefaults.shared.ownerEmail,
								 ownerURL: AppDefaults.shared.ownerURL)
		return document
	}
	
	// MARK: Notifications
	
	@objc func accountDocumentsDidChange(_ note: Notification) {
		debounceLoadDocuments()
	}
	
	@objc func outlineTagsDidChange(_ note: Notification) {
		debounceLoadDocuments()
	}
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)
		self.loadDocuments(animated: true)
	}
	
	@objc func documentUpdatedDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)
	}
	
	@objc func documentSharingDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		reload(document: document)
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if AccountManager.shared.isSyncAvailable {
			AccountManager.shared.sync()
		}
		collectionView?.refreshControl?.endRefreshing()
	}
	
	@objc func createOutline() {
		createOutline(animated: true)
	}

	@objc func importOPML() {
		let opmlType = UTType(exportedAs: DataRepresentation.opml.typeIdentifier)
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [opmlType, .xml])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = true
		self.present(docPicker, animated: true)
	}

}

// MARK: UIDocumentPickerDelegate

extension DocumentsViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		importOPMLs(urls: urls)
	}
	
}

// MARK: Collection View

extension DocumentsViewController {
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return documents.count
	}
		
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		// If we don't force the text view to give up focus, we get its additional context menu items
		if let textView = UIResponder.currentFirstResponder as? UITextView {
			textView.resignFirstResponder()
		}
        
        if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
			collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at: [], scrollPosition: [], animated: true))
        }
        
        let allRowIDs: [GenericRowIdentifier]
        if let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty {
			allRowIDs = selected.sorted().compactMap { GenericRowIdentifier(indexPath: $0)}
        } else {
            allRowIDs = [GenericRowIdentifier(indexPath: indexPath)]
        }
        
        return makeOutlineContextMenu(mainRowID: GenericRowIdentifier(indexPath: indexPath), allRowIDs: allRowIDs)
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: documents[indexPath.row])
	}

	override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		guard let documentContainers else { return }
		
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: [], isNew: false, isNavigationBranch: false, animated: true)
			return
		}
		
		let selectedDocuments = selectedIndexPaths.map { documents[$0.row] }
		delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: selectedDocuments, isNew: false, isNavigationBranch: true, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let documentContainers else { return }

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
		
		let selectedDocuments = selectedIndexPaths.map { documents[$0.row] }
		delegate?.documentSelectionDidChange(self, documentContainers: documentContainers, documents: selectedDocuments, isNew: false, isNavigationBranch: true, animated: true)
    }
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let isMac = layoutEnvironment.traitCollection.userInterfaceIdiom == .mac
			var configuration = UICollectionLayoutListConfiguration(appearance: isMac ? .plain : .sidebar)
			configuration.showsSeparators = false

			configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
				guard let self else { return nil }
				return UISwipeActionsConfiguration(actions: [self.deleteContextualAction(indexPath: indexPath)])
			}

			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	func openDocumentInNewWindow(indexPath: IndexPath) {
		collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at: [], scrollPosition: [], animated: true))
		let document = documents[indexPath.row]
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [Pin.UserInfoKeys.pin: Pin(document: document).userInfo]
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}
	
	func reload(document: Document) {
		let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
		if let index = documents.firstIndex(of: document) {
			collectionViewQueue.add(ReloadIndexPathsOperation(collectionView: collectionView, at: [IndexPath(row: index, section: 0)]))
		}
		if let selectedIndexPaths {
			collectionViewQueue.add(SelectIndexPathsOperation(collectionView: collectionView, at:selectedIndexPaths, scrollPosition: [], animated: false))
		}
	}
	
	func loadDocuments(animated: Bool, isNavigationBranch: Bool = false, completion: (() -> Void)? = nil) {
		guard let documentContainers else {
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
			let sortedDocuments = documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })

            guard animated else {
                self.documents = sortedDocuments
				self.collectionViewQueue.add(ReloadAllOperation(collectionView: self.collectionView))
				self.delegate?.documentSelectionDidChange(self,
														  documentContainers: documentContainers,
														  documents: [],
														  isNew: false,
														  isNavigationBranch: isNavigationBranch,
														  animated: true)
				completion?()
				return
			}
			
			let prevSelectedDoc = self.collectionView.indexPathsForSelectedItems?.map({ self.documents[$0.row] }).first
			
			self.collectionViewQueue.add(ApplyDiffOperation(collectionView: self.collectionView, oldDocuments: Array(self.documents), newDocuments: sortedDocuments))
			self.documents = sortedDocuments

			if let prevSelectedDoc = prevSelectedDoc, let index = sortedDocuments.firstIndex(of: prevSelectedDoc) {
				let indexPath = IndexPath(row: index, section: 0)
				self.collectionViewQueue.add(SelectIndexPathsOperation(collectionView: self.collectionView, at: [indexPath], scrollPosition: [], animated: false))
				self.collectionViewQueue.add(ScrollToIndexPathOperation(collectionView: self.collectionView, at: indexPath, scrollPosition: [], animated: true))
			} else {
				self.delegate?.documentSelectionDidChange(self,
														  documentContainers: documentContainers,
														  documents: [],
														  isNew: false,
														  isNavigationBranch: isNavigationBranch,
														  animated: true)
			}

			completion?()
		}
	}
	
	private func reconfigureAll() {
		let indexPaths = (0..<documents.count).map { IndexPath(row: $0, section: 0) }
		collectionViewQueue.add(ReconfigureIndexPathsOperation(collectionView: collectionView, indexPaths: indexPaths))
	}
	
	private func scheduleReconfigureAll() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
			self?.reconfigureAll()
			self?.scheduleReconfigureAll()
		}
	}
	
}

// MARK: UISearchControllerDelegate

extension DocumentsViewController: UISearchControllerDelegate {

	func willPresentSearchController(_ searchController: UISearchController) {
		heldDocumentContainers = documentContainers
		setDocumentContainers([Search(searchText: "")], isNavigationBranch: false)
	}

	func didDismissSearchController(_ searchController: UISearchController) {
		if let heldDocumentContainers {
			setDocumentContainers(heldDocumentContainers, isNavigationBranch: false)
			self.heldDocumentContainers = nil
		}
	}

}

// MARK: UISearchResultsUpdating

extension DocumentsViewController: UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		setDocumentContainers([Search(searchText: searchController.searchBar.text!)], isNavigationBranch: false)
	}

}

// MARK: Helpers

private extension DocumentsViewController {
	
	func debounceLoadDocuments() {
		loadDocumentsDebouncer.debounce { [weak self] in
			self?.loadDocuments(animated: true)
		}
	}
	
	func updateUI() {
		guard isViewLoaded else { return }
        let title = documentContainers?.title ?? ""
        navigationItem.title = title
        
        var defaultAccount: Account? = nil
        if let containers = documentContainers {
            if containers.count == 1, let onlyContainer = containers.first {
                defaultAccount = onlyContainer.account
            }
        }
        
		if traitCollection.userInterfaceIdiom != .mac {
			if defaultAccount == nil {
				navigationItem.rightBarButtonItem = nil
			} else {
				navigationItem.rightBarButtonItem = navButtonsBarButtonItem
			}
		}
	}
	
    func makeOutlineContextMenu(mainRowID: GenericRowIdentifier, allRowIDs: [GenericRowIdentifier]) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: mainRowID as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self else { return nil }
            let documents = allRowIDs.map { self.documents[$0.indexPath.row] }
			
			var menuItems = [UIMenuElement]()

            if documents.count == 1, let document = documents.first {
                menuItems.append(self.showGetInfoAction(document: document))
            }
            
			menuItems.append(self.duplicateAction(documents: documents))

            let outlines = documents.compactMap { $0.outline }

			var shareMenuItems = [UIMenuElement]()

			if let cell = self.collectionView.cellForItem(at: allRowIDs.first!.indexPath) {
				shareMenuItems.append(self.shareAction(documents: documents, sourceView: cell))
			}

			var printActions = [UIAction]()
			printActions.append(self.printDocsAction(outlines: outlines))
			printActions.append(self.printListsAction(outlines: outlines))
			let printMenu = UIMenu(title: AppStringAssets.printControlLabel, image: AppImageAssets.printDoc, children: printActions)
			shareMenuItems.append(printMenu)

			var exportActions = [UIAction]()
			exportActions.append(self.exportPDFDocsOutlineAction(outlines: outlines))
			exportActions.append(self.exportPDFListsOutlineAction(outlines: outlines))
			exportActions.append(self.exportMarkdownDocsOutlineAction(outlines: outlines))
			exportActions.append(self.exportMarkdownListsOutlineAction(outlines: outlines))
			exportActions.append(self.exportOPMLsAction(outlines: outlines))
			let exportMenu = UIMenu(title: AppStringAssets.exportControlLabel, image: AppImageAssets.export, children: exportActions)
			shareMenuItems.append(exportMenu)

			menuItems.append(UIMenu(title: "", options: .displayInline, children: shareMenuItems))
			
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.deleteDocumentsAction(documents: documents)]))
			
			return UIMenu(title: "", children: menuItems)
		})
	}

	func showGetInfoAction(document: Document) -> UIAction {
		let action = UIAction(title: AppStringAssets.getInfoControlLabel, image: AppImageAssets.getInfo) { [weak self] action in
			guard let self = self, let outline = document.outline else { return }
			self.delegate?.showGetInfo(self, outline: outline)
		}
		return action
	}
	
	func duplicateAction(documents: [Document]) -> UIAction {
		let action = UIAction(title: AppStringAssets.duplicateControlLabel, image: AppImageAssets.duplicate) { action in
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
	
	func shareAction(documents: [Document], sourceView: UIView) -> UIAction {
		let action = UIAction(title: AppStringAssets.shareEllipsisControlLabel, image: AppImageAssets.share) { action in
			let controller = UIActivityViewController(activityItemsConfiguration: DocumentsActivityItemsConfiguration(selectedDocuments: documents))
			controller.popoverPresentationController?.sourceView = sourceView
			self.present(controller, animated: true)
		}
		return action
	}

	func exportPDFDocsOutlineAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: AppStringAssets.exportPDFDocEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportPDFDocs(self, outlines: outlines)
		}
		return action
	}
	
	func exportPDFListsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: AppStringAssets.exportPDFListEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportPDFLists(self, outlines: outlines)
		}
		return action
	}
	
	func exportMarkdownDocsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: AppStringAssets.exportMarkdownDocEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportMarkdownDocs(self, outlines: outlines)
		}
		return action
	}
	
	func exportMarkdownListsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: AppStringAssets.exportMarkdownListEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportMarkdownLists(self, outlines: outlines)
		}
		return action
	}
	
	func exportOPMLsAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: AppStringAssets.exportOPMLEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportOPMLs(self, outlines: outlines)
		}
		return action
	}
	
	func printDocsAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: AppStringAssets.printDocEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.printDocs(self, outlines: outlines)
		}
		return action
	}
	
	func printListsAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: AppStringAssets.printListControlEllipsisLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.printLists(self, outlines: outlines)
		}
		return action
	}
	
	func deleteContextualAction(indexPath: IndexPath) -> UIContextualAction {
		return UIContextualAction(style: .destructive, title: AppStringAssets.deleteControlLabel) { [weak self] _, _, completion in
			guard let self else { return }
			let document = self.documents[indexPath.row]
			self.deleteDocuments([document], completion: completion)
		}
	}
	
	func deleteDocumentsAction(documents: [Document]) -> UIAction {
		let action = UIAction(title: AppStringAssets.deleteControlLabel, image: AppImageAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteDocuments(documents)
		}
		
		return action
	}
	
	func deleteDocuments(_ documents: [Document], completion: ((Bool) -> Void)? = nil) {
		func delete() {
            let deselect = selectedDocuments.filter({ documents.contains($0) }).isEmpty
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
		
		let deleteAction = UIAlertAction(title: AppStringAssets.deleteControlLabel, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: AppStringAssets.cancelControlLabel, style: .cancel) { _ in
			completion?(true)
		}
		
        let title: String
        let message: String
        if documents.count > 1 {
			title = AppStringAssets.deleteOutlinesPrompt(outlineCount: documents.count)
            message = AppStringAssets.deleteOutlinesMessage
        } else {
			title = AppStringAssets.deleteOutlinePrompt(outlineName: documents.first?.title ?? "")
            message = AppStringAssets.deleteOutlineMessage
        }
        
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(deleteAction)
		alert.addAction(cancelAction)
		alert.preferredAction = deleteAction
		
		present(alert, animated: true, completion: nil)
	}
	
}
