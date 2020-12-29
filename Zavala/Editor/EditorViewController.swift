//
//  EditorViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import RSCore
import Templeton

class EditorViewController: UICollectionViewController, MainControllerIdentifiable, UndoableCommandRunner {
	var mainControllerIdentifer: MainControllerIdentifier { return .editor }

	var isOutlineFunctionsUnavailable: Bool {
		return outline == nil
	}
	
	var isOutlineFiltered: Bool {
		return outline?.isFiltered ?? false
	}
	
	var isOutlineNotesHidden: Bool {
		return outline?.isNotesHidden ?? false
	}
	
	var isDeleteCurrentRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isCreateRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isIndentRowsUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isIndentRowsUnavailable(rows: rows)
	}

	var isOutdentRowsUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isOutdentRowsUnavailable(rows: rows)
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
		return currentTextView == nil || !(currentTextView?.isSelecting ?? false)
	}

	var isLinkUnavailable: Bool {
		return currentTextView == nil || !(currentTextView?.isSelecting ?? false)
	}

	var isExpandAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isExpandAllUnavailable(containers: [outline!])
	}

	var isCollapseAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isCollapseAllUnavailable(containers: [outline!])
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

	var undoableCommands = [UndoableCommand]()
	override var canBecomeFirstResponder: Bool { return true }

	private(set) var outline: Outline?
	
	private var currentTextView: OutlineTextView? {
		return UIResponder.currentFirstResponder as? OutlineTextView
	}
	
	// This is the ones that the user has selected without the ones we programmatically select
	private var selectedIndexes = Set<Int>()

	private var currentRows: [Row]? {
		if !selectedIndexes.isEmpty {
			return selectedIndexes.compactMap { outline?.shadowTable?[$0] }
		} else if let currentRow = currentTextView?.row {
			return [currentRow]
		}
		return nil
	}
	
	private var currentTextRowStrings: TextRowStrings? {
		return currentTextView?.textRowStrings
	}
	
	private var currentCursorPosition: Int? {
		return currentTextView?.cursorPosition
	}
	
	private var currentKeyPresses = Set<UIKeyboardHIDUsage>()
	
	
	private var filterBarButtonItem: UIBarButtonItem?

	private var titleRegistration: UICollectionView.CellRegistration<EditorTitleViewCell, Outline>?
	private var headerRegistration: UICollectionView.CellRegistration<EditorTextRowViewCell, Row>?
	
	private var firstVisibleShadowTableIndex: Int? {
		let visibleRect = collectionView.layoutMarginsGuide.layoutFrame
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.minY)
		if let indexPath = collectionView.indexPathForItem(at: visiblePoint), indexPath.section == 1 {
			return indexPath.row
		}
		return nil
	}
	
	// This is used to keep the collection view from scrolling to the top as its layout gets invalidated.
	private var transitionContentOffset: CGPoint?
	
	private var isOutlineNewFlag = false
	private var hasAlreadyMovedThisKeyPressFlag = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			filterBarButtonItem = UIBarButtonItem(image: AppAssets.filterInactive, style: .plain, target: self, action: #selector(toggleOutlineFilter(_:)))
			navigationItem.rightBarButtonItems = [filterBarButtonItem!]
		}
		
		collectionView.collectionViewLayout = createLayout()
		collectionView.dataSource = self
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.dragInteractionEnabled = true
		collectionView.allowsMultipleSelection = true

		titleRegistration = UICollectionView.CellRegistration<EditorTitleViewCell, Outline> { [weak self] (cell, indexPath, outline) in
			cell.outline = outline
			cell.delegate = self
		}
		
		headerRegistration = UICollectionView.CellRegistration<EditorTextRowViewCell, Row> { [weak self] (cell, indexPath, row) in
			cell.row = row
			cell.isNotesHidden = self?.outline?.isNotesHidden
			cell.delegate = self
		}
		
		updateUI()
		collectionView.reloadData()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		restoreOutlineCursorPosition()
		restoreScrollPosition()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		moveCursorToTitleOnNew()
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.outline?.verticleScrollState = firstVisibleShadowTableIndex
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		transitionContentOffset = collectionView.contentOffset
	}
	
	override func viewDidLayoutSubviews() {
		if let offset = transitionContentOffset {
			collectionView.contentOffset = offset
			transitionContentOffset = nil
		}
	}
	
	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesBegan(presses, with: event)

		guard let key = presses.first?.key else { return }
		switch key.keyCode {
		case .keyboardUpArrow:
			currentKeyPresses.insert(key.keyCode)
			repeatMoveCursorUp()
		case .keyboardDownArrow:
			currentKeyPresses.insert(key.keyCode)
			repeatMoveCursorDown()
		default:
			break
		}
		
	}
	
	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesEnded(presses, with: event)
		let keyCodes = presses.compactMap { $0.key?.keyCode }
		keyCodes.forEach { currentKeyPresses.remove($0) }
	}
	
	// MARK: API
	
	func edit(_ newOutline: Outline?, isNew: Bool) {
		guard outline != newOutline else { return }
		isOutlineNewFlag = isNew
		
		// Get ready for the new outline, buy saving the current one
		outline?.cursorCoordinates = CursorCoordinates.currentCoordinates
		
		if let textField = UIResponder.currentFirstResponder as? OutlineTextView {
			textField.endEditing(true)
		}
		
		outline?.suspend()
		clearUndoableCommands()
	
		// Assign the new Outline and load it
		outline = newOutline
		
		outline?.load()
			
		guard isViewLoaded else { return }
		updateUI()
		collectionView.reloadData()
		
		restoreOutlineCursorPosition()
		restoreScrollPosition()
		moveCursorToTitleOnNew()
	}
	
	func deleteCurrentRows() {
		guard let rows = currentRows,
			  let textRowStrings = currentTextRowStrings else { return }
		deleteRows(rows, textRowStrings: textRowStrings)
	}
	
	func createRow() {
		guard let row = currentRows?.last,
			  let textRowStrings = currentTextRowStrings else { return }
		createRow(afterRow: row, textRowStrings: textRowStrings)
	}
	
	func indentRows() {
		guard let rows = currentRows,
			  let textRowStrings = currentTextRowStrings else { return }
		indentRows(rows, textRowStrings: textRowStrings)
	}
	
	func outdentRows() {
		guard let rows = currentRows,
			  let textRowStrings = currentTextRowStrings else { return }
		outdentRows(rows, textRowStrings: textRowStrings)
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
		guard let rows = currentRows,
			  let textRowStrings = currentTextRowStrings else { return }
		createRowNotes(rows, textRowStrings: textRowStrings)
	}
	
	func deleteRowNotes() {
		guard let rows = currentRows,
			  let textRowStrings = currentTextRowStrings else { return }
		deleteRowNotes(rows, textRowStrings: textRowStrings)
	}
	
	func splitRow() {
		guard let row = currentRows?.last,
			  let topic = currentTextRowStrings?.topic,
			  let cursorPosition = currentCursorPosition else { return }
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func outlineToggleBoldface() {
		currentTextView?.toggleBoldface(self)
	}
	
	func outlineToggleItalics() {
		currentTextView?.toggleItalics(self)
	}
	
	func link() {
		currentTextView?.editLink(self)
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
	
	// MARK: Actions
	
	@objc func toggleOutlineFilter(_ sender: Any?) {
		guard let changes = outline?.toggleFilter() else { return }
		updateUI()
		applyChangesRestoringCursor(changes)
	}
	
	@objc func toggleOutlineHideNotes(_ sender: Any?) {
		guard let changes = outline?.toggleNotesHidden() else { return }
		updateUI()
		applyChangesRestoringCursor(changes)
	}
	
	@objc func repeatMoveCursorUp() {
		guard !hasAlreadyMovedThisKeyPressFlag else {
			hasAlreadyMovedThisKeyPressFlag = false
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				self.repeatMoveCursorUp()
			}
			return
		}
		
		if currentKeyPresses.contains(.keyboardUpArrow) {
			if let textView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView, !textView.isSelecting, let row = textView.row {
				moveCursorUp(row: row)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					self.repeatMoveCursorUp()
				}
			}
		}
	}

	@objc func repeatMoveCursorDown() {
		guard !hasAlreadyMovedThisKeyPressFlag else {
			hasAlreadyMovedThisKeyPressFlag = false
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				self.repeatMoveCursorUp()
			}
			return
		}
		
		if currentKeyPresses.contains(.keyboardDownArrow) {
			if let textView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView, !textView.isSelecting, let row = textView.row {
				moveCursorDown(row: row)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					self.repeatMoveCursorDown()
				}
			} else if let textView = UIResponder.currentFirstResponder as? EditorTitleTextView, !textView.isSelecting, outline?.shadowTable?.count ?? 0 > 0 {
				if let rowCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 1)) as? EditorTextRowViewCell {
					rowCell.moveToEnd()
				}
			}
		}
	}
	
}

// MARK: Collection View

extension EditorViewController {
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			configuration.showsSeparators = false
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if section == 0 {
			return outline == nil ? 0 : 1
		} else {
			return outline?.shadowTable?.count ?? 0
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if indexPath.section == 0 {
			return collectionView.dequeueConfiguredReusableCell(using: titleRegistration!, for: indexPath, item: outline)
		} else {
			let row = outline?.shadowTable?[indexPath.row] ?? Row.text(TextRow())
			return collectionView.dequeueConfiguredReusableCell(using: headerRegistration!, for: indexPath, item: row)
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
			deselectAll()
		}
		
		let rows: [Row]
		if let currentRows = currentRows {
			rows = currentRows
		} else {
			if let editorCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell,
			   let row = editorCell.row {
				rows = [row]
			} else {
				rows = [Row]()
			}

		}
		
		return makeRowsContextMenu(rows: rows)
	}
	
	override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		guard let row = configuration.identifier as? TextRow,
			  let rowShadowTableIndex = row.shadowTableIndex,
			  let cell = collectionView.cellForItem(at: IndexPath(row: rowShadowTableIndex, section: 1)) as? EditorTextRowViewCell else { return nil }
		
		return UITargetedPreview(view: cell, parameters: EditorTextRowPreviewParameters(cell: cell, row: row))
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return indexPath.section == 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selectedIndexes.insert(indexPath.row)
		outline?.childrenIndexes(forIndex: indexPath.row).forEach { rowIndex in
			collectionView.selectItem(at: IndexPath(row: rowIndex, section: 1), animated: false, scrollPosition: [])
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		selectedIndexes.remove(indexPath.row)
	}
	
}

extension EditorViewController: EditorTitleViewCellDelegate {
	
	var editorTitleUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTitleLayoutEditor() {
		layoutEditor()
	}
	
	func editorTitleTextFieldDidBecomeActive() {
		deselectAll()
	}
	
	func editorTitleCreateRow(textRowStrings: TextRowStrings?) {
		createRow(afterRow: nil, textRowStrings: textRowStrings)
	}
	
}

extension EditorViewController: EditorTextRowViewCellDelegate {

	var editorTextRowUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTextRowLayoutEditor() {
		layoutEditor()
	}
	
	func editorTextRowTextFieldDidBecomeActive() {
		deselectAll()
	}

	func editorTextRowToggleDisclosure(row: Row) {
		toggleDisclosure(row: row)
	}
	
	func editorTextRowTextChanged(row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		textChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func editorTextRowDeleteRow(_ row: Row, textRowStrings: TextRowStrings) {
		deleteRows([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowCreateRow(beforeRow: Row) {
		createRow(beforeRow: beforeRow)
	}
	
	func editorTextRowCreateRow(afterRow: Row?, textRowStrings: TextRowStrings?) {
		createRow(afterRow: afterRow, textRowStrings: textRowStrings)
	}
	
	func editorTextRowIndentRow(_ row: Row, textRowStrings: TextRowStrings) {
		indentRows([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowOutdentRow(_ row: Row, textRowStrings: TextRowStrings) {
		outdentRows([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowSplitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editorTextRowCreateRowNote(_ row: Row, textRowStrings: TextRowStrings) {
		createRowNotes([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowDeleteRowNote(_ row: Row, textRowStrings: TextRowStrings) {
		deleteRowNotes([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowMoveCursorTo(row: Row) {
		moveCursorTo(row: row)
		hasAlreadyMovedThisKeyPressFlag = true
	}
	
	func editorTextRowMoveCursorDown(row: Row) {
		moveCursorDown(row: row)
		hasAlreadyMovedThisKeyPressFlag = true
	}
	
	func editorTextRowEditLink(_ link: String?, range: NSRange) {
		editLink(link, range: range)
	}

}

// MARK: EditorOutlineCommandDelegate

extension EditorViewController: OutlineCommandDelegate {
	
	func applyChanges(_ changes: ShadowTableChanges) {
		if let deletes = changes.deleteIndexPaths, !deletes.isEmpty {
			collectionView.deleteItems(at: deletes)
		}
		if let inserts = changes.insertIndexPaths, !inserts.isEmpty {
			collectionView.insertItems(at: inserts)
		}
		if let moves = changes.moveIndexPaths, !moves.isEmpty {
			collectionView.performBatchUpdates {
				for move in moves {
					collectionView.moveItem(at: move.0, to: move.1)
				}
			}
		}
		if let reloads = changes.reloadIndexPaths, !reloads.isEmpty {
			collectionView.reloadItems(at: reloads)
		}
	}
	
	func applyChangesRestoringCursor(_ changes: ShadowTableChanges) {
		var textRange: UITextRange? = nil
		var cursorRow: Row? = nil
		if let editorTextView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView {
			textRange = editorTextView.selectedTextRange
			cursorRow = editorTextView.row
		}
		
		applyChanges(changes)
		
		if let textRange = textRange,
		   let updated = cursorRow?.shadowTableIndex,
		   let rowCell = collectionView.cellForItem(at: IndexPath(row: updated, section: 1)) as? EditorTextRowViewCell {
			rowCell.restoreSelection(textRange)
		}
	}

	func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates) {
		guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: 1)

		func restoreCursor() {
			guard let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell else { return	}
			rowCell.restoreCursor(cursorCoordinates)
		}
		
		if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
			CATransaction.begin()
			CATransaction.setCompletionBlock {
				// Got to wait or the row cell won't be found
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					restoreCursor()
				}
			}
			collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
			CATransaction.commit()
		} else {
			restoreCursor()
		}
	}
	
}

// MARK: LinkViewControllerDelegate

extension EditorViewController: LinkViewControllerDelegate {
	
	func updateLink(_: LinkViewController, cursorCoordinates: CursorCoordinates, link: String?, range: NSRange) {
		guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: 1)
		guard let textRowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell else { return	}
		
		if cursorCoordinates.isInNotes {
			textRowCell.noteTextView?.updateLinkForCurrentSelection(link: link, range: range)
		} else {
			textRowCell.topicTextView?.updateLinkForCurrentSelection(link: link, range: range)
		}
	}
	
}

// MARK: Helpers

private extension EditorViewController {
	
	private func updateUI() {
		navigationItem.title = outline?.title
		navigationItem.largeTitleDisplayMode = .never
		
		if traitCollection.userInterfaceIdiom != .mac {
			if outline?.isFiltered ?? false {
				filterBarButtonItem?.image = AppAssets.filterActive
			} else {
				filterBarButtonItem?.image = AppAssets.filterInactive
			}
		}
	}
	
	private func layoutEditor() {
		let contentOffset = collectionView.contentOffset
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.layoutIfNeeded()
		collectionView.contentOffset = contentOffset
	}
	
	private func restoreOutlineCursorPosition() {
		if let cursorCoordinates = outline?.cursorCoordinates {
			restoreCursorPosition(cursorCoordinates)
		}
	}
	
	private func restoreScrollPosition() {
		if let verticleScrollState = outline?.verticleScrollState, verticleScrollState != 0 {
			collectionView.scrollToItem(at: IndexPath(row: verticleScrollState, section: 1), at: .top, animated: false)
			DispatchQueue.main.async {
				self.collectionView.scrollToItem(at: IndexPath(row: verticleScrollState, section: 1), at: .top, animated: false)
			}
		}
	}
	
	private func moveCursorToTitleOnNew() {
		if isOutlineNewFlag {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
				self.moveCursorToTitle()
			}
		}
		isOutlineNewFlag = false
	}
	
	private func moveCursorToTitle() {
		if let titleCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? EditorTitleViewCell {
			titleCell.takeCursor()
		}
	}
	
	private func deselectAll() {
		selectedIndexes.removeAll()
		collectionView.indexPathsForSelectedItems?.forEach { indexPath in
			collectionView.deselectItem(at: indexPath, animated: true)
		}
	}
	
	private func editLink(_ link: String?, range: NSRange) {
		if traitCollection.userInterfaceIdiom == .mac {
		
			let linkViewController = UIStoryboard.dialog.instantiateController(ofType: LinkViewController.self)
			linkViewController.preferredContentSize = LinkViewController.preferredContentSize
			linkViewController.cursorCoordinates = CursorCoordinates.bestCoordinates
			linkViewController.link = link
			linkViewController.range = range
			linkViewController.delegate = self
			present(linkViewController, animated: true)
		
		} else {
			
			let linkNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "LinkViewControllerNav") as! UINavigationController
			linkNavViewController.preferredContentSize = LinkViewController.preferredContentSize
			linkNavViewController.modalPresentationStyle = .formSheet

			let linkViewController = linkNavViewController.topViewController as! LinkViewController
			linkViewController.cursorCoordinates = CursorCoordinates.bestCoordinates
			linkViewController.link = link
			linkViewController.range = range
			linkViewController.delegate = self
			present(linkNavViewController, animated: true)
			
		}
	}
	
	private func makeRowsContextMenu(rows: [Row]) -> UIContextMenuConfiguration? {
		guard let firstRow = rows.first, let lastRow = rows.last else { return nil }
		
		return UIContextMenuConfiguration(identifier: firstRow.associatedRow as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self, let outline = self.outline else { return nil }
			
			var menuItems = [UIMenu]()

			var firstOutlineActions = [UIAction]()
			firstOutlineActions.append(self.addAction(row: lastRow))
			if !outline.isIndentRowsUnavailable(rows: rows) {
				firstOutlineActions.append(self.indentAction(rows: rows))
			}
			if !outline.isOutdentRowsUnavailable(rows: rows) {
				firstOutlineActions.append(self.outdentAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: firstOutlineActions))
			
			var secondOutlineActions = [UIAction]()
			if !outline.isCompleteUnavailable(rows: rows) {
				secondOutlineActions.append(self.completeAction(rows: rows))
			}
			if !outline.isUncompleteUnavailable(rows: rows) {
				secondOutlineActions.append(self.uncompleteAction(rows: rows))
			}
			if !outline.isCreateNotesUnavailable(rows: rows) {
				secondOutlineActions.append(self.createNoteAction(rows: rows))
			}
			if !outline.isDeleteNotesUnavailable(rows: rows) {
				secondOutlineActions.append(self.deleteNoteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: secondOutlineActions))

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
	
	private func addAction(row: Row) -> UIAction {
		return UIAction(title: L10n.addRow, image: AppAssets.add) { [weak self] action in
			// Have to let the text field get the first responder by getting it away from this
			// action which appears to be holding on to it.
			DispatchQueue.main.async {
				self?.createRow(afterRow: row)
			}
		}
	}

	private func indentAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.indent, image: AppAssets.indent) { [weak self] action in
			self?.indentRows(rows)
		}
	}

	private func outdentAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.outdent, image: AppAssets.outdent) { [weak self] action in
			self?.outdentRows(rows)
		}
	}

	private func expandAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.expandAll, image: AppAssets.expandAll) { [weak self] action in
			self?.expandAll(containers: rows)
		}
	}

	private func collapseAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.collapseAll, image: AppAssets.collapseAll) { [weak self] action in
			self?.collapseAll(containers: rows)
		}
	}

	private func completeAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.complete, image: AppAssets.completeRow) { [weak self] action in
			self?.completeRows(rows)
		}
	}
	
	private func uncompleteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.uncomplete, image: AppAssets.uncompleteRow) { [weak self] action in
			self?.uncompleteRows(rows)
		}
	}
	
	private func createNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.addNote, image: AppAssets.note) { [weak self] action in
			self?.createRowNotes(rows)
		}
	}

	private func deleteNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.deleteNote, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteRowNotes(rows)
		}
	}

	private func deleteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.deleteRow, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteRows(rows)
		}
	}

	func moveCursorTo(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex else {
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex, section: 1)
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
			rowCell.moveToEnd()
		}
	}
	
	func moveCursorUp(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex, shadowTableIndex > 0 else {
			moveCursorToTitle()
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: 1)
		makeCellVisibleIfNecessary(indexPath: indexPath) {
			if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func moveCursorDown(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex, let shadowTable = outline?.shadowTable, shadowTableIndex < (shadowTable.count - 1) else { return }
		let indexPath = IndexPath(row: shadowTableIndex + 1, section: 1)
		makeCellVisibleIfNecessary(indexPath: indexPath) {
			if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func toggleDisclosure(row: Row) {
		if row.isExpandable {
			expand(rows: [row])
		} else {
			collapse(rows: [row])
		}
	}

	func expand(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		deselectAll()
		
		let command = ExpandCommand(undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)
		
		runCommand(command)
	}

	func collapse(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		deselectAll()
		
		let command = CollapseCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows)
		
		runCommand(command)
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

	func textChanged(row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = TextChangedCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 row: row,
										 textRowStrings: textRowStrings,
										 isInNotes: isInNotes,
										 cursorPosition: cursorPosition)
		runCommand(command)
	}
	
	func deleteRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DeleteRowCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   textRowStrings: textRowStrings)

		runCommand(command)
		
		if let deleteIndex = command.changes?.deletes?.first {
			if deleteIndex > 0, let rowCell = collectionView.cellForItem(at: IndexPath(row: deleteIndex - 1, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			} else {
				moveCursorToTitle()
			}
		}
	}
	
	func createRow(beforeRow: Row) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateRowBeforeCommand(undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 beforeRow: beforeRow)
		
		runCommand(command)
		
		if let insert = command.changes?.insertIndexPaths?.first {
			if let rowCell = collectionView.cellForItem(at: insert) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func createRow(afterRow: Row?, textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = CreateRowAfterCommand(undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let insert = command.changes?.insertIndexPaths?.first {
			makeCellVisibleIfNecessary(indexPath: insert) {
				if let rowCell = self.collectionView.cellForItem(at: insert) as? EditorTextRowViewCell {
					rowCell.moveToEnd()
				}
			}
		}
	}
	
	func indentRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = IndentRowCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   textRowStrings: textRowStrings)
		
		runCommand(command)
	}
	
	func outdentRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = OutdentRowCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)
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
		
		if let insert = command.changes?.insertIndexPaths?.first {
			if let rowCell = collectionView.cellForItem(at: insert) as? EditorTextRowViewCell {
				rowCell.moveToStart()
			}
		}
	}

	func completeRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CompleteCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows,
									  textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let deleteIndex = command.changes?.deletes?.first {
			let cursorIndex = deleteIndex < outline.shadowTable?.count ?? 0 ? deleteIndex : (outline.shadowTable?.count ?? 1) - 1
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: cursorIndex, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func uncompleteRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = UncompleteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)
	}
	
	func createRowNotes(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateNoteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let reloadIndex = command.changes?.reloads?.first {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: reloadIndex, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToNote()
			}
		}
	}

	func deleteRowNotes(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = DeleteNoteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)

		if let reloadIndex = command.changes?.reloads?.first {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: reloadIndex, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}

	func makeCellVisibleIfNecessary(indexPath: IndexPath, completion: @escaping () -> Void) {
		guard let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
			completion()
			return
		}
		
		let top = collectionView.contentOffset.y
		let bottom = collectionView.contentOffset.y + collectionView.frame.size.height
		
		guard frame.minY < top || frame.maxY > bottom else {
			completion()
			return
		}
		
		CATransaction.begin()
		CATransaction.setCompletionBlock {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				completion()
			}
		}
		collectionView.scrollRectToVisible(frame, animated: true)
		CATransaction.commit()
	}
}
