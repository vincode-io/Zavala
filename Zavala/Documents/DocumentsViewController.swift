//
//  DocumentsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import UniformTypeIdentifiers
import CoreSpotlight
import AsyncAlgorithms
import Semaphore
import VinOutlineKit
import VinUtility

extension Selector {
	static let sortByTitle = #selector(DocumentsViewController.sortByTitle(_:))
	static let sortByCreated = #selector(DocumentsViewController.sortByCreated(_:))
	static let sortByUpdated = #selector(DocumentsViewController.sortByUpdated(_:))
	static let sortAscending = #selector(DocumentsViewController.sortAscending(_:))
	static let sortDescending = #selector(DocumentsViewController.sortDescending(_:))
}

@MainActor
protocol DocumentsDelegate: AnyObject  {
	func documentSelectionDidChange(_: DocumentsViewController, documentContainers: [DocumentContainer], documents: [Document], selectRow: EntityID?, isNew: Bool, isNavigationBranch: Bool, animated: Bool)
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

	nonisolated var mainControllerIdentifer: MainControllerIdentifier { return .documents }

	weak var delegate: DocumentsDelegate?

	var selectedDocuments: [Document] {
		guard let indexPaths = collectionView.indexPathsForSelectedItems else { return [] }
		return indexPaths.sorted().map { documents[$0.row] }
	}
	
	var documents = [Document]()
	
	var documentSortOrderState: [[AnyHashable: AnyHashable]: [AnyHashable: AnyHashable]] {
		get {
			var userInfos = [[AnyHashable: AnyHashable]: [AnyHashable: AnyHashable]]()
			for (id, order) in documentSortOrders {
				userInfos[id.userInfo] = order.userInfo
			}
			return userInfos
		}
		set {
			var docSortOrders = [EntityID: DocumentSortOrder]()
			for (id, order) in newValue {
				if let entityID = EntityID(userInfo: id) {
					docSortOrders[entityID] = .init(userInfo: order)
				}
			}
			documentSortOrders = docSortOrders
		}
	}

	var currentSortOrder: DocumentSortOrder {
		if documentContainers?.count == 1, let id = documentContainers?.first?.id {
			return documentSortOrders[id] ?? .default
		} else {
			return .default
		}
	}
	
	override var canBecomeFirstResponder: Bool { return true }

	private(set) var documentContainers: [DocumentContainer]?
	private var heldDocumentContainers: [DocumentContainer]?
	private var documentSortOrders = [EntityID: DocumentSortOrder]()

	private let searchController = UISearchController(searchResultsController: nil)

	private var navButtonsBarButtonItem: UIBarButtonItem!
	private var moreMenuButton: ButtonGroup.Button!
	private var addButton: ButtonGroup.Button!

	private var loadDocumentsChannel = AsyncChannel<Void>()
	
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
			moreMenuButton = navButtonGroup.addButton(label: .moreControlLabel, image: .ellipsis, showMenu: true)
			addButton = navButtonGroup.addButton(label: .addControlLabel, image: .createEntity, selector: .createOutline)
			navButtonsBarButtonItem = navButtonGroup.buildBarButtonItem()

			searchController.delegate = self
			searchController.searchResultsUpdater = self
			searchController.obscuresBackgroundDuringPresentation = false
			searchController.searchBar.placeholder = .searchPlaceholder
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
		collectionView.reloadData()
		
		rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, Document> { [weak self] (cell, indexPath, document) in
			guard let self else { return }
			
			let title = (document.title?.isEmpty ?? true) ? .noTitleLabel : document.title!
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			if document.isCollaborating {
				let attrText = NSMutableAttributedString(string: "\(title) ")
				let shareAttachement = NSTextAttachment(image: .collaborating)
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
		
		Task {
			for await _ in loadDocumentsChannel.debounce(for: .seconds(0.5)) {
				await loadDocuments(animated: true)
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		updateUI()
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .delete:
			return !UIResponder.isFirstResponderTextField && !selectedDocuments.isEmpty
		case .selectAll:
			return !UIResponder.isFirstResponderTextField
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
	override func validate(_ command: UICommand) {
		switch command.action {
		case .sortByTitle:
			if documentContainers?.count == 1 {
				if currentSortOrder.field == .title {
					command.state = .on
				} else {
					command.state = .off
				}
			} else {
				command.attributes = [.disabled]
			}
		case .sortByCreated:
			if documentContainers?.count == 1 {
				if currentSortOrder.field == .created {
					command.state = .on
				} else {
					command.state = .off
				}
			} else {
				command.attributes = [.disabled]
			}
		case .sortByUpdated:
			if documentContainers?.count == 1 {
				if currentSortOrder.field == .updated {
					command.state = .on
				} else {
					command.state = .off
				}
			} else {
				command.attributes = [.disabled]
			}
		case .sortAscending:
			if documentContainers?.count == 1 {
				if currentSortOrder.ordered == .ascending {
					command.state = .on
				} else {
					command.state = .off
				}
			} else {
				command.attributes = [.disabled]
			}
		case .sortDescending:
			if documentContainers?.count == 1 {
				if currentSortOrder.ordered == .descending {
					command.state = .on
				} else {
					command.state = .off
				}
			} else {
				command.attributes = [.disabled]
			}
		default:
			break
		}
	}
	
	// MARK: API
	
	func setDocumentContainers(_ documentContainers: [DocumentContainer], isNavigationBranch: Bool) async {
		func updateContainer() async {
			self.documentContainers = documentContainers
			updateUI()
			collectionView.deselectAll()
			await loadDocuments(animated: false, isNavigationBranch: isNavigationBranch)
		}
		
		if documentContainers.count == 1, documentContainers.first is Search {
			await updateContainer()
		} else {
			heldDocumentContainers = nil
			searchController.searchBar.text = ""
			searchController.dismiss(animated: false)
			await updateContainer()
		}
	}

	func selectDocument(_ document: Document?, selectRow: EntityID? = nil, isNew: Bool = false, isNavigationBranch: Bool = true, animated: Bool) {
		guard let documentContainers else { return }

		collectionView.deselectAll()

		if let document, let index = documents.firstIndex(of: document) {
			collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .centeredVertically)
			delegate?.documentSelectionDidChange(self, 
												 documentContainers: documentContainers,
												 documents: [document],
												 selectRow: selectRow,
												 isNew: isNew,
												 isNavigationBranch: isNavigationBranch,
												 animated: animated)
		} else {
			delegate?.documentSelectionDidChange(self, 
												 documentContainers: documentContainers,
												 documents: [],
												 selectRow: selectRow, 
												 isNew: isNew,
												 isNavigationBranch: isNavigationBranch,
												 animated: animated)
		}
	}
	
	func importOPMLs(urls: [URL]) {
		guard let documentContainers,
			  let account = documentContainers.uniqueAccount else { return }

		for url in urls {
			Task {
				do {
					let tags = documentContainers.compactMap { ($0 as? TagDocuments)?.tag }
					let document = try await account.importOPML(url, tags: tags)
					
					await loadDocuments(animated: true)
					selectDocument(document, animated: true)
					
					DocumentIndexer.updateIndex(forDocument: document)
				} catch {
					self.presentError(title: .importFailedTitle, message: error.localizedDescription)
				}
			}
		}
	}
	
	func createOutline(animated: Bool) {
		guard let document = createOutlineDocument(title: "") else { return }
		Task {
			await loadDocuments(animated: animated)
			selectDocument(document, isNew: true, animated: true)
		}
	}

	func createOutlineDocument(title: String) -> Document? {
		guard let documentContainers,
			  let account = documentContainers.uniqueAccount else { return nil }

        let document = account.createOutline(title: title, tags: documentContainers.tags)
		
		let defaults = AppDefaults.shared
		document.outline?.update(numberingStyle: defaults.numberingStyle,
								 checkSpellingWhileTyping: defaults.checkSpellingWhileTyping,
								 correctSpellingAutomatically: defaults.correctSpellingAutomatically,
								 automaticallyCreateLinks: defaults.automaticallyCreateLinks,
								 automaticallyChangeLinkTitles: defaults.automaticallyChangeLinkTitles,
								 ownerName: defaults.ownerName,
								 ownerEmail: defaults.ownerEmail,
								 ownerURL: defaults.ownerURL)
		return document
	}
	
	func share() {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let cell = collectionView.cellForItem(at: indexPath) else { return }
		
		let controller = UIActivityViewController(activityItemsConfiguration: DocumentsActivityItemsConfiguration(selectedDocuments: selectedDocuments))
		controller.popoverPresentationController?.sourceView = cell
		self.present(controller, animated: true)
	}
	
	func manageSharing() {
		guard let document = selectedDocuments.first,
			  let shareRecord = document.shareRecord,
			  let container = appDelegate.accountManager.cloudKitAccount?.cloudKitContainer,
			  let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let cell = collectionView.cellForItem(at: indexPath) else {
			return
		}

		let controller = UICloudSharingController(share: shareRecord, container: container)
		controller.popoverPresentationController?.sourceView = cell
		controller.delegate = self
		self.present(controller, animated: true)
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
		Task {
			await reload(document: document)
			await loadDocuments(animated: true)
		}
	}
	
	@objc func documentUpdatedDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		Task {
			await reload(document: document)
		}
	}
	
	@objc func documentSharingDidChange(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		Task {
			await reload(document: document)
		}
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if appDelegate.accountManager.isSyncAvailable {
			Task {
				await appDelegate.accountManager.sync()
			}
		}
		collectionView?.refreshControl?.endRefreshing()
	}
	
	@objc func createOutline() {
		createOutline(animated: true)
	}

	@objc func importOPML() {
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.opml, .xml])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = true
		self.present(docPicker, animated: true)
	}

	@objc func sortByTitle(_ sender: Any?) {
		changeSortField(.title)
	}
	
	@objc func sortByCreated(_ sender: Any?) {
		changeSortField(.created)
	}
	
	@objc func sortByUpdated(_ sender: Any?) {
		changeSortField(.updated)
	}
	
	@objc func sortAscending(_ sender: Any?) {
		changeSortOrder(.ascending)
	}
	
	@objc func sortDescending(_ sender: Any?) {
		changeSortOrder(.descending)
	}
	
	override func delete(_ sender: Any?) {
		deleteDocuments(selectedDocuments)
	}
	
	override func selectAll(_ sender: Any?) {
		guard let documentContainers else { return }

		for i in 0..<collectionView.numberOfItems(inSection: 0) {
			collectionView.selectItem(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: [])
		}
		
		delegate?.documentSelectionDidChange(self,
											 documentContainers: documentContainers,
											 documents: documents,
											 selectRow: nil,
											 isNew: false,
											 isNavigationBranch: false,
											 animated: true)
	}

}

// MARK: UIDocumentPickerDelegate

extension DocumentsViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		importOPMLs(urls: urls)
	}
	
}

// MARK: UICloudSharingControllerDelegate

extension DocumentsViewController: UICloudSharingControllerDelegate {
	
	func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
	}
	
	func itemTitle(for csc: UICloudSharingController) -> String? {
		return nil
	}
	
	func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
		Task {
			try await Task.sleep(for: .seconds(2))
			await appDelegate.accountManager.sync()
		}
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
			collectionView.deselectAll()
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
		if indexPath.row < documents.count {
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: documents[indexPath.row])
		} else {
			// This should never happen, but does. If you are using an iPad and the collection isn't visible when performBatchUpdates
			// is called, when deleting the selected Tag, and the last item is removed this gets called with a row index of 0. This
			// happens before any updates are made in performBatchUpdates, so the 0 document count is invalid.
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: Document.dummy)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		guard let documentContainers else { return }
		
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			delegate?.documentSelectionDidChange(self,
												 documentContainers: documentContainers,
												 documents: [],
												 selectRow: nil,
												 isNew: false,
												 isNavigationBranch: false,
												 animated: true)
			return
		}
		
		let selectedDocuments = selectedIndexPaths.map { documents[$0.row] }
		delegate?.documentSelectionDidChange(self,
											 documentContainers: documentContainers,
											 documents: selectedDocuments,
											 selectRow: nil,
											 isNew: false,
											 isNavigationBranch: true,
											 animated: true)
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let documentContainers else { return }

		// We have to figure out double clicks for ourselves
		#if targetEnvironment(macCatalyst)
		let now: TimeInterval = Date().timeIntervalSince1970
		if now - lastClick < 0.3 && lastIndexPath?.row == indexPath.row {
			openDocumentInNewWindow(indexPath: indexPath)
		}
		lastClick = now
		lastIndexPath = indexPath
		#endif
		
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			delegate?.documentSelectionDidChange(self,
												 documentContainers: documentContainers,
												 documents: [],
												 selectRow: nil,
												 isNew: false,
												 isNavigationBranch: false,
												 animated: true)
			return
		}
		
		let selectedDocuments = selectedIndexPaths.map { documents[$0.row] }
		delegate?.documentSelectionDidChange(self,
											 documentContainers: documentContainers,
											 documents: selectedDocuments,
											 selectRow: nil,
											 isNew: false,
											 isNavigationBranch: true,
											 animated: true)
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
		collectionView.deselectAll()
		let document = documents[indexPath.row]
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [Pin.UserInfoKeys.pin: Pin(accountManager: appDelegate.accountManager, document: document).userInfo]
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}
	
	func reload(document: Document) async {
		let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
		if let index = documents.firstIndex(of: document) {
			collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
		}
		if let selectedItem = selectedIndexPaths?.first {
			collectionView.selectItem(at: selectedItem, animated: false, scrollPosition: [])
		}
	}
	
	func loadDocuments(animated: Bool, isNavigationBranch: Bool = false) async {
		guard let documentContainers else {
			return
		}
		
		var selectionContainers: [DocumentProvider]
		if documentContainers.count > 1 {
			selectionContainers = [TagsDocuments(containers: documentContainers)]
		} else {
			selectionContainers = documentContainers
		}

		var documents = Set<Document>()
		for selectionContainer in selectionContainers {
			documents.formUnion((try? await selectionContainer.documents) ?? [])
		}
		
		let sortedDocuments: [Document]
		
		if documentContainers.count == 1, let id = documentContainers.first?.id, let sortOrder = documentSortOrders[id] {
			switch sortOrder.ordered {
			case .ascending:
				switch sortOrder.field {
				case .title:
					sortedDocuments = documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
				case .created:
					sortedDocuments = documents.sorted(by: { $0.created ?? Date() < $1.created ?? Date() })
				case .updated:
					sortedDocuments = documents.sorted(by: { $0.updated ?? Date() < $1.updated ?? Date() })
				}
			case .descending:
				switch sortOrder.field {
				case .title:
					sortedDocuments = documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedDescending })
				case .created:
					sortedDocuments = documents.sorted(by: { $0.created ?? Date() > $1.created ?? Date() })
				case .updated:
					sortedDocuments = documents.sorted(by: { $0.updated ?? Date() > $1.updated ?? Date() })
				}
			}
		} else {
			sortedDocuments = documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
		}

		guard animated else {
			self.documents = sortedDocuments
			self.collectionView.reloadData()
			self.delegate?.documentSelectionDidChange(self,
													  documentContainers: documentContainers,
													  documents: [],
													  selectRow: nil,
													  isNew: false,
													  isNavigationBranch: isNavigationBranch,
													  animated: true)
			return
		}
		
		let prevSelectedDoc = self.collectionView.indexPathsForSelectedItems?.map({ self.documents[$0.row] }).first

		let diff = sortedDocuments.difference(from: self.documents).inferringMoves()
		self.documents = sortedDocuments

		self.collectionView.performBatchUpdates {
			for change in diff {
				switch change {
				case .insert(let offset, _, let associated):
					if let associated {
						self.collectionView.moveItem(at: IndexPath(row: associated, section: 0), to: IndexPath(row: offset, section: 0))
					} else {
						self.collectionView.insertItems(at: [IndexPath(row: offset, section: 0)])
					}
				case .remove(let offset, _, let associated):
					if let associated {
						self.collectionView.moveItem(at: IndexPath(row: offset, section: 0), to: IndexPath(row: associated, section: 0))
					} else {
						self.collectionView.deleteItems(at: [IndexPath(row: offset, section: 0)])
					}
				}
			}
		}
		
		if let prevSelectedDoc, let index = self.documents.firstIndex(of: prevSelectedDoc) {
			let indexPath = IndexPath(row: index, section: 0)
			self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
			self.collectionView.scrollToItem(at: indexPath, at: [], animated: true)
		} else {
			self.delegate?.documentSelectionDidChange(self,
													  documentContainers: documentContainers,
													  documents: [],
													  selectRow: nil,
													  isNew: false,
													  isNavigationBranch: isNavigationBranch, 
													  animated: true)
		}
	}
	
	private func reconfigureAll() {
		let indexPaths = (0..<documents.count).map { IndexPath(row: $0, section: 0) }
		collectionView.reconfigureItems(at: indexPaths)
	}
	
	private func scheduleReconfigureAll() {
		Task { @MainActor [weak self] in
			try? await Task.sleep(for: .seconds(60))
			self?.reconfigureAll()
			self?.scheduleReconfigureAll()
		}
	}
	
}

// MARK: UISearchControllerDelegate

extension DocumentsViewController: UISearchControllerDelegate {

	func willPresentSearchController(_ searchController: UISearchController) {
		heldDocumentContainers = documentContainers
		Task {
			await setDocumentContainers([Search(accountManager: appDelegate.accountManager, searchText: "")], isNavigationBranch: false)
		}
	}

	func didDismissSearchController(_ searchController: UISearchController) {
		if let heldDocumentContainers {
			Task {
				await setDocumentContainers(heldDocumentContainers, isNavigationBranch: false)
				self.heldDocumentContainers = nil
			}
		}
	}

}

// MARK: UISearchResultsUpdating

extension DocumentsViewController: UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		guard heldDocumentContainers != nil else { return }
		
		Task {
			await setDocumentContainers([Search(accountManager: appDelegate.accountManager, searchText: searchController.searchBar.text!)], isNavigationBranch: false)
		}
	}

}

// MARK: Helpers

private extension DocumentsViewController {
	
	func debounceLoadDocuments() {
		Task {
			await loadDocumentsChannel.send(())
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

			moreMenuButton.menu = buildEllipsisMenu()
		}
	}
	
	func buildEllipsisMenu() -> UIMenu {

		let importOPMLAction = UIAction(title: .importOPMLControlLabel, image: .importDocument) { [weak self] _ in
			self?.importOPML()
		}

		let currentSortOrder = currentSortOrder
		
		let sortByTitle = UIAction(title: .titleLabel) { [weak self] _ in
			self?.sortByTitle(nil)
		}
		if currentSortOrder.field == .title {
			sortByTitle.state = .on
		}
		
		let sortByCreated = UIAction(title: .createdControlLabel) { [weak self] _ in
			self?.sortByCreated(nil)
		}
		if currentSortOrder.field == .created {
			sortByCreated.state = .on
		}

		let sortByUpdated = UIAction(title: .updatedControlLabel) { [weak self] _ in
			self?.sortByUpdated(nil)
		}
		if currentSortOrder.field == .updated {
			sortByUpdated.state = .on
		}

		let sortAscending = UIAction(title: .ascendingControlLabel) { [weak self] _ in
			self?.sortAscending(nil)
		}
		if currentSortOrder.ordered == .ascending {
			sortAscending.state = .on
		}

		let sortDescending = UIAction(title: .descendingControlLabel) { [weak self] _ in
			self?.sortDescending(nil)
		}
		if currentSortOrder.ordered == .descending {
			sortDescending.state = .on
		}

		let sortByMenu = UIMenu(title: "", options: .displayInline, children: [sortByTitle, sortByCreated, sortByUpdated])
		let sortOrderMenu = UIMenu(title: "", options: .displayInline, children: [sortAscending, sortDescending])
		
		let importMenu = UIMenu(title: "", options: .displayInline, children: [importOPMLAction])
		let sortMenu = UIMenu(title: "", options: .displayInline, children: [UIMenu(title: .sortDocumentsControlLabel, image: .sort, children: [sortByMenu, sortOrderMenu])])

		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [importMenu, sortMenu])
	}
	
	func changeSortField(_ field: DocumentSortOrder.Field) {
		guard documentContainers?.count == 1, let docContainerID = documentContainers?.first?.id else { return }
		
		var documentSort = documentSortOrders[docContainerID]
		
		if documentSort == nil {
			documentSort = DocumentSortOrder(field: field, ordered: .ascending)
		} else {
			documentSort?.field = field
		}
		
		documentSortOrders[docContainerID] = documentSort
		
		Task {
			await loadDocuments(animated: true)
			updateUI()
		}
	}
	
	func changeSortOrder(_ ordered: DocumentSortOrder.Ordered) {
		guard documentContainers?.count == 1, let docContainerID = documentContainers?.first?.id else { return }
		
		var documentSort = documentSortOrders[docContainerID]

		if documentSort == nil {
			documentSort = DocumentSortOrder(field: .title, ordered: ordered)
		} else {
			documentSort?.ordered = ordered
		}

		documentSortOrders[docContainerID] = documentSort

		Task {
			await loadDocuments(animated: true)
			updateUI()
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
			
			if documents.count == 1,
			   let document = documents.first,
			   documents.first!.isCollaborating,
			   let cell = self.collectionView.cellForItem(at: allRowIDs.first!.indexPath),
			   let action = manageSharingAction(document: document, sourceView: cell) {
				shareMenuItems.append(action)
			}

			var exportActions = [UIAction]()
			exportActions.append(self.exportPDFDocsOutlineAction(outlines: outlines))
			exportActions.append(self.exportPDFListsOutlineAction(outlines: outlines))
			exportActions.append(self.exportMarkdownDocsOutlineAction(outlines: outlines))
			exportActions.append(self.exportMarkdownListsOutlineAction(outlines: outlines))
			exportActions.append(self.exportOPMLsAction(outlines: outlines))
			let exportMenu = UIMenu(title: .exportControlLabel, image: .export, children: exportActions)
			shareMenuItems.append(exportMenu)

			var printActions = [UIAction]()
			printActions.append(self.printDocsAction(outlines: outlines))
			printActions.append(self.printListsAction(outlines: outlines))
			let printMenu = UIMenu(title: .printControlLabel, image: .printDoc, children: printActions)
			shareMenuItems.append(printMenu)

			menuItems.append(UIMenu(title: "", options: .displayInline, children: shareMenuItems))
			
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [self.deleteDocumentsAction(documents: documents)]))
			
			return UIMenu(title: "", children: menuItems)
		})
	}

	func showGetInfoAction(document: Document) -> UIAction {
		let action = UIAction(title: .getInfoControlLabel, image: .getInfo) { [weak self] action in
			guard let self, let outline = document.outline else { return }
			self.delegate?.showGetInfo(self, outline: outline)
		}
		return action
	}
	
	func duplicateAction(documents: [Document]) -> UIAction {
		let action = UIAction(title: .duplicateControlLabel, image: .duplicate) { action in
            for document in documents {
				Task {
					document.load()
					
					guard let documentAccount = document.account else { return }
					
					let newDocument = document.duplicate(account: documentAccount)
					documentAccount.createDocument(newDocument)
					
					await newDocument.forceSave()
					await newDocument.unload()
					await document.unload()
				}
            }
		}
		return action
	}
	
	func shareAction(documents: [Document], sourceView: UIView) -> UIAction {
		let action = UIAction(title: .shareEllipsisControlLabel, image: .share) { action in
			let controller = UIActivityViewController(activityItemsConfiguration: DocumentsActivityItemsConfiguration(selectedDocuments: documents))
			controller.popoverPresentationController?.sourceView = sourceView
			self.present(controller, animated: true)
		}
		return action
	}
	
	func manageSharingAction(document: Document, sourceView: UIView) -> UIAction? {
		guard let shareRecord = document.shareRecord, let container = appDelegate.accountManager.cloudKitAccount?.cloudKitContainer else {
			return nil
		}

		let action = UIAction(title: .manageSharingEllipsisControlLabel, image: .collaborating) { [weak self] action in
			guard let self else { return }
			let controller = UICloudSharingController(share: shareRecord, container: container)
			controller.popoverPresentationController?.sourceView = sourceView
			controller.delegate = self
			self.present(controller, animated: true)
		}
		return action
	}

	func exportPDFDocsOutlineAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: .exportPDFDocEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportPDFDocs(self, outlines: outlines)
		}
		return action
	}
	
	func exportPDFListsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: .exportPDFListEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportPDFLists(self, outlines: outlines)
		}
		return action
	}
	
	func exportMarkdownDocsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: .exportMarkdownDocEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportMarkdownDocs(self, outlines: outlines)
		}
		return action
	}
	
	func exportMarkdownListsOutlineAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: .exportMarkdownListEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportMarkdownLists(self, outlines: outlines)
		}
		return action
	}
	
	func exportOPMLsAction(outlines: [Outline]) -> UIAction {
        let action = UIAction(title: .exportOPMLEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.exportOPMLs(self, outlines: outlines)
		}
		return action
	}
	
	func printDocsAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: .printDocEllipsisControlLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.printDocs(self, outlines: outlines)
		}
		return action
	}
	
	func printListsAction(outlines: [Outline]) -> UIAction {
		let action = UIAction(title: .printListControlEllipsisLabel) { [weak self] action in
			guard let self else { return }
			self.delegate?.printLists(self, outlines: outlines)
		}
		return action
	}
	
	func deleteContextualAction(indexPath: IndexPath) -> UIContextualAction {
		return UIContextualAction(style: .destructive, title: .deleteControlLabel) { [weak self] _, _, completion in
			guard let self else { return }
			let document = self.documents[indexPath.row]
			self.deleteDocuments([document], completion: completion)
		}
	}
	
	func deleteDocumentsAction(documents: [Document]) -> UIAction {
		let action = UIAction(title: .deleteControlLabel, image: .delete, attributes: .destructive) { [weak self] action in
			self?.deleteDocuments(documents)
		}
		
		return action
	}
	
	func deleteDocuments(_ documents: [Document], completion: ((Bool) -> Void)? = nil) {
		func delete() {
			let deselect = selectedDocuments.filter({ documents.contains($0) }).isEmpty
			if deselect, let documentContainers = self.documentContainers {
				self.delegate?.documentSelectionDidChange(self,
														  documentContainers: documentContainers,
														  documents: [],
														  selectRow: nil,
														  isNew: false,
														  isNavigationBranch: true,
														  animated: true)
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
		
		let deleteAction = UIAlertAction(title: .deleteControlLabel, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: .cancelControlLabel, style: .cancel) { _ in
			completion?(true)
		}
		
        let title: String
        let message: String
        if documents.count > 1 {
			title = .deleteOutlinesPrompt(outlineCount: documents.count)
            message = .deleteOutlinesMessage
        } else {
			title = .deleteOutlinePrompt(outlineTitle: documents.first?.title ?? "")
            message = .deleteOutlineMessage
        }
        
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(deleteAction)
		alert.addAction(cancelAction)
		alert.preferredAction = deleteAction
		
		present(alert, animated: true, completion: nil)
	}
	
}
