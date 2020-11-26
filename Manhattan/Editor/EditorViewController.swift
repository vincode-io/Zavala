//
//  EditorViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import RSCore
import Templeton

class EditorViewController: UICollectionViewController {

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
		}
		
		didSet {
			if oldValue != outline {
				outline?.load()
				
				guard isViewLoaded else { return }
				updateUI()
				collectionView.reloadData()
			}
		}
		
	}
	
	var currentKeyPresses = Set<UIKeyboardHIDUsage>()
	
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
		
		collectionView.allowsSelection = false
		collectionView.collectionViewLayout = createLayout()
		collectionView.dataSource = self

		editorRegistration = UICollectionView.CellRegistration<EditorCollectionViewCell, Headline> { (cell, indexPath, headline) in
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
			if let headline = (UIResponder.currentFirstResponder as? EditorTextView)?.headline {
				moveCursorUp(headline: headline)
			}
		case .keyboardDownArrow:
			currentKeyPresses.insert(key.keyCode)
			if let headline = (UIResponder.currentFirstResponder as? EditorTextView)?.headline {
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
		let headline = outline!.shadowTable![indexPath.row]
		return collectionView.dequeueConfiguredReusableCell(using: editorRegistration!, for: indexPath, item: headline)
	}
	
}

extension EditorViewController: EditorCollectionViewCellDelegate {

	func toggleDisclosure(headline: Headline) {
		guard let outline = outline else { return }
		let changes = outline.toggleDisclosure(headline: headline)
		
		if let deletes = changes.deletes {
			let indexPaths = deletes.map { IndexPath(row: $0, section: 0) }
			collectionView.deleteItems(at: indexPaths)
		}

		if let inserts = changes.inserts {
			let indexPaths = inserts.map { IndexPath(row: $0, section: 0) }
			collectionView.insertItems(at: indexPaths)
		}
	}

	func textChanged(headline: Headline, attributedText: NSAttributedString) {
		if headline.attributedText != attributedText {
			outline?.updateHeadline(headline: headline, attributedText: attributedText)
		}
	}
	
	func deleteHeadline(_ headline: Headline) {
		if let deleteIndex = outline?.deleteHeadline(headline: headline) {
			collectionView.deleteItems(at: [IndexPath(row: deleteIndex, section: 0)])
			if deleteIndex > 0, let target = collectionView.cellForItem(at: IndexPath(row: deleteIndex - 1, section: 0)) as? TextCursorTarget {
				target.moveToEnd()
			}
		}
	}
	
	// TODO: Need to take into consideration expanded state when placing the new Headline
	func createHeadline(_ headline: Headline) {
		if let insertIndex = outline?.createHeadline(afterHeadline: headline) {
			let indexPath = IndexPath(row: insertIndex, section: 0)
			collectionView.insertItems(at: [indexPath])
			if let textCursor = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
				textCursor.moveToEnd()
			}
		}
	}
	
	func indentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		guard let headlineShadowTableIndex = headline.shadowTableIndex else { return }
		
		if let reloadIndexes = outline?.indentHeadline(headline: headline, attributedText: attributedText) {
			var textRange: UITextRange? = nil
			let indexPath = IndexPath(row: headlineShadowTableIndex, section: 0)
			if let textCursor = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
				textRange = textCursor.selectionRange
			}
			
			let indexPaths = reloadIndexes.map { IndexPath(row: $0, section: 0) }
			collectionView.reloadItems(at: indexPaths)
			
			if let textRange = textRange, let textCursor = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
				textCursor.restoreSelection(textRange)
			}
		}
	}
	
	func outdentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		
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

// MARK: Helpers

private extension EditorViewController {
	
	private func updateUI() {
		navigationItem.title = outline?.title
		navigationItem.largeTitleDisplayMode = .never
		
		if outline?.isFavorite ?? false {
			favoriteBarButtonItem?.image = AppAssets.favoriteSelected
		} else {
			favoriteBarButtonItem?.image = AppAssets.favoriteUnselected
		}
	}
	
}
