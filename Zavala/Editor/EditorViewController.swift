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
	
	var isDeleteCurrentRowUnavailable: Bool {
		return currentRow == nil
	}
	
	var isCreateRowUnavailable: Bool {
		return currentRow == nil
	}
	
	var isIndentRowUnavailable: Bool {
		guard let outline = outline, let row = currentRow else { return true }
		return outline.isIndentRowUnavailable(row: row)
	}

	var isOutdentRowUnavailable: Bool {
		guard let outline = outline, let row = currentRow else { return true }
		return outline.isOutdentRowUnavailable(row: row)
	}

	var isToggleRowCompleteUnavailable: Bool {
		return currentRow == nil
	}

	var isCurrentRowComplete: Bool {
		return currentRow?.isComplete ?? false
	}
	
	var isCreateRowNoteUnavailable: Bool {
		return currentRow == nil || !currentRow!.isNoteEmpty
	}

	var isDeleteRowNoteUnavailable: Bool {
		return currentRow == nil || currentRow!.isNoteEmpty
	}

	var isCurrentRowNoteEmpty: Bool {
		return currentRow?.isNoteEmpty ?? false
	}
	
	var isSplitRowUnavailable: Bool {
		return currentRow == nil
	}

	var isFormatUnavailable: Bool {
		return currentTextView == nil || !(currentTextView?.isSelecting ?? false)
	}

	var isLinkUnavailable: Bool {
		return currentTextView == nil || !(currentTextView?.isSelecting ?? false)
	}

	var isExpandAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isExpandAllUnavailable(container: outline!)
	}

	var isCollapseAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isCollapseAllUnavailable(container: outline!)
	}

	var isExpandAllUnavailable: Bool {
		guard let outline = outline, let row = currentRow else { return true }
		return outline.isExpandAllUnavailable(container: row)
	}

	var isCollapseAllUnavailable: Bool {
		guard let outline = outline, let row = currentRow else { return true }
		return outline.isCollapseAllUnavailable(container: row)
	}

	var isExpandUnavailable: Bool {
		return !(currentRow?.isExpandable ?? false)
	}

	var isCollapseUnavailable: Bool {
		return !(currentRow?.isCollapsable ?? false)
	}

	private(set) var outline: Outline?
	
	var currentTextView: OutlineTextView? {
		return UIResponder.currentFirstResponder as? OutlineTextView
	}
	
	var currentRow: TextRow? {
		return currentTextView?.textRow
	}
	
	var currentTextRowStrings: TextRowStrings? {
		return currentTextView?.textRowStrings
	}
	
	var currentCursorPosition: Int? {
		return currentTextView?.cursorPosition
	}
	
	var undoableCommands = [UndoableCommand]()
	var currentKeyPresses = Set<UIKeyboardHIDUsage>()
	
	override var canBecomeFirstResponder: Bool { return true }
	
	private var filterBarButtonItem: UIBarButtonItem?

	private var titleRegistration: UICollectionView.CellRegistration<EditorTitleViewCell, Outline>?
	private var headerRegistration: UICollectionView.CellRegistration<EditorTextRowViewCell, TextRow>?
	
	private var firstVisibleShadowTableIndex: Int? {
		let visibleRect = collectionView.layoutMarginsGuide.layoutFrame
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.minY)
		if let indexPath = collectionView.indexPathForItem(at: visiblePoint), indexPath.section == 1 {
			return indexPath.row
		}
		return nil
	}

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
		collectionView.allowsSelection = false

		titleRegistration = UICollectionView.CellRegistration<EditorTitleViewCell, Outline> { (cell, indexPath, outline) in
			cell.outline = outline
			cell.delegate = self
		}
		
		headerRegistration = UICollectionView.CellRegistration<EditorTextRowViewCell, TextRow> { (cell, indexPath, row) in
			cell.textRow = row
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
	
	func deleteCurrentRow() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		deleteRow(row, textRowStrings: textRowStrings)
	}
	
	func createRow() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		createRow(afterRow: row, textRowStrings: textRowStrings)
	}
	
	func indentRow() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		indentRow(row, textRowStrings: textRowStrings)
	}
	
	func outdentRow() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		outdentRow(row, textRowStrings: textRowStrings)
	}
	
	func toggleCompleteRow() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		toggleCompleteRow(row, textRowStrings: textRowStrings)
	}
	
	func createRowNote() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		createRowNote(row, textRowStrings: textRowStrings)
	}
	
	func deleteRowNote() {
		guard let row = currentRow,
			  let textRowStrings = currentTextRowStrings else { return }
		deleteRowNote(row, textRowStrings: textRowStrings)
	}
	
	func splitRow() {
		guard let row = currentRow,
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
		expandAll(container: outline)
	}
	
	func collapseAllInOutline() {
		guard let outline = outline else { return }
		collapseAll(container: outline)
	}
	
	func expandAll() {
		guard let row = currentRow else { return }
		expandAll(container: row)
	}
	
	func collapseAll() {
		guard let row = currentRow else { return }
		collapseAll(container: row)
	}
	
	func expand() {
		guard let row = currentRow else { return }
		toggleDisclosure(row: row)
	}
	
	func collapse() {
		guard let row = currentRow else { return }
		toggleDisclosure(row: row)
	}
	
	// MARK: Actions
	
	@objc func toggleOutlineFilter(_ sender: Any?) {
		guard let changes = outline?.toggleFilter() else { return }
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
			if let textView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView, !textView.isSelecting, let row = textView.textRow {
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
			if let textView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView, !textView.isSelecting, let row = textView.textRow {
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
			let row = outline?.shadowTable?[indexPath.row] ?? TextRow()
			return collectionView.dequeueConfiguredReusableCell(using: headerRegistration!, for: indexPath, item: row)
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let editorCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell,
			  let row = editorCell.textRow,
			  let textRowStrings = editorCell.textRowStrings else { return nil }
		
		return makeRowContextMenu(row: row, textRowStrings: textRowStrings)
	}
	
	override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		guard let row = configuration.identifier as? TextRow,
			  let rowShadowTableIndex = row.shadowTableIndex,
			  let cell = collectionView.cellForItem(at: IndexPath(row: rowShadowTableIndex, section: 1)) as? EditorTextRowViewCell else { return nil }
		
		return UITargetedPreview(view: cell, parameters: EditorTextRowPreviewParameters(cell: cell, row: row))
	}
	
}

extension EditorViewController: EditorTitleViewCellDelegate {
	
	var editorTitleUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTitleInvalidateLayout() {
		collectionView.collectionViewLayout.invalidateLayout()
	}
	
	func editorTitleCreateRow(textRowStrings: TextRowStrings?) {
		createRow(afterRow: nil, textRowStrings: textRowStrings)
	}
	
}

extension EditorViewController: EditorTextRowViewCellDelegate {

	var editorTextRowUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTextRowInvalidateLayout() {
		collectionView.collectionViewLayout.invalidateLayout()
	}
	
	func editorTextRowToggleDisclosure(row: TextRow) {
		toggleDisclosure(row: row)
	}
	
	func editorTextRowTextChanged(row: TextRow, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		textChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func editorTextRowDeleteRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		deleteRow(row, textRowStrings: textRowStrings)
	}
	
	func editorTextRowCreateRow(beforeRow: TextRow) {
		createRow(beforeRow: beforeRow)
	}
	
	func editorTextRowCreateRow(afterRow: TextRow?, textRowStrings: TextRowStrings?) {
		createRow(afterRow: afterRow, textRowStrings: textRowStrings)
	}
	
	func editorTextRowIndentRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		indentRow(row, textRowStrings: textRowStrings)
	}
	
	func editorTextRowOutdentRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		outdentRow(row, textRowStrings: textRowStrings)
	}
	
	func editorTextRowSplitRow(_ row: TextRow, topic: NSAttributedString, cursorPosition: Int) {
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editorTextRowCreateRowNote(_ row: TextRow, textRowStrings: TextRowStrings) {
		createRowNote(row, textRowStrings: textRowStrings)
	}
	
	func editorTextRowDeleteRowNote(_ row: TextRow, textRowStrings: TextRowStrings) {
		deleteRowNote(row, textRowStrings: textRowStrings)
	}
	
	func editorTextRowMoveCursorTo(row: TextRow) {
		moveCursorTo(row: row)
		hasAlreadyMovedThisKeyPressFlag = true
	}
	
	func editorTextRowMoveCursorDown(row: TextRow) {
		moveCursorDown(row: row)
		hasAlreadyMovedThisKeyPressFlag = true
	}
	
	func editorTextRowEditLink(_ link: String?, range: NSRange) {
		editLink(link, range: range)
	}

}

// MARK: EditorOutlineCommandDelegate

extension EditorViewController: EditorOutlineCommandDelegate {
	
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
		var cursorRow: TextRow? = nil
		if let editorTextView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView {
			textRange = editorTextView.selectedTextRange
			cursorRow = editorTextView.textRow
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
	
	private func makeRowContextMenu(row: TextRow, textRowStrings: TextRowStrings) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: row as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self, let outline = self.outline else { return nil }
			
			var menuItems = [UIMenu]()

			var firstOutlineActions = [UIAction]()
			firstOutlineActions.append(self.addAction(row: row, textRowStrings: textRowStrings))
			if !outline.isIndentRowUnavailable(row: row) {
				firstOutlineActions.append(self.indentAction(row: row, textRowStrings: textRowStrings))
			}
			if !outline.isOutdentRowUnavailable(row: row) {
				firstOutlineActions.append(self.outdentAction(row: row, textRowStrings: textRowStrings))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: firstOutlineActions))
			
			var secondOutlineActions = [UIAction]()
			secondOutlineActions.append(self.toggleCompleteAction(row: row, textRowStrings: textRowStrings))
			secondOutlineActions.append(self.toggleNoteAction(row: row, textRowStrings: textRowStrings))
			menuItems.append(UIMenu(title: "", options: .displayInline, children: secondOutlineActions))

			var viewActions = [UIAction]()
			if !outline.isExpandAllUnavailable(container: row) {
				viewActions.append(self.expandAllAction(row: row))
			}
			if !outline.isCollapseAllUnavailable(container: row) {
				viewActions.append(self.collapseAllAction(row: row))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: viewActions))
			
			let deleteAction = self.deleteAction(row: row, textRowStrings: textRowStrings)
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [deleteAction]))

			return UIMenu(title: "", children: menuItems)
		})
	}
	
	private func addAction(row: TextRow, textRowStrings: TextRowStrings) -> UIAction {
		return UIAction(title: L10n.addRow, image: AppAssets.add) { [weak self] action in
			// Have to let the text field get the first responder by getting it away from this
			// action which appears to be holding on to it.
			DispatchQueue.main.async {
				self?.createRow(afterRow: row, textRowStrings: textRowStrings)
			}
		}
	}

	private func indentAction(row: TextRow, textRowStrings: TextRowStrings) -> UIAction {
		return UIAction(title: L10n.indent, image: AppAssets.indent) { [weak self] action in
			self?.indentRow(row, textRowStrings: textRowStrings)
		}
	}

	private func outdentAction(row: TextRow, textRowStrings: TextRowStrings) -> UIAction {
		return UIAction(title: L10n.outdent, image: AppAssets.outdent) { [weak self] action in
			self?.outdentRow(row, textRowStrings: textRowStrings)
		}
	}

	private func expandAllAction(row: TextRow) -> UIAction {
		return UIAction(title: L10n.expandAll, image: AppAssets.expandAll) { [weak self] action in
			self?.expandAll(container: row)
		}
	}

	private func collapseAllAction(row: TextRow) -> UIAction {
		return UIAction(title: L10n.collapseAll, image: AppAssets.collapseAll) { [weak self] action in
			self?.collapseAll(container: row)
		}
	}

	private func toggleCompleteAction(row: TextRow, textRowStrings: TextRowStrings) -> UIAction {
		let title = row.isComplete ?? false ? L10n.uncomplete : L10n.complete
		let image = row.isComplete ?? false ? AppAssets.uncompleteRow : AppAssets.completeRow
		return UIAction(title: title, image: image) { [weak self] action in
			self?.toggleCompleteRow(row, textRowStrings: textRowStrings)
		}
	}
	
	private func toggleNoteAction(row: TextRow, textRowStrings: TextRowStrings) -> UIAction {
		if row.isNoteEmpty {
			return UIAction(title: L10n.addNote, image: AppAssets.note) { [weak self] action in
				self?.createRowNote(row, textRowStrings: textRowStrings)
			}
		} else {
			return UIAction(title: L10n.deleteNote, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
				self?.deleteRowNote(row, textRowStrings: textRowStrings)
			}
		}
	}

	private func deleteAction(row: TextRow, textRowStrings: TextRowStrings) -> UIAction {
		return UIAction(title: L10n.deleteRow, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteRow(row, textRowStrings: textRowStrings)
		}
	}

	func moveCursorTo(row: TextRow) {
		guard let shadowTableIndex = row.shadowTableIndex else {
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex, section: 1)
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
			rowCell.moveToEnd()
		}
	}
	
	func moveCursorUp(row: TextRow) {
		guard let shadowTableIndex = row.shadowTableIndex, shadowTableIndex > 0 else {
			moveCursorToTitle()
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: 1)
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
			rowCell.moveToEnd()
		}
	}
	
	func moveCursorDown(row: TextRow) {
		guard let shadowTableIndex = row.shadowTableIndex, let shadowTable = outline?.shadowTable, shadowTableIndex < (shadowTable.count - 1) else { return }
		let indexPath = IndexPath(row: shadowTableIndex + 1, section: 1)
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
			rowCell.moveToEnd()
		}
	}
	
	func toggleDisclosure(row: TextRow) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorToggleDisclosureCommand(undoManager: undoManager,
													delegate: self,
													outline: outline,
													row: row)
		
		runCommand(command)
	}

	func expandAll(container: RowContainer) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorExpandAllCommand(undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 container: container)
		
		runCommand(command)
	}

	func collapseAll(container: RowContainer) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorCollapseAllCommand(undoManager: undoManager,
											   delegate: self,
											   outline: outline,
											   container: container)

		runCommand(command)
	}

	func textChanged(row: TextRow, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorTextChangedCommand(undoManager: undoManager,
											   delegate: self,
											   outline: outline,
											   row: row,
											   textRowStrings: textRowStrings,
											   isInNotes: isInNotes,
											   cursorPosition: cursorPosition)
		runCommand(command)
	}
	
	func deleteRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = EditorDeleteRowCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  row: row,
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
	
	func createRow(beforeRow: TextRow) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorCreateRowBeforeCommand(undoManager: undoManager,
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
	
	func createRow(afterRow: TextRow?, textRowStrings: TextRowStrings?) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = EditorCreateRowAfterCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  afterRow: afterRow,
												  textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let insert = command.changes?.insertIndexPaths?.first {
			if let rowCell = collectionView.cellForItem(at: insert) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func indentRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorIndentRowCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  row: row,
												  textRowStrings: textRowStrings)
		
		runCommand(command)
	}
	
	func outdentRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorOutdentRowCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  row: row,
												  textRowStrings: textRowStrings)
		
		runCommand(command)
	}

	func splitRow(_ row: TextRow, topic: NSAttributedString, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = EditorSplitRowCommand(undoManager: undoManager,
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

	func toggleCompleteRow(_ row: TextRow, textRowStrings: TextRowStrings) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorToggleCompleteRowCommand(undoManager: undoManager,
														  delegate: self,
														  outline: outline,
														  row: row,
														  textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let deleteIndex = command.changes?.deletes?.first {
			let cursorIndex = deleteIndex < outline.shadowTable?.count ?? 0 ? deleteIndex : (outline.shadowTable?.count ?? 1) - 1
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: cursorIndex, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	func createRowNote(_ row: TextRow, textRowStrings: TextRowStrings) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorCreateNoteCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  row: row,
											  textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let reloadIndex = command.changes?.reloads?.first {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: reloadIndex, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToNote()
			}
		}
	}

	func deleteRowNote(_ row: TextRow, textRowStrings: TextRowStrings) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorDeleteNoteCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  row: row,
											  textRowStrings: textRowStrings)
		
		runCommand(command)

		if let reloadIndex = command.changes?.reloads?.first {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: reloadIndex, section: 1)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}

}
