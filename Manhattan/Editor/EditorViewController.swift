//
//  EditorViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import RSCore
import Templeton

class EditorViewController: UICollectionViewController, UndoableCommandRunner {

	public var isToggleFavoriteUnavailable: Bool {
		return outline == nil
	}
	
	var outline: Outline? {
		
		willSet {
			if let textField = UIResponder.currentFirstResponder as? EditorTextView {
				textField.endEditing(true)
			}
			outline?.suspend()
			outline?.headlines = nil
			clearUndoableCommands()
		}
		
		didSet {
			if oldValue != outline {
				outline?.load()
				
				guard isViewLoaded else { return }
				updateUI()
				collectionView.reloadData()
				moveCursorToFirstItem()
			}
		}
		
	}
	
	var undoableCommands = [UndoableCommand]()
	var currentKeyPresses = Set<UIKeyboardHIDUsage>()
	
	override var canBecomeFirstResponder: Bool { return true }
	
	private var favoriteBarButtonItem: UIBarButtonItem?
	
	private var editorRegistration: UICollectionView.CellRegistration<EditorCollectionViewCell, Headline>?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			favoriteBarButtonItem = UIBarButtonItem(image: AppAssets.favoriteUnselected, style: .plain, target: self, action: #selector(toggleOutlineIsFavorite(_:)))
			navigationItem.rightBarButtonItem = favoriteBarButtonItem
		}
		
		collectionView.collectionViewLayout = createLayout()
		collectionView.dataSource = self

		editorRegistration = UICollectionView.CellRegistration<EditorCollectionViewCell, Headline> { (cell, indexPath, headline) in
			cell.headline = headline
			cell.delegate = self
		}
		
		updateUI()
		collectionView.reloadData()
		moveCursorToFirstItem()
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesBegan(presses, with: event)

		guard let key = presses.first?.key else { return }
		switch key.keyCode {
		case .keyboardUpArrow:
			currentKeyPresses.insert(key.keyCode)
			if let textView = UIResponder.currentFirstResponder as? EditorTextView, !textView.isSelecting, let headline = textView.headline {
				moveCursorUp(headline: headline)
			}
		case .keyboardDownArrow:
			currentKeyPresses.insert(key.keyCode)
			if let textView = UIResponder.currentFirstResponder as? EditorTextView, !textView.isSelecting, let headline = textView.headline {
				moveCursorDown(headline: headline)
			}
		default:
			break
		}
	}
	
	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesEnded(presses, with: event)

		guard let key = presses.first?.key else { return }
		switch key.keyCode {
		case .keyboardUpArrow, .keyboardDownArrow:
			currentKeyPresses.remove(key.keyCode)
		default:
			break
		}
	}
	
	// MARK: Actions
	
	@objc func toggleOutlineIsFavorite(_ sender: Any?) {
		outline?.toggleFavorite()
		updateUI()
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
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return outline?.shadowTable?.count ?? 0
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let headline: Headline
		if let shadowTableEntry = outline?.shadowTable?[indexPath.row] {
			headline = shadowTableEntry
		} else {
			headline = Headline()
		}
		return collectionView.dequeueConfiguredReusableCell(using: editorRegistration!, for: indexPath, item: headline)
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let text = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
			text.moveToEnd()
		}
		collectionView.deselectItem(at: indexPath, animated: false)
	}
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let editorCell = collectionView.cellForItem(at: indexPath) as? EditorCollectionViewCell,
			  let headline = editorCell.headline,
			  let attributedText = editorCell.attributedText else { return nil }
		
		return makeHeadlineContextMenu(headline: headline, attributedText: attributedText)
	}
	
}

extension EditorViewController: EditorCollectionViewCellDelegate {

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
			if deleteIndex > 0, let target = collectionView.cellForItem(at: IndexPath(row: deleteIndex - 1, section: 0)) as? TextCursorTarget {
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
	
	func toggleCompleteHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = EditorToggleCompleteHeadlineCommand(undoManager: undoManager,
														  delegate: self,
														  outline: outline,
														  headline: headline,
														  attributedText: attributedText)
		
		runCommand(command)
	}
	
	func moveCursorUp(headline: Headline) {
		guard let shadowTableIndex = headline.shadowTableIndex, shadowTableIndex > 0 else { return }
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: 0)
		if let target = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
			target.moveToEnd()
		}
	}
	
	func moveCursorDown(headline: Headline) {
		guard let shadowTableIndex = headline.shadowTableIndex, let shadowTable = outline?.shadowTable, shadowTableIndex < (shadowTable.count - 1) else { return }
		let indexPath = IndexPath(row: shadowTableIndex + 1, section: 0)
		if let target = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
			target.moveToEnd()
		}
	}
	
}

// MARK: EditorOutlineCommandDelegate

extension EditorViewController: EditorOutlineCommandDelegate {
	
	func applyChanges(_ changes: ShadowTableChanges) {
		if let deletes = changes.deleteIndexPaths {
			collectionView.deleteItems(at: deletes)
		}
		if let moves = changes.moveIndexPaths {
			collectionView.performBatchUpdates {
				for move in moves {
					collectionView.moveItem(at: move.0, to: move.1)
				}
			}
		}
		if let inserts = changes.insertIndexPaths {
			collectionView.insertItems(at: inserts)
		}
		if let reloads = changes.reloadIndexPaths {
			collectionView.reloadItems(at: reloads)
		}
	}
	
	func applyChangesRestoringCursor(_ changes: ShadowTableChanges) {
		var textRange: UITextRange? = nil
		var cursorHeadline: Headline? = nil
		if let editorTextView = UIResponder.currentFirstResponder as? EditorTextView {
			textRange = editorTextView.selectedTextRange
			cursorHeadline = editorTextView.headline
		}
		
		applyChanges(changes)
		
		if let textRange = textRange,
		   let updated = cursorHeadline?.shadowTableIndex,
		   let textCursor = collectionView.cellForItem(at: IndexPath(row: updated, section: 0)) as? TextCursorTarget {
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
		}
	}
	
	private func moveCursorToFirstItem() {
		DispatchQueue.main.async {
			if let textCursor = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? TextCursorTarget {
				textCursor.moveToEnd()
			}
		}
	}
	
	private func makeHeadlineContextMenu(headline: Headline, attributedText: NSAttributedString) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: headline as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }
			
			let menuItems = [
				UIMenu(title: "", options: .displayInline, children: [self.getToggleCompleteAction(headline: headline, attributedText: attributedText)]),
			]

			return UIMenu(title: "", children: menuItems.compactMap { $0 })
		})
	}
	
	private func getToggleCompleteAction(headline: Headline, attributedText: NSAttributedString) -> UIAction {
		let title = headline.isComplete ?? false ? L10n.uncomplete : L10n.complete
		let action = UIAction(title: title, image: AppAssets.completeHeadline) { [weak self] action in
			self?.toggleCompleteHeadline(headline, attributedText: attributedText)
		}
		return action
	}
}
