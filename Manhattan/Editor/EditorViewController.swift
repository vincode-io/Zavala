//
//  EditorViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import RSCore
import Templeton

class EditorViewController: UICollectionViewController, MainControllerIdentifiable, UndoableCommandRunner {
	var mainControllerIdentifer: MainControllerIdentifier { return .editor }

	public var isOutlineFunctionsUnavailable: Bool {
		return outline == nil
	}
	
	var isDeleteCurrentHeadlineUnavailable: Bool {
		return currentHeadline == nil
	}
	
	var isCreateHeadlineUnavailable: Bool {
		return currentHeadline == nil
	}
	
	var isIndentHeadlineUnavailable: Bool {
		guard let outline = outline, let headline = currentHeadline else { return true }
		return outline.isIndentHeadlineUnavailable(headline: headline)
	}

	var isOutdentHeadlineUnavailable: Bool {
		guard let outline = outline, let headline = currentHeadline else { return true }
		return outline.isOutdentHeadlineUnavailable(headline: headline)
	}

	var isToggleHeadlineCompleteUnavailable: Bool {
		return currentHeadline == nil
	}

	var isSplitHeadlineUnavailable: Bool {
		return currentHeadline == nil
	}

	var isCurrentHeadlineComplete: Bool {
		return currentHeadline?.isComplete ?? false
	}
	
	var outline: Outline?
	
	var currentTextView: EditorHeadlineTextView? {
		return UIResponder.currentFirstResponder as? EditorHeadlineTextView
	}
	
	var currentHeadline: Headline? {
		return currentTextView?.headline
	}
	
	var currentAttributedText: NSAttributedString? {
		return currentTextView?.attributedText
	}
	
	var currentCursorPosition: Int? {
		return currentTextView?.cursorPosition
	}
	
	var undoableCommands = [UndoableCommand]()
	var currentKeyPresses = Set<UIKeyboardHIDUsage>()
	
	override var canBecomeFirstResponder: Bool { return true }
	
	private var favoriteBarButtonItem: UIBarButtonItem?
	private var filterBarButtonItem: UIBarButtonItem?

	private var titleRegistration: UICollectionView.CellRegistration<EditorTitleViewCell, Outline>?
	private var headerRegistration: UICollectionView.CellRegistration<EditorHeadlineViewCell, Headline>?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			favoriteBarButtonItem = UIBarButtonItem(image: AppAssets.favoriteUnselected, style: .plain, target: self, action: #selector(toggleOutlineIsFavorite(_:)))
			filterBarButtonItem = UIBarButtonItem(image: AppAssets.filterInactive, style: .plain, target: self, action: #selector(toggleOutlineFilter(_:)))
			navigationItem.rightBarButtonItems = [favoriteBarButtonItem!, filterBarButtonItem!]
		}
		
		collectionView.collectionViewLayout = createLayout()
		collectionView.dataSource = self
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.dragInteractionEnabled = true
		collectionView.allowsSelection = false

		titleRegistration = UICollectionView.CellRegistration<EditorTitleViewCell, Outline> { (cell, indexPath, outline) in
			cell.outline = outline
		}
		
		headerRegistration = UICollectionView.CellRegistration<EditorHeadlineViewCell, Headline> { (cell, indexPath, headline) in
			cell.headline = headline
			cell.delegate = self
		}
		
		updateUI()
		collectionView.reloadData()
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
	
	func edit(_ outline: Outline?, isNew: Bool) {
		guard self.outline != outline else { return }
		
		self.outline = outline
		
		if let textField = UIResponder.currentFirstResponder as? EditorHeadlineTextView {
			textField.endEditing(true)
		}
		
		outline?.suspend()
		clearUndoableCommands()
	
		outline?.load()
			
		guard isViewLoaded else { return }
		updateUI()
		collectionView.reloadData()

		if isNew {
			DispatchQueue.main.async {
				if let titleCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? EditorTitleViewCell {
					titleCell.takeCursor()
				}
			}
		}

	}
	
	func deleteCurrentHeadline() {
		guard let headline = currentHeadline else { return }
		deleteHeadline(headline)
	}
	
	func createHeadline() {
		guard let headline = currentHeadline else { return }
		createHeadline(headline)
	}
	
	func indentHeadline() {
		guard let headline = currentHeadline,
			  let attributedText = currentAttributedText else { return }
		indentHeadline(headline, attributedText: attributedText)
	}
	
	func outdentHeadline() {
		guard let headline = currentHeadline,
			  let attributedText = currentAttributedText else { return }
		outdentHeadline(headline, attributedText: attributedText)
	}
	
	func toggleCompleteHeadline() {
		guard let headline = currentHeadline,
			  let attributedText = currentAttributedText else { return }
		toggleCompleteHeadline(headline, attributedText: attributedText)
	}
	
	func splitHeadline() {
		guard let headline = currentHeadline,
			  let attributedText = currentAttributedText,
			  let cursorPosition = currentCursorPosition else { return }
		splitHeadline(headline, attributedText: attributedText, cursorPosition: cursorPosition)
	}
	
	// MARK: Actions
	
	@objc func toggleOutlineIsFavorite(_ sender: Any?) {
		outline?.toggleFavorite()
		updateUI()
	}
	
	@objc func toggleOutlineFilter(_ sender: Any?) {
		guard let changes = outline?.toggleFilter() else { return }
		updateUI()
		applyChangesRestoringCursor(changes)
	}
	
	@objc func repeatMoveCursorUp() {
		if currentKeyPresses.contains(.keyboardUpArrow) {
			if let textView = UIResponder.currentFirstResponder as? EditorHeadlineTextView, !textView.isSelecting, let headline = textView.headline {
				moveCursorUp(headline: headline)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					self.repeatMoveCursorUp()
				}
			}
		}
	}

	@objc func repeatMoveCursorDown() {
		if currentKeyPresses.contains(.keyboardDownArrow) {
			if let textView = UIResponder.currentFirstResponder as? EditorHeadlineTextView, !textView.isSelecting, let headline = textView.headline {
				moveCursorDown(headline: headline)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					self.repeatMoveCursorDown()
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
			let headline = outline?.shadowTable?[indexPath.row] ?? Headline()
			return collectionView.dequeueConfiguredReusableCell(using: headerRegistration!, for: indexPath, item: headline)
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let editorCell = collectionView.cellForItem(at: indexPath) as? EditorHeadlineViewCell,
			  let headline = editorCell.headline,
			  let attributedText = editorCell.attributedText else { return nil }
		
		return makeHeadlineContextMenu(headline: headline, attributedText: attributedText)
	}
	
	override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		guard let headline = configuration.identifier as? Headline,
			  let row = headline.shadowTableIndex,
			  let cell = collectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? EditorHeadlineViewCell else { return nil }
		
		return UITargetedPreview(view: cell, parameters: EditorHeadlinePreviewParameters(cell: cell, headline: headline))
	}
	
}

extension EditorViewController: EditorHeadlineViewCellDelegate {

	func invalidateLayout() {
		collectionView.collectionViewLayout.invalidateLayout()
	}

	func toggleDisclosure(headline: Headline) {
		guard let undoManager = undoManager, let outline = outline else { return }
		let command = EditorToggleDisclosureCommand(undoManager: undoManager,
													delegate: self,
													outline: outline,
													headline: headline)
		runCommand(command)
	}

	func textChanged(headline: Headline, attributedText: NSAttributedString) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorTextChangedCommand(undoManager: undoManager,
											   delegate: self,
											   outline: outline,
											   headline: headline,
											   attributedText: attributedText)
		runCommand(command)
	}
	
	func deleteHeadline(_ headline: Headline) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = EditorDeleteHeadlineCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  headline: headline)

		runCommand(command)
		
		if let deleteIndex = command.changes?.deletes?.first {
			if deleteIndex > 0, let target = collectionView.cellForItem(at: IndexPath(row: deleteIndex - 1, section: 1)) as? TextCursorTarget {
				target.moveToEnd()
			}
		}
	}
	
	func createHeadline(_ afterHeadline: Headline) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = EditorCreateHeadlineCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  afterHeadline: afterHeadline)
		
		runCommand(command)
		
		if let insert = command.changes?.insertIndexPaths?.first {
			if let textCursor = collectionView.cellForItem(at: insert) as? TextCursorTarget {
				textCursor.moveToEnd()
			}
		}
	}
	
	func indentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorIndentHeadlineCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  headline: headline,
												  attributedText: attributedText)
		
		runCommand(command)
	}
	
	func outdentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorOutdentHeadlineCommand(undoManager: undoManager,
												  delegate: self,
												  outline: outline,
												  headline: headline,
												  attributedText: attributedText)
		
		runCommand(command)
	}

	func splitHeadline(_ headline: Headline, attributedText: NSAttributedString, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = EditorSplitHeadlineCommand(undoManager: undoManager,
												 delegate: self,
												 outline: outline,
												 headline: headline,
												 attributedText: attributedText,
												 cursorPosition: cursorPosition)
												  
		
		runCommand(command)
		
		if let insert = command.changes?.insertIndexPaths?.first {
			if let textCursor = collectionView.cellForItem(at: insert) as? TextCursorTarget {
				textCursor.moveToStart()
			}
		}
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
		var cursorHeadline: Headline? = nil
		if let editorTextView = UIResponder.currentFirstResponder as? EditorHeadlineTextView {
			textRange = editorTextView.selectedTextRange
			cursorHeadline = editorTextView.headline
		}
		
		applyChanges(changes)
		
		if let textRange = textRange,
		   let updated = cursorHeadline?.shadowTableIndex,
		   let textCursor = collectionView.cellForItem(at: IndexPath(row: updated, section: 1)) as? TextCursorTarget {
			textCursor.restoreSelection(textRange)
		}
	}
}

// MARK: Helpers

private extension EditorViewController {
	
	private func updateUI() {
		navigationItem.title = outline?.title
		navigationItem.largeTitleDisplayMode = .never
		
		if traitCollection.userInterfaceIdiom != .mac {
			if outline?.isFavorite ?? false {
				favoriteBarButtonItem?.image = AppAssets.favoriteSelected
			} else {
				favoriteBarButtonItem?.image = AppAssets.favoriteUnselected
			}
			if outline?.isFiltered ?? false {
				filterBarButtonItem?.image = AppAssets.filterActive
			} else {
				filterBarButtonItem?.image = AppAssets.filterInactive
			}
		}
	}
	
	private func makeHeadlineContextMenu(headline: Headline, attributedText: NSAttributedString) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: headline as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self, let outline = self.outline else { return nil }
			
			var mainActions = [UIAction]()
			mainActions.append(self.addAction(headline: headline))

			if !outline.isIndentHeadlineUnavailable(headline: headline) {
				mainActions.append(self.indentAction(headline: headline, attributedText: attributedText))
			}
			
			if !outline.isOutdentHeadlineUnavailable(headline: headline) {
				mainActions.append(self.outdentAction(headline: headline, attributedText: attributedText))
			}
			
			let menuItems = [
				UIMenu(title: "", options: .displayInline, children: mainActions),
				UIMenu(title: "", options: .displayInline, children: [self.toggleCompleteAction(headline: headline, attributedText: attributedText)]),
				UIMenu(title: "", options: .displayInline, children: [self.deleteAction(headline: headline)]),
			]

			return UIMenu(title: "", children: menuItems)
		})
	}
	
	private func addAction(headline: Headline) -> UIAction {
		let action = UIAction(title: L10n.addRow, image: AppAssets.add) { [weak self] action in
			// Have to let the text field get the first responder by getting it away from this
			// action which appears to be holding on to it.
			DispatchQueue.main.async {
				self?.createHeadline(headline)
			}
		}
		return action
	}

	private func indentAction(headline: Headline, attributedText: NSAttributedString) -> UIAction {
		let action = UIAction(title: L10n.indent, image: AppAssets.indent) { [weak self] action in
			self?.indentHeadline(headline, attributedText: attributedText)
		}
		return action
	}

	private func outdentAction(headline: Headline, attributedText: NSAttributedString) -> UIAction {
		let action = UIAction(title: L10n.outdent, image: AppAssets.outdent) { [weak self] action in
			self?.outdentHeadline(headline, attributedText: attributedText)
		}
		return action
	}

	private func toggleCompleteAction(headline: Headline, attributedText: NSAttributedString) -> UIAction {
		let title = headline.isComplete ?? false ? L10n.uncomplete : L10n.complete
		let image = headline.isComplete ?? false ? AppAssets.uncompleteHeadline : AppAssets.completeHeadline
		let action = UIAction(title: title, image: image) { [weak self] action in
			self?.toggleCompleteHeadline(headline, attributedText: attributedText)
		}
		return action
	}

	private func deleteAction(headline: Headline) -> UIAction {
		let action = UIAction(title: L10n.delete, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteHeadline(headline)
		}
		return action
	}

	func moveCursorUp(headline: Headline) {
		guard let shadowTableIndex = headline.shadowTableIndex, shadowTableIndex > 0 else { return }
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: 1)
		if let target = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
			target.moveToEnd()
		}
	}
	
	func moveCursorDown(headline: Headline) {
		guard let shadowTableIndex = headline.shadowTableIndex, let shadowTable = outline?.shadowTable, shadowTableIndex < (shadowTable.count - 1) else { return }
		let indexPath = IndexPath(row: shadowTableIndex + 1, section: 1)
		if let target = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
			target.moveToEnd()
		}
	}
	
	func toggleCompleteHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorToggleCompleteHeadlineCommand(undoManager: undoManager,
														  delegate: self,
														  outline: outline,
														  headline: headline,
														  attributedText: attributedText)
		
		runCommand(command)
		
		if let deleteIndex = command.changes?.deletes?.first {
			let cursorIndex = deleteIndex < outline.shadowTable?.count ?? 0 ? deleteIndex : (outline.shadowTable?.count ?? 1) - 1
			if let target = collectionView.cellForItem(at: IndexPath(row: cursorIndex, section: 1)) as? TextCursorTarget {
				target.moveToEnd()
			}
		}
		
	}
	

}
