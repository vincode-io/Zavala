//
//  EditorViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import MobileCoreServices
import PhotosUI
import RSCore
import Templeton

extension Selector {
	static let insertImage = #selector(EditorViewController.insertImage)
}

protocol EditorDelegate: AnyObject {
	var editorViewControllerIsGoBackUnavailable: Bool { get }
	var editorViewControllerIsGoForwardUnavailable: Bool { get }
	var editorViewControllerGoBackwardStack: [Pin] { get }
	var editorViewControllerGoForwardStack: [Pin] { get }
	func goBackward(_: EditorViewController, to: Int)
	func goForward(_: EditorViewController, to: Int)
	func createNewOutline(_ : EditorViewController, title: String) -> Outline?
	func validateToolbar(_ : EditorViewController)
	func showGetInfo(_: EditorViewController, outline: Outline)
	func exportPDFDoc(_: EditorViewController, outline: Outline)
	func exportPDFList(_: EditorViewController, outline: Outline)
	func exportMarkdownDoc(_: EditorViewController, outline: Outline)
	func exportMarkdownList(_: EditorViewController, outline: Outline)
	func exportOPML(_: EditorViewController, outline: Outline)
	func printDoc(_: EditorViewController, outline: Outline)
	func printList(_: EditorViewController, outline: Outline)
	func zoomImage(_: EditorViewController, image: UIImage, transitioningDelegate: UIViewControllerTransitioningDelegate)
}

class EditorViewController: UIViewController, MainControllerIdentifiable, UndoableCommandRunner {

	private static let searchBarHeight: CGFloat = 44
	
	@IBOutlet weak var searchBar: EditorSearchBar!
	@IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var collectionView: EditorCollectionView!
	
	var mainControllerIdentifer: MainControllerIdentifier { return .editor }

	weak var delegate: EditorDelegate?
	
	var isOutlineFunctionsUnavailable: Bool {
		return outline == nil
	}
	
	var isCollaborateUnavailable: Bool {
		return outline == nil || !outline!.isCloudKit
	}
	
	var isDocumentCollaborating: Bool {
		return outline?.iCollaborating ?? false
	}
	
	var isFilterOn: Bool {
		return outline?.isFilterOn ?? false
	}

	var isCompletedFiltered: Bool {
		return outline?.isCompletedFiltered ?? true
	}
	
	var isNotesFiltered: Bool {
		return outline?.isNotesFiltered ?? true
	}
	
	var isSelectAllRowsUnavailable: Bool {
		if let selected = collectionView?.indexPathsForSelectedItems, !selected.isEmpty {
			return false
		}
		return true
	}
	
	var isDeleteCurrentRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isInsertRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isCreateRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isDuplicateRowsUnavailable: Bool {
		return currentRows == nil
	}
	
	var isCreateRowInsideUnavailable: Bool {
		return currentRows == nil
	}

	var isCreateRowOutsideUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCreateRowOutsideUnavailable(rows: rows)
	}

	var isGoBackwardUnavailable: Bool {
		return delegate?.editorViewControllerIsGoBackUnavailable ?? true
	}
	
	var isGoForwardUnavailable: Bool {
		return delegate?.editorViewControllerIsGoForwardUnavailable ?? true
	}
	
	var isMoveRowsRightUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isMoveRowsRightUnavailable(rows: rows)
	}

	var isMoveRowsLeftUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isMoveRowsLeftUnavailable(rows: rows)
	}

	var isMoveRowsUpUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isMoveRowsUpUnavailable(rows: rows)
	}

	var isMoveRowsDownUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isMoveRowsDownUnavailable(rows: rows)
	}

	var isToggleRowCompleteUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCompleteUnavailable(rows: rows) && outline.isUncompleteUnavailable(rows: rows)
	}

	var isCompleteRowsAvailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return !outline.isCompleteUnavailable(rows: rows)
	}
	
	var isCreateRowNotesUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCreateNotesUnavailable(rows: rows)
	}

	var isDeleteRowNotesUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isDeleteNotesUnavailable(rows: rows)
	}

	var isSplitRowUnavailable: Bool {
		return currentTextView == nil
	}

	var isFormatUnavailable: Bool {
		return currentTextView == nil
	}

	var isLinkUnavailable: Bool {
		return currentTextView == nil
	}

	var isInsertImageUnavailable: Bool {
		return currentTextView == nil
	}

	var isExpandAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isExpandAllInOutlineUnavailable
	}

	var isCollapseAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isCollapseAllInOutlineUnavailable
	}

	var isExpandAllUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isExpandAllUnavailable(containers: rows)
	}

	var isCollapseAllUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCollapseAllUnavailable(containers: rows)
	}

	var isExpandUnavailable: Bool {
		guard let rows = currentRows else { return true }
		for row in rows {
			if row.isExpandable {
				return false
			}
		}
		return true
	}

	var isCollapseUnavailable: Bool {
		guard let rows = currentRows else { return true }
		for row in rows {
			if row.isCollapsable {
				return false
			}
		}
		return true
	}

	var isCollapseParentRowUnavailable: Bool {
		guard let rows = currentRows else { return true }
		for row in rows {
			if (row.parent as? Row)?.isCollapsable ?? false {
				return false
			}
		}
		return true
	}
	
	var isDeleteCompletedRowsUnavailable: Bool {
		return !(outline?.isAnyRowCompleted ?? false)
	}
	
	var currentRows: [Row]? {
		if let selected = collectionView?.indexPathsForSelectedItems, !selected.isEmpty {
			return selected.compactMap { outline?.shadowTable?[$0.row] }
		} else if let currentRow = currentTextView?.row {
			return [currentRow]
		}
		return nil
	}
	
	var isInEditMode: Bool {
		if let responder = UIResponder.currentFirstResponder, responder is UITextField || responder is UITextView {
			return true
		} else {
			return false
		}
	}
	
	var isBoldToggledOn: Bool {
		return currentTextView?.isBoldToggledOn ?? false
	}

	var isItalicToggledOn: Bool {
		return currentTextView?.isItalicToggledOn ?? false
	}

	var isSearching = false
	
	var adjustedRowsSection: Int {
		return outline?.adjustedRowsSection.rawValue ?? Outline.Section.rows.rawValue
	}
	
	var undoableCommands = [UndoableCommand]()
	
	override var canBecomeFirstResponder: Bool { return true }

	private var keyboardToolBar: UIToolbar!
	private var goBackwardButton: UIBarButtonItem!
	private var goForwardButton: UIBarButtonItem!
	private var moveRightButton: UIBarButtonItem!
	private var moveLeftButton: UIBarButtonItem!
	private var moveUpButton: UIBarButtonItem!
	private var moveDownButton: UIBarButtonItem!
	private var insertImageButton: UIBarButtonItem!
	private var linkButton: UIBarButtonItem!

	private var messageLabel: UILabel?
	
	private(set) var outline: Outline?
	
	private var currentTitle: String? {
		guard let titleCell = collectionView.cellForItem(at: IndexPath(row: 0, section: Outline.Section.title.rawValue)) as? EditorTitleViewCell else {
			return nil
		}
		return titleCell.textViewText
	}
	
	private var currentTextView: EditorRowTextView? {
		return UIResponder.currentFirstResponder as? EditorRowTextView
	}
	
	private var currentRowStrings: RowStrings? {
		return currentTextView?.rowStrings
	}
	
	private var currentCursorPosition: Int? {
		return currentTextView?.cursorPosition
	}
	
	private var cancelledKeys = Set<UIKey>()
	private var isCursoringUp = false
	private var isCursoringDown = false
	
	private var ellipsisBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: AppAssets.ellipsis, style: .plain, target: nil, action: nil)
	private var filterBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: AppAssets.filterInactive, style: .plain, target: nil, action: nil)
	private var doneBarButtonItem: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(done))

	private var titleRegistration: UICollectionView.CellRegistration<EditorTitleViewCell, Outline>?
	private var tagRegistration: UICollectionView.CellRegistration<EditorTagViewCell, String>?
	private var tagInputRegistration: UICollectionView.CellRegistration<EditorTagInputViewCell, EntityID>?
	private var rowRegistration: UICollectionView.CellRegistration<EditorRowViewCell, Row>?
	private var backlinkRegistration: UICollectionView.CellRegistration<EditorBacklinkViewCell, Outline>?

	private var firstVisibleShadowTableIndex: Int? {
		let visibleRect = collectionView.layoutMarginsGuide.layoutFrame
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.minY)
		if let indexPath = collectionView.indexPathForItem(at: visiblePoint), indexPath.section == adjustedRowsSection {
			return indexPath.row
		}
		return nil
	}
	
	// This is used to keep the collection view from scrolling to the top as its layout gets invalidated.
	private var transitionContentOffset: CGPoint?
	
	private var isOutlineNewFlag = false
	private var updateTitleWorkItem: DispatchWorkItem?
	private var keyboardWorkItem: DispatchWorkItem?

	private var currentKeyboardHeight: CGFloat = 0
	
	private var headerFooterSections: IndexSet {
		var sections = [Outline.Section.title.rawValue, Outline.Section.tags.rawValue]
		if !(outline?.documentBacklinks?.isEmpty ?? true) {
			sections.append(Outline.Section.backlinks.rawValue)
		}
		return IndexSet(sections)
	}
	
	private static var defaultContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
	
	private lazy var transition = ImageTransition(delegate: self)
	private var imageBlocker: UIView?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		//NSTextAttachment.registerViewProviderClass(MetadataTextAttachmentViewProvider.self, forFileType: MetadataTextAttachmentViewProvider.fileType)
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			ellipsisBarButtonItem.title = L10n.more
			filterBarButtonItem.title = L10n.filter

			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
		}
		
		searchBar.delegate = self
		collectionViewTopConstraint.constant = 0
		
		collectionView.collectionViewLayout = createLayout()
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.dragInteractionEnabled = true
		collectionView.allowsMultipleSelection = true
		collectionView.selectionFollowsFocus = false
		collectionView.contentInset = EditorViewController.defaultContentInsets

		let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(createInitialRowIfNecessary))
		tapGestureRecogniser.delegate = self
		collectionView.addGestureRecognizer(tapGestureRecogniser)
		
		titleRegistration = UICollectionView.CellRegistration<EditorTitleViewCell, Outline> { [weak self] (cell, indexPath, outline) in
			cell.outline = outline
			cell.delegate = self
		}
		
		tagRegistration = UICollectionView.CellRegistration<EditorTagViewCell, String> { (cell, indexPath, name) in
			cell.name = name
			cell.delegate = self
		}
		
		tagInputRegistration = UICollectionView.CellRegistration<EditorTagInputViewCell, EntityID> { (cell, indexPath, outlineID) in
			cell.outlineID = outlineID
			cell.delegate = self
		}
		
		rowRegistration = UICollectionView.CellRegistration<EditorRowViewCell, Row> { [weak self] (cell, indexPath, row) in
			cell.row = row
			cell.isNotesHidden = self?.outline?.isNotesFilterOn ?? false
			cell.isSearching = self?.isSearching ?? false
			cell.delegate = self
		}
		
		backlinkRegistration = UICollectionView.CellRegistration<EditorBacklinkViewCell, Outline> { [weak self] (cell, indexPath, outline) in
			cell.reference = self?.generateBacklinkVerbaige(outline: outline)
		}
		
		goBackwardButton = UIBarButtonItem(image: AppAssets.goBackward, style: .plain, target: self, action: #selector(goBackwardOne))
		goBackwardButton.title = L10n.goBackward
		goForwardButton = UIBarButtonItem(image: AppAssets.goForward, style: .plain, target: self, action: #selector(goForwardOne))
		goForwardButton.title = L10n.goForward
		
		moveRightButton = UIBarButtonItem(image: AppAssets.moveRight, style: .plain, target: self, action: #selector(moveCurrentRowsRight))
		moveRightButton.title = L10n.moveLeft
		moveLeftButton = UIBarButtonItem(image: AppAssets.moveLeft, style: .plain, target: self, action: #selector(moveCurrentRowsLeft))
		moveLeftButton.title = L10n.moveRight
		moveUpButton = UIBarButtonItem(image: AppAssets.moveUp, style: .plain, target: self, action: #selector(moveCurrentRowsUp))
		moveUpButton.title = L10n.moveUp
		moveDownButton = UIBarButtonItem(image: AppAssets.moveDown, style: .plain, target: self, action: #selector(moveCurrentRowsDown))
		moveDownButton.title = L10n.moveDown
		
		insertImageButton = UIBarButtonItem(image: AppAssets.insertImage, style: .plain, target: self, action: #selector(insertImage))
		insertImageButton.title = L10n.insertImage
		linkButton = UIBarButtonItem(image: AppAssets.link, style: .plain, target: self, action: #selector(link))
		linkButton.title = L10n.link

		if traitCollection.userInterfaceIdiom != .mac {
			keyboardToolBar = UIToolbar()
			let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			keyboardToolBar.items = [moveLeftButton, moveRightButton, moveUpButton, moveDownButton, flexibleSpace, insertImageButton, linkButton]
			keyboardToolBar.sizeToFit()
			navigationItem.rightBarButtonItems = [filterBarButtonItem, ellipsisBarButtonItem, goForwardButton, goBackwardButton]
		}

		updatePhoneUI(editMode: false)
		updateUI()
		collectionView.reloadData()

		restoreScrollPosition()
		restoreOutlineCursorPosition()
		
		NotificationCenter.default.addObserver(self, selector: #selector(outlineFontCacheDidRebuild(_:)), name: .OutlineFontCacheDidRebuild, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineElementsDidChange(_:)), name: .OutlineElementsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineSearchWillBegin(_:)), name: .OutlineSearchWillBegin, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineSearchTextDidChange(_:)), name: .OutlineSearchTextDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineSearchWillEnd(_:)), name: .OutlineSearchWillEnd, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineAddedBacklinks(_:)), name: .OutlineAddedBacklinks, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineRemovedBacklinks(_:)), name: .OutlineRemovedBacklinks, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)),	name: UIApplication.willTerminateNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sceneWillDeactivate(_:)),	name: UIScene.willDeactivateNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncDidComplete(_:)), name: .CloudKitSyncDidComplete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		moveCursorToTitleOnNew()
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		// I'm not sure how collectionView could be nil, but we have crash reports where it is
		guard collectionView != nil else { return }
		
		if collectionView.contentOffset != .zero {
			transitionContentOffset = collectionView.contentOffset
		}
	}
	
	override func viewDidLayoutSubviews() {
		if let offset = transitionContentOffset {
			collectionView.contentOffset = offset
			transitionContentOffset = nil
		}
	}
	
	override func cut(_ sender: Any?) {
		guard let rows = currentRows else { return }
		cutRows(rows)
	}
	
	override func copy(_ sender: Any?) {
		guard let rows = currentRows else { return }
		copyRows(rows)
	}
	
	override func paste(_ sender: Any?) {
		pasteRows(afterRows: currentRows)
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .cut, .copy:
			return !(collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
		case .paste:
			return UIPasteboard.general.contains(pasteboardTypes: [kUTTypeUTF8PlainText as String, Row.typeIdentifier])
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if collectionView.indexPathsForSelectedItems?.isEmpty ?? true {
			pressesBeganForEditMode(presses, with: event)
		} else {
			pressesBeganForSelectMode(presses, with: event)
		}
	}
	
	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesEnded(presses, with: event)
		for press in presses {
			if let key = press.key {
				if key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty {
					if key.keyCode == .keyboardUpArrow {
						isCursoringUp = false
					}
					if key.keyCode == .keyboardDownArrow {
						isCursoringDown = false
					}
				}
				if key.modifierFlags.contains(.control) && key.keyCode == .keyboardP {
					isCursoringUp = false
				}
				if key.modifierFlags.contains(.control) && key.keyCode == .keyboardN {
					isCursoringDown = false
				}
			}
			
		}
	}
	
	override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesCancelled(presses, with: event)
		let keys = presses.compactMap { $0.key }
		keys.forEach { cancelledKeys.insert($0)	}
	}
	
	// MARK: Notifications
	
	@objc func outlineFontCacheDidRebuild(_ note: Notification) {
		collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
	}
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let document = note.object as? Document,
			  let updatedOutline = document.outline,
			  updatedOutline == outline,
			  currentTitle != outline?.title else { return }
		collectionView.reloadItems(at: [IndexPath(row: 0, section: Outline.Section.title.rawValue)])
	}
	
	@objc func outlineElementsDidChange(_ note: Notification) {
		if note.object as? Outline == outline {
			guard let changes = note.userInfo?[OutlineElementChanges.userInfoKey] as? OutlineElementChanges else { return }
			applyChangesRestoringState(changes)
		}
	}
	
	@objc func outlineSearchWillBegin(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		
		isSearching = true
		
		// I don't understand why, but on iOS deleting the sections will cause random crashes.
		// I should check periodically to see if this bug is fixed.
		if traitCollection.userInterfaceIdiom == .mac {
			collectionView.deleteSections(headerFooterSections)
		} else {
			collectionView.reloadData()
		}
		
		searchBar.becomeFirstResponder()
		discloseSearchBar()
	}
	
	@objc func outlineSearchTextDidChange(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		if let searchText = note.userInfo?[Outline.UserInfoKeys.searchText] as? String {
			searchBar.searchField.text = searchText
		}
	}
	
	@objc func outlineSearchWillEnd(_ note: Notification) {
		guard note.object as? Outline == outline else { return }

		if searchBar.searchField.isFirstResponder {
			searchBar.searchField.resignFirstResponder()
		}
		
		guard isSearching else {
			self.collectionViewTopConstraint.constant = 0
			return
		}
		
		view.layoutIfNeeded()
		UIView.animate(withDuration: 0.3) {
			self.collectionViewTopConstraint.constant = 0
			self.view.layoutIfNeeded()
		}

		isSearching = false
		collectionView.insertSections(headerFooterSections)

		searchBar.searchField.text = ""
		searchBar.selectedResult = (outline?.currentSearchResult ?? 0) + 1
		searchBar.resultsCount = (outline?.searchResultCount ?? 0)
	}
	
	@objc func outlineAddedBacklinks(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		collectionView.insertSections([Outline.Section.backlinks.rawValue])
	}
	
	@objc func outlineRemovedBacklinks(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		collectionView.deleteSections([Outline.Section.backlinks.rawValue])
	}
	
	@objc func applicationWillTerminate(_ note: Notification) {
		updateSpotlightIndex()
	}
	
	@objc func sceneWillDeactivate(_ note: Notification) {
		saveCurrentText()
		
		// If we don't update the last know coordinates, then when the container
		// tries to save and update the outine we might not have the ability to tell
		// what the last first responder was or where its cursor was.
		CursorCoordinates.updateLastKnownCoordinates()
	}
	
	@objc func didEnterBackground(_ note: Notification) {
		saveCurrentText()
	}
	
	@objc func cloudKitSyncDidComplete(_ note: Notification) {
		collectionView?.refreshControl?.endRefreshing()
	}
	
	@objc func adjustForKeyboard(_ note: Notification) {
		guard let keyboardValue = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

		let keyboardScreenEndFrame = keyboardValue.cgRectValue
		let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

		if note.name == UIResponder.keyboardWillHideNotification {
			keyboardWorkItem?.cancel()
			keyboardWorkItem = DispatchWorkItem { [weak self] in
				UIView.animate(withDuration: 0.25) {
					self?.collectionView.contentInset = EditorViewController.defaultContentInsets
				}
				self?.updatePhoneUI(editMode: false)
				self?.currentKeyboardHeight = 0
			}
			DispatchQueue.main.async(execute: keyboardWorkItem!)
		} else {
			keyboardWorkItem?.cancel()
			keyboardWorkItem = DispatchWorkItem { [weak self] in
				let newInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
				if self?.collectionView.contentInset != newInsets {
					self?.collectionView.contentInset = newInsets
				}
				self?.updatePhoneUI(editMode: true)
				self?.makeCursorVisibleIfNecessary()
				self?.currentKeyboardHeight = keyboardViewEndFrame.height
			}
			DispatchQueue.main.async(execute: keyboardWorkItem!)
		}
	}
	
	// MARK: API
	
	func showMessage(_ message: String) {
		messageLabel?.removeFromSuperview()
		
		messageLabel = UILabel()
		messageLabel!.font = UIFont.preferredFont(forTextStyle: .title1)
		messageLabel!.textColor = .tertiaryLabel
		messageLabel!.translatesAutoresizingMaskIntoConstraints = false
		messageLabel!.text = message

		collectionView.addSubview(messageLabel!)
		
		NSLayoutConstraint.activate([
			messageLabel!.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
			messageLabel!.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -50)
		])
	}
	
	func edit(_ newOutline: Outline?, isNew: Bool, searchText: String? = nil) {
		guard outline != newOutline else { return }
		isOutlineNewFlag = isNew
		
		messageLabel?.removeFromSuperview()
		messageLabel = nil
		
		// On the iPad if we aren't editing a field, clear out the last know coordinates
		if traitCollection.userInterfaceIdiom == .pad && !UIResponder.isFirstResponderTextField {
			CursorCoordinates.clearLastKnownCoordinates()
		}
		
		// Get ready for the new outline, buy saving the current one
		outline?.cursorCoordinates = CursorCoordinates.bestCoordinates
		
		if let textField = UIResponder.currentFirstResponder as? EditorRowTextView {
			textField.endEditing(true)
		}
		
		updateSpotlightIndex()
		
		// After this point as long as we don't have this Outline open in other
		// windows, no more collection view updates should happen for it.
		outline?.beingViewedCount = (outline?.beingViewedCount ?? 1) - 1
		
		// End the search collection view updates early
		isSearching = false
		outline?.endSearching()
		
		outline?.unload()
		clearUndoableCommands()
	
		// Assign the new Outline and load it
		outline = newOutline
		
		// Don't continue if we are just clearing out the editor
		guard let outline = outline else {
			collectionView.reloadData()
			return
		}

		outline.beingViewedCount = outline.beingViewedCount + 1
		outline.load()
		outline.prepareForViewing()
			
		guard isViewLoaded else { return }

		updateNavigationMenus()
		collectionView.reloadData()
		
		if let searchText = searchText {
			discloseSearchBar()
			searchBar.searchField.text = outline.searchText
			beginInDocumentSearch(text: searchText)
			return
		}

		updateUI()

		restoreScrollPosition()
		restoreOutlineCursorPosition()
		moveCursorToTitleOnNew()
	}
	
	func selectAllRows() {
		for i in 0..<collectionView.numberOfItems(inSection: adjustedRowsSection) {
			collectionView.selectItem(at: IndexPath(row: i, section: adjustedRowsSection), animated: false, scrollPosition: [])
		}
	}
	
	func updatePhoneUI(editMode: Bool) {
		if traitCollection.userInterfaceIdiom == .phone {
			if editMode {
				navigationItem.rightBarButtonItems = [doneBarButtonItem, filterBarButtonItem, ellipsisBarButtonItem, goForwardButton, goBackwardButton]
			} else {
				navigationItem.rightBarButtonItems = [filterBarButtonItem, ellipsisBarButtonItem, goForwardButton, goBackwardButton]
			}
		}
	}
	
	func updateNavigationMenus() {
		guard let delegate = delegate else { return }
		
		var backwardItems = [UIAction]()
		for (index, pin) in delegate.editorViewControllerGoBackwardStack.enumerated() {
			backwardItems.append(UIAction(title: pin.document?.title ?? L10n.noTitle) { [weak self] _ in
				guard let self = self else { return }
				DispatchQueue.main.async {
					delegate.goBackward(self, to: index)
				}
			})
		}
		goBackwardButton.menu = UIMenu(title: "", children: backwardItems)

		var forwardItems = [UIAction]()
		for (index, pin) in delegate.editorViewControllerGoForwardStack.enumerated() {
			forwardItems.append(UIAction(title: pin.document?.title ?? L10n.noTitle) { [weak self] _ in
				guard let self = self else { return }
				DispatchQueue.main.async {
					delegate.goForward(self, to: index)
				}
			})
		}
		goForwardButton.menu = UIMenu(title: "", children: forwardItems)
	}
	
	func updateUI() {
		navigationItem.largeTitleDisplayMode = .never
		
		if traitCollection.userInterfaceIdiom != .mac {
			ellipsisBarButtonItem.menu = buildEllipsisMenu()

			if isFilterOn {
				filterBarButtonItem.image = AppAssets.filterActive
			} else {
				filterBarButtonItem.image = AppAssets.filterInactive
			}

			filterBarButtonItem.menu = buildFilterMenu()
			
			if outline == nil {
				filterBarButtonItem.isEnabled = false
				ellipsisBarButtonItem.isEnabled = false
			} else {
				filterBarButtonItem.isEnabled = true
				ellipsisBarButtonItem.isEnabled = true
			}
			
			goBackwardButton.isEnabled = !isGoBackwardUnavailable
			goForwardButton.isEnabled = !isGoForwardUnavailable
			moveLeftButton.isEnabled = !isMoveRowsLeftUnavailable
			moveRightButton.isEnabled = !isMoveRowsRightUnavailable
			moveUpButton.isEnabled = !isMoveRowsUpUnavailable
			moveDownButton.isEnabled = !isMoveRowsDownUnavailable
			insertImageButton.isEnabled = !isInsertImageUnavailable
			linkButton.isEnabled = !isLinkUnavailable
		}
		
	}
	
	func beginInDocumentSearch(text: String? = nil) {
		guard !isSearching else {
			searchBar.searchField.becomeFirstResponder()
			return
		}

		searchBar.searchField.text = text
		outline?.beginSearching(for: text)
		searchBar.selectedResult = (outline?.currentSearchResult ?? 0) + 1
		searchBar.resultsCount = (outline?.searchResultCount ?? 0)

		// I don't know why, but if you are clicking down the documents with a collections search active
		// the title row won't reload and you will get titles when you should only have search results.
		if outline?.shadowTable?.count ?? 0 > 0  {
			collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
		}
	}
	
	func deleteCurrentRows() {
		guard let rows = currentRows else { return }
		deleteRows(rows)
	}
	
	func insertRow() {
		guard let rows = currentRows else { return }
		createRow(beforeRows: rows)
	}
	
	func createRow() {
		guard let rows = currentRows else { return }
		createRow(afterRows: rows)
	}
	
	func duplicateCurrentRows() {
		guard let rows = currentRows else { return }
		duplicateRows(rows)
	}
	
	func createRowInside() {
		guard let rows = currentRows else { return }
		createRowInside(afterRows: rows)
	}
	
	func createRowOutside() {
		guard let rows = currentRows else { return }
		createRowOutside(afterRows: rows)
	}
	
	func moveRowsLeft() {
		guard let rows = currentRows else { return }
		moveRowsLeft(rows)
	}
	
	func moveRowsRight() {
		guard let rows = currentRows else { return }
		moveRowsRight(rows)
	}
	
	func toggleCompleteRows() {
		guard let outline = outline, let rows = currentRows else { return }
		if !outline.isCompleteUnavailable(rows: rows) {
			completeRows(rows)
		} else if !outline.isUncompleteUnavailable(rows: rows) {
			uncompleteRows(rows)
		}
	}
	
	func createRowNotes() {
		guard let rows = currentRows else { return }
		createRowNotes(rows)
	}
	
	func deleteRowNotes() {
		guard let rows = currentRows else { return }
		deleteRowNotes(rows)
	}
	
	func splitRow() {
		guard let row = currentRows?.last,
			  let topic = (currentTextView as? EditorRowTopicTextView)?.attributedText,
			  let cursorPosition = currentCursorPosition else { return }
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func expandAllInOutline() {
		guard let outline = outline else { return }
		expandAll(containers: [outline])
	}
	
	func collapseAllInOutline() {
		guard let outline = outline else { return }
		collapseAll(containers: [outline])
	}
	
	func expandAll() {
		guard let rows = currentRows else { return }
		expandAll(containers: rows)
	}
	
	func collapseAll() {
		guard let rows = currentRows else { return }
		collapseAll(containers: rows)
	}
	
	func expand() {
		guard let rows = currentRows else { return }
		expand(rows: rows)
	}
	
	func collapse() {
		guard let rows = currentRows else { return }
		collapse(rows: rows)
	}
	
	func collapseParentRow() {
		guard let rows = currentRows else { return }
		let parentRows = rows.compactMap { $0.parent as? Row }
		guard !parentRows.isEmpty else { return }
		collapse(rows: parentRows)
	}
	
	func deleteCompletedRows() {
		guard let completedRows = outline?.allCompletedRows else { return }

		guard AppDefaults.shared.confirmDeleteCompletedRows else {
			deleteRows(completedRows)
			return
		}
		
		let alertController = UIAlertController(title: L10n.deleteCompletedTitle, message: L10n.deleteCompletedMessage, preferredStyle: .alert)
		
		let alwaysDeleteCompletedAction = UIAlertAction(title: L10n.deleteAlways, style: .destructive) { [weak self] action in
			AppDefaults.shared.confirmDeleteCompletedRows = false
			self?.deleteRows(completedRows)
		}
		alertController.addAction(alwaysDeleteCompletedAction)

		let deleteCompletedAction = UIAlertAction(title: L10n.deleteOnce, style: .destructive) { [weak self] action in
			self?.deleteRows(completedRows)
		}
		
		alertController.addAction(deleteCompletedAction)
		alertController.preferredAction = deleteCompletedAction

		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
		alertController.addAction(cancelAction)

		present(alertController, animated: true)
	}
	
	func useSelectionForSearch() {
		beginInDocumentSearch(text: currentTextView?.selectedText)
	}
	
	func nextInDocumentSearch() {
		nextSearchResult()
	}
	
	func previousInDocumentSearch() {
		previousSearchResult()
	}
	
	func printDoc() {
		guard let outline = outline else { return }
		currentTextView?.saveText()
		delegate?.printDoc(self, outline: outline)
	}
	
	func printList() {
		guard let outline = outline else { return }
		currentTextView?.saveText()
		delegate?.printList(self, outline: outline)
	}
	
	// MARK: Actions
	
	@objc func createInitialRowIfNecessary() {
		guard let outline = outline, outline.rowCount == 0 else { return }
		createRow(afterRows: nil)
	}
	
	@objc func sync() {
		if AccountManager.shared.isSyncAvailable {
			AccountManager.shared.sync()
		} else {
			collectionView?.refreshControl?.endRefreshing()
		}
	}
	
	@objc func done() {
		UIResponder.currentFirstResponder?.resignFirstResponder()
		CursorCoordinates.clearLastKnownCoordinates()
	}
	
	@objc func toggleFilterOn() {
		guard let changes = outline?.toggleFilterOn() else { return }
		applyChangesRestoringState(changes)
		updateUI()
	}
	
	@objc func toggleCompletedFilter() {
		guard let changes = outline?.toggleCompletedFilter() else { return }
		applyChangesRestoringState(changes)
		updateUI()
	}
	
	@objc func toggleNotesFilter() {
		guard let changes = outline?.toggleNotesFilter() else { return }
		applyChangesRestoringState(changes)
		updateUI()
	}
	
	@objc func repeatMoveCursorUp() {
		guard isCursoringUp else { return }

		if let textView = UIResponder.currentFirstResponder as? EditorRowTopicTextView {
			moveCursorUp(topicTextView: textView)
		} else if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			if tagInput.isShowingResults {
				tagInput.selectAbove()
				return
			} else {
				moveCursorToTitle()
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.repeatMoveCursorUp()
		}
	}

	@objc func repeatMoveCursorDown() {
		guard isCursoringDown else { return }
		
		if let textView = UIResponder.currentFirstResponder as? EditorRowTopicTextView {
			moveCursorDown(topicTextView: textView)
		} else if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			if tagInput.isShowingResults {
				tagInput.selectBelow()
				return
			} else if outline?.shadowTable?.count ?? 0 > 0 {
				if let rowCell = collectionView.cellForItem(at: IndexPath(row: 0, section: adjustedRowsSection)) as? EditorRowViewCell {
					rowCell.moveToEnd()
				}
			}
		} else if let textView = UIResponder.currentFirstResponder as? EditorTitleTextView, !textView.isSelecting {
			moveCursorToTagInput()
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.repeatMoveCursorDown()
		}
	}
	
	@objc func insertImage() {
		var config = PHPickerConfiguration()
		config.filter = PHPickerFilter.images
		config.selectionLimit = 1

		let pickerViewController = PHPickerViewController(configuration: config)
		pickerViewController.delegate = self
		self.present(pickerViewController, animated: true, completion: nil)
	}
	
	@objc func link() {
		currentTextView?.editLink(self)
	}
	
	@objc func outlineToggleBoldface(_ sender: Any? = nil) {
		currentTextView?.toggleBoldface(self)
	}
	
	@objc func outlineToggleItalics(_ sender: Any? = nil) {
		currentTextView?.toggleItalics(self)
	}
	
	@objc func share(_ sender: Any? = nil) {
		guard let outline = outline else { return }
		
		var activities = [UIActivity]()
		
		let exportPDFDocActivity = ExportPDFDocActivity()
		exportPDFDocActivity.delegate = self
		activities.append(exportPDFDocActivity)
		
		let exportPDFListActivity = ExportPDFListActivity()
		exportPDFListActivity.delegate = self
		activities.append(exportPDFListActivity)
		
		let exportMarkdownDocActivity = ExportMarkdownDocActivity()
		exportMarkdownDocActivity.delegate = self
		activities.append(exportMarkdownDocActivity)
		
		let exportMarkdownListActivity = ExportMarkdownListActivity()
		exportMarkdownListActivity.delegate = self
		activities.append(exportMarkdownListActivity)
		
		let exportOPMLActivity = ExportOPMLActivity()
		exportOPMLActivity.delegate = self
		activities.append(exportOPMLActivity)
		
		let controller = UIActivityViewController(outline: outline, applicationActivities: activities)
		controller.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
		present(controller, animated: true)
	}
	
	@objc func collaborate(_ sender: Any? = nil) {
		guard let outline = outline else { return }
		
		AccountManager.shared.cloudKitAccount?.prepareCloudSharingController(document: .outline(outline)) { result in
			switch result {
			case .success(let sharingController):
				sharingController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
				sharingController.delegate = self
				sharingController.availablePermissions = [.allowReadWrite]
				self.present(sharingController, animated: true)
			case .failure(let error):
				self.presentError(error)
			}
		}
	}
	
	@objc func showOutlineGetInfo() {
		guard let outline = outline else { return }
		delegate?.showGetInfo(self, outline: outline)
	}
	
	@objc func goBackwardOne() {
		delegate?.goBackward(self, to: 0)
	}

	@objc func goForwardOne() {
		delegate?.goForward(self, to: 0)
	}

	@objc func moveCurrentRowsLeft() {
		guard let rows = currentRows else { return }
		moveRowsLeft(rows)
	}
	
	@objc func moveCurrentRowsRight() {
		guard let rows = currentRows else { return }
		moveRowsRight(rows)
	}
	
	@objc func moveCurrentRowsUp() {
		guard let rows = currentRows else { return }
		moveRowsUp(rows)
	}
	
	@objc func moveCurrentRowsDown() {
		guard let rows = currentRows else { return }
		moveRowsDown(rows)
	}
	
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource

extension EditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = EditorCollectionViewCompositionalLayout() { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == Outline.Section.tags.rawValue {
				let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .estimated(50))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
				
				return NSCollectionLayoutSection(group: group)
			} else {
				var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
				configuration.showsSeparators = false
				
				if sectionIndex == self?.adjustedRowsSection {
					configuration.leadingSwipeActionsConfigurationProvider = { [weak self] indexPath in
						guard let self = self, let row = self.outline?.shadowTable?[indexPath.row] else { return nil }
						
						if row.isComplete {
							let actionHandler: UIContextualAction.Handler = { action, view, completion in
								self.uncompleteRows([row])
								completion(true)
							}
							
							let action = UIContextualAction(style: .normal, title: L10n.uncomplete, handler: actionHandler)
							if self.traitCollection.userInterfaceIdiom == .mac {
								action.image = AppAssets.uncompleteRow.symbolSizedForCatalyst(color: .white)
							} else {
								action.image = AppAssets.uncompleteRow
							}
							action.backgroundColor = UIColor.accentColor
							
							return UISwipeActionsConfiguration(actions: [action])
						} else {
							let actionHandler: UIContextualAction.Handler = { action, view, completion in
								self.completeRows([row])
								completion(true)
							}
							
							let action = UIContextualAction(style: .normal, title: L10n.complete, handler: actionHandler)
							if self.traitCollection.userInterfaceIdiom == .mac {
								action.image = AppAssets.completeRow.symbolSizedForCatalyst(color: .white)
							} else {
								action.image = AppAssets.completeRow
							}
							action.backgroundColor = UIColor.accentColor

							return UISwipeActionsConfiguration(actions: [action])
						}
					}
					
					configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
						guard let self = self, let row = self.outline?.shadowTable?[indexPath.row] else { return nil }

						let actionHandler: UIContextualAction.Handler = { action, view, completion in
							self.deleteRows([row])
							completion(true)
						}
						
						let action = UIContextualAction(style: .destructive, title: L10n.delete, handler: actionHandler)
						if self.traitCollection.userInterfaceIdiom == .mac {
							action.image = AppAssets.delete.symbolSizedForCatalyst(color: .white)
						} else {
							action.image = AppAssets.delete
						}

						return UISwipeActionsConfiguration(actions: [action])
					}
				}
				
				return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
			}
			
		}
		
		return layout
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.outline?.verticleScrollState = firstVisibleShadowTableIndex
		
		if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			tagInput.setNeedsLayout()
		}
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		// We resign first responder and put it back later to work around: https://openradar.appspot.com/39604024
		if let rowInput = UIResponder.currentFirstResponder as? EditorRowTextView {
			rowInput.resignFirstResponder()
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if traitCollection.userInterfaceIdiom == .mac {
			restoreBestKnownCursorPosition()
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate && traitCollection.userInterfaceIdiom == .mac {
			restoreBestKnownCursorPosition()
		}
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		if isSearching {
			return 1
		} else {
			if outline?.documentBacklinks?.isEmpty ?? true {
				return 3
			} else {
				return 4
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let adjustedSection = isSearching ? section + 2 : section
		
		switch adjustedSection {
		case Outline.Section.title.rawValue:
			return outline == nil ? 0 : 1
		case Outline.Section.tags.rawValue:
			if let outline = outline {
				return outline.tags.count + 1
			} else {
				return 0
			}
		case Outline.Section.backlinks.rawValue:
			return outline == nil ? 0 : 1
		default:
			return outline?.shadowTable?.count ?? 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let adjustedSection = isSearching ? indexPath.section + 2 : indexPath.section

		switch adjustedSection {
		case Outline.Section.title.rawValue:
			return collectionView.dequeueConfiguredReusableCell(using: titleRegistration!, for: indexPath, item: outline)
		case Outline.Section.tags.rawValue:
			if let outline = outline, indexPath.row < outline.tagCount {
				let tag = outline.tags[indexPath.row]
				return collectionView.dequeueConfiguredReusableCell(using: tagRegistration!, for: indexPath, item: tag.name)
			} else {
				return collectionView.dequeueConfiguredReusableCell(using: tagInputRegistration!, for: indexPath, item: outline!.id)
			}
		case Outline.Section.backlinks.rawValue:
			return collectionView.dequeueConfiguredReusableCell(using: backlinkRegistration!, for: indexPath, item: outline)
		default:
			let row = outline?.shadowTable?[indexPath.row] ?? Row()
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration!, for: indexPath, item: row)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		let adjustedSection = isSearching ? indexPath.section + 2: indexPath.section
		guard adjustedSection == Outline.Section.rows.rawValue else { return nil }
		
		// Force save the text if the context menu has been requested so that we don't lose our
		// text changes when the cell configuration gets applied
		saveCurrentText()
		
		if let responder = UIResponder.currentFirstResponder, responder is UISearchTextField {
			responder.resignFirstResponder()
		}
		
		if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
			collectionView.deselectAll()
		}
		
		let rows: [Row]
		if let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty {
			rows = selected.compactMap { outline?.shadowTable?[$0.row] }
		} else {
			if let row = outline?.shadowTable?[indexPath.row] {
				rows = [row]
			} else {
				rows = [Row]()
			}
		}
		
		return makeRowsContextMenu(rows: rows)
	}
	
	func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		guard let row = configuration.identifier as? Row,
			  let rowShadowTableIndex = row.shadowTableIndex,
			  let cell = collectionView.cellForItem(at: IndexPath(row: rowShadowTableIndex, section: adjustedRowsSection)) as? EditorRowViewCell else { return nil }
		
		let isCompact = traitCollection.horizontalSizeClass == .compact
		return UITargetedPreview(view: cell, parameters: EditorRowPreviewParameters(cell: cell, row: row, isCompact: isCompact))
	}
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		let adjustedSection = isSearching ? indexPath.section + 2 : indexPath.section
		return adjustedSection == Outline.Section.rows.rawValue
	}
	
	func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		updateUI()
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let responder = UIResponder.currentFirstResponder, responder is UITextField || responder is UITextView {
			responder.resignFirstResponder()
		}
		updateUI()
	}
	
}

// MARK: EditorTitleViewCellDelegate

extension EditorViewController: UIGestureRecognizerDelegate {

	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let point = gestureRecognizer.location(in: collectionView)
		let indexPath = collectionView.indexPathForItem(at: point)
		return indexPath == nil
	}
	
}

// MARK: EditorTitleViewCellDelegate

extension EditorViewController: EditorTitleViewCellDelegate {
	
	var editorTitleUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTitleLayoutEditor() {
		layoutEditor()
	}
	
	func editorTitleTextFieldDidBecomeActive() {
		updateUI()
		collectionView.deselectAll()
	}
	
	func editorTitleDidUpdate(title: String) {
		updateTitleWorkItem?.cancel()
		updateTitleWorkItem = DispatchWorkItem { [weak self] in
			self?.outline?.update(title: title)
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: updateTitleWorkItem!)
	}
	
	func editorTitleMoveToTagInput() {
		moveCursorToTagInput()
	}

}

// MARK: EditorTagInputViewCellDelegate

extension EditorViewController: EditorTagInputViewCellDelegate {
	
	var editorTagInputUndoManager: UndoManager? {
		return undoManager
	}
	
	var editorTagInputTags: [Tag]? {
		guard let outlineTags = outline?.tags else { return nil }
		return outline?.account?.tags?.filter({ !outlineTags.contains($0) })
	}
	
	func editorTagInputLayoutEditor() {
		layoutEditor()
	}
	
	func editorTagInputTextFieldDidBecomeActive() {
		updateUI()
		collectionView.deselectAll()
	}
		
	func editorTagInputTextFieldCreateRow() {
		createRow(afterRows: nil)
	}
	
	func editorTagInputTextFieldCreateTag(name: String) {
		createTag(name: name)
	}
	
}

// MARK: EditorTagViewCellDelegate

extension EditorViewController: EditorTagViewCellDelegate {
	
	func editorTagDeleteTag(name: String) {
		deleteTag(name: name)
	}
	
}

// MARK: EditorRowViewCellDelegate

extension EditorViewController: EditorRowViewCellDelegate {

	var editorRowUndoManager: UndoManager? {
		return undoManager
	}
	
	var editorRowInputAccessoryView: UIView? {
		return keyboardToolBar
	}
	
    func editorRowLayoutEditor(row: Row) {
		layoutEditor(row: row)
	}
	
	func editorRowMakeCursorVisibleIfNecessary() {
		makeCursorVisibleIfNecessary()
	}

	func editorRowTextFieldDidBecomeActive(row: Row) {
		collectionView.deselectAll()
		updateUI()
		delegate?.validateToolbar(self)
	}

	func editorRowToggleDisclosure(row: Row, applyToAll: Bool) {
		toggleDisclosure(row: row, applyToAll: applyToAll)
	}
	
	func editorRowTextChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange) {
		textChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func editorRowDeleteRow(_ row: Row, rowStrings: RowStrings) {
		deleteRows([row], rowStrings: rowStrings)
	}
	
	func editorRowCreateRow(beforeRow: Row) {
		createRow(beforeRows: [beforeRow])
	}
	
	func editorRowCreateRow(afterRow: Row?, rowStrings: RowStrings?) {
		let afterRows = afterRow == nil ? nil : [afterRow!]
		createRow(afterRows: afterRows, rowStrings: rowStrings)
	}
	
	func editorRowMoveRowLeft(_ row: Row, rowStrings: RowStrings) {
		moveRowsLeft([row], rowStrings: rowStrings)
	}
	
	func editorRowMoveRowRight(_ row: Row, rowStrings: RowStrings) {
		moveRowsRight([row], rowStrings: rowStrings)
	}
	
	func editorRowSplitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editorRowDeleteRowNote(_ row: Row, rowStrings: RowStrings) {
		deleteRowNotes([row], rowStrings: rowStrings)
	}
	
	func editorRowMoveCursorTo(row: Row) {
		moveCursorTo(row: row)
	}

	func editorRowMoveCursorUp(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
		guard let topicTextView = (collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView else { return }
		moveCursorUp(topicTextView: topicTextView)
	}

	func editorRowMoveCursorDown(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
		guard let topicTextView = (collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView else { return }
		moveCursorDown(topicTextView: topicTextView)
	}
	
	func editorRowEditLink(_ link: String?, text: String?, range: NSRange) {
		editLink(link, text: text, range: range)
	}

	func editorRowZoomImage(_ image: UIImage, rect: CGRect) {
		transition.maskFrame = collectionView.convert(collectionView.safeAreaLayoutGuide.layoutFrame, to: nil)
		transition.originFrame = rect
		transition.originImage = image
		delegate?.zoomImage(self, image: image, transitioningDelegate: self)
	}

}

// MARK: EditorOutlineCommandDelegate

extension EditorViewController: OutlineCommandDelegate {
	
	var currentCoordinates: CursorCoordinates? {
		return CursorCoordinates.currentCoordinates
	}
	
	func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates) {
		restoreCursorPosition(cursorCoordinates, scroll: false)
	}
	
}

// MARK: PHPickerViewControllerDelegate

extension EditorViewController: PHPickerViewControllerDelegate {
	
	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
		picker.dismiss(animated: true, completion: nil)
		
		guard let cursorCoordinates = CursorCoordinates.bestCoordinates, let result = results.first else {
			return
		}
		
		result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] (object, error) in
			guard let self = self else { return }
			
			if let data = (object as? UIImage)?.rotateImage()?.pngData(), let cgImage = RSImage.scaleImage(data, maxPixelSize: 1800) {
				let scaledImage = UIImage(cgImage: cgImage)
				
				DispatchQueue.main.async {
					self.restoreCursorPosition(cursorCoordinates)
					
					guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
					let indexPath = IndexPath(row: shadowTableIndex, section: self.adjustedRowsSection)
					guard let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return	}
					
					if cursorCoordinates.isInNotes, let textView = rowCell.noteTextView {
						textView.replaceCharacters(textView.selectedRange, withImage: scaledImage)
					} else if let textView = rowCell.topicTextView {
						textView.replaceCharacters(textView.selectedRange, withImage: scaledImage)
					}
				}
			}
		})
		
	}
	
}

// MARK: LinkViewControllerDelegate

extension EditorViewController: LinkViewControllerDelegate {
	
	func createOutline(title: String) -> Outline? {
		return delegate?.createNewOutline(self, title: title)
	}
	
	func updateLink(cursorCoordinates: CursorCoordinates, text: String, link: String?, range: NSRange) {
		var correctedLink = link
		if correctedLink != nil, !correctedLink!.isEmpty {
			if var urlComponents = URLComponents(string: correctedLink!), urlComponents.scheme == nil {
				urlComponents.scheme = "https"
				correctedLink = urlComponents.string ?? ""
			}
		}
		
		guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
		guard let rowCell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return	}
		
		// When contained in EditorContainerViewController, the search bar registers as the first responder
		// even after we tell the text view to become first responder. Directly telling it to resign solves
		// the problem.
		UIResponder.currentFirstResponder?.resignFirstResponder()
		
		if cursorCoordinates.isInNotes {
			rowCell.noteTextView?.becomeFirstResponder()
			rowCell.noteTextView?.updateLinkForCurrentSelection(text: text, link: correctedLink, range: range)
		} else {
			rowCell.topicTextView?.becomeFirstResponder()
			rowCell.topicTextView?.updateLinkForCurrentSelection(text: text, link: correctedLink, range: range)
		}
	}
	
}

// MARK: ExportPDFDocActivityDelegate

extension EditorViewController: ExportPDFDocActivityDelegate {

	func exportPDFDoc(_: ExportPDFDocActivity) {
		guard let outline = outline else { return }
		delegate?.exportPDFDoc(self, outline: outline)
	}
	
}

// MARK: ExportPDFListActivityDelegate

extension EditorViewController: ExportPDFListActivityDelegate {

	func exportPDFList(_: ExportPDFListActivity) {
		guard let outline = outline else { return }
		delegate?.exportPDFList(self, outline: outline)
	}
	
}

// MARK: ExportMarkdownDocActivityDelegate

extension EditorViewController: ExportMarkdownDocActivityDelegate {

	func exportMarkdownDoc(_: ExportMarkdownDocActivity) {
		guard let outline = outline else { return }
		delegate?.exportMarkdownDoc(self, outline: outline)
	}
	
}

// MARK: ExportMarkdownListActivityDelegate

extension EditorViewController: ExportMarkdownListActivityDelegate {

	func exportMarkdownList(_: ExportMarkdownListActivity) {
		guard let outline = outline else { return }
		delegate?.exportMarkdownList(self, outline: outline)
	}
	
}

// MARK: ExportOPMLActivityDelegate

extension EditorViewController: ExportOPMLActivityDelegate {
	
	func exportOPML(_: ExportOPMLActivity) {
		guard let outline = outline else { return }
		delegate?.exportOPML(self, outline: outline)
	}
	
}

// MARK: SearchBarDelegate

extension EditorViewController: SearchBarDelegate {

	func nextWasPressed(_ searchBar: EditorSearchBar) {
		nextSearchResult()
	}

	func previousWasPressed(_ searchBar: EditorSearchBar) {
		previousSearchResult()
	}

	func doneWasPressed(_ searchBar: EditorSearchBar) {
		outline?.endSearching()
	}
	
	func searchBar(_ searchBar: EditorSearchBar, textDidChange: String) {
		search(for: textDidChange)
	}
	
}

// MARK: UICloudSharingControllerDelegate

extension EditorViewController: UICloudSharingControllerDelegate {
	
	func itemTitle(for csc: UICloudSharingController) -> String? {
		return outline?.title
	}
	
	func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
		presentError(error)
	}
	
	func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
		AccountManager.shared.sync()
	}
	
	func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
		AccountManager.shared.sync()
	}

}

// MARK: UIViewControllerTransitioningDelegate

extension EditorViewController: UIViewControllerTransitioningDelegate {

	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transition.presenting = true
		return transition
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transition.presenting = false
		return transition
	}
}

// MARK: ImageTransitionDelegate

extension EditorViewController: ImageTransitionDelegate {
	
	func hideImage(_: ImageTransition, frame: CGRect) {
		guard let splitView = splitViewController?.view else { return }
		let convertedFrame = splitView.convert(frame, to: collectionView)
		imageBlocker = UIView(frame: convertedFrame)
		imageBlocker!.backgroundColor = AppAssets.fullScreenBackgroundColor
		collectionView.addSubview(imageBlocker!)
	}
	
	func unhideImage(_: ImageTransition) {
		imageBlocker?.removeFromSuperview()
		imageBlocker = nil
	}
	
}

// MARK: Helpers

private extension EditorViewController {
	
	func discloseSearchBar() {
		view.layoutIfNeeded()

		UIView.animate(withDuration: 0.3) {
			self.collectionViewTopConstraint.constant = Self.searchBarHeight
			self.view.layoutIfNeeded()
		}
	}
	
	func buildEllipsisMenu() -> UIMenu {
		var shareActions = [UIAction]()

		if !isCollaborateUnavailable {
			let collaborateAction = UIAction(title: L10n.collaborateEllipsis, image: AppAssets.statelessCollaborate) { [weak self] _ in
				self?.collaborate(self?.ellipsisBarButtonItem)
			}
			shareActions.append(collaborateAction)
		}

		let shareAction = UIAction(title: L10n.shareEllipsis, image: AppAssets.share) { [weak self] _ in
			self?.share(self?.ellipsisBarButtonItem)
		}
		shareActions.append(shareAction)

		let printDocAction = UIAction(title: L10n.printDocEllipsis, image: AppAssets.printDoc) { [weak self] _ in
			self?.printDoc()
		}
		shareActions.append(printDocAction)

		let printListAction = UIAction(title: L10n.printListEllipsis, image: AppAssets.printList) { [weak self] _ in
			self?.printList()
		}
		shareActions.append(printListAction)

		var getInfoActions = [UIAction]()
		let getInfoAction = UIAction(title: L10n.getInfo, image: AppAssets.getInfo) { [weak self] _ in
			self?.showOutlineGetInfo()
		}
		getInfoActions.append(getInfoAction)

		var findActions = [UIAction]()
		let findAction = UIAction(title: L10n.findEllipsis, image: AppAssets.find) { [weak self] _ in
			self?.beginInDocumentSearch()
		}
		findActions.append(findAction)

		var viewActions = [UIAction]()
		
		let expandAllInOutlineAction = UIAction(title: L10n.expandAllInOutline, image: AppAssets.expandAll) { [weak self] _ in
			self?.expandAllInOutline()
		}
		viewActions.append(expandAllInOutlineAction)
		
		let collapseAllInOutlineAction = UIAction(title: L10n.collapseAllInOutline, image: AppAssets.collapseAll) { [weak self] _ in
			self?.collapseAllInOutline()
		}
		viewActions.append(collapseAllInOutlineAction)
		
		let deleteCompletedRowsAction = UIAction(title: L10n.deleteCompletedRows, image: AppAssets.delete, attributes: .destructive) { [weak self] _ in
			self?.deleteCompletedRows()
		}
		
		let shareMenu = UIMenu(title: "", options: .displayInline, children: shareActions)
		let getInfoMenu = UIMenu(title: "", options: .displayInline, children: getInfoActions)
		let findMenu = UIMenu(title: "", options: .displayInline, children: findActions)
		let viewMenu = UIMenu(title: "", options: .displayInline, children: viewActions)
		let changeMenu = UIMenu(title: "", options: .displayInline, children: [deleteCompletedRowsAction])
		
		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [shareMenu, getInfoMenu, findMenu, viewMenu, changeMenu])
	}
	
	func buildFilterMenu() -> UIMenu {
		let turnFilterOnAction = UIAction() { [weak self] _ in
		   self?.toggleFilterOn()
		}
		turnFilterOnAction.title = isFilterOn ? L10n.turnFilterOff : L10n.turnFilterOn
		
		let turnFilterOnMenu = UIMenu(title: "", options: .displayInline, children: [turnFilterOnAction])
		
		let filterCompletedAction = UIAction(title: L10n.filterCompleted) { [weak self] _ in
			self?.toggleCompletedFilter()
		}
		filterCompletedAction.state = isCompletedFiltered ? .on : .off
		filterCompletedAction.attributes = isFilterOn ? [] : .disabled

		let filterNotesAction = UIAction(title: L10n.filterNotes) { [weak self] _ in
		   self?.toggleNotesFilter()
		}
		filterNotesAction.state = isNotesFiltered ? .on : .off
		filterNotesAction.attributes = isFilterOn ? [] : .disabled

		let filterOptionsMenu = UIMenu(title: "", options: .displayInline, children: [filterCompletedAction, filterNotesAction])

		return UIMenu(title: "", children: [turnFilterOnMenu, filterOptionsMenu])
	}
	
	func pressesBeganForEditMode(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		guard presses.count == 1, let key = presses.first?.key else {
			super.pressesBegan(presses, with: event)
			return
		}
		
		if !(CursorCoordinates.currentCoordinates?.isInNotes ?? false) {
			guard cancelledKeys.remove(key) == nil else {
				return
			}
			
			switch (key.keyCode, true) {
            case (.keyboardUpArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView {
					if topic.cursorIsOnTopLine {
						isCursoringUp = true
						repeatMoveCursorUp()
					} else {
						super.pressesBegan(presses, with: event)
					}
				} else {
					isCursoringUp = true
					repeatMoveCursorUp()
				}
			case (.keyboardDownArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView {
					if topic.cursorIsOnBottomLine {
						isCursoringDown = true
						repeatMoveCursorDown()
					} else {
						super.pressesBegan(presses, with: event)
					}
				} else {
					isCursoringDown = true
					repeatMoveCursorDown()
				}
			default:
				super.pressesBegan(presses, with: event)
			}
			
		} else {
			switch (key.keyCode, true) {
			case (.keyboardUpArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty), (.keyboardDownArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				makeCursorVisibleIfNecessary()
			default:
				break
			}

			super.pressesBegan(presses, with: event)
		}
	}
	
	func pressesBeganForSelectMode(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if presses.count == 1, let key = presses.first?.key {
			guard cancelledKeys.remove(key) == nil else {
				return
			}
			
			switch key.keyCode {
			case .keyboardUpArrow:
				if let first = collectionView.indexPathsForSelectedItems?.sorted().first {
					if first.row > 0 {
						if let cell = collectionView.cellForItem(at: IndexPath(row: first.row - 1, section: first.section)) as? EditorRowViewCell {
							cell.moveToEnd()
						}
					} else {
						if let cell = collectionView.cellForItem(at: first) as? EditorRowViewCell {
							cell.moveToStart()
						}
					}
				}
			case .keyboardDownArrow:
				if let last = collectionView.indexPathsForSelectedItems?.sorted().last {
					if last.row + 1 < outline?.shadowTable?.count ?? 0 {
						if let cell = collectionView.cellForItem(at: IndexPath(row: last.row + 1, section: last.section)) as? EditorRowViewCell {
							cell.moveToEnd()
						}
					} else {
						if let cell = collectionView.cellForItem(at: last) as? EditorRowViewCell {
							cell.moveToEnd()
						}
					}
				}
			case .keyboardLeftArrow:
				if let first = collectionView.indexPathsForSelectedItems?.sorted().first {
					if let cell = collectionView.cellForItem(at: first) as? EditorRowViewCell {
						cell.moveToStart()
					}
				}
			case .keyboardRightArrow:
				if let last = collectionView.indexPathsForSelectedItems?.sorted().last {
					if let cell = collectionView.cellForItem(at: last) as? EditorRowViewCell {
						cell.moveToEnd()
					}
				}
			default:
				super.pressesBegan(presses, with: event)
			}
			
		} else {
			super.pressesBegan(presses, with: event)
		}
	}
	
	func scrollRowToShowBottom() {
		// If we don't do this when we are creating a row after a really long one, for
		// some reason the newly created topic will not become the first responder.
		if let lastRowIndex = currentRows?.last?.shadowTableIndex {
			let lastRowIndexPath = IndexPath(row: lastRowIndex, section: adjustedRowsSection)
			if let lastRowFrame = collectionView.cellForItem(at: lastRowIndexPath)?.frame {
				let bottomRect = CGRect(x: lastRowFrame.origin.x, y: lastRowFrame.maxY - 1, width: lastRowFrame.width, height: 1)
				collectionView.scrollRectToVisibleBypass(bottomRect, animated: false)
			}
		}
	}
	
	func layoutEditor() {
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.layoutIfNeeded()
	}
	
	func layoutEditor(row: Row) {
		if #available(iOS 15, *) {
			guard let index = row.shadowTableIndex else { return }
			let indexPath = IndexPath(row: index, section: adjustedRowsSection)
			UIView.performWithoutAnimation {
				collectionView.reconfigureItems(at: [indexPath])
			}
		} else {
			// This is presumably less effecient than just reconfiguring the item and
			// it can trigger layout bugs. For example if the first row of a topic above
			// this row is an image, things go to 💩 in a hurry.
			collectionView.collectionViewLayout.invalidateLayout()
			collectionView.layoutIfNeeded()
		}
		
		makeCursorVisibleIfNecessary()
	}
	
	func applyChanges(_ changes: OutlineElementChanges) {
		if !changes.isOnlyReloads {
			collectionView.performBatchUpdates {
				if let deletes = changes.deleteIndexPaths, !deletes.isEmpty {
					collectionView.deleteItems(at: deletes)
				}
				
				if let inserts = changes.insertIndexPaths, !inserts.isEmpty {
					collectionView.insertItems(at: inserts)
				}

				if let moves = changes.moveIndexPaths, !moves.isEmpty {
					for move in moves {
						collectionView.moveItem(at: move.0, to: move.1)
					}
				}
			}
		}
		
		guard let reloads = changes.reloadIndexPaths, !reloads.isEmpty else { return }
		
		let hasSectionOtherThanRows = reloads.contains(where: { $0.section != adjustedRowsSection })
		
		if #available(iOS 15, *), !hasSectionOtherThanRows {
			collectionView.reconfigureItems(at: reloads)
		} else {
			if changes.isReloadsAnimatable {
				collectionView.reloadItems(at: reloads)
			} else {
				// This is to prevent jumping when reloading the last item in the collection
				UIView.performWithoutAnimation {
					let contentOffset = collectionView.contentOffset
					collectionView.reloadItems(at: reloads)
					collectionView.contentOffset = contentOffset
				}
			}
		}
	}
	
	func applyChangesRestoringState(_ changes: OutlineElementChanges) {
		let currentCoordinates = CursorCoordinates.currentCoordinates
		let selectedIndexPaths = collectionView.indexPathsForSelectedItems
		
		applyChanges(changes)

		if #available(iOS 15, *) {
		} else {
			if let coordinates = currentCoordinates {
				restoreCursorPosition(coordinates, scroll: true)
			}
		}
		
		if changes.isOnlyReloads, let indexPaths = selectedIndexPaths {
			for indexPath in indexPaths {
				collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
			}
		}
		
		updateUI()
	}

	func restoreOutlineCursorPosition() {
		if let cursorCoordinates = outline?.cursorCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: true)
		}
	}
	
	func restoreBestKnownCursorPosition() {
		if let cursorCoordinates = CursorCoordinates.bestCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: false)
		}
	}

	func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates, scroll: Bool) {
		guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)

		func restoreCursor() {
			guard let rowCell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return }
			rowCell.restoreCursor(cursorCoordinates)
		}
		
		guard scroll else {
			restoreCursor()
			return
		}
		
		if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
			CATransaction.begin()
			CATransaction.setCompletionBlock {
				// Got to wait or the row cell won't be found
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					restoreCursor()
				}
			}
			if indexPath.row < collectionView.numberOfItems(inSection: indexPath.section) {
				collectionView.scrollToItem(at: indexPath, at: [], animated: false)
			}
			CATransaction.commit()
		} else {
			restoreCursor()
		}
	}
	
	func restoreScrollPosition() {
		let rowCount = collectionView.numberOfItems(inSection: adjustedRowsSection)
		if let verticleScrollState = outline?.verticleScrollState, verticleScrollState != 0, verticleScrollState < rowCount {
			collectionView.scrollToItem(at: IndexPath(row: verticleScrollState, section: adjustedRowsSection), at: .top, animated: false)
			DispatchQueue.main.async {
				let rowCount = self.collectionView.numberOfItems(inSection: self.adjustedRowsSection)
				if verticleScrollState < rowCount {
					self.collectionView.scrollToItem(at: IndexPath(row: verticleScrollState, section: self.adjustedRowsSection), at: .top, animated: false)
				}
			}
		} else {
			if collectionView.numberOfSections > 0 && collectionView.numberOfItems(inSection: 0) > 0 {
				collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
			}
		}
	}
	
	func moveCursorToTitleOnNew() {
		if isOutlineNewFlag {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
				self.moveCursorToTitle()
			}
		}
		isOutlineNewFlag = false
	}
	
	func moveCursorToTitle() {
		if let titleCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: Outline.Section.title.rawValue)) as? EditorTitleViewCell {
			titleCell.takeCursor()
		}
		makeCursorVisibleIfNecessary()
	}
	
	func moveCursorToTagInput() {
		if let outline = outline {
			let indexPath = IndexPath(row: outline.tags.count, section: Outline.Section.tags.rawValue)
			if let tagInputCell = collectionView.cellForItem(at: indexPath) as? EditorTagInputViewCell {
				tagInputCell.takeCursor()
			}
		}
		makeCursorVisibleIfNecessary()
	}
	
	func editLink(_ link: String?, text: String?, range: NSRange) {
		if traitCollection.userInterfaceIdiom == .mac {
		
			let linkViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "MacLinkViewController") as! MacLinkViewController
			linkViewController.preferredContentSize = CGSize(width: 400, height: 116)
			linkViewController.cursorCoordinates = CursorCoordinates.bestCoordinates
			linkViewController.text = text
			linkViewController.link = link
			linkViewController.range = range
			linkViewController.delegate = self
			present(linkViewController, animated: true)
		
		} else {
			
			let linkNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "LinkViewControllerNav") as! UINavigationController
			linkNavViewController.preferredContentSize = CGSize(width: 400, height: 150)
			linkNavViewController.modalPresentationStyle = .formSheet

			let linkViewController = linkNavViewController.topViewController as! LinkViewController
			linkViewController.cursorCoordinates = CursorCoordinates.bestCoordinates
			linkViewController.text = text
			linkViewController.link = link
			linkViewController.range = range
			linkViewController.delegate = self
			present(linkNavViewController, animated: true)
			
		}
	}
	
	func makeRowsContextMenu(rows: [Row]) -> UIContextMenuConfiguration? {
		guard let firstRow = rows.sortedByDisplayOrder().first else { return nil }
		
		return UIContextMenuConfiguration(identifier: firstRow as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self, let outline = self.outline else { return nil }
			
			var menuItems = [UIMenu]()

			var standardEditActions = [UIAction]()
			standardEditActions.append(self.cutAction(rows: rows))
			standardEditActions.append(self.copyAction(rows: rows))
			if self.canPerformAction(.paste, withSender: nil) {
				standardEditActions.append(self.pasteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: standardEditActions))

			var outlineActions = [UIAction]()
			outlineActions.append(self.addAction(rows: rows))
			outlineActions.append(self.duplicateAction(rows: rows))
			if !outline.isCompleteUnavailable(rows: rows) {
				outlineActions.append(self.completeAction(rows: rows))
			}
			if !outline.isUncompleteUnavailable(rows: rows) {
				outlineActions.append(self.uncompleteAction(rows: rows))
			}
			if outline.isDeleteNotesUnavailable(rows: rows) {
				outlineActions.append(self.createNoteAction(rows: rows))
			}
			if !outline.isDeleteNotesUnavailable(rows: rows) {
				outlineActions.append(self.deleteNoteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: outlineActions))

			var viewActions = [UIAction]()
			if !outline.isExpandAllUnavailable(containers: rows) {
				viewActions.append(self.expandAllAction(rows: rows))
			}
			if !outline.isCollapseAllUnavailable(containers: rows) {
				viewActions.append(self.collapseAllAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: viewActions))
			
			let deleteAction = self.deleteAction(rows: rows)
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [deleteAction]))

			return UIMenu(title: "", children: menuItems)
		})
	}
	
	func cutAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.cut, image: AppAssets.cut) { [weak self] action in
			guard let self = self else { return }
			self.cutRows(rows)
			self.delegate?.validateToolbar(self)
		}
	}

	func copyAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.copy, image: AppAssets.copy) { [weak self] action in
			self?.copyRows(rows)
		}
	}

	func pasteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.paste, image: AppAssets.paste) { [weak self] action in
			guard let self = self else { return }
			self.pasteRows(afterRows: rows)
			self.delegate?.validateToolbar(self)
		}
	}

	func addAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.addRow, image: AppAssets.add) { [weak self] action in
			// Have to let the text field get the first responder by getting it away from this
			// action which appears to be holding on to it.
			DispatchQueue.main.async {
				self?.createRow(afterRows: rows)
			}
		}
	}

	func duplicateAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.duplicate, image: AppAssets.duplicate) { [weak self] action in
			self?.duplicateRows(rows)
		}
	}

	func expandAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.expandAll, image: AppAssets.expandAll) { [weak self] action in
			self?.expandAll(containers: rows)
		}
	}

	func collapseAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.collapseAll, image: AppAssets.collapseAll) { [weak self] action in
			self?.collapseAll(containers: rows)
		}
	}

	func completeAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.complete, image: AppAssets.completeRow) { [weak self] action in
			self?.completeRows(rows)
		}
	}
	
	func uncompleteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.uncomplete, image: AppAssets.uncompleteRow) { [weak self] action in
			self?.uncompleteRows(rows)
		}
	}
	
	func createNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.addNote, image: AppAssets.note) { [weak self] action in
			self?.createRowNotes(rows)
		}
	}

	func deleteNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.deleteNote, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteRowNotes(rows)
		}
	}

	func deleteAction(rows: [Row]) -> UIAction {
		let title = rows.count == 1 ? L10n.deleteRow : L10n.deleteRows
		return UIAction(title: title, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			guard let self = self else { return }
			self.deleteRows(rows)
			self.delegate?.validateToolbar(self)
		}
	}

	func moveCursorTo(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex else {
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell {
			rowCell.moveToEnd()
		}
	}
	
	func moveCursorUp(topicTextView: EditorRowTopicTextView) {
		guard let row = topicTextView.row, let shadowTableIndex = row.shadowTableIndex, shadowTableIndex > 0 else {
			moveCursorToTagInput()
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: adjustedRowsSection)
		if let nextTopicTextView = (self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView {
			nextTopicTextView.becomeFirstResponder()
			if let topicTextViewCursorRect = topicTextView.cursorRect {
				let convertedRect = topicTextView.convert(topicTextViewCursorRect, to: collectionView)
				let nextRect = nextTopicTextView.convert(convertedRect, from: collectionView)
				if let cursorPosition = nextTopicTextView.closestPosition(to: CGPoint(x: nextRect.midX, y: nextTopicTextView.bounds.height - 1)) {
					let cursorOffset = nextTopicTextView.offset(from: nextTopicTextView.beginningOfDocument, to: cursorPosition)
					let range = NSRange(location: cursorOffset, length: 0)
					nextTopicTextView.selectedRange = range
				}
			}
		}
		makeCursorVisibleIfNecessary()
	}
	
	func moveCursorDown(topicTextView: EditorRowTopicTextView) {
		guard let row = topicTextView.row, let shadowTableIndex = row.shadowTableIndex, let shadowTable = outline?.shadowTable else { return }
		
		// Move the cursor to the end of the last row
		guard shadowTableIndex < (shadowTable.count - 1) else {
			let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
			if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
			return
		}
		
		func moveCursorDownToNext(nextTopicTextView: EditorRowTopicTextView) {
			if let topicTextViewCursorRect = topicTextView.cursorRect {
				let convertedRect = topicTextView.convert(topicTextViewCursorRect, to: collectionView)
				let nextRect = nextTopicTextView.convert(convertedRect, from: collectionView)
				if let cursorPosition = nextTopicTextView.closestPosition(to: CGPoint(x: nextRect.midX, y: 0)) {
					let cursorOffset = nextTopicTextView.offset(from: nextTopicTextView.beginningOfDocument, to: cursorPosition)
					let range = NSRange(location: cursorOffset, length: 0)
					nextTopicTextView.selectedRange = range
				}
				makeCursorVisibleIfNecessary()
			}
		}
		
		let indexPath = IndexPath(row: shadowTableIndex + 1, section: adjustedRowsSection)
		
		// This is needed because the collection view might not have the cell built yet or the topic won't take the
		// first responder if it isn't visible.
		func scrollAndMoveCursorDownToNext() {
			if let frame = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame {
				let xHeight = "X".height(withConstrainedWidth: Double.infinity, font: topicTextView.font!)
				let totalHeight = xHeight + topicTextView.textContainerInset.top + topicTextView.textContainerInset.bottom
				let rect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: totalHeight)
				collectionView.scrollRectToVisibleBypass(rect, animated: true)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					if let nextTopicTextView = (self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView {
						nextTopicTextView.becomeFirstResponder()
						moveCursorDownToNext(nextTopicTextView: nextTopicTextView)
					}
				}
			}
		}
		
		if let nextTopicTextView = (self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView {
			if nextTopicTextView.becomeFirstResponder() {
				moveCursorDownToNext(nextTopicTextView: nextTopicTextView)
			} else {
				scrollAndMoveCursorDownToNext()
			}
		} else {
			scrollAndMoveCursorDownToNext()
		}
	}
	
	func toggleDisclosure(row: Row, applyToAll: Bool) {
		switch (row.isExpandable, applyToAll) {
		case (true, false):
			expand(rows: [row])
		case (true, true):
			expandAll(containers: [row])
		case (false, false):
			collapse(rows: [row])
		case (false, true):
			collapseAll(containers: [row])
		}
	}

	func createTag(name: String) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateTagCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		runCommand(command)
		moveCursorToTagInput()
	}

	func deleteTag(name: String) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DeleteTagCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		runCommand(command)
	}
	
	func expand(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = ExpandCommand(undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)
		
		runCommand(command)
	}

	func collapse(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let currentRow = currentTextView?.row
		
		let command = CollapseCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows)
		
		runCommand(command)
		
		if let cursorRow = currentRow {
			for row in rows {
				if cursorRow.isDecendent(row), let newCursorIndex = row.shadowTableIndex {
					if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
						rowCell.moveToEnd()
					}
				}
			}
		}
	}

	func expandAll(containers: [RowContainer]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = ExpandAllCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   containers: containers)
		
		runCommand(command)
	}

	func collapseAll(containers: [RowContainer]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CollapseAllCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 containers: containers)

		runCommand(command)
	}

	func textChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = TextChangedCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 row: row,
										 rowStrings: rowStrings,
										 isInNotes: isInNotes,
										 selection: selection)
		runCommand(command)
	}

	func cutRows(_ rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		copyRows(rows)

		let command = CutRowCommand(undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)

		runCommand(command)
	}

	func copyRows(_ rows: [Row]) {
		var itemProviders = [NSItemProvider]()

		for row in rows.sortedWithDecendentsFiltered() {
			let itemProvider = NSItemProvider()
			
			// We only register the text representation on the first one, since it looks like most text editors only support 1 dragged text item
			if row == rows[0] {
				itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
					var markdowns = [String]()
					for row in rows {
						markdowns.append(row.markdownList())
					}
					let data = markdowns.joined(separator: "\n").data(using: .utf8)
					completion(data, nil)
					return nil
				}
			}
			
			itemProvider.registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
				do {
					let data = try RowGroup(row).asData()
					completion(data, nil)
				} catch {
					completion(nil, error)
				}
				return nil
			}
			
			itemProviders.append(itemProvider)
		}
		
		UIPasteboard.general.setItemProviders(itemProviders, localOnly: false, expirationDate: nil)
	}

	func pasteRows(afterRows: [Row]?) {
		guard let undoManager = undoManager, let outline = outline else { return }

		if let rowProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [Row.typeIdentifier]), !rowProviderIndexes.isEmpty {
			let group = DispatchGroup()
			var rowGroups = [RowGroup]()
			
			for index in rowProviderIndexes {
				let itemProvider = UIPasteboard.general.itemProviders[index]
				group.enter()
				itemProvider.loadDataRepresentation(forTypeIdentifier: Row.typeIdentifier) { [weak self] (data, error) in
					DispatchQueue.main.async {
						if let data = data {
							do {
								rowGroups.append(try RowGroup.fromData(data))
								group.leave()
							} catch {
								self?.presentError(error)
								group.leave()
							}
						}
					}
				}
			}

			group.notify(queue: DispatchQueue.main) {
				let command = PasteRowCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  rowGroups: rowGroups,
											  afterRow: afterRows?.last)

				self.runCommand(command)
			}
			
		} else if let stringProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [kUTTypeUTF8PlainText as String]), !stringProviderIndexes.isEmpty {
			
			let group = DispatchGroup()
			var texts = [String]()
			
			for index in stringProviderIndexes {
				let itemProvider = UIPasteboard.general.itemProviders[index]
				group.enter()
				itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String) { (data, error) in
					if let data = data, let itemText = String(data: data, encoding: .utf8) {
						texts.append(itemText)
						group.leave()
					}
				}
			}

			group.notify(queue: DispatchQueue.main) {
				let text = texts.joined(separator: "\n")
				guard !text.isEmpty else { return }
				
				var rowGroups = [RowGroup]()
				let textRows = text.split(separator: "\n").map { String($0) }
				for textRow in textRows {
					let row = Row(outline: outline, topicMarkdown: textRow.trimmingWhitespace)
					rowGroups.append(RowGroup(row))
				}
				
				let command = PasteRowCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  rowGroups: rowGroups,
											  afterRow: afterRows?.last)

				self.runCommand(command)
			}

		}
	}

	func deleteRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DeleteRowCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   rowStrings: rowStrings)

		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if newCursorIndex == -1 {
				moveCursorToTagInput()
			} else {
				if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
					rowCell.moveToEnd()
				}
			}
		}
	}
	
	func createRow(beforeRows: [Row]) {
		guard let undoManager = undoManager, let outline = outline, let beforeRow = beforeRows.sortedByDisplayOrder().first else { return }

		let command = CreateRowBeforeCommand(undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 beforeRow: beforeRow)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func createRow(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		scrollRowToShowBottom()
		
		let afterRow = afterRows?.sortedByDisplayOrder().last
		
		let command = CreateRowAfterCommand(undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											rowStrings: rowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			let newCursorIndexPath = IndexPath(row: newCursorIndex, section: adjustedRowsSection)
			if let rowCell = self.collectionView.cellForItem(at: newCursorIndexPath) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}
		
		makeCursorVisibleIfNecessary()
	}
	
	func createRowInside(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		scrollRowToShowBottom()
		
		guard let afterRow = afterRows?.sortedByDisplayOrder().last else { return }
		
		let command = CreateRowInsideCommand(undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 afterRow: afterRow,
											 rowStrings: rowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			let newCursorIndexPath = IndexPath(row: newCursorIndex, section: adjustedRowsSection)
			if let rowCell = self.collectionView.cellForItem(at: newCursorIndexPath) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}

		makeCursorVisibleIfNecessary()
	}
	
	func createRowOutside(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		scrollRowToShowBottom()
		
		guard let afterRow = afterRows?.sortedByDisplayOrder().last else { return }
		
		let command = CreateRowOutsideCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  afterRow: afterRow,
											  rowStrings: rowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			let newCursorIndexPath = IndexPath(row: newCursorIndex, section: adjustedRowsSection)
			if let rowCell = self.collectionView.cellForItem(at: newCursorIndexPath) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}
		
		makeCursorVisibleIfNecessary()
	}
	
	func duplicateRows(_ rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DuplicateRowCommand(undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows)
		
		runCommand(command)
	}
	
	func moveRowsLeft(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowLeftCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 rows: rows,
										 rowStrings: rowStrings)
		
		runCommand(command)
	}

	func moveRowsRight(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowRightCommand(undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows,
										  rowStrings: rowStrings)
		
		runCommand(command)
	}

	func moveRowsUp(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowUpCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   rowStrings: rowStrings)
		
		runCommand(command)
		makeCursorVisibleIfNecessary()
	}

	func moveRowsDown(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowDownCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 rows: rows,
										 rowStrings: rowStrings)
		
		runCommand(command)
		makeCursorVisibleIfNecessary()
	}

	func splitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = SplitRowCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  row: row,
									  topic: topic,
									  cursorPosition: cursorPosition)
												  
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToStart()
			}
		}
	}

	func completeRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CompleteCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows,
									  rowStrings: rowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func uncompleteRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = UncompleteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		runCommand(command)
	}
	
	func createRowNotes(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateNoteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex ?? rows.first?.shadowTableIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToNote()
			}
		}

		makeCursorVisibleIfNecessary()
	}

	func deleteRowNotes(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = DeleteNoteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		runCommand(command)

		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}

	func makeCursorVisibleIfNecessary() {
		guard let textInput = UIResponder.currentFirstResponder as? UITextInput,
			  let cursorRect = textInput.cursorRect,
			  var convertedRect = (textInput as? UIView)?.convert(cursorRect, to: collectionView) else { return }
		
		// This isInNotes hack isn't well understood, but it improves the user experience...
		if textInput is EditorRowNoteTextView {
			convertedRect.size.height = convertedRect.size.height + 10
		}
		
		collectionView.scrollRectToVisibleBypass(convertedRect, animated: true)
	}
	
	func updateSpotlightIndex() {
		if let outline = outline {
			DocumentIndexer.updateIndex(forDocument: .outline(outline))
		}
	}
	
	func saveCurrentText() {
		if let textView = UIResponder.currentFirstResponder as? EditorRowTextView {
			textView.saveText()
		}
	}
	
	func generateBacklinkVerbaige(outline: Outline) -> NSAttributedString? {
		guard let backlinks = outline.documentBacklinks, !backlinks.isEmpty else {
			return nil
		}
		
		let references = Set(backlinks).map({ generateBacklink(id: $0) }).sorted() { lhs, rhs in
			return lhs.string.caseInsensitiveCompare(rhs.string) == .orderedAscending
		}
		
		let refString = references.count == 1 ? L10n.reference : L10n.references
		let result = NSMutableAttributedString(string: "\(refString)")
		result.append(references[0])
		
		for i in 1..<references.count {
			result.append(NSAttributedString(string: ", "))
			result.append(references[i])
		}
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		attrs[.font] = OutlineFontCache.shared.backline
		result.addAttributes(attrs, range: NSRange(0..<result.length))
		return result
	}
	
	func generateBacklink(id: EntityID) -> NSAttributedString {
		if let title = AccountManager.shared.findDocument(id)?.title, !title.isEmpty, let url = id.url {
			let result = NSMutableAttributedString(string: title)
			result.addAttribute(.link, value: url, range: NSRange(0..<result.length))
			return result
		}
		return NSAttributedString()
	}
	
	func search(for searchText: String) {
		outline?.search(for: searchText)
		searchBar.selectedResult = (outline?.currentSearchResult ?? 0) + 1
		searchBar.resultsCount = (outline?.searchResultCount ?? 0)
		scrollSearchResultIntoView()
	}
	
	func nextSearchResult() {
		outline?.nextSearchResult()
		searchBar.selectedResult = (outline?.currentSearchResult ?? 0) + 1
		scrollSearchResultIntoView()
	}
	
	func previousSearchResult() {
		outline?.previousSearchResult()
		searchBar.selectedResult = (outline?.currentSearchResult ?? 0) + 1
		scrollSearchResultIntoView()
	}
	
	func scrollSearchResultIntoView() {
		guard let resultIndex = outline?.currentSearchResultRow?.shadowTableIndex else { return }
		let indexPath = IndexPath(row: resultIndex, section: adjustedRowsSection)
		
		guard let cellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else { return }
		var collectionViewFrame = collectionView.safeAreaLayoutGuide.layoutFrame
		collectionViewFrame = view.convert(collectionViewFrame, to: view.window)
		
		var adjustedCollectionViewFrame = CGRect(x: collectionViewFrame.origin.x, y: collectionViewFrame.origin.y, width: collectionViewFrame.width, height: collectionViewFrame.height - currentKeyboardHeight)
		adjustedCollectionViewFrame = view.convert(adjustedCollectionViewFrame, to: view.window)
		
		if !adjustedCollectionViewFrame.contains(cellFrame) {
			collectionView.scrollRectToVisibleBypass(cellFrame, animated: true)
		}
	}

}
