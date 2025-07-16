//
//  EditorViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import MobileCoreServices
import PhotosUI
import AsyncAlgorithms
import VinOutlineKit
import VinUtility

extension Selector {
	static let copyRowLink = #selector(EditorViewController.copyRowLink(_:))
	static let insertImage = #selector(EditorViewController.insertImage(_:))
	static let insertReturn = #selector(EditorViewController.insertReturn(_:))

	static let focusIn = #selector(EditorViewController.focusIn(_:))
	static let focusOut = #selector(EditorViewController.focusOut(_:))
	static let toggleFocus = #selector(EditorViewController.toggleFocus(_:))
	
	static let toggleFilterOn = #selector(EditorViewController.toggleFilterOn(_:))
	static let toggleCompletedFilter = #selector(EditorViewController.toggleCompletedFilter(_:))
	static let toggleNotesFilter = #selector(EditorViewController.toggleNotesFilter(_:))
	
	static let expandAllInOutline = #selector(EditorViewController.expandAllInOutline(_:))
	static let collapseAllInOutline = #selector(EditorViewController.collapseAllInOutline(_:))
	static let expandAll = #selector(EditorViewController.expandAll(_:))
	static let collapseAll = #selector(EditorViewController.collapseAll(_:))
	static let expand = #selector(EditorViewController.expand(_:))
	static let collapse = #selector(EditorViewController.collapse(_:))
	static let collapseParentRow = #selector(EditorViewController.collapseParentRow(_:))
	
	static let addRowAbove = #selector(EditorViewController.addRowAbove(_:))
	static let addRowBelow = #selector(EditorViewController.addRowBelow(_:))
	static let createRowInside = #selector(EditorViewController.createRowInside(_:))
	static let createRowOutside = #selector(EditorViewController.createRowOutside(_:))
	static let duplicateCurrentRows = #selector(EditorViewController.duplicateCurrentRows(_:))
	static let deleteCurrentRows = #selector(EditorViewController.deleteCurrentRows(_:))
	static let groupCurrentRows = #selector(EditorViewController.groupCurrentRows(_:))
	static let sortCurrentRows = #selector(EditorViewController.sortCurrentRows(_:))
	static let moveCurrentRowsLeft = #selector(EditorViewController.moveCurrentRowsLeft(_:))
	static let moveCurrentRowsRight = #selector(EditorViewController.moveCurrentRowsRight(_:))
	static let moveCurrentRowsUp = #selector(EditorViewController.moveCurrentRowsUp(_:))
	static let moveCurrentRowsDown = #selector(EditorViewController.moveCurrentRowsDown(_:))
	static let toggleCompleteRows = #selector(EditorViewController.toggleCompleteRows(_:))
	static let deleteCompletedRows = #selector(EditorViewController.deleteCompletedRows(_:))
	static let toggleRowNotes = #selector(EditorViewController.toggleRowNotes(_:))
	static let createOrDeleteNotes = #selector(EditorViewController.createOrDeleteNotes(_:))
	static let deleteRowNotes = #selector(EditorViewController.deleteRowNotes(_:))
	
	static let undo = Selector(("undo:"))
	static let redo = Selector(("redo:"))
	static let showUndoMenu = #selector(EditorViewController.showUndoMenu(_:))
	static let showFormatMenu = #selector(EditorViewController.showFormatMenu(_:))
	
	static let editorLink = #selector(EditorViewController.editorLink(_:))
	static let editorToggleBoldface = #selector(EditorViewController.editorToggleBoldface(_:))
	static let editorToggleItalics = #selector(EditorViewController.editorToggleItalics(_:))
}

@MainActor
protocol EditorDelegate: AnyObject {
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

class EditorViewController: UIViewController, DocumentsActivityItemsConfigurationDelegate, MainControllerIdentifiable {

	static var focusGroupIdentifier: String? = "io.vincode.Zavala.EditorViewController"

	private static let searchBarHeight: CGFloat = 44
	
	var collectionView: EditorCollectionView!
	
	override var keyCommands: [UIKeyCommand]? {
		var keyCommands = [UIKeyCommand]()
		
		if isEditingTopic {
			let shiftTab = UIKeyCommand(input: "\t", modifierFlags: [.shift], action: .moveCurrentRowsLeft)
			shiftTab.wantsPriorityOverSystemBehavior = true
			keyCommands.append(shiftTab)
			
			let tab = UIKeyCommand(action: .moveCurrentRowsRight, input: "\t")
			tab.wantsPriorityOverSystemBehavior = true
			keyCommands.append(tab)
		}
		
		// We need to have this here in addition to the AppDelegate, since iOS won't pick it up for some reason
		if UIResponder.valid(action: .toggleCompleteRows) {
			let commandReturn = UIKeyCommand(input: "\r", modifierFlags: [.command], action: .toggleCompleteRows)
			commandReturn.wantsPriorityOverSystemBehavior = true
			keyCommands.append(commandReturn)
		}

		keyCommands.append(UIKeyCommand(action: #selector(toggleMode), input: UIKeyCommand.inputEscape))

		return keyCommands
	}
	
	var selectedDocuments: [VinOutlineKit.Document] {
		guard let outline else { return []	}
		return [Document.outline(outline)]
	}
	
	nonisolated var mainControllerIdentifer: MainControllerIdentifier { return .editor }

	weak var delegate: EditorDelegate?
	
	var isOutlineFunctionsUnavailable: Bool {
		return outline == nil
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
	
	var isCreateRowNotesUnavailable: Bool {
		guard let outline, let rows = currentRows else { return true }
		return outline.isCreateNotesUnavailable(rows: rows)
	}

	var isDeleteRowNotesUnavailable: Bool {
		guard let outline, let rows = currentRows else { return true }
		return outline.isDeleteNotesUnavailable(rows: rows)
	}

	var isInsertNewlineUnavailable: Bool {
		return currentTextView == nil
	}

	var currentRows: [Row]? {
		if let selected = collectionView?.indexPathsForSelectedItems?.sorted(), !selected.isEmpty {
			return selected.compactMap {
				if $0.row < outline?.shadowTable?.count ?? 0 {
					return outline?.shadowTable?[$0.row]
				} else {
					return nil
				}
			}
		} else if let currentRowID = currentTextView?.rowID, let currentRow = outline?.findRow(id: currentRowID) {
			return [currentRow]
		}
		return nil
	}
	
	var isInOutlineMode: Bool {
		return !(collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
	}
	
	var isInEditMode: Bool {
		if let responder = UIResponder.currentFirstResponder, responder is UITextField || responder is UITextView {
			return true
		} else {
			return false
		}
	}
	
	var isEditingTopic: Bool {
		if let responder = UIResponder.currentFirstResponder, responder is EditorRowTopicTextView {
			return true
		} else {
			return false
		}
	}
	
	var isEditingNote: Bool {
		if let responder = UIResponder.currentFirstResponder, responder is EditorRowNoteTextView {
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
	var isFocusing: Bool {
		guard let outline else { return false }
		return outline.focusRow != nil
	}
	
	var adjustedRowsSection: Int {
		return outline?.adjustedRowsSection.rawValue ?? Outline.Section.rows.rawValue
	}
	
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
	
	private var cancelledKeys = Set<UIKey>()

	private static var slowRepeatInterval = 1.0
	private static var fastRepeatInterval = 0.1
	
	private var isGoingUp = false
	private var isGoingDown = false
	private lazy var goingUpRepeatInterval: Double = Self.slowRepeatInterval
	private lazy var goingDownRepeatInterval: Double = Self.slowRepeatInterval
	private var goingUpOrDownTask: Task<(()), Never>?
	private var savedCursorRectForUpAndDownArrowing: CGRect?
	private var shiftStartIndex: Int?
	
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
	
	private var updateTitleChannel = AsyncChannel<String>()

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
	
	private lazy var findInteraction = UIFindInteraction(sessionDelegate: self)
	
	private lazy var transition = ImageTransition(delegate: self)
	private var imageBlocker: UIView?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		collectionView = EditorCollectionView(frame: .zero, collectionViewLayout: createLayout())
		collectionView.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(collectionView)
		
		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: view.topAnchor),
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
			collectionView.refreshControl!.tintColor = .clear
		}

		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.dragInteractionEnabled = true
		collectionView.allowsMultipleSelection = true
		collectionView.allowsFocus = true
		collectionView.selectionFollowsFocus = true
		collectionView.focusGroupIdentifier = EditorViewController.focusGroupIdentifier
		collectionView.contentInset = EditorViewController.defaultContentInsets
		collectionView.addInteraction(findInteraction)

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
			cell.isSearching = self?.isSearching ?? false
			cell.delegate = self
			cell.setNeedsUpdateConfiguration()
		}
		
		backlinkRegistration = UICollectionView.CellRegistration<EditorBacklinkViewCell, Outline> { [weak self] (cell, indexPath, outline) in
			cell.reference = self?.generateBacklinkVerbaige(outline: outline)
		}

		configureButtonBars(size: view.bounds.size)
		updateUI()
		collectionView.reloadData()

		restoreScrollPosition()
		restoreOutlineCursorPosition()
		
		NotificationCenter.default.addObserver(self, selector: #selector(outlineFontCacheDidRebuild(_:)), name: .OutlineFontCacheDidRebuild, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineElementsDidChange(_:)), name: .OutlineElementsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineSearchWillBegin(_:)), name: .OutlineSearchWillBegin, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineSearchResultDidChange(_:)), name: .OutlineSearchResultDidChange, object: nil)
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
		
		Task {
			for await title in updateTitleChannel.debounce(for: .seconds(1)) {
				outline?.update(title: title)
			}
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
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
		
		if let currentRows {
			cutRows(currentRows)
		}
	}
	
	override func copy(_ sender: Any?) {
		navButtonGroup?.dismissPopOverMenu()
		
		if let currentRows {
			copyRows(currentRows)
		}
	}
	
	override func paste(_ sender: Any?) {
		navButtonGroup?.dismissPopOverMenu()
		pasteRows(afterRows: currentRows)
	}

	override func delete(_ sender: Any?) {
		deleteCurrentRows(sender)
	}

	override func find(_ sender: Any?) {
		showFindInteraction()
	}
	
	override func findAndReplace(_ sender: Any?) {
		showFindInteraction(replace: true)
	}
	
	override func findNext(_ sender: Any?) {
		findInteraction.findNext()
	}
	
	override func findPrevious(_ sender: Any?) {
		findInteraction.findPrevious()
	}
	
	override func useSelectionForFind(_ sender: Any?) {
		showFindInteraction(text: currentTextView?.selectedText)
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .selectAll:
			return !isSelectAllRowsUnavailable
		case .cut, .copy, .delete:
			return !(collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
		case .paste:
			return UIPasteboard.general.contains(pasteboardTypes: [UTType.utf8PlainText.identifier, Row.typeIdentifier])
		case .find, .findAndReplace, .findNext, .findPrevious, .useSelectionForFind:
			if outline == nil {
				return false
			} else {
				return super.canPerformAction(action, withSender: sender)
			}
		case .copyRowLink:
			return currentRows?.count == 1
		case .insertImage, .insertReturn:
			return currentTextView != nil
		case .focusIn:
			return currentRows?.count == 1
		case .focusOut:
			return !(outline?.isFocusOutUnavailable() ?? true)
		case .toggleFocus:
			if isFocusing {
				return true
			} else {
				return currentRows?.count == 1
			}
		case .toggleFilterOn:
			return outline != nil
		case .toggleCompletedFilter, .toggleNotesFilter:
			return isFilterOn
		case .expandAllInOutline:
			if let outline, !outline.isExpandAllInOutlineUnavailable {
				return true
			} else {
				return false
			}
		case .collapseAllInOutline:
			if let outline, !outline.isCollapseAllInOutlineUnavailable {
				return true
			} else {
				return false
			}
		case .expandAll:
			if let outline, let currentRows, !outline.isExpandAllUnavailable(containers: currentRows) {
				return true
			} else {
				return false
			}
		case .collapseAll:
			if let outline, let currentRows, !outline.isCollapseAllUnavailable(containers: currentRows) {
				return true
			} else {
				return false
			}
		case .expand:
			if let currentRows {
				for row in currentRows {
					if !row.isExpandable {
						return false
					}
				}
				return true
			} else {
				return false
			}
		case .collapse:
			if let currentRows {
				for row in currentRows {
					if !row.isCollapsable {
						return false
					}
				}
				return true
			} else {
				return false
			}
		case .collapseParentRow:
			if let currentRows {
				for row in currentRows {
					if !((row.parent as? Row)?.isCollapsable ?? false) {
						return false
					}
				}
				return true
			} else {
				return false
			}
		case .addRowAbove, .addRowBelow, .createRowInside, .duplicateCurrentRows, .deleteCurrentRows:
			return currentRows != nil
		case .createRowOutside:
			if let outline, let currentRows, !outline.isCreateRowOutsideUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .groupCurrentRows:
			if let outline, let currentRows, !outline.isGroupRowsUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .sortCurrentRows:
			if let outline, let currentRows, !outline.isSortRowsUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .moveCurrentRowsLeft:
			if let outline, let currentRows, !outline.isMoveRowsLeftUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .moveCurrentRowsRight:
			if let outline, let currentRows, !outline.isMoveRowsRightUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .moveCurrentRowsUp:
			if let outline, let currentRows, !outline.isMoveRowsUpUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .moveCurrentRowsDown:
			if let outline, let currentRows, !outline.isMoveRowsDownUnavailable(rows: currentRows) {
				return true
			} else {
				return false
			}
		case .toggleCompleteRows:
			if let outline, let currentRows, !(outline.isCompleteUnavailable(rows: currentRows) && outline.isUncompleteUnavailable(rows: currentRows)) {
				return true
			} else {
				return false
			}
		case .deleteCompletedRows:
			return outline?.isAnyRowCompleted ?? false
		case .toggleRowNotes:
			return isInEditMode
		case .deleteRowNotes:
			return !isDeleteRowNotesUnavailable
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
	override func validate(_ command: UICommand) {
		switch command.action {
		case .duplicateCurrentRows:
			if currentRows?.count ?? 0 > 1 {
				command.title = .duplicateRowsControlLabel
			} else {
				command.title = .duplicateRowControlLabel
			}
		case .groupCurrentRows:
			if currentRows?.count ?? 0 > 1 {
				command.title = .groupRowsControlLabel
			} else {
				command.title = .groupRowControlLabel
			}
		case .deleteCurrentRows:
			if currentRows?.count ?? 0 > 1 {
				command.title = .deleteRowsControlLabel
			} else {
				command.title = .deleteRowControlLabel
			}
		case .toggleCompleteRows:
			if  let outline, let currentRows, !outline.isCompleteUnavailable(rows: currentRows) {
				command.title = .completeControlLabel
			} else {
				command.title = .uncompleteControlLabel
			}
		case .toggleRowNotes:
			if isCreateRowNotesUnavailable {
				if isEditingTopic {
					command.title = .jumpToNoteControlLabel
				} else if isEditingNote {
					command.title = .jumpToTopicControlLabel
				} else {
					command.title = .addNoteControlLabel
				}
			} else {
				command.title = .addNoteControlLabel
			}
		case .toggleFilterOn:
			if isFilterOn {
				command.title = .turnFilterOffControlLabel
			} else {
				command.title = .turnFilterOnControlLabel
			}
		case .toggleCompletedFilter:
			if isCompletedFiltered {
				command.state = .on
			} else {
				command.state = .off
			}
		case .toggleNotesFilter:
			if isNotesFiltered {
				command.state = .on
			} else {
				command.state = .off
			}
		default:
			break
		}
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if collectionView.indexPathsForSelectedItems?.isEmpty ?? true {
			pressesBeganForEditMode(presses, with: event)
		} else {
			pressesBeganForOutlineMode(presses, with: event)
		}
	}
	
	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesEnded(presses, with: event)
		for press in presses {
			if let key = press.key {
				if key.keyCode == .keyboardUpArrow {
					isGoingUp = false
				}
				if key.keyCode == .keyboardDownArrow {
					isGoingDown = false
				}
				
				if key.modifierFlags.contains(.control) && key.keyCode == .keyboardP {
					isGoingUp = false
				}
				if key.modifierFlags.contains(.control) && key.keyCode == .keyboardN {
					isGoingDown = false
				}
				
				if key.keyCode == .keyboardLeftShift || key.keyCode == .keyboardRightShift {
					shiftStartIndex = nil
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
	
	@objc nonisolated func userDefaultsDidChange() {
		Task { @MainActor in
			if rowIndentSize != AppDefaults.shared.rowIndentSize {
				rowIndentSize = AppDefaults.shared.rowIndentSize
				collectionView.reloadData()
			}
			
			if rowSpacingSize != AppDefaults.shared.rowSpacingSize {
				rowSpacingSize = AppDefaults.shared.rowSpacingSize
				collectionView.reloadData()
			}

			guard let layout = self.collectionView.collectionViewLayout as? EditorCollectionViewCompositionalLayout else { return }
			if layout.editorMaxWidth != AppDefaults.shared.editorMaxWidth.points {
				layout.editorMaxWidth = AppDefaults.shared.editorMaxWidth.points
				self.collectionView.reloadData()
			}
		}
	}
	
	@objc func outlineTextPreferencesDidChange(_ note: Notification) {
		if note.object as? Outline == outline {
			collectionView.reloadData()
		}
	}
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let document = note.object as? VinOutlineKit.Document,
			  let updatedOutline = document.outline,
			  updatedOutline == outline,
			  currentTitle != outline?.title,
			  collectionView.numberOfSections > Outline.Section.title.rawValue,
			  collectionView.numberOfItems(inSection: Outline.Section.title.rawValue) > 0 else { return }
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
	}
	
	@objc func outlineSearchResultDidChange(_ note: Notification) {
		scrollSearchResultIntoView()
	}
	
	@objc func outlineSearchWillEnd(_ note: Notification) {
		guard note.object as? Outline == outline else { return }
		
		// If a user changed the outline without dismissing find interaction, then
		// this will get set to false in the edit function so that we don't try
		// to insert the header and footer sections, preventing a crash.
		guard isSearching else { return	}
		
		isSearching = false
		collectionView.insertSections(headerFooterSections)
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
			UIView.animate(withDuration: 0.25) {
				self.collectionView.contentInset = EditorViewController.defaultContentInsets
			}
			currentKeyboardHeight = 0
		} else {
			let newInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
			if collectionView.contentInset != newInsets {
				collectionView.contentInset = newInsets
			}
			scrollCursorToVisible()
			currentKeyboardHeight = keyboardViewEndFrame.height
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
	
	func open(_ newOutline: Outline?, searchText: String? = nil) {
		guard outline != newOutline else {
			if let newOutline {
				reload(newOutline)
			}
			return
		}
		
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
		
		Task.detached {
			await self.updateSpotlightIndex()
		}
		
		// After this point as long as we don't have this Outline open in other
		// windows, no more collection view updates should happen for it.
		outline?.decrementBeingViewedCount()
		
		// End the search collection view updates early
		if isSearching {
			isSearching = false // Necessary to prevent crashing while switching outlines during a find session
			findInteraction.dismissFindNavigator()
		}
		
		let oldOutline = outline
		Task.detached {
			await oldOutline?.unload()
		}
		undoManager?.removeAllActions()
	
		// Assign the new Outline and load it
		outline = newOutline
		
		// Don't continue if we are just clearing out the editor
		guard let outline else {
			guard isViewLoaded else { return }
			updateUI()
			collectionView.reloadData()
			return
		}

		outline.load()
		outline.incrementBeingViewedCount()
		checkForCorruptOutline()
		outline.prepareForViewing()
			
		guard isViewLoaded else { return }

		updateNavigationMenus()
		collectionView.reloadData()
		
		// If we don't have this delay, when switching between documents in the documents view, while searching,
		// causes the find interaction to glitch out. This is especially true on macOS. We could have a shorter
		// duration on iOS, but I don't see the need to complicate the code.
		if let searchText {
			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.5))
				self.showFindInteraction(text: searchText)
			}
			return
		}

		updateUI()
	}
	
	func edit(isNew: Bool = false, selectRow: EntityID? = nil) {
		guard !isNew else {
			moveCursorToTitleOnNew()
			return
		}
		
		guard isViewLoaded, let outline else { return }
		
		if let selectRow {
			guard let index = outline.shadowTable?.first(where: { $0.entityID == selectRow })?.shadowTableIndex else { return }
			collectionView.selectItem(at: IndexPath(row: index, section: adjustedRowsSection), animated: false, scrollPosition: [.centeredVertically])
		} else {
			restoreScrollPosition()
			restoreOutlineCursorPosition()
		}
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
				Task { @MainActor in
					delegate.goBackward(self, to: index)
				}
			})
		}
		goBackwardButton.menu = UIMenu(title: "", children: backwardItems)

		var forwardItems = [UIAction]()
		for (index, pin) in delegate.editorViewControllerGoForwardStack.enumerated() {
			forwardItems.append(UIAction(title: pin.document?.title ?? .noTitleLabel) { [weak self] _ in
				guard let self else { return }
				Task { @MainActor in
					delegate.goForward(self, to: index)
				}
			})
		}
		goForwardButton.menu = UIMenu(title: "", children: forwardItems)
	}
	
	func updateUI() {
		guard traitCollection.userInterfaceIdiom != .mac else {
			delegate?.validateToolbar(self)
			return
		}
		
		navigationItem.largeTitleDisplayMode = .never
		moreMenuButton.menu = buildEllipsisMenu()
		
		if !(outline?.isFocusOutUnavailable() ?? true) {
			focusButton.accessibilityLabel = .focusOutControlLabel
			focusButton.setImage(.focusActive, for: .normal)
			focusButton.isEnabled = true
		} else {
			focusButton.accessibilityLabel = .focusInControlLabel
			focusButton.setImage(.focusInactive, for: .normal)
			if currentRows?.count ?? 0 == 1 {
				focusButton.isEnabled = true
			} else {
				focusButton.isEnabled = false
			}
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
		
		goBackwardButton.isEnabled = !(delegate?.editorViewControllerGoBackwardStack.isEmpty ?? false)
		goForwardButton.isEnabled = !(delegate?.editorViewControllerGoForwardStack.isEmpty ?? false)
		
		undoButton.isEnabled = UIResponder.valid(action: .undo)
		cutButton.isEnabled = UIResponder.valid(action: .cut)
		copyButton.isEnabled = UIResponder.valid(action: .copy)
		pasteButton.isEnabled = UIResponder.valid(action: .paste)
		redoButton.isEnabled = UIResponder.valid(action: .redo)
		
		moveLeftButton.isEnabled = UIResponder.valid(action: .moveCurrentRowsLeft)
		moveRightButton.isEnabled = UIResponder.valid(action: .moveCurrentRowsRight)
		moveUpButton.isEnabled = UIResponder.valid(action: .moveCurrentRowsUp)
		moveDownButton.isEnabled = UIResponder.valid(action: .moveCurrentRowsDown)
		
		insertImageButton.isEnabled =  UIResponder.valid(action: .insertImage)
		linkButton.isEnabled = UIResponder.valid(action: .editLink)
		boldButton.isEnabled = UIResponder.valid(action: .toggleBoldface)
		italicButton.isEnabled = UIResponder.valid(action: .toggleItalics)
		
		// Because these items are in the Toolbar, they shouldn't ever be disabled. We will
		// only have one row selected at a time while editing and that row either has a note
		// or it doesn't.
		if let outline, let currentRows, !outline.isCreateNotesUnavailable(rows: currentRows) {
			noteButton.isEnabled = true
			noteButton.setImage(.noteAdd, for: .normal)
			noteButton.accessibilityLabel = .addNoteControlLabel
		} else {
			noteButton.isEnabled = true
			noteButton.setImage(.noteDelete, for: .normal)
			noteButton.accessibilityLabel = .deleteNoteControlLabel
		}
		
		insertNewlineButton.isEnabled = !isInsertNewlineUnavailable
		
	}
	
	func moveCursorToCurrentRowTopic() {
		guard let rowShadowTableIndex = currentRows?.last?.shadowTableIndex,
			  let currentRowViewCell = collectionView.cellForItem(at: IndexPath(row: rowShadowTableIndex, section: adjustedRowsSection)) as? EditorRowViewCell else { return }
		currentRowViewCell.moveToTopicEnd()
	}
	
	func moveCursorToCurrentRowNote() {
		guard let rowShadowTableIndex = currentRows?.last?.shadowTableIndex,
			  let currentRowViewCell = collectionView.cellForItem(at: IndexPath(row: rowShadowTableIndex, section: adjustedRowsSection)) as? EditorRowViewCell else { return }
		currentRowViewCell.moveToNoteEnd()
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
		guard let outline, outline.rowCount == 0 else { return }
		createRow(afterRows: nil)
	}
	
	@objc func sync() {
		if appDelegate.accountManager.isSyncAvailable {
			Task {
				await appDelegate.accountManager.sync()
			}
		}
		collectionView?.refreshControl?.endRefreshing()
	}
	
	@objc func hideKeyboard() {
		UIResponder.currentFirstResponder?.resignFirstResponder()
		CursorCoordinates.clearLastKnownCoordinates()
	}
	
	@objc func toggleMode() {
		let currentFirstResponder = UIResponder.currentFirstResponder
		
		if currentFirstResponder is EditorTitleTextView || currentFirstResponder is EditorTagInputTextField {
			currentFirstResponder?.resignFirstResponder()
			return
		}
		
		if let topicView = currentFirstResponder as? EditorRowTopicTextView,
		   let rowID = topicView.rowID,
		   let row = outline?.findRow(id: rowID),
		   let shadowTableIndex = row.shadowTableIndex {
			_ = topicView.resignFirstResponder()
			collectionView.selectItem(at: IndexPath(row: shadowTableIndex, section: adjustedRowsSection), animated: true, scrollPosition: [])
		} else {
			moveCursorToCurrentRowTopic()
		}
	}

	@objc func copyRowLink(_ sender: Any?) {
		guard let entityID = currentRows?.first?.entityID else { return }
		UIPasteboard.general.url = entityID.url
	}

	@objc func insertImage(_ sender: Any?) {
		var config = PHPickerConfiguration()
		config.filter = PHPickerFilter.images
		config.selectionLimit = 1

		let pickerViewController = PHPickerViewController(configuration: config)
		pickerViewController.delegate = self
		self.present(pickerViewController, animated: true, completion: nil)
	}
	
	@objc func focusIn(_ sender: Any?) {
		guard let row = currentRows?.first else { return }
		outline?.focusIn(row)
	}
	
	@objc func focusOut(_ sender: Any?) {
		outline?.focusOut()
	}

	@objc func toggleFocus(_ sender: Any?) {
		if isFocusing {
			focusOut(sender)
		} else {
			focusIn(sender)
		}
	}

	@objc func toggleFilterOn(_ sender: Any?) {
		guard let changes = outline?.toggleFilterOn() else { return }
		applyChangesRestoringState(changes)
		updateUI()
	}
	
	@objc func toggleCompletedFilter(_ sender: Any?) {
		guard let changes = outline?.toggleCompletedFilter() else { return }
		applyChangesRestoringState(changes)
		updateUI()
	}
	
	@objc func toggleNotesFilter(_ sender: Any?) {
		guard let changes = outline?.toggleNotesFilter() else { return }
		applyChangesRestoringState(changes)
		updateUI()
	}
		
	@objc func expandAllInOutline(_ sender: Any?) {
		guard let outline else { return }
		expandAll(containers: [outline])
	}
	
	@objc func collapseAllInOutline(_ sender: Any?) {
		guard let outline else { return }
		collapseAll(containers: [outline])
	}
	
	@objc func expandAll(_ sender: Any?) {
		guard let rows = currentRows else { return }
		expandAll(containers: rows)
	}
	
	@objc func collapseAll(_ sender: Any?) {
		guard let rows = currentRows else { return }
		collapseAll(containers: rows)
	}
	
	@objc func expand(_ sender: Any?) {
		guard let rows = currentRows else { return }
		expand(rows: rows)
	}
	
	@objc func collapse(_ sender: Any?) {
		guard let rows = currentRows else { return }
		collapse(rows: rows)
	}
	
	@objc func collapseParentRow(_ sender: Any?) {
		guard let rows = currentRows else { return }
		let parentRows = rows.compactMap { $0.parent as? Row }
		guard !parentRows.isEmpty else { return }
		collapse(rows: parentRows)
	}
	
	@objc func addRowAbove(_ sender: Any?) {
		guard let rows = currentRows else { return }
		createRow(beforeRows: rows, moveCursor: true)
	}
	
	@objc func addRowBelow(_ sender: Any?) {
		guard let rows = currentRows else { return }
		createRow(afterRows: rows)
	}
	
	@objc func createRowInside(_ sender: Any?) {
		guard let rows = currentRows else { return }
		createRowInside(afterRows: rows)
	}
	
	@objc func createRowOutside(_ sender: Any?) {
		guard let rows = currentRows else { return }
		createRowOutside(afterRows: rows)
	}
	
	@objc func duplicateCurrentRows(_ sender: Any?) {
		guard let rows = currentRows else { return }
		duplicateRows(rows)
	}
	
	@objc func deleteCurrentRows(_ sender: Any?) {
		guard let rows = currentRows else { return }
		deleteRows(rows)
	}
	
	@objc func moveCurrentRowsLeft(_ sender: Any?) {
		guard let rows = currentRows else { return }
		moveRowsLeft(rows)
	}
	
	@objc func moveCurrentRowsRight(_ sender: Any?) {
		guard let rows = currentRows else { return }
		moveRowsRight(rows)
	}
	
	@objc func moveCurrentRowsUp(_ sender: Any?) {
		guard let rows = currentRows else { return }
		moveRowsUp(rows)
	}
	
	@objc func moveCurrentRowsDown(_ sender: Any?) {
		guard let rows = currentRows else { return }
		moveRowsDown(rows)
	}

	@objc func groupCurrentRows(_ sender: Any?) {
		guard let rows = currentRows else { return }
		groupRows(rows)
	}
	
	@objc func sortCurrentRows(_ sender: Any?) {
		guard let rows = currentRows else { return }
		sortRows(rows)
	}
	
	@objc func toggleCompleteRows(_ sender: Any?) {
		guard let outline, let rows = currentRows else { return }
		if !outline.isCompleteUnavailable(rows: rows) {
			completeRows(rows)
		} else if !outline.isUncompleteUnavailable(rows: rows) {
			uncompleteRows(rows)
		}
	}
	
	@objc func deleteCompletedRows(_ sender: Any?) {
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
	
	@objc func toggleRowNotes(_ sender: Any?) {
		guard let outline, let currentRows else { return }
		
		if outline.isCreateNotesUnavailable(rows: currentRows) {
			if isEditingTopic {
				moveCursorToCurrentRowNote()
			} else if isEditingNote {
				moveCursorToCurrentRowTopic()
			}
		} else {
			createRowNotes(currentRows)
		}
	}

	@objc func createOrDeleteNotes(_ sender: Any?) {
		guard let currentRows else { return }

		if isDeleteRowNotesUnavailable {
			createRowNotes(currentRows, rowStrings: currentRowStrings)
		} else {
			deleteRowNotes(currentRows, rowStrings: currentRowStrings)
		}
	}
	
	@objc func deleteRowNotes(_ sender: Any?) {
		guard let rows = currentRows else { return }
		deleteRowNotes(rows, rowStrings: currentRowStrings)
	}

	@objc func insertReturn(_ sender: Any?) {
		currentTextView?.insertNewline(self)
	}
	
	@objc func editorLink(_ sender: Any?) {
		rightToolbarButtonGroup.dismissPopOverMenu()
		currentTextView?.editLink(self)
	}

	@objc func editorToggleBoldface(_ sender: Any? = nil) {
		rightToolbarButtonGroup.dismissPopOverMenu()
		currentTextView?.toggleBoldface(self)
	}
	
	@objc func editorToggleItalics(_ sender: Any? = nil) {
		rightToolbarButtonGroup.dismissPopOverMenu()
		currentTextView?.toggleItalics(self)
	}
	
	func share(sourceView: UIView? = nil) {
		let controller = UIActivityViewController(activityItemsConfiguration: DocumentsActivityItemsConfiguration(delegate: self))
		if let sourceView {
			controller.popoverPresentationController?.sourceView = sourceView
		} else {
			controller.popoverPresentationController?.sourceView = collectionView
			var rect = collectionView.bounds
			rect.size.height = rect.size.height / 4
			controller.popoverPresentationController?.sourceRect = rect
		}
		present(controller, animated: true)
	}
	
	@objc func showOutlineGetInfo() {
		guard let outline else { return }
		delegate?.showGetInfo(self, outline: outline)
	}
	
	@objc func showUndoMenu(_ sender: Any?) {
		updateUI()
		navButtonGroup.showPopOverMenu(for: undoMenuButton)
	}

	@objc func showFormatMenu(_ sender: Any?) {
		updateUI()
		rightToolbarButtonGroup.showPopOverMenu(for: formatMenuButton)
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
						guard let self, let row = self.outline?.shadowTable?[indexPath.row] else { return nil }
						
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
						guard let self, let row = self.outline?.shadowTable?[indexPath.row] else { return nil }

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
		} else if let titleOrTagInput = UIResponder.currentFirstResponder as? EditorTextInput & UIResponder {
			if traitCollection.userInterfaceIdiom != .mac {
				titleOrTagInput.resignFirstResponder()
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
			if let outlineTags = outline?.tags, indexPath.row < outlineTags.count {
				let tag = outlineTags[indexPath.row]
				return collectionView.dequeueConfiguredReusableCell(using: tagRegistration!, for: indexPath, item: tag.name)
			} else {
				return collectionView.dequeueConfiguredReusableCell(using: tagInputRegistration!, for: indexPath, item: outline!.id)
			}
		case Outline.Section.backlinks.rawValue:
			return collectionView.dequeueConfiguredReusableCell(using: backlinkRegistration!, for: indexPath, item: outline)
		default:
			let row: Row
			if let shadowTable = outline?.shadowTable, indexPath.row < shadowTable.count {
				row = shadowTable[indexPath.row]
			} else {
				row = Row(outline: outline)
			}
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration!, for: indexPath, item: row)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
		// Force save the text if the context menu has been requested so that we don't lose our
		// text changes when the cell configuration gets applied
		saveCurrentText()
		
		if let responder = UIResponder.currentFirstResponder, responder is UISearchTextField {
			responder.resignFirstResponder()
		}
		
		let rows: [Row] = indexPaths.filter( {$0.section == adjustedRowsSection })
			.map(\.row)
			.compactMap({ outline?.shadowTable?[$0] })
		return buildRowsContextMenu(rows: rows)

	}
	
	func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
		guard let cell = collectionView.cellForItem(at:indexPath) as? EditorRowViewCell else { return nil }		
		return UITargetedPreview(view: cell, parameters: EditorRowPreviewParameters(cell: cell))
	}
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		let adjustedSection = isSearching ? indexPath.section + 2 : indexPath.section
		return adjustedSection == Outline.Section.rows.rawValue
	}
	
	func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return indexPath.section == adjustedRowsSection
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
	
	func editorTitleTextFieldDidBecomeActive() {
		updateUI()
		collectionView.deselectAll()
	}
	
	func editorTitleDidUpdate(title: String) {
		Task {
			await updateTitleChannel.send(title)
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
		
	func editorTagInputTextFieldDidReturn() {
		if isFocusing {
			moveCursorToFirstRow()
		} else {
			createRow(afterRows: nil)
		}
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

	func editorRowScrollIfNecessary() {
		scrollIfNecessary()
	}

	func editorRowScrollEditorToVisible(textView: UITextView, rect: CGRect) {
		scrollToVisible(textInput: textView, rect: rect, animated: true)
	}

	func editorRowTextFieldDidBecomeActive() {
		// This makes doing row insertions much faster because this work will
		// be performed a cycle after the actual insertion was completed.
		Task { @MainActor in
			self.collectionView.deselectAll()
			self.updateUI()
		}
	}

	func editorRowTextFieldDidBecomeInactive() {
		// This makes doing row insertions much faster because this work will
		// be performed a cycle after the actual insertion was completed.
		Task { @MainActor in
			self.updateUI()
		}
	}
	
	func editorRowToggleDisclosure(rowID: String, applyToAll: Bool) {
		guard let row = outline?.findRow(id: rowID) else { return }
		toggleDisclosure(row: row, applyToAll: applyToAll)
	}
	
	func editorRowMoveRowLeft(rowID: String) {
		guard let row = outline?.findRow(id: rowID) else { return }
		moveRowsLeft([row])
	}

	func editorRowMoveRowRight(rowID: String) {
		guard let row = outline?.findRow(id: rowID) else { return }
		moveRowsRight([row])
	}

	func editorRowTextChanged(rowID: String, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange) {
		guard let row = outline?.findRow(id: rowID) else { return }
		textChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
		savedCursorRectForUpAndDownArrowing = nil
	}
	
	func editorRowDeleteRow(rowID: String, rowStrings: RowStrings) {
		guard let row = outline?.findRow(id: rowID) else { return }
		deleteRows([row], rowStrings: rowStrings)
	}
	
	func editorRowCreateRow(beforeRowID: String, rowStrings: RowStrings?, moveCursor: Bool) {
		guard let beforeRow = outline?.findRow(id: beforeRowID) else { return }
		createRow(beforeRows: [beforeRow], rowStrings: rowStrings, moveCursor: moveCursor)
	}
	
	func editorRowCreateRow(afterRowID: String, rowStrings: RowStrings?) {
		guard let afterRow = outline?.findRow(id: afterRowID) else { return }
		createRow(afterRows: [afterRow], rowStrings: rowStrings)
	}
	
	func editorRowSplitRow(rowID: String, topic: NSAttributedString, cursorPosition: Int) {
		guard let row = outline?.findRow(id: rowID) else { return }
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editorRowJoinRowWithPreviousSibling(rowID: String, attrText: NSAttributedString) {
		guard let row = outline?.findRow(id: rowID),
			  let shadowTableIndex = row.shadowTableIndex,
			  shadowTableIndex > 0,
			  let candidateSibling = outline?.shadowTable?[shadowTableIndex - 1],
			  row.hasSameParent(candidateSibling) else {
				return
			}
		
		let topic = if let siblingTopic = candidateSibling.topic {
			NSMutableAttributedString(attributedString: siblingTopic)
		} else {
			NSMutableAttributedString()
		}
		
		topic.append(attrText)
		
		joinRow(row, topic: topic)
	}

	func editorRowShouldMoveLeftOnReturn(rowID: String) -> Bool {
		guard let row = outline?.findRow(id: rowID) else { return false }
		return outline?.shouldMoveLeftOnReturn(row: row) ?? false
	}

	func editorRowDeleteRowNote(rowID: String) {
		guard let row = outline?.findRow(id: rowID) else { return }
		deleteRowNotes([row], rowStrings: nil)
	}
	
	func editorRowMoveCursorTo(rowID: String) {
		guard let row = outline?.findRow(id: rowID) else { return }
		moveCursorTo(row: row)
	}

	func editorRowMoveCursorUp(rowID: String) {
		guard let row = outline?.findRow(id: rowID), let shadowTableIndex = row.shadowTableIndex else { return }
		
		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
		guard let topicTextView = (collectionView.cellForItem(at: indexPath) as? EditorRowViewCell)?.topicTextView else { return }
		moveCursorUp(topicTextView: topicTextView)
	}

	func editorRowMoveCursorDown(rowID: String) {
		guard let row = outline?.findRow(id: rowID), let shadowTableIndex = row.shadowTableIndex else { return }
		
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
			guard let self, let image = object as? UIImage else { return }

			Task(priority: .medium) {
				guard let rotatedImage = image.rotateImage(),
					  let data = rotatedImage.pngData(),
					  let cgImage = UIImage.scaleImage(data, maxPixelSize: 1800) else { return }
				
				let scaledImage = UIImage(cgImage: cgImage)

				await MainActor.run {
					self.restoreCursorPosition(cursorCoordinates)

					guard let row = self.outline?.findRow(id: cursorCoordinates.rowID),
						  let shadowTableIndex = row.shadowTableIndex else { return }

					let indexPath = IndexPath(row: shadowTableIndex, section: self.adjustedRowsSection)
					guard let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return }

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
		
		guard let row = outline?.findRow(id: cursorCoordinates.rowID),
			  let shadowTableIndex = row.shadowTableIndex else {
			return
		}

		let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
		guard let rowCell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return }
		
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

// MARK: UIFindInteractionDelegate

extension EditorViewController: UIFindInteractionDelegate {
	
	func findInteraction(_ interaction: UIFindInteraction, sessionFor view: UIView) -> UIFindSession? {
		return EditorFindSession(delegate: self)
	}
	
	func findInteraction(_ interaction: UIFindInteraction, didBegin session: UIFindSession) {
		// When the search field isn't already loaded from history, the search wasn't already initiated before getting
		// here, so we have to initialize it by calling search.
		if interaction.searchText?.isEmpty ?? true {
			outline?.search(for: "", options: [])
		}
	}
	
	func findInteraction(_ interaction: UIFindInteraction, didEnd session: UIFindSession) {
		outline?.endSearching()
	}
}
// MARK: EditorFindSessionDelegate

extension EditorViewController: EditorFindSessionDelegate {
	
	func replaceCurrentSearchResult(with replacementText: String) {
		guard let outline, let undoManager else { return }
		
		let coordinate = outline.searchResultCoordinates[outline.currentSearchResult]
		let command = ReplaceSearchResultCommand(actionName: .replaceControlLabel,
												 undoManager: undoManager,
												 delegate: self,
												 outline: outline,
												 coordinates: [coordinate],
												 replacementText: replacementText)
		
		command.execute()

	}
	
	func replaceAllSearchResults(with replacementText: String) {
		guard let outline, let undoManager else { return }
		
		let command = ReplaceSearchResultCommand(actionName: .replaceControlLabel,
												 undoManager: undoManager,
												 delegate: self,
												 outline: outline,
												 coordinates: outline.searchResultCoordinates,
												 replacementText: replacementText)
		
		command.execute()
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
		Task {
			await appDelegate.accountManager.sync()
		}
	}
	
	func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
		Task {
			await appDelegate.accountManager.sync()
		}
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
	
	func configureButtonBars(size: CGSize) {
		undoMenuButtonGroup = ButtonGroup(hostController: self, containerType: .standard, alignment: .none)
		undoButton = undoMenuButtonGroup.addButton(label: .undoControlLabel, image: .undo, selector: .undo)
		cutButton = undoMenuButtonGroup.addButton(label: .cutControlLabel, image: .cut, selector: .cut)
		copyButton = undoMenuButtonGroup.addButton(label: .copyControlLabel, image: .copy, selector: .copy)
		pasteButton = undoMenuButtonGroup.addButton(label: .pasteControlLabel, image: .paste, selector: .paste)
		redoButton = undoMenuButtonGroup.addButton(label: .redoControlLabel, image: .redo, selector: .redo)

		navButtonGroup = ButtonGroup(hostController: self, containerType: .compactable, alignment: .right)
		goBackwardButton = navButtonGroup.addButton(label: .goBackwardControlLabel, image: .goBackward, selector: .goBackwardOne)
		goForwardButton = navButtonGroup.addButton(label: .goForwardControlLabel, image: .goForward, selector: .goForwardOne)
		undoMenuButton = navButtonGroup.addButton(label: .undoMenuControlLabel, image: .undoMenu, selector: .showUndoMenu)
		undoMenuButton.popoverButtonGroup = undoMenuButtonGroup
		moreMenuButton = navButtonGroup.addButton(label: .moreControlLabel, image: .ellipsis, showMenu: true)
		focusButton = navButtonGroup.addButton(label: .focusInControlLabel, image: .focusInactive, selector: .toggleFocus)
		filterButton = navButtonGroup.addButton(label: .filterControlLabel, image: .filterInactive, showMenu: true)
		let navButtonsBarButtonItem = navButtonGroup.buildBarButtonItem()

		leftToolbarButtonGroup = ButtonGroup(hostController: self, containerType: .compactable, alignment: .left)
		moveLeftButton = leftToolbarButtonGroup.addButton(label: .moveLeftControlLabel, image: .moveLeft, selector: .moveCurrentRowsLeft)
		moveRightButton = leftToolbarButtonGroup.addButton(label: .moveRightControlLabel, image: .moveRight, selector: .moveCurrentRowsRight)
		moveUpButton = leftToolbarButtonGroup.addButton(label: .moveUpControlLabel, image: .moveUp, selector: .moveCurrentRowsUp)
		moveDownButton = leftToolbarButtonGroup.addButton(label: .moveDownControlLabel, image: .moveDown, selector: .moveCurrentRowsDown)
		let moveButtonsBarButtonItem = leftToolbarButtonGroup.buildBarButtonItem()

		formatMenuButtonGroup = ButtonGroup(hostController: self, containerType: .standard, alignment: .none)
		linkButton = formatMenuButtonGroup.addButton(label: .linkControlLabel, image: .link, target: self, selector: .editorLink)
		let boldImage = UIImage.bold.applyingSymbolConfiguration(.init(pointSize: 25, weight: .regular, scale: .medium))!
		boldButton = formatMenuButtonGroup.addButton(label: .boldControlLabel, image: boldImage, target: self, selector: .editorToggleBoldface)
		let italicImage = UIImage.italic.applyingSymbolConfiguration(.init(pointSize: 25, weight: .regular, scale: .medium))!
		italicButton = formatMenuButtonGroup.addButton(label: .italicControlLabel, image: italicImage, target: self, selector: .editorToggleItalics)

		rightToolbarButtonGroup = ButtonGroup(hostController: self, containerType: .compactable, alignment: .right)
		insertImageButton = rightToolbarButtonGroup.addButton(label: .insertImageControlLabel, image: .insertImage, selector: .insertImage)
		formatMenuButton = rightToolbarButtonGroup.addButton(label: .formatControlLabel, image: .format, selector: .showFormatMenu)
		formatMenuButton.popoverButtonGroup = formatMenuButtonGroup
		noteButton = rightToolbarButtonGroup.addButton(label: .addNoteControlLabel, image: .noteAdd, selector: .createOrDeleteNotes)
		insertNewlineButton = rightToolbarButtonGroup.addButton(label: .newOutlineControlLabel, image: .newline, selector: .insertReturn)
		let insertButtonsBarButtonItem = rightToolbarButtonGroup.buildBarButtonItem()

		if traitCollection.userInterfaceIdiom != .mac {
			keyboardToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
			let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			
			if traitCollection.userInterfaceIdiom == .pad {
				keyboardToolBar.items = [moveButtonsBarButtonItem, flexibleSpace, insertButtonsBarButtonItem]
			} else {
				let hideKeyboardBarButtonItem = UIBarButtonItem(image: .hideKeyboard, style: .plain, target: self, action: #selector(hideKeyboard))
				hideKeyboardBarButtonItem.accessibilityLabel = .hideKeyboardControlLabel
				keyboardToolBar.items = [moveButtonsBarButtonItem, .fixedSpace(0), hideKeyboardBarButtonItem, .fixedSpace(0), insertButtonsBarButtonItem]
			}
			
			keyboardToolBar.sizeToFit()
			navigationItem.rightBarButtonItems = [navButtonsBarButtonItem]

			if traitCollection.userInterfaceIdiom == .pad {
				navButtonGroup.remove(undoMenuButton)
				rightToolbarButtonGroup.remove(formatMenuButton)
				formatMenuButtonGroup.remove(linkButton)
				rightToolbarButtonGroup.insert(linkButton, at: 1)
			}

			navButtonGroup.containerWidth = size.width
			leftToolbarButtonGroup.containerWidth = size.width
			rightToolbarButtonGroup.containerWidth = size.width
		}

	}
	
	func buildEllipsisMenu() -> UIMenu {
		var outlineActions = [UIMenuElement]()

		let getInfoAction = UIAction(title: .getInfoControlLabel, image: .getInfo) { [weak self] _ in
			self?.showOutlineGetInfo()
		}
		outlineActions.append(getInfoAction)

		let findAction = UIAction(title: .findEllipsisControlLabel, image: .find) { [weak self] _ in
			self?.showFindInteraction()
		}
		outlineActions.append(findAction)

		let expandAllInOutlineAction = UIAction(title: .expandAllInOutlineControlLabel, image: .expandAll) { [weak self] _ in
			self?.expandAllInOutline(self)
		}
		outlineActions.append(expandAllInOutlineAction)
		
		let collapseAllInOutlineAction = UIAction(title: .collapseAllInOutlineControlLabel, image: .collapseAll) { [weak self] _ in
			self?.collapseAllInOutline(self)
		}
		outlineActions.append(collapseAllInOutlineAction)
		
		var shareActions = [UIMenuElement]()

		let shareAction = UIAction(title: .shareEllipsisControlLabel, image: .share) { [weak self] _ in
			self?.share(sourceView: self?.moreMenuButton)
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
			guard let self, let outline = self.outline else { return }
			self.delegate?.exportPDFDoc(self, outline: outline)
		}
		let exportPDFList = UIAction(title: .exportPDFListEllipsisControlLabel) { [weak self] _ in
			guard let self, let outline = self.outline else { return }
			self.delegate?.exportPDFList(self, outline: outline)
		}
		let exportMarkdownDoc = UIAction(title: .exportMarkdownDocEllipsisControlLabel) { [weak self] _ in
			guard let self, let outline = self.outline else { return }
			self.delegate?.exportMarkdownDoc(self, outline: outline)
		}
		let exportMarkdownList = UIAction(title: .exportMarkdownListEllipsisControlLabel) { [weak self] _ in
			guard let self, let outline = self.outline else { return }
			self.delegate?.exportMarkdownList(self, outline: outline)
		}
		let exportOPML = UIAction(title: .exportOPMLEllipsisControlLabel) { [weak self] _ in
			guard let self, let outline = self.outline else { return }
			self.delegate?.exportOPML(self, outline: outline)
		}
		let exportActions = [exportPDFDoc, exportPDFList, exportMarkdownDoc, exportMarkdownList, exportOPML]
		shareActions.append(UIMenu(title: .exportControlLabel, image: .export, children: exportActions))

		let deleteCompletedRowsAction = UIAction(title: .deleteCompletedRowsControlLabel,
												 image: .delete,
												 attributes: .destructive) { [weak self] _ in
			self?.deleteCompletedRows(nil)
		}
		let outlineMenu = UIMenu(title: "", options: .displayInline, children: outlineActions)
		let shareMenu = UIMenu(title: "", options: .displayInline, children: shareActions)
		let changeMenu = UIMenu(title: "", options: .displayInline, children: [deleteCompletedRowsAction])
		
		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [outlineMenu, shareMenu, changeMenu])
	}
	
	func buildFilterMenu() -> UIMenu {
		let turnFilterOnAction = UIAction() { [weak self] _ in
		   self?.toggleFilterOn(self)
		}
		turnFilterOnAction.title = isFilterOn ? .turnFilterOffControlLabel : .turnFilterOnControlLabel
		
		let turnFilterOnMenu = UIMenu(title: "", options: .displayInline, children: [turnFilterOnAction])
		
		let filterCompletedAction = UIAction(title: .filterCompletedControlLabel) { [weak self] _ in
			self?.toggleCompletedFilter(self)
		}
		filterCompletedAction.state = isCompletedFiltered ? .on : .off
		filterCompletedAction.attributes = isFilterOn ? [] : .disabled

		let filterNotesAction = UIAction(title: .filterNotesControlLabel) { [weak self] _ in
		   self?.toggleNotesFilter(self)
		}
		filterNotesAction.state = isNotesFiltered ? .on : .off
		filterNotesAction.attributes = isFilterOn ? [] : .disabled

		let filterOptionsMenu = UIMenu(title: "", options: .displayInline, children: [filterCompletedAction, filterNotesAction])

		return UIMenu(title: "", children: [turnFilterOnMenu, filterOptionsMenu])
	}
	
	func reload(_ newOutline: Outline) {
		outline?.decrementBeingViewedCount()
		
		let oldOutline = outline
		Task {
			await oldOutline?.unload()
		}

		outline = newOutline
		
		outline?.load()
		outline?.incrementBeingViewedCount()
		outline?.prepareForViewing()

		let cursorCoordinates = CursorCoordinates.bestCoordinates
		
		collectionView.reloadData()
		
		if let cursorCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: false)
		}
	}
	
	func showFindInteraction(text: String? = nil, replace: Bool = false) {
		guard !isSearching else {
			return
		}

		findInteraction.searchText = text ?? ""
		findInteraction.presentFindNavigator(showingReplace: replace)

		// I don't know why, but if you are clicking down the documents with a collections search active
		// the title row won't reload and you will get titles when you should only have search results.
		if outline?.shadowTable?.count ?? 0 > 0  {
			collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
		}
	}
	
	func checkForCorruptOutline() {
		guard let outline, outline.isOutlineCorrupted else { return }
		
		let alertController = UIAlertController(title: .corruptedOutlineTitle,
												message: .corruptedOutlineMessage,
												preferredStyle: .alert)
		
		let recoverAction = UIAlertAction(title: .fixItControlLabel, style: .default) { [weak self] action in
			self?.outline?.correctRowToRowOrderCorruption()
			self?.outline?.correctDuplicateRowCorruption()
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

		switch (key.keyCode, true) {
		case (.keyboardUpArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
			break
		case (.keyboardDownArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
			break
		default:
			savedCursorRectForUpAndDownArrowing = nil
		}
		
		if !(CursorCoordinates.currentCoordinates?.isInNotes ?? false) {
			guard cancelledKeys.remove(key) == nil else {
				return
			}
			
			switch (key.keyCode, true) {
			case (.keyboardDeleteForward, true):
				if let topic = currentTextView as? EditorRowTopicTextView,
				   topic.cursorIsAtEnd,
				   let rowID = topic.rowID,
				   let row = outline?.findRow(id: rowID),
				   let shadowTableIndex = row.shadowTableIndex,
				   shadowTableIndex + 1 < outline?.shadowTable?.count ?? 0,
				   let bottomRow = outline?.shadowTable?[shadowTableIndex + 1] {
					let attrString = NSMutableAttributedString(attributedString: topic.cleansedAttributedText)
					attrString.append(bottomRow.topic ?? NSAttributedString())

					topic.isTextChanged = false
					joinRow(bottomRow, topic: attrString)
				} else {
					super.pressesBegan(presses, with: event)
				}
            case (.keyboardUpArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView {
					if topic.cursorIsOnTopLine {
						isGoingUp = true
						repeatMoveCursorUp()
					} else {
						super.pressesBegan(presses, with: event)
						scrollIfNecessary()
					}
				} else {
					isGoingUp = true
					repeatMoveCursorUp()
				}
			case (.keyboardDownArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView {
					if topic.cursorIsOnBottomLine {
						isGoingDown = true
						repeatMoveCursorDown()
					} else {
						super.pressesBegan(presses, with: event)
						scrollIfNecessary()
					}
				} else {
					isGoingDown = true
					repeatMoveCursorDown()
				}
			case (.keyboardLeftArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView, topic.cursorIsAtBeginning,
				   let rowID = topic.rowID,
				   let row = outline?.findRow(id: rowID),
				   let currentRowIndex = row.shadowTableIndex,
				   currentRowIndex > 0,
				   let cell = collectionView.cellForItem(at: IndexPath(row: currentRowIndex - 1, section: adjustedRowsSection)) as? EditorRowViewCell {
					cell.moveToTopicEnd()
				} else {
					super.pressesBegan(presses, with: event)
					scrollIfNecessary()
				}
			case (.keyboardRightArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let topic = currentTextView as? EditorRowTopicTextView, topic.cursorIsAtEnd,
				   let rowID = topic.rowID,
				   let row = outline?.findRow(id: rowID),
				   let currentRowIndex = row.shadowTableIndex,
				   currentRowIndex + 1 < outline?.shadowTable?.count ?? 0,
				   let cell = collectionView.cellForItem(at: IndexPath(row: currentRowIndex + 1, section: adjustedRowsSection)) as? EditorRowViewCell {
					cell.moveToTopicStart()
				} else {
					super.pressesBegan(presses, with: event)
					scrollIfNecessary()
				}
			default:
				super.pressesBegan(presses, with: event)
			}
			
		} else {
			switch (key.keyCode, true) {
			case (.keyboardUpArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty), (.keyboardDownArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				scrollIfNecessary()
			default:
				break
			}

			super.pressesBegan(presses, with: event)
		}
	}
	
	func pressesBeganForOutlineMode(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if presses.count == 1, let key = presses.first?.key {
			guard cancelledKeys.remove(key) == nil else {
				super.pressesBegan(presses, with: event)
				return
			}
			
			switch (key.keyCode, true) {
			case (.keyboardLeftArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let first = collectionView.indexPathsForSelectedItems?.sorted().first {
					if let cell = collectionView.cellForItem(at: first) as? EditorRowViewCell {
						cell.moveToTopicStart()
					}
				}
			case (.keyboardRightArrow, key.modifierFlags.subtracting([.alphaShift, .numericPad]).isEmpty):
				if let last = collectionView.indexPathsForSelectedItems?.sorted().last {
					if let cell = collectionView.cellForItem(at: last) as? EditorRowViewCell {
						cell.moveToTopicEnd()
					}
				}
			default:
				super.pressesBegan(presses, with: event)
			}
			
		} else {
			super.pressesBegan(presses, with: event)
		}
	}

	func repeatMoveCursorUp() {
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
		
		goingUpOrDownTask?.cancel()
		goingUpOrDownTask = Task {
			try? await Task.sleep(for: .seconds(goingUpRepeatInterval))
			guard !Task.isCancelled else { return }
			
			if self.isGoingUp {
				self.goingUpRepeatInterval = Self.fastRepeatInterval
				self.repeatMoveCursorUp()
			} else {
				self.goingUpRepeatInterval = Self.slowRepeatInterval
			}
		}
	}
	
	func repeatMoveCursorDown() {
		if let textView = UIResponder.currentFirstResponder as? EditorRowTopicTextView {
			moveCursorDown(topicTextView: textView)
		} else if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			if tagInput.isShowingResults {
				tagInput.selectBelow()
				return
			} else {
				moveCursorToFirstRow()
			}
		} else if let textView = UIResponder.currentFirstResponder as? EditorTitleTextView, !textView.isSelecting {
			moveCursorToTagInput()
		}
		
		goingUpOrDownTask?.cancel()
		goingUpOrDownTask = Task {
			try? await Task.sleep(for: .seconds(goingDownRepeatInterval))
			guard !Task.isCancelled else { return }
			
			if self.isGoingDown {
				self.goingDownRepeatInterval = Self.fastRepeatInterval
				self.repeatMoveCursorDown()
			} else {
				self.goingDownRepeatInterval = Self.slowRepeatInterval
			}
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
		
		// Moving the cursor before the changes can prevent the keyboard bouncing on iOS
		if changes.cursorMoveIsBeforeChanges, let newCursorIndex = changes.newCursorIndex {
			if newCursorIndex == -1 {
				moveCursorToTagInput()
			} else {
				moveCursorToRow(index: newCursorIndex, toStart: changes.cursorMoveIsToStart, toNote: changes.cursorMoveIsToNote)
			}
		}
		
		applyChanges(changes)

		if changes.isOnlyReloads, let indexPaths = selectedIndexPaths {
			for indexPath in indexPaths {
				collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
			}
		}

		// Usually we need to move the cursor after the change because we are moving to a newly created element
		if !changes.cursorMoveIsBeforeChanges {
			if let newSelectIndex = changes.newSelectIndex {
				moveSelectionToRow(index: newSelectIndex)
			} else if let newCursorIndex = changes.newCursorIndex {
				if newCursorIndex == -1 {
					moveCursorToTagInput()
				} else {
					moveCursorToRow(index: newCursorIndex, toStart: changes.cursorMoveIsToStart, toNote: changes.cursorMoveIsToNote)
				}
			} else {
				scrollIfNecessary(animated: false)
			}
		}

		Task {
			updateUI()
		}
	}

	func restoreOutlineCursorPosition() {
		if let cursorCoordinates = outline?.cursorCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: true)
		}
	}
	
	// Currently only used on the Mac to get the cursor back while scrolling. On iOS we don't want the cursor to comeback
	// and show the keyboard again until the user selects something. Don't try to restore the cursor on the Mac if we
	// are selecting rows. That will deselect them.
	func restoreBestKnownCursorPosition() {
		guard collectionView.indexPathsForSelectedItems == nil || collectionView.indexPathsForSelectedItems!.isEmpty else { return }
		if let cursorCoordinates = CursorCoordinates.bestCoordinates {
			restoreCursorPosition(cursorCoordinates, scroll: false)
		}
	}

	func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates, scroll: Bool, centered: Bool = false) {
		guard let row = outline?.findRow(id: cursorCoordinates.rowID),
			  let shadowTableIndex = row.shadowTableIndex else {
			return
		}

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
				Task { @MainActor in
					self.restoreCursorPosition(cursorCoordinates, scroll: scroll, centered: centered)
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
			Task { @MainActor in
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
		// On the iPhone the view might not be there when this gets called, so try until it is ready.
		guard isViewLoaded && collectionView.numberOfSections > 0 else {
			Task {
				self.moveCursorToTitleOnNew()
			}
			return
		}
		
		// On the iPad you have to wait for another run loop or it won't work. Dunno why.
		Task {
			self.moveCursorToTitle()
		}
	}
	
	func moveCursorToTitle() {
		let indexPath = IndexPath(row: 0, section: Outline.Section.title.rawValue)
		collectionView.scrollToItem(at: indexPath, at: [], animated: !AppDefaults.shared.disableEditorAnimations)
		Task {
			if let titleCell = self.collectionView.cellForItem(at: indexPath) as? EditorTitleViewCell {
				titleCell.takeCursor()
			}
		}
	}
	
	func moveCursorToTagInput() {
		if let outline {
			let indexPath = IndexPath(row: outline.tags.count, section: Outline.Section.tags.rawValue)
			collectionView.scrollToItem(at: indexPath, at: [], animated: !AppDefaults.shared.disableEditorAnimations)
			Task {
				if let tagInputCell = collectionView.cellForItem(at: indexPath) as? EditorTagInputViewCell {
					tagInputCell.takeCursor()
				}
			}
		}
	}
	
	func moveCursorToFirstRow() {
		if outline?.shadowTable?.count ?? 0 > 0 {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: 0, section: adjustedRowsSection)) as? EditorRowViewCell {
				rowCell.moveToTopicEnd()
			}
		}
	}
	
	func editLink(_ link: String?, text: String?, range: NSRange) {
		if traitCollection.userInterfaceIdiom == .mac {
		
			let linkViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "MacLinkViewController") as! MacLinkViewController
			linkViewController.preferredContentSize = CGSize(width: 400, height: 126)
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
			guard let self, let outline = self.outline else { return nil }
			
			var menuItems = [UIMenu]()

			var standardEditActions = [UIAction]()
			standardEditActions.append(self.cutAction(rows: rows))
			standardEditActions.append(self.copyAction(rows: rows))
			if rows.count == 1 {
				standardEditActions.append(self.copyRowLinkAction(rows: rows))
			}
			if self.canPerformAction(.paste, withSender: nil) {
				standardEditActions.append(self.pasteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: standardEditActions))

			var outlineActions = [UIAction]()
			outlineActions.append(self.addAction(rows: rows))
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
			outlineActions.append(self.duplicateAction(rows: rows))
			if !outline.isGroupRowsUnavailable(rows: rows) {
				outlineActions.append(self.groupAction(rows: rows))
			}
			if !outline.isSortRowsUnavailable(rows: rows) {
				outlineActions.append(self.sortAction(rows: rows))
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

	func copyRowLinkAction(rows: [Row]) -> UIAction {
		return UIAction(title: .copyRowLinkControlLabel, image: .copyRowLink) { action in
			var urls = [URL]()
			for row in rows {
				guard let url = row.entityID.url else { continue }
				urls.append(url)
			}
			UIPasteboard.general.urls = urls
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
			Task { @MainActor in
				self?.createRow(afterRows: rows)
			}
		}
	}

	func duplicateAction(rows: [Row]) -> UIAction {
		let title = rows.count == 1 ? String.duplicateRowControlLabel : String.duplicateRowsControlLabel
		return UIAction(title: title, image: .duplicate) { [weak self] action in
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

	func groupAction(rows: [Row]) -> UIAction {
		let title = rows.count == 1 ? String.groupRowControlLabel : String.groupRowsControlLabel
		return UIAction(title: title, image: .groupRows) { [weak self] action in
			self?.groupCurrentRows(rows)
		}
	}

	func sortAction(rows: [Row]) -> UIAction {
		return UIAction(title: .sortRowsControlLabel, image: .sort) { [weak self] action in
			self?.sortCurrentRows(rows)
		}
	}

	func moveCursorTo(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex else {
			return
		}
		moveCursorToRow(index: shadowTableIndex)
	}
	
	func moveCursorToRow(index: Int, toStart: Bool = false, toNote: Bool = false) {
		let indexPath = IndexPath(row: index, section: adjustedRowsSection)
		
		func move(rowCell: EditorRowViewCell) {
			if toNote {
				rowCell.moveToNoteEnd()
			} else {
				if toStart {
					rowCell.moveToTopicStart()
				} else {
					rowCell.moveToTopicEnd()
				}
			}
			scrollIfNecessary(animated: false)
		}
		
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell {
			move(rowCell: rowCell)
		} else {
			Task {
				if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell {
					move(rowCell: rowCell)
				}
			}
		}

	}
	
	func moveSelectionToRow(index: Int) {
		let indexPath = IndexPath(row: index, section: adjustedRowsSection)
		collectionView.deselectAll()
		collectionView.scrollToItem(at: indexPath, at: [], animated: false)
		collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
	}
	
	func moveCursorUp(topicTextView: EditorRowTopicTextView) {
		guard let rowID = topicTextView.rowID,
			  let row = outline?.findRow(id: rowID),
			  let shadowTableIndex = row.shadowTableIndex, shadowTableIndex > 0 else {
			moveCursorToTagInput()
			return
		}
		
		func moveCursorUpToNext(nextTopicTextView: EditorRowTopicTextView) {
			if savedCursorRectForUpAndDownArrowing == nil, let topicTextViewCursorRect = topicTextView.cursorRect {
				savedCursorRectForUpAndDownArrowing = topicTextView.convert(topicTextViewCursorRect, to: collectionView)
			}

			if let savedCursorRectForUpAndDownArrowing {
				let nextRect = nextTopicTextView.convert(savedCursorRectForUpAndDownArrowing, from: collectionView)
				if let cursorPosition = nextTopicTextView.closestPosition(to: CGPoint(x: nextRect.midX, y: nextTopicTextView.bounds.height - 1)) {
					let cursorOffset = nextTopicTextView.offset(from: nextTopicTextView.beginningOfDocument, to: cursorPosition)
					let range = NSRange(location: cursorOffset, length: 0)
					nextTopicTextView.selectedRange = range
				}
			}
			scrollIfNecessary()
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
				Task { @MainActor in
					try? await Task.sleep(for: .seconds(0.3))
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
		guard let rowID = topicTextView.rowID,
			  let row = outline?.findRow(id: rowID),
			  let shadowTableIndex = row.shadowTableIndex,
			  let shadowTable = outline?.shadowTable else {
			return
		}
		
		// Move the cursor to the end of the last row
		guard shadowTableIndex < (shadowTable.count - 1) else {
			let indexPath = IndexPath(row: shadowTableIndex, section: adjustedRowsSection)
			if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorRowViewCell {
				rowCell.moveToTopicEnd()
			}
			return
		}
		
		func moveCursorDownToNext(nextTopicTextView: EditorRowTopicTextView) {
			if savedCursorRectForUpAndDownArrowing == nil, let topicTextViewCursorRect = topicTextView.cursorRect {
				savedCursorRectForUpAndDownArrowing = topicTextView.convert(topicTextViewCursorRect, to: collectionView)
			}

			if let savedCursorRectForUpAndDownArrowing {
				let nextRect = nextTopicTextView.convert(savedCursorRectForUpAndDownArrowing, from: collectionView)
				
				if let cursorPosition = nextTopicTextView.closestPosition(to: CGPoint(x: nextRect.midX, y: 0)) {
					let cursorOffset = nextTopicTextView.offset(from: nextTopicTextView.beginningOfDocument, to: cursorPosition)
					let range = NSRange(location: cursorOffset, length: 0)
					nextTopicTextView.selectedRange = range
				}
				
				scrollIfNecessary()
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
				Task { @MainActor in
					try? await Task.sleep(for: .seconds(0.3))
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
		guard let undoManager, let outline else { return }
		
		let command = CreateTagCommand(actionName: .addTagControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		command.execute()
		moveCursorToTagInput()
	}

	func deleteTag(name: String) {
		guard let undoManager, let outline else { return }

		let command = DeleteTagCommand(actionName: .removeTagControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		command.execute()
	}
	
	func expand(rows: [Row]) {
		guard let undoManager, let outline else { return }
		
		let command = ExpandCommand(actionName: .expandControlLabel,
									undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)
		
		command.execute()
	}

	func collapse(rows: [Row]) {
		guard let undoManager, let outline else { return }

		var currentRow: Row? = nil
		if let rowID = currentTextView?.rowID {
			currentRow = outline.findRow(id: rowID)
		}
		
		let command = CollapseCommand(actionName: .collapseControlLabel,
									  undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows)
		
		command.execute()
		
		if let cursorRow = currentRow {
			for row in rows {
				if cursorRow.isDecendent(row), let newCursorIndex = row.shadowTableIndex {
					if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: adjustedRowsSection)) as? EditorRowViewCell {
						rowCell.moveToTopicEnd()
					}
				}
			}
		}
	}

	func expandAll(containers: [RowContainer]) {
		guard let undoManager, let outline else { return }
		
		let command = ExpandAllCommand(actionName: .expandAllControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   containers: containers)
		
		command.execute()
	}

	func collapseAll(containers: [RowContainer]) {
		guard let undoManager, let outline else { return }
		
		let command = CollapseAllCommand(actionName: .collapseAllControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 containers: containers)

		command.execute()
	}

	func textChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange) {
		guard let undoManager, let outline else { return }
		
		let command = TextChangedCommand(actionName: .typingControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 row: row,
										 rowStrings: rowStrings,
										 isInNotes: isInNotes,
										 selection: selection)
		command.execute()
	}

	func cutRows(_ rows: [Row]) {
		guard let undoManager, let outline else { return }
		copyRows(rows)

		let command = CutRowCommand(actionName: .cutControlLabel,
									undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows,
									isInOutlineMode: isInOutlineMode)

		command.execute()
	}

	func copyRows(_ rows: [Row]) {
		var itemProviders = [NSItemProvider]()

		let markdownItemProvider = NSItemProvider()

		var markdowns = [String]()
		for row in rows.sortedWithDecendentsFiltered() {
			markdowns.append(row.markdownList(numberingStyle: .none))
		}
		let markdownData = markdowns.joined(separator: "\n").data(using: .utf8)

		markdownItemProvider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { completion in
			completion(markdownData, nil)
			return nil
		}

		itemProviders.append(markdownItemProvider)
		
		for row in rows.sortedWithDecendentsFiltered() {
			let rowItemProvider = NSItemProvider()

			// We need to create the RowGroup data before our data representation callback happens
			// because we might actually be cutting the data and it won't be available anymore at
			// the time that the callback happens.
			let rowData = try? RowGroup(row).asData()
			
			rowItemProvider.registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
				completion(rowData, nil)
				return nil
			}
			
			itemProviders.append(rowItemProvider)
		}
		
		UIPasteboard.general.setItemProviders(itemProviders, localOnly: false, expirationDate: nil)
	}

	func pasteRows(afterRows: [Row]?) {
		guard let undoManager, let outline else { return }
		
		Task {
			if let rowProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [Row.typeIdentifier]), !rowProviderIndexes.isEmpty {
				let itemProviders = rowProviderIndexes.compactMap { UIPasteboard.general.itemProviders[$0] }
				
				do {
					let rowGroups = try await RowGroup.fromRowItemProviders(itemProviders)
					
					let command = PasteRowCommand(actionName: .pasteControlLabel,
												  undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  rowGroups: rowGroups,
												  afterRow: afterRows?.last)
				
					command.execute()
				} catch {
					presentError(error)
				}
			} else if let textProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [UTType.utf8PlainText.identifier]), !textProviderIndexes.isEmpty {
				let itemProviders = textProviderIndexes.compactMap { UIPasteboard.general.itemProviders[$0] }
				
				let rowGroups = await RowGroup.fromTextItemProviders(itemProviders)
				
				let command = PasteRowCommand(actionName: .pasteControlLabel,
											  undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  rowGroups: rowGroups,
											  afterRow: afterRows?.last)
				
				command.execute()
			}
		}
	}
	
	func deleteRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }

		let command = DeleteRowCommand(actionName: .deleteRowsControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   rowStrings: rowStrings,
									   isInOutlineMode: isInOutlineMode)

		command.execute()
	}
	
	func createRow(beforeRows: [Row], rowStrings: RowStrings? = nil, moveCursor: Bool) {
		guard let undoManager, let outline, let beforeRow = beforeRows.sortedByDisplayOrder().first else { return }

		let command = CreateRowBeforeCommand(actionName: .addRowControlLabel,
											 undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 beforeRow: beforeRow,
											 rowStrings: rowStrings,
											 moveCursor: moveCursor)
		
		command.execute()
	}
	
	func createRow(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }

		scrollRowToShowBottom()
		
		let afterRow = afterRows?.sortedByDisplayOrder().last
		
		let command = CreateRowAfterCommand(actionName: .addRowAfterControlLabel,
											undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											rowStrings: rowStrings)
		
		command.execute()
	}
	
	func createRowInside(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }

		scrollRowToShowBottom()
		
		guard let afterRow = afterRows?.sortedByDisplayOrder().last else { return }
		
		let command = CreateRowInsideCommand(actionName: .addRowInsideControlLabel,
											 undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 afterRow: afterRow,
											 rowStrings: rowStrings)
		
		command.execute()
}
	
	func createRowOutside(afterRows: [Row]?, rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }

		scrollRowToShowBottom()
		
		guard let afterRow = afterRows?.sortedByDisplayOrder().last else { return }
		
		let command = CreateRowOutsideCommand(actionName: .addRowOutsideControlLabel,
											  undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  afterRow: afterRow,
											  rowStrings: rowStrings)
		
		command.execute()
	}
	
	func duplicateRows(_ rows: [Row]) {
		guard let undoManager, let outline else { return }

		let command = DuplicateRowCommand(actionName: .duplicateRowsControlLabel,
										  undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows)
		
		command.execute()
	}
	
	func moveRowsLeft(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = MoveRowLeftCommand(actionName: .moveLeftControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 rows: rows,
										 rowStrings: rowStrings)
		
		command.execute()
	}

	func moveRowsRight(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = MoveRowRightCommand(actionName: .moveRightControlLabel,
										  undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows,
										  rowStrings: rowStrings)
		
		command.execute()
	}

	func moveRowsUp(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = MoveRowUpCommand(actionName: .moveUpControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   rowStrings: rowStrings)
		
		command.execute()
		scrollIfNecessary()
	}

	func moveRowsDown(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = MoveRowDownCommand(actionName: .moveDownControlLabel,
										 undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 rows: rows,
										 rowStrings: rowStrings)
		
		command.execute()
		scrollIfNecessary()
	}

	func splitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		guard let undoManager, let outline else { return }

		let command = SplitRowCommand(actionName: .splitRowControlLabel,
									  undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  row: row,
									  topic: topic,
									  cursorPosition: cursorPosition)
												  
		
		command.execute()
	}

	func joinRow(_ bottomRow: Row, topic: NSAttributedString) {
		guard let undoManager,
			  let outline,
			  let rowShadowTableIndex = bottomRow.shadowTableIndex,
			  rowShadowTableIndex > 0,
			  let topRow = outline.shadowTable?[rowShadowTableIndex - 1] else { return }

		let command = JoinRowCommand(actionName: .splitRowControlLabel,
									 undoManager: undoManager,
									 delegate: self,
									 outline: outline,
									 topRow: topRow,
									 bottomRow: bottomRow,
									 topic: topic)
												  
		
		command.execute()
	}

	func groupRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = GroupRowsCommand(actionName: .groupRowsControlLabel,
									   undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   rowStrings: rowStrings)
		
		command.execute()
	}

	func sortRows(_ rows: [Row]) {
		guard let undoManager, let outline else { return }
		
		let command = SortRowsCommand(actionName: .groupRowsControlLabel,
									  undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows)
		
		command.execute()
	}

	func completeRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = CompleteCommand(actionName: .completeControlLabel,
									  undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows,
									  rowStrings: rowStrings)
		
		command.execute()
	}
	
	func uncompleteRows(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = UncompleteCommand(actionName: .uncompleteControlLabel,
										undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		command.execute()
	}
	
	func createRowNotes(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = CreateNoteCommand(actionName: .addNoteControlLabel,
										undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		command.execute()
	}

	func deleteRowNotes(_ rows: [Row], rowStrings: RowStrings? = nil) {
		guard let undoManager, let outline else { return }
		
		let command = DeleteNoteCommand(actionName: .deleteNoteControlLabel,
										undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										rowStrings: rowStrings)
		
		command.execute()
	}

	func scrollIfNecessary(animated: Bool = true) {
		// If we don't use a Task here, the cursorRect will sometimes comeback as .zero and if we
		// don't sleep for a bit, the cursorRect will be slightly less than it should be on the
		// iPhone.
		Task {
			try? await Task.sleep(for: .seconds(0.1))
			guard let textInput = UIResponder.currentFirstResponder as? EditorTextInput,
				  let cursorRect = textInput.cursorRect else { return }
			
			self.scrollToVisible(textInput: textInput, rect: cursorRect, animated: animated)

			if AppDefaults.shared.scrollMode == .typewriterCenter {
				self.scrollToCenter(textInput: textInput, rect: cursorRect, animated: animated)
			}
		}
	}

	func scrollToCenter(textInput: UITextInput, rect: CGRect, animated: Bool) {
		guard let convertedRect = (textInput as? UIView)?.convert(rect, to: collectionView) else { return }
		
		let halfHeight = (collectionView.visibleSize.height - currentKeyboardHeight) / 2
		let offsetY = convertedRect.midY - halfHeight

		if offsetY > 0 {
			if AppDefaults.shared.disableEditorAnimations {
				collectionView.contentOffset = CGPoint(x: 0, y: offsetY)
			} else {
				UIView.animate(withDuration: 0.33) {
					self.collectionView.contentOffset = CGPoint(x: 0, y: offsetY)
				}
			}
		}
	}
	
	func scrollCursorToVisible(animated: Bool = true) {
		guard let textInput = UIResponder.currentFirstResponder as? EditorTextInput,
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
			outline.load()
			DocumentIndexer.updateIndex(forDocument: .outline(outline))
			Task {
				await outline.unload()
			}
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
		let result = NSMutableAttributedString(string: "\(refString): ")
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
		if let title = appDelegate.accountManager.findDocument(id)?.title, !title.isEmpty, let url = id.url {
			let result = NSMutableAttributedString(string: title)
			result.addAttribute(.link, value: url, range: NSRange(0..<result.length))
			return result
		}
		return NSAttributedString()
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
