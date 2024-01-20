//
//  EditorViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import MobileCoreServices
import PhotosUI
import VinOutlineKit
import VinUtility

extension Selector {
	static let insertImage = #selector(EditorViewController.insertImage)
	static let splitRow = #selector(EditorViewController.splitRow as (EditorViewController) -> () -> Void)
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

class EditorViewController: UIViewController, DocumentsActivityItemsConfigurationDelegate, MainControllerIdentifiable, UndoableCommandRunner {

	private static let searchBarHeight: CGFloat = 44
	
	@IBOutlet weak var searchBar: EditorSearchBar!
	@IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var collectionView: EditorCollectionView!
	
	override var keyCommands: [UIKeyCommand]? {
		var keyCommands = [UIKeyCommand]()
		
		let shiftTab = UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(moveCurrentRowsLeft))
		shiftTab.wantsPriorityOverSystemBehavior = true
		keyCommands.append(shiftTab)
		
		let tab = UIKeyCommand(action: #selector(moveCurrentRowsRight), input: "\t")
		tab.wantsPriorityOverSystemBehavior = true
		keyCommands.append(tab)
		
		// We need to have this here in addition to the AppDelegate, since iOS won't pick it up for some reason
		if !isToggleRowCompleteUnavailable {
			let commandReturn = UIKeyCommand(input: "\r", modifierFlags: [.command], action: #selector(toggleCompleteRows))
			commandReturn.wantsPriorityOverSystemBehavior = true
			keyCommands.append(commandReturn)
		}
		
		return keyCommands
	}
	
	var selectedDocuments: [Document] {
		guard let outline else { return []	}
		return [Document.outline(outline)]
	}
	
	var mainControllerIdentifer: MainControllerIdentifier { return .editor }

	weak var delegate: EditorDelegate?
	
	var isOutlineFunctionsUnavailable: Bool {
		return outline == nil
	}
	
	var isFocusInUnavailable: Bool {
		return !(currentRows?.count ?? 0 == 1)
	}
	
	var isFocusOutUnavailable: Bool {
		return outline?.isFocusOutUnavailable() ?? true
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
		return !(UIResponder.currentFirstResponder is EditorRowTopicTextView)
	}

	var isFormatUnavailable: Bool {
		return currentTextView == nil
	}
	
	var isUndoUnvailable: Bool {
		if let currentTextView {
			return !(currentTextView.undoManager?.canUndo ?? false)
		} else {
			return !(undoManager?.canUndo ?? false)
		}
	}

	var isRedoUnvailable: Bool {
		if let currentTextView {
			return !(currentTextView.undoManager?.canRedo ?? false)
		} else {
			return !(undoManager?.canRedo ?? false)
		}
	}
	
	var isCutUnavailable: Bool {
		if let currentTextView {
			return !currentTextView.canPerformAction(.cut, withSender: nil)
		}
		if let currentRows {
			return currentRows.isEmpty
		}
		return true
	}

	var isCopyUnavailable: Bool {
		if let currentTextView {
			return !currentTextView.canPerformAction(.copy, withSender: nil)
		}
		if let currentRows {
			return currentRows.isEmpty
		}
		return true
	}

	var isPasteUnavailable: Bool {
		if let currentTextView {
			return !currentTextView.canPerformAction(.paste, withSender: nil)
		}
		return !UIPasteboard.general.contains(pasteboardTypes: [Row.typeIdentifier, UTType.utf8PlainText.identifier], inItemSet: nil)
	}

	var isInsertImageUnavailable: Bool {
		return currentTextView == nil
	}

	var isLinkUnavailable: Bool {
		return currentTextView == nil
	}

	var isInsertNewlineUnavailable: Bool {
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
		if let selected = collectionView?.indexPathsForSelectedItems?.sorted(), !selected.isEmpty {
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
	private static var slowRepeatInterval = 1.0
	private static var fastRepeatInterval = 0.1
	private lazy var cursorUpRepeatInterval: Double = Self.slowRepeatInterval
	private lazy var cursorDownRepeatInterval: Double = Self.slowRepeatInterval

	private var undoMenuButton: ButtonGroup.Button!
	private var undoMenuButtonGroup: ButtonGroup!
	private var undoButton: ButtonGroup.Button!
	private var cutButton: ButtonGroup.Button!
	private var copyButton: ButtonGroup.Button!
	private var pasteButton: ButtonGroup.Button!
	private var redoButton: ButtonGroup.Button!

	private var navButtonGroup: ButtonGroup!
	private var goBackwardButton: ButtonGroup.Button!
	private var goForwardButton: ButtonGroup.Button!
	private var moreMenuButton: ButtonGroup.Button!
	private var focusButton: ButtonGroup.Button!
	private var filterButton: ButtonGroup.Button!
	
	private var formatMenuButton: ButtonGroup.Button!
	private var formatMenuButtonGroup: ButtonGroup!
	private var boldButton: ButtonGroup.Button!
	private var italicButton: ButtonGroup.Button!
	private var linkButton: ButtonGroup.Button!

	private var keyboardToolBar: UIToolbar!
	private var leftToolbarButtonGroup: ButtonGroup!
	private var rightToolbarButtonGroup: ButtonGroup!
	private var moveRightButton: ButtonGroup.Button!
	private var moveLeftButton: ButtonGroup.Button!
	private var moveUpButton: ButtonGroup.Button!
	private var moveDownButton: ButtonGroup.Button!
	private var insertImageButton: ButtonGroup.Button!
	private var noteButton: ButtonGroup.Button!
	private var insertNewlineButton: ButtonGroup.Button!
	private var squareButton: ButtonGroup.Button!

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
	private var updateTitleDebouncer = Debouncer(duration: 1)
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
	private var rowIndentSize = AppDefaults.shared.rowIndentSize
	private var rowSpacingSize = AppDefaults.shared.rowSpacingSize
	
	private lazy var transition = ImageTransition(delegate: self)
	private var imageBlocker: UIView?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		//NSTextAttachment.registerViewProviderClass(MetadataTextAttachmentViewProvider.self, forFileType: MetadataTextAttachmentViewProvider.fileType)
		
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		
		// Mac Catalyst and regular iOS use different contraint connections to manage Toolbar and Navigation bar translucency
		let collectionViewLeadingConstraint: NSLayoutConstraint
		let collectionViewTrailingConstraint: NSLayoutConstraint
		let collectionViewBottomConstraint: NSLayoutConstraint

		if traitCollection.userInterfaceIdiom == .mac {
			collectionViewTopConstraint = collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
			collectionViewLeadingConstraint = collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
			collectionViewTrailingConstraint = collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
			collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			collectionViewTopConstraint = collectionView.topAnchor.constraint(equalTo: view.topAnchor)
			collectionViewLeadingConstraint = collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
			collectionViewTrailingConstraint = collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
			collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
			collectionView.refreshControl!.tintColor = .clear
		}

		NSLayoutConstraint.activate([
			collectionViewTopConstraint,
			collectionViewLeadingConstraint,
			collectionViewTrailingConstraint,
			collectionViewBottomConstraint
		])

		searchBar.delegate = self
		
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
			cell.rowIndentSize = self?.rowIndentSize
			cell.rowSpacingSize = self?.rowSpacingSize
			cell.isNotesHidden = self?.outline?.isNotesFilterOn ?? false
			cell.isSearching = self?.isSearching ?? false
			cell.delegate = self
		}
		
		backlinkRegistration = UICollectionView.CellRegistration<EditorBacklinkViewCell, Outline> { [weak self] (cell, indexPath, outline) in
			cell.reference = self?.generateBacklinkVerbaige(outline: outline)
		}

		configureButtonBars()
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
		NotificationCenter.default.addObserver(self, selector: #selector(outlineSearchDidEnd(_:)), name: .OutlineSearchDidEnd, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineDidFocusOut(_:)), name: .OutlineDidFocusOut, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineAddedBacklinks(_:)), name: .OutlineAddedBacklinks, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineRemovedBacklinks(_:)), name: .OutlineRemovedBacklinks, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTextPreferencesDidChange(_:)), name: .OutlineTextPreferencesDidChange, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(didUndoChange(_:)), name: .NSUndoManagerDidUndoChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didRedoChange(_:)), name: .NSUndoManagerDidRedoChange, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)),	name: UIApplication.willTerminateNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sceneWillDeactivate(_:)),	name: UIScene.willDeactivateNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		moveCursorToTitleOnNew()
		undoManager?.removeAllActions()
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		// I'm not sure how collectionView could be nil, but we have crash reports where it is
		guard collectionView != nil else { return }
		
		if collectionView.contentOffset != .zero {
			transitionContentOffset = collectionView.contentOffset
		}
		
		navButtonGroup.containerWidth = size.width
		leftToolbarButtonGroup.containerWidth = size.width
		rightToolbarButtonGroup.containerWidth = size.width
	}
	
	override func viewDidLayoutSubviews() {
		if let offset = transitionContentOffset {
			collectionView.contentOffset = offset
			transitionContentOffset = nil
		}
	}
	
	override func contentScrollView(for edge: NSDirectionalRectEdge) -> UIScrollView? {
		return collectionView
	}
		
	override func selectAll(_ sender: Any?) {
		selectAllRows()
	}
	
	override func cut(_ sender: Any?) {
		navButtonGroup?.dismissPopOverMenu()
		
		if let currentTextView {
			currentTextView.cut(sender)
		} else if let currentRows {
			cutRows(currentRows)
		}
	}
	
	override func copy(_ sender: Any?) {
		navButtonGroup?.dismissPopOverMenu()
		
		if let currentTextView {
			currentTextView.copy(sender)
		} else if let currentRows {
			copyRows(currentRows)
		}
	}
	
	override func paste(_ sender: Any?) {
		navButtonGroup?.dismissPopOverMenu()
		
		if let currentTextView {
			currentTextView.paste(sender)
		} else {
			pasteRows(afterRows: currentRows)
		}
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .selectAll:
			return !isSelectAllRowsUnavailable
		case .cut, .copy:
			return !(collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
		case .paste:
			return UIPasteboard.general.contains(pasteboardTypes: [UTType.utf8PlainText.identifier, Row.typeIdentifier])
		case .splitRow:
			return !isSplitRowUnavailable
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
		collectionView.reloadData()
	}
	
	@objc func userDefaultsDidChange() {
		if rowIndentSize != AppDefaults.shared.rowIndentSize {
			rowIndentSize = AppDefaults.shared.rowIndentSize
			collectionView.reloadData()
		}

		if rowSpacingSize != AppDefaults.shared.rowSpacingSize {
			rowSpacingSize = AppDefaults.shared.rowSpacingSize
			collectionView.reloadData()
		}
	}
	
	@objc func outlineTextPreferencesDidChange(_ note: Notification) {
		collectionView.reloadData()
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
		collectionView.deleteSections(headerFooterSections)
		
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

	@objc func outlineSearchDidEnd(_ note: Notification) {
		if let cursorCoordinates = CursorCoordinates.bestCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: true, centered: true)
		}
	}
	
	@objc func outlineDidFocusOut(_ note: Notification) {
		if let cursorCoordinates = CursorCoordinates.bestCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: true, centered: true)
		}
	}
	
	@objc func outlineAddedBacklinks(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		collectionView.insertSections([Outline.Section.backlinks.rawValue])
	}
	
	@objc func outlineRemovedBacklinks(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		collectionView.deleteSections([Outline.Section.backlinks.rawValue])
	}
	
	@objc func didUndoChange(_ note: Notification) {
		updateUI()
	}
	
	@objc func didRedoChange(_ note: Notification) {
		updateUI()
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
				self?.makeCursorVisibleIfNecessary()
				self?.currentKeyboardHeight = keyboardViewEndFrame.height
			}
			DispatchQueue.main.async(execute: keyboardWorkItem!)
		}
	}
	
	// MARK: API
	
	func showMessage(_ message: String) {
		// This may get called before the collectionView is created when running on the iPhone
		guard let collectionView else { return }
		
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
		outline?.decrementBeingUsedCount()
		
		// End the search collection view updates early
		isSearching = false
		outline?.endSearching()
		
		outline?.unload()
		undoManager?.removeAllActions()
	
		// Assign the new Outline and load it
		outline = newOutline
		
		// Don't continue if we are just clearing out the editor
		guard let outline else {
			updateUI()
			collectionView.reloadData()
			return
		}

		outline.incrementBeingUsedCount()
		outline.load()
		checkForCorruptOutline()
		outline.prepareForViewing()
			
		guard isViewLoaded else { return }

		updateNavigationMenus()
		collectionView.reloadData()
		
		if let searchText {
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
	
	func updateNavigationMenus() {
		guard let delegate else { return }
		
		var backwardItems = [UIAction]()
		for (index, pin) in delegate.editorViewControllerGoBackwardStack.enumerated() {
			backwardItems.append(UIAction(title: pin.document?.title ?? .noTitleLabel) { [weak self] _ in
				guard let self else { return }
				DispatchQueue.main.async {
					delegate.goBackward(self, to: index)
				}
			})
		}
		goBackwardButton.menu = UIMenu(title: "", children: backwardItems)

		var forwardItems = [UIAction]()
		for (index, pin) in delegate.editorViewControllerGoForwardStack.enumerated() {
			forwardItems.append(UIAction(title: pin.document?.title ?? .noTitleLabel) { [weak self] _ in
				guard let self else { return }
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
			moreMenuButton.menu = buildEllipsisMenu()

			if isFocusOutUnavailable {
				focusButton.accessibilityLabel = .focusInControlLabel
				focusButton.setImage(.focusInactive, for: .normal)
				if currentRows?.count ?? 0 == 1 {
					focusButton.isEnabled = true
				} else {
					focusButton.isEnabled = false
				}
			} else {
				focusButton.accessibilityLabel = .focusOutControlLabel
				focusButton.setImage(.focusActive, for: .normal)
				focusButton.isEnabled = true
			}
			
			if isFilterOn {
				filterButton.accessibilityLabel = .turnFilterOffControlLabel
				filterButton.setImage(.filterActive, for: .normal)
			} else {
				filterButton.accessibilityLabel = .turnFilterOnControlLabel
				filterButton.setImage(.filterInactive, for: .normal)
			}

			filterButton.menu = buildFilterMenu()
			
			if outline == nil {
				filterButton.isEnabled = false
				moreMenuButton.isEnabled = false
			} else {
				filterButton.isEnabled = true
				moreMenuButton.isEnabled = true
			}
			
			goBackwardButton.isEnabled = !isGoBackwardUnavailable
			goForwardButton.isEnabled = !isGoForwardUnavailable
			
			undoButton.isEnabled = !isUndoUnvailable
			cutButton.isEnabled = !isCutUnavailable
			copyButton.isEnabled = !isCopyUnavailable
			pasteButton.isEnabled = !isPasteUnavailable
			redoButton.isEnabled = !isRedoUnvailable
			
			moveLeftButton.isEnabled = !isMoveRowsLeftUnavailable
			moveRightButton.isEnabled = !isMoveRowsRightUnavailable
			moveUpButton.isEnabled = !isMoveRowsUpUnavailable
			moveDownButton.isEnabled = !isMoveRowsDownUnavailable
			
			insertImageButton.isEnabled = !isInsertImageUnavailable
			linkButton.isEnabled = !isLinkUnavailable
			boldButton.isEnabled = !isFormatUnavailable
			italicButton.isEnabled = !isFormatUnavailable

			// Because these items are in the Toolbar, they shouldn't ever be disabled. We will
			// only have one row selected at a time while editing and that row eitherh has a note
			// or it doesn't.
			if !isCreateRowNotesUnavailable {
				noteButton.isEnabled = true
				noteButton.setImage(.noteAdd, for: .normal)
				noteButton.accessibilityLabel = .addNoteControlLabel
			} else if !isDeleteRowNotesUnavailable {
				noteButton.isEnabled = true
				noteButton.setImage(.noteDelete, for: .normal)
				noteButton.accessibilityLabel = .deleteNoteControlLabel
			} else {
				noteButton.isEnabled = false
				noteButton.setImage(.noteAdd, for: .normal)
				noteButton.accessibilityLabel = .addNoteControlLabel
			}
			
			insertNewlineButton.isEnabled = !isInsertNewlineUnavailable
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
	
	func createRowNotes() {
		guard let rows = currentRows else { return }
		createRowNotes(rows)
	}
	
	func deleteRowNotes() {
		guard let rows = currentRows else { return }
		deleteRowNotes(rows)
	}
	
	func expandAllInOutline() {
		guard let outline else { return }
		expandAll(containers: [outline])
	}
	
	func collapseAllInOutline() {
		guard let outline else { return }
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
		
		let alertController = UIAlertController(title: .deleteCompletedRowsTitle,
												message: .deleteCompletedRowsMessage,
												preferredStyle: .alert)
		
		let alwaysDeleteCompletedAction = UIAlertAction(title: .deleteAlwaysControlLabel, style: .destructive) { [weak self] action in
			AppDefaults.shared.confirmDeleteCompletedRows = false
			self?.deleteRows(completedRows)
		}
		alertController.addAction(alwaysDeleteCompletedAction)

		let deleteCompletedAction = UIAlertAction(title: .deleteOnceControlLabel, style: .destructive) { [weak self] action in
			self?.deleteRows(completedRows)
		}
		
		alertController.addAction(deleteCompletedAction)
		alertController.preferredAction = deleteCompletedAction

		let cancelAction = UIAlertAction(title: .cancelControlLabel, style: .cancel)
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
		guard let outline else { return }
		currentTextView?.saveText()
		delegate?.printDoc(self, outline: outline)
	}
	
	func printList() {
		guard let outline else { return }
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
		}
		collectionView?.refreshControl?.endRefreshing()
	}
	
	@objc func hideKeyboard() {
		UIResponder.currentFirstResponder?.resignFirstResponder()
		CursorCoordinates.clearLastKnownCoordinates()
	}

	@objc func focusIn() {
		guard let row = currentRows?.first else { return }
		outline?.focusIn(row)
	}
	
	@objc func focusOut() {
		outline?.focusOut()
	}

	@objc func toggleFocus() {
		if isFocusOutUnavailable {
			focusIn()
		} else {
			focusOut()
		}
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
		
		DispatchQueue.main.asyncAfter(deadline: .now() + cursorUpRepeatInterval) { [weak self] in
			if self?.isCursoringUp ?? false {
				self?.cursorUpRepeatInterval = Self.fastRepeatInterval
				self?.repeatMoveCursorUp()
			} else {
				self?.cursorUpRepeatInterval = Self.slowRepeatInterval
			}
		}
	}
	
	@objc func repeatMoveCursorDown() {
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
		
		DispatchQueue.main.asyncAfter(deadline: .now() + cursorDownRepeatInterval) { [weak self] in
			if self?.isCursoringDown ?? false {
				self?.cursorDownRepeatInterval = Self.fastRepeatInterval
				self?.repeatMoveCursorDown()
			} else {
				self?.cursorDownRepeatInterval = Self.slowRepeatInterval
			}
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
		rightToolbarButtonGroup.dismissPopOverMenu()
		currentTextView?.editLink(self)
	}
	
	@objc func insertNewline() {
		currentTextView?.insertNewline(self)
	}
	
	@objc func splitRow() {
		guard let row = currentRows?.last,
			  let topic = (currentTextView as? EditorRowTopicTextView)?.attributedText,
			  let cursorPosition = currentCursorPosition else { return }
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	@objc func outlineToggleBoldface(_ sender: Any? = nil) {
		rightToolbarButtonGroup.dismissPopOverMenu()
		currentTextView?.toggleBoldface(self)
	}
	
	@objc func outlineToggleItalics(_ sender: Any? = nil) {
		rightToolbarButtonGroup.dismissPopOverMenu()
		currentTextView?.toggleItalics(self)
	}
	
	@objc func share(_ sender: Any? = nil) {
		let controller = UIActivityViewController(activityItemsConfiguration: DocumentsActivityItemsConfiguration(delegate: self))
		if let sendingView = sender as? UIView {
			controller.popoverPresentationController?.sourceView = sendingView
		} else {
			controller.popoverPresentationController?.sourceView = collectionView
			var rect = collectionView.bounds
			rect.size.height = rect.size.height / 4
			controller.popoverPresentationController?.sourceRect = rect
		}
		present(controller, animated: true)
	}
	
	@objc func collaborate(_ sender: Any? = nil) {
		guard let outline else { return }
		
		AccountManager.shared.cloudKitAccount?.prepareCloudSharingController(document: .outline(outline)) { result in
			switch result {
			case .success(let sharingController):
				sharingController.popoverPresentationController?.sourceView = sender as? UIView
				sharingController.delegate = self
				sharingController.availablePermissions = [.allowReadWrite]
				self.present(sharingController, animated: true)
			case .failure(let error):
				self.presentError(error)
			}
		}
	}
	
	@objc func showOutlineGetInfo() {
		guard let outline else { return }
		delegate?.showGetInfo(self, outline: outline)
	}
	
	@objc func goBackwardOne() {
		delegate?.goBackward(self, to: 0)
	}

	@objc func goForwardOne() {
		delegate?.goForward(self, to: 0)
	}

	@objc func showUndoMenu() {
		updateUI()
		navButtonGroup.showPopOverMenu(for: undoMenuButton)
	}

	@objc func undo() {
		undoManager?.undo()
	}
	
	@objc func redo() {
		undoManager?.redo()
	}
	
	@objc func showFormatMenu() {
		updateUI()
		rightToolbarButtonGroup.showPopOverMenu(for: formatMenuButton)
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
	
	@objc func createOrDeleteNotes() {
		guard let rows = currentRows else { return }

		if !isCreateRowNotesUnavailable {
			createRowNotes(rows)
		} else {
			deleteRowNotes(rows)
		}
	}

	@objc func toggleCompleteRows() {
		guard let outline = outline, let rows = currentRows else { return }
		if !outline.isCompleteUnavailable(rows: rows) {
			completeRows(rows)
		} else if !outline.isUncompleteUnavailable(rows: rows) {
			uncompleteRows(rows)
		}
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
						
						if row.isComplete ?? false {
							let actionHandler: UIContextualAction.Handler = { action, view, completion in
								self.uncompleteRows([row])
								completion(true)
							}
							
							let action = UIContextualAction(style: .normal, title: .uncompleteControlLabel, handler: actionHandler)
							if self.traitCollection.userInterfaceIdiom == .mac {
								action.image = .uncompleteRow.symbolSizedForCatalyst(color: .white)
							} else {
								action.image = .uncompleteRow
							}
							action.backgroundColor = UIColor.accentColor
							
							return UISwipeActionsConfiguration(actions: [action])
						} else {
							let actionHandler: UIContextualAction.Handler = { action, view, completion in
								self.completeRows([row])
								completion(true)
							}
							
							let action = UIContextualAction(style: .normal, title: .completeControlLabel, handler: actionHandler)
							if self.traitCollection.userInterfaceIdiom == .mac {
								action.image = .completeRow.symbolSizedForCatalyst(color: .white)
							} else {
								action.image = .completeRow
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
						
						let action = UIContextualAction(style: .destructive, title: .deleteControlLabel, handler: actionHandler)
						if self.traitCollection.userInterfaceIdiom == .mac {
							action.image = .delete.symbolSizedForCatalyst(color: .white)
						} else {
							action.image = .delete
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
			if traitCollection.userInterfaceIdiom != .mac {
				CursorCoordinates.clearLastKnownCoordinates()
			}                      
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
			if let outline {
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
		
		return buildRowsContextMenu(rows: rows)
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
		updateTitleDebouncer.debounce { [weak self] in
			self?.outline?.update(title: title)
		}
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
	
	func editorRowScrollEditorToVisible(textView: UITextView, rect: CGRect) {
		scrollToVisible(textInput: textView, rect: rect, animated: true)
	}

	func editorRowTextFieldDidBecomeActive(row: Row) {
		// This makes doing row insertions much faster because this work will
		// be performed a cycle after the actual insertion was completed.
		DispatchQueue.main.async {
			self.collectionView.deselectAll()
			self.updateUI()
			self.delegate?.validateToolbar(self)
		}
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
			guard let self else { return }
			
			if let data = (object as? UIImage)?.rotateImage()?.pngData(), let cgImage = UIImage.scaleImage(data, maxPixelSize: 1800) {
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
			rowCell.noteTextView?.updateLink(text: text, link: correctedLink, range: range)
		} else {
			rowCell.topicTextView?.becomeFirstResponder()
			rowCell.topicTextView?.updateLink(text: text, link: correctedLink, range: range)
		}
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
		imageBlocker!.backgroundColor = .fullScreenBackgroundColor
		collectionView.addSubview(imageBlocker!)
	}
	
	func unhideImage(_: ImageTransition) {
		imageBlocker?.removeFromSuperview()
		imageBlocker = nil
	}
	
}

// MARK: Helpers

private extension EditorViewController {
	
	func configureButtonBars() {
		undoMenuButtonGroup = ButtonGroup(hostController: self, containerType: .standard, alignment: .none)
		undoButton = undoMenuButtonGroup.addButton(label: .undoControlLabel, image: .undo, selector: "undo")
		cutButton = undoMenuButtonGroup.addButton(label: .cutControlLabel, image: .cut, selector: "cut:")
		copyButton = undoMenuButtonGroup.addButton(label: .copyControlLabel, image: .copy, selector: "copy:")
		pasteButton = undoMenuButtonGroup.addButton(label: .pasteControlLabel, image: .paste, selector: "paste:")
		redoButton = undoMenuButtonGroup.addButton(label: .redoControlLabel, image: .redo, selector: "redo")

		navButtonGroup = ButtonGroup(hostController: self, containerType: .compactable, alignment: .right)
		goBackwardButton = navButtonGroup.addButton(label: .goBackwardControlLabel, image: .goBackward, selector: "goBackwardOne")
		goForwardButton = navButtonGroup.addButton(label: .goForwardControlLabel, image: .goForward, selector: "goForwardOne")
		undoMenuButton = navButtonGroup.addButton(label: .undoMenuControlLabel, image: .undoMenu, selector: "showUndoMenu")
		undoMenuButton.popoverButtonGroup = undoMenuButtonGroup
		moreMenuButton = navButtonGroup.addButton(label: .moreControlLabel, image: .ellipsis, showMenu: true)
		focusButton = navButtonGroup.addButton(label: .focusInControlLabel, image: .focusInactive, selector: "toggleFocus")
		filterButton = navButtonGroup.addButton(label: .filterControlLabel, image: .filterInactive, showMenu: true)
		let navButtonsBarButtonItem = navButtonGroup.buildBarButtonItem()

		leftToolbarButtonGroup = ButtonGroup(hostController: self, containerType: .compactable, alignment: .left)
		moveLeftButton = leftToolbarButtonGroup.addButton(label: .moveLeftControlLabel, image: .moveLeft, selector: "moveCurrentRowsLeft")
		moveRightButton = leftToolbarButtonGroup.addButton(label: .moveRightControlLabel, image: .moveRight, selector: "moveCurrentRowsRight")
		moveUpButton = leftToolbarButtonGroup.addButton(label: .moveUpControlLabel, image: .moveUp, selector: "moveCurrentRowsUp")
		moveDownButton = leftToolbarButtonGroup.addButton(label: .moveDownControlLabel, image: .moveDown, selector: "moveCurrentRowsDown")
		let moveButtonsBarButtonItem = leftToolbarButtonGroup.buildBarButtonItem()

		formatMenuButtonGroup = ButtonGroup(hostController: self, containerType: .standard, alignment: .none)
		linkButton = formatMenuButtonGroup.addButton(label: .linkControlLabel, image: .link, selector: "link")
		let boldImage = UIImage.bold.applyingSymbolConfiguration(.init(pointSize: 25, weight: .regular, scale: .medium))!
		boldButton = formatMenuButtonGroup.addButton(label: .boldControlLabel, image: boldImage, selector: "outlineToggleBoldface:")
		let italicImage = UIImage.italic.applyingSymbolConfiguration(.init(pointSize: 25, weight: .regular, scale: .medium))!
		italicButton = formatMenuButtonGroup.addButton(label: .italicControlLabel, image: italicImage, selector: "outlineToggleItalics:")

		rightToolbarButtonGroup = ButtonGroup(hostController: self, containerType: .compactable, alignment: .right)
		insertImageButton = rightToolbarButtonGroup.addButton(label: .insertImageControlLabel, image: .insertImage, selector: "insertImage")
		formatMenuButton = rightToolbarButtonGroup.addButton(label: .formatControlLabel, image: .format, selector: "showFormatMenu")
		formatMenuButton.popoverButtonGroup = formatMenuButtonGroup
		noteButton = rightToolbarButtonGroup.addButton(label: .addNoteControlLabel, image: .noteAdd, selector: "createOrDeleteNotes")
		insertNewlineButton = rightToolbarButtonGroup.addButton(label: .newOutlineControlLabel, image: .newline, selector: "insertNewline")
		let insertButtonsBarButtonItem = rightToolbarButtonGroup.buildBarButtonItem()

		if traitCollection.userInterfaceIdiom != .mac {
			keyboardToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
			let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			
			if traitCollection.userInterfaceIdiom == .pad {
				keyboardToolBar.items = [moveButtonsBarButtonItem, flexibleSpace, insertButtonsBarButtonItem]
			} else {
				let hideKeyboardBarButtonItem = UIBarButtonItem(image: .hideKeyboard, style: .plain, target: self, action: #selector(hideKeyboard))
				hideKeyboardBarButtonItem.accessibilityLabel = .hideKeyboardControlLabel
				keyboardToolBar.items = [moveButtonsBarButtonItem, flexibleSpace, hideKeyboardBarButtonItem, flexibleSpace, insertButtonsBarButtonItem]
			}
			
			keyboardToolBar.sizeToFit()
			navigationItem.rightBarButtonItems = [navButtonsBarButtonItem]

			if traitCollection.userInterfaceIdiom == .pad {
				navButtonGroup.remove(undoMenuButton)
				rightToolbarButtonGroup.remove(formatMenuButton)
				formatMenuButtonGroup.remove(linkButton)
				rightToolbarButtonGroup.insert(linkButton, at: 1)
			}
		}
	}
	
	func discloseSearchBar() {
		view.layoutIfNeeded()

		UIView.animate(withDuration: 0.3) {
			if self.traitCollection.userInterfaceIdiom == .mac {
				self.collectionViewTopConstraint.constant = Self.searchBarHeight
			} else {
				self.collectionViewTopConstraint.constant = Self.searchBarHeight + self.view.safeAreaInsets.top
			}
			self.view.layoutIfNeeded()
		}
	}
	
	func buildEllipsisMenu() -> UIMenu {
		var outlineActions = [UIMenuElement]()

		let getInfoAction = UIAction(title: .getInfoControlLabel, image: .getInfo) { [weak self] _ in
			self?.showOutlineGetInfo()
		}
		outlineActions.append(getInfoAction)

		let findAction = UIAction(title: .findEllipsisControlLabel, image: .find) { [weak self] _ in
			self?.beginInDocumentSearch()
		}
		outlineActions.append(findAction)

		let expandAllInOutlineAction = UIAction(title: .expandAllInOutlineControlLabel, image: .expandAll) { [weak self] _ in
			self?.expandAllInOutline()
		}
		outlineActions.append(expandAllInOutlineAction)
		
		let collapseAllInOutlineAction = UIAction(title: .collapseAllInOutlineControlLabel, image: .collapseAll) { [weak self] _ in
			self?.collapseAllInOutline()
		}
		outlineActions.append(collapseAllInOutlineAction)
		
		var shareActions = [UIMenuElement]()

		if !isCollaborateUnavailable {
			let collaborateAction = UIAction(title: .collaborateEllipsisControlLabel, image: .statelessCollaborate) { [weak self] _ in
				self?.collaborate(self?.moreMenuButton)
			}
			shareActions.append(collaborateAction)
		}

		let shareAction = UIAction(title: .shareEllipsisControlLabel, image: .share) { [weak self] _ in
			self?.share(self?.moreMenuButton)
		}
		shareActions.append(shareAction)

		let printDocAction = UIAction(title: .printDocEllipsisControlLabel) { [weak self] _ in
			self?.printDoc()
		}
		let printListAction = UIAction(title: .printListControlEllipsisLabel) { [weak self] _ in
			self?.printList()
		}
		shareActions.append(UIMenu(title: .printControlLabel, image: .printDoc, children: [printDocAction, printListAction]))

		let exportPDFDoc = UIAction(title: .exportPDFDocEllipsisControlLabel) { [weak self] _ in
			guard let self = self, let outline = self.outline else { return }
			self.delegate?.exportPDFDoc(self, outline: outline)
		}
		let exportPDFList = UIAction(title: .exportPDFListEllipsisControlLabel) { [weak self] _ in
			guard let self = self, let outline = self.outline else { return }
			self.delegate?.exportPDFList(self, outline: outline)
		}
		let exportMarkdownDoc = UIAction(title: .exportMarkdownDocEllipsisControlLabel) { [weak self] _ in
			guard let self = self, let outline = self.outline else { return }
			self.delegate?.exportMarkdownDoc(self, outline: outline)
		}
		let exportMarkdownList = UIAction(title: .exportMarkdownListEllipsisControlLabel) { [weak self] _ in
			guard let self = self, let outline = self.outline else { return }
			self.delegate?.exportMarkdownList(self, outline: outline)
		}
		let exportOPML = UIAction(title: .exportOPMLEllipsisControlLabel) { [weak self] _ in
			guard let self = self, let outline = self.outline else { return }
			self.delegate?.exportOPML(self, outline: outline)
		}
		let exportActions = [exportPDFDoc, exportPDFList, exportMarkdownDoc, exportMarkdownList, exportOPML]
		shareActions.append(UIMenu(title: .exportControlLabel, image: .export, children: exportActions))

		let deleteCompletedRowsAction = UIAction(title: .deleteCompletedRowsControlLabel,
												 image: .delete,
												 attributes: .destructive) { [weak self] _ in
			self?.deleteCompletedRows()
		}
		let outlineMenu = UIMenu(title: "", options: .displayInline, children: outlineActions)
		let shareMenu = UIMenu(title: "", options: .displayInline, children: shareActions)
		let changeMenu = UIMenu(title: "", options: .displayInline, children: [deleteCompletedRowsAction])
		
		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [outlineMenu, shareMenu, changeMenu])
	}
	
	func buildFilterMenu() -> UIMenu {
		let turnFilterOnAction = UIAction() { [weak self] _ in
		   self?.toggleFilterOn()
		}
		turnFilterOnAction.title = isFilterOn ? .turnFilterOffControlLabel : .turnFilterOnControlLabel
		
		let turnFilterOnMenu = UIMenu(title: "", options: .displayInline, children: [turnFilterOnAction])
		
		let filterCompletedAction = UIAction(title: .filterCompletedControlLabel) { [weak self] _ in
			self?.toggleCompletedFilter()
		}
		filterCompletedAction.state = isCompletedFiltered ? .on : .off
		filterCompletedAction.attributes = isFilterOn ? [] : .disabled

		let filterNotesAction = UIAction(title: .filterNotesControlLabel) { [weak self] _ in
		   self?.toggleNotesFilter()
		}
		filterNotesAction.state = isNotesFiltered ? .on : .off
		filterNotesAction.attributes = isFilterOn ? [] : .disabled

		let filterOptionsMenu = UIMenu(title: "", options: .displayInline, children: [filterCompletedAction, filterNotesAction])

		return UIMenu(title: "", children: [turnFilterOnMenu, filterOptionsMenu])
	}
	
	func checkForCorruptOutline() {
		guard let outline, outline.isRecoveringRowsPossible else { return }
		
		let alertController = UIAlertController(title: .corruptedOutlineTitle,
												message: .corruptedOutlineMessage,
												preferredStyle: .alert)
		
		let recoverAction = UIAlertAction(title: .recoverControlLabel, style: .default) { [weak self] action in
			self?.outline?.recoverLostRows()
		}
		alertController.addAction(recoverAction)
		alertController.preferredAction = recoverAction

		let cancelAction = UIAlertAction(title: .cancelControlLabel, style: .cancel)
		alertController.addAction(cancelAction)

		present(alertController, animated: true)
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
			case (.keyboardLeftArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView, topic.cursorIsAtBeginning,
				   let currentRowIndex = topic.row?.shadowTableIndex,
				   currentRowIndex > 0,
				   let cell = collectionView.cellForItem(at: IndexPath(row: currentRowIndex - 1, section: adjustedRowsSection)) as? EditorRowViewCell {
					cell.moveToEnd()
				} else {
					super.pressesBegan(presses, with: event)
				}
			case (.keyboardRightArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView, topic.cursorIsAtEnd,
				   let currentRowIndex = topic.row?.shadowTableIndex,
				   currentRowIndex + 1 < outline?.shadowTable?.count ?? 0,
				   let cell = collectionView.cellForItem(at: IndexPath(row: currentRowIndex + 1, section: adjustedRowsSection)) as? EditorRowViewCell {
					cell.moveToStart()
				} else {
					super.pressesBegan(presses, with: event)
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
		guard let index = row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: index, section: adjustedRowsSection)
		UIView.performWithoutAnimation {
			self.collectionView.reconfigureItems(at: [indexPath])
		}
		
		makeCursorVisibleIfNecessary()
	}
	
	func applyChanges(_ changes: OutlineElementChanges) {
		func performBatchUpdates() {
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
		
		if !changes.isOnlyReloads {
			if AppDefaults.shared.disableEditorAnimations {
				UIView.performWithoutAnimation {
					performBatchUpdates()
				}
			} else {
				performBatchUpdates()
			}
		}
		
		guard let reloads = changes.reloadIndexPaths, !reloads.isEmpty else { return }
		
		let hasSectionOtherThanRows = reloads.contains(where: { $0.section != adjustedRowsSection })
		
		if !hasSectionOtherThanRows {
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
		let selectedIndexPaths = collectionView.indexPathsForSelectedItems
		
		applyChanges(changes)

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

	func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates, scroll: Bool, centered: Bool = false) {
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
		
		if !collectionView.isVisible(indexPath: indexPath) {
			CATransaction.begin()
			CATransaction.setCompletionBlock {
				// Got to wait or the row cell won't be found
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					restoreCursor()
				}
			}
			if indexPath.row < collectionView.numberOfItems(inSection: indexPath.section) {
				let scrollPosition = centered ? UICollectionView.ScrollPosition.centeredVertically : []
				collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: false)
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
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
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
		if let outline {
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
	
	func buildRowsContextMenu(rows: [Row]) -> UIContextMenuConfiguration? {
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
			if !outline.isCreateNotesUnavailable(rows: rows) {
				outlineActions.append(self.createNoteAction(rows: rows))
			}
			if !outline.isDeleteNotesUnavailable(rows: rows) {
				outlineActions.append(self.deleteNoteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: outlineActions))

			var viewActions = [UIAction]()
			if rows.count == 1 {
				viewActions.append(self.focusInAction(rows: rows))
			}
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
		return UIAction(title: .cutControlLabel, image: .cut) { [weak self] action in
			guard let self else { return }
			self.cutRows(rows)
			self.delegate?.validateToolbar(self)
		}
	}

	func copyAction(rows: [Row]) -> UIAction {
		return UIAction(title: .copyControlLabel, image: .copy) { [weak self] action in
			self?.copyRows(rows)
		}
	}

	func pasteAction(rows: [Row]) -> UIAction {
		return UIAction(title: .pasteControlLabel, image: .paste) { [weak self] action in
			guard let self else { return }
			self.pasteRows(afterRows: rows)
			self.delegate?.validateToolbar(self)
		}
	}

	func addAction(rows: [Row]) -> UIAction {
		return UIAction(title: .addRowControlLabel, image: .add) { [weak self] action in
			// Have to let the text field get the first responder by getting it away from this
			// action which appears to be holding on to it.
			DispatchQueue.main.async {
				self?.createRow(afterRows: rows)
			}
		}
	}

	func duplicateAction(rows: [Row]) -> UIAction {
		return UIAction(title: .duplicateControlLabel, image: .duplicate) { [weak self] action in
			self?.duplicateRows(rows)
		}
	}

	func expandAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: .expandAllControlLabel, image: .expandAll) { [weak self] action in
			self?.expandAll(containers: rows)
		}
	}

	func collapseAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: .collapseAllControlLabel, image: .collapseAll) { [weak self] action in
			self?.collapseAll(containers: rows)
		}
	}

	func focusInAction(rows: [Row]) -> UIAction {
		return UIAction(title: .focusInControlLabel, image: .focusActive) { [weak self] action in
			guard let self else { return }
			self.outline?.focusIn(rows.first!)
			self.delegate?.validateToolbar(self)
		}
	}
	
	func completeAction(rows: [Row]) -> UIAction {
		return UIAction(title: .completeControlLabel, image: .completeRow) { [weak self] action in
			self?.completeRows(rows)
		}
	}
	
	func uncompleteAction(rows: [Row]) -> UIAction {
		return UIAction(title: .uncompleteControlLabel, image: .uncompleteRow) { [weak self] action in
			self?.uncompleteRows(rows)
		}
	}
	
	func createNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: .addNoteControlLabel, image: .noteAdd) { [weak self] action in
			self?.createRowNotes(rows)
		}
	}

	func deleteNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: .deleteNoteControlLabel, image: .delete, attributes: .destructive) { [weak self] action in
			self?.deleteRowNotes(rows)
		}
	}

	func deleteAction(rows: [Row]) -> UIAction {
		let title = rows.count == 1 ? String.deleteRowControlLabel : String.deleteRowsControlLabel
		return UIAction(title: title, image: .delete, attributes: .destructive) { [weak self] action in
			guard let self else { return }
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
		
		func moveCursorUpToNext(nextTopicTextView: EditorRowTopicTextView) {
			if let topicTextViewCursorRect = topicTextView.cursorRect {
				let convertedRect = topicTextView.convert(topicTextViewCursorRect, to: collectionView)
				let nextRect = nextTopicTextView.convert(convertedRect, from: collectionView)
				if let cursorPosition = nextTopicTextView.closestPosition(to: CGPoint(x: nextRect.midX, y: nextTopicTextView.bounds.height - 1)) {
					let cursorOffset = nextTopicTextView.offset(from: nextTopicTextView.beginningOfDocument, to: cursorPosition)
					let range = NSRange(location: cursorOffset, length: 0)
					nextTopicTextView.selectedRange = range
				}
			}
			makeCursorVisibleIfNecessary()
		}
		
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: adjustedRowsSection)
		
		// This is needed because the collection view might not have the cell built yet or the topic won't take the
		// first responder if it isn't visible.
		func scrollAndMoveCursorUpToNext() {
			if let frame = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame {
				let xHeight = "X".height(withConstrainedWidth: Double.infinity, font: topicTextView.font!)
				let totalHeight = xHeight + topicTextView.textContainerInset.top + topicTextView.textContainerInset.bottom
				let rect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: totalHeight)
				collectionView.scrollRectToVisibleBypass(rect, animated: true)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					if let nextTopicTextView = (self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView {
						nextTopicTextView.becomeFirstResponder()
						moveCursorUpToNext(nextTopicTextView: nextTopicTextView)
					}
				}
			}
		}

		if let nextTopicTextView = (self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView {
			if nextTopicTextView.becomeFirstResponder() {
				moveCursorUpToNext(nextTopicTextView: nextTopicTextView)
			} else {
				scrollAndMoveCursorUpToNext()
			}
		} else {
			scrollAndMoveCursorUpToNext()
		}
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
		
		let command = CreateTagCommand(actionName: .addTagControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		runCommand(command)
		moveCursorToTagInput()
	}

	func deleteTag(name: String) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DeleteTagCommand(actionName: .removeTagControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		runCommand(command)
	}
	
	func expand(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = ExpandCommand(actionName: .expandControlLabel,
									undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)
		
		runCommand(command)
	}

	func collapse(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let currentRow = currentTextView?.row
		
		let command = CollapseCommand(actionName: .collapseControlLabel,
									  undoManager: undoManager,
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
		
		let command = ExpandAllCommand(actionName: .expandAllControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   containers: containers)
		
		runCommand(command)
	}

	func collapseAll(containers: [RowContainer]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CollapseAllCommand(actionName: .collapseAllControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 containers: containers)

		runCommand(command)
	}

	func textChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = TextChangedCommand(actionName: .typingControlLabel,
										 undoManager: undoManager,
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

		let command = CutRowCommand(actionName: .cutControlLabel,
									undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)

		runCommand(command)
	}

	func copyRows(_ rows: [Row]) {
		var itemProviders = [NSItemProvider]()

		for row in rows.sortedWithDecendentsFiltered() {
			let itemProvider = NSItemProvider()

			// We need to create the RowGroup data before our data representation callback happens
			// because we might actually be cutting the data and it won't be available anymore at
			// the time that the callback happens.
			let data = try? RowGroup(row).asData()

			// We only register the text representation on the first one, since it looks like most text editors only support 1 dragged text item
			if row == rows[0] {
				itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { completion in
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
				completion(data, nil)
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
						if let data {
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
				let command = PasteRowCommand(actionName: .pasteControlLabel,
											  undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  rowGroups: rowGroups,
											  afterRow: afterRows?.last)

				self.runCommand(command)
			}
			
		} else if let stringProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [UTType.utf8PlainText.identifier]), !stringProviderIndexes.isEmpty {
			
			let group = DispatchGroup()
			var texts = [String]()
			
			for index in stringProviderIndexes {
				let itemProvider = UIPasteboard.general.itemProviders[index]
				group.enter()
				itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier) { (data, error) in
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
					let row = Row(outline: outline, topicMarkdown: textRow.trimmed())
					row.detectData()
					rowGroups.append(RowGroup(row))
				}
				
				let command = PasteRowCommand(actionName: .pasteControlLabel,
											  undoManager: undoManager,
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

		let command = DeleteRowCommand(actionName: .deleteRowsControlLabel,
									   undoManager: undoManager,
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

		let command = CreateRowBeforeCommand(actionName: .addRowControlLabel,
											 undoManager: undoManager,
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
		
		let command = CreateRowAfterCommand(actionName: .addRowAfterControlLabel,
											undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											rowStrings: rowStrings)
		
		runCommand(command)
		
		// We won't get the cursor to move from the tag to the new row on return without dispatching
		DispatchQueue.main.async {
			if let newCursorIndex = command.newCursorIndex {
				let newCursorIndexPath = IndexPath(row: newCursorIndex, section: self.adjustedRowsSection)
				if let rowCell = self.collectionView.cellForItem(at: newCursorIndexPath) as? EditorRowViewCell {
					rowCell.moveToEnd()
				}
			}

			self.makeCursorVisibleIfNecessary(animated: false)
		}
		
	}
	
	func createRowInside(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		scrollRowToShowBottom()
		
		guard let afterRow = afterRows?.sortedByDisplayOrder().last else { return }
		
		let command = CreateRowInsideCommand(actionName: .addRowInsideControlLabel,
											 undoManager: undoManager,
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

		makeCursorVisibleIfNecessary(animated: false)
	}
	
	func createRowOutside(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		scrollRowToShowBottom()
		
		guard let afterRow = afterRows?.sortedByDisplayOrder().last else { return }
		
		let command = CreateRowOutsideCommand(actionName: .addRowOutsideControlLabel,
											  undoManager: undoManager,
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
		
		makeCursorVisibleIfNecessary(animated: false)
	}
	
	func duplicateRows(_ rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DuplicateRowCommand(actionName: .duplicateControlLabel,
										  undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows)
		
		runCommand(command)
	}
	
	func moveRowsLeft(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowLeftCommand(actionName: .moveLeftControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 rows: rows,
										 rowStrings: rowStrings)
		
		runCommand(command)
	}

	func moveRowsRight(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowRightCommand(actionName: .moveRightControlLabel,
										  undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows,
										  rowStrings: rowStrings)
		
		runCommand(command)
	}

	func moveRowsUp(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowUpCommand(actionName: .moveUpControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   rowStrings: rowStrings)
		
		runCommand(command)
		makeCursorVisibleIfNecessary()
	}

	func moveRowsDown(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = MoveRowDownCommand(actionName: .moveDownControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 rows: rows,
										 rowStrings: rowStrings)
		
		runCommand(command)
		makeCursorVisibleIfNecessary()
	}

	func splitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = SplitRowCommand(actionName: .splitRowControlLabel,
									  undoManager: undoManager,
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
		
		let cursorIsInCompletingRows = rows.contains(where: { $0 == currentTextView?.row })
		
		let command = CompleteCommand(actionName: .completeControlLabel,
									  undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows,
									  rowStrings: rowStrings)
		
		runCommand(command)

		guard cursorIsInCompletingRows && isCompletedFiltered else { return }
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func uncompleteRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = UncompleteCommand(actionName: .uncompleteControlLabel,
										undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		runCommand(command)
	}
	
	func createRowNotes(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateNoteCommand(actionName: .addNoteControlLabel,
										undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex ?? rows.first?.shadowTableIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
				// This fixes the problem of not moving to the note on iOS when adding a note
				DispatchQueue.main.async {
					rowCell.moveToNote()
				}
			}
		}

		makeCursorVisibleIfNecessary(animated: false)
	}

	func deleteRowNotes(_ rows: [Row], rowStrings: RowStrings? = nil) {
		// If the user is currently editing a note and wants to delete it, the text view will try to save
		// its current contents to the row after the note data was already cleared.
		if let noteTextView = currentTextView as? EditorRowNoteTextView {
			noteTextView.isSavingTextUnnecessary = true
		}
		
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = DeleteNoteCommand(actionName: .deleteNoteControlLabel,
										undoManager: undoManager,
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

	func makeCursorVisibleIfNecessary(animated: Bool = true) {
		guard let textInput = UIResponder.currentFirstResponder as? UITextInput,
			  let cursorRect = textInput.cursorRect else { return }
		
		scrollToVisible(textInput: textInput, rect: cursorRect, animated: animated)
	}
	
	func scrollToVisible(textInput: UITextInput, rect: CGRect, animated: Bool) {
		guard var convertedRect = (textInput as? UIView)?.convert(rect, to: collectionView) else { return }
		
		// This isInNotes hack isn't well understood, but it improves the user experience...
		if textInput is EditorRowNoteTextView {
			convertedRect.size.height = convertedRect.size.height + 10
		}
		
		collectionView.scrollRectToVisibleBypass(convertedRect, animated: animated)
	}

	func updateSpotlightIndex() {
		if let outline {
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
		
		let refString = references.count == 1 ? String.referenceLabel : String.referencesLabel
		let result = NSMutableAttributedString(string: "\(refString)")
		result.append(references[0])
		
		for i in 1..<references.count {
			result.append(NSAttributedString(string: ", "))
			result.append(references[i])
		}
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.font] = OutlineFontCache.shared.backlinkFont
		attrs[.foregroundColor] = OutlineFontCache.shared.backlinkColor
		result.addAttributes(attrs)
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
