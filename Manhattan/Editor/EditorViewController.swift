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
			cell.indentationLevel = headline.indentLevel ?? 0
			cell.headline = headline
			cell.delegate = self
		}
		
		updateUI()
		collectionView.reloadData()
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
		
	}

	func textChanged(headline: Headline, attributedText: NSAttributedString) {
		if headline.attributedText != attributedText {
			outline?.updateHeadline(headline: headline, attributedText: attributedText)
		}
	}
	
	func deleteHeadline(headline: Headline) {
		if let deleteIndex = outline?.deleteHeadline(headline: headline) {
			collectionView.deleteItems(at: [IndexPath(row: deleteIndex, section: 0)])
			if deleteIndex > 0, let textCursor = collectionView.cellForItem(at: IndexPath(row: deleteIndex - 1, section: 0)) as? TextCursorTarget {
				textCursor.moveToEnd()
			}
		}
	}
	
	// TODO: Need to take into consideration expanded state when placing the new Headline
	func createHeadline(headline: Headline) {
		if let insertIndex = outline?.createHeadline(afterHeadline: headline) {
			let indexPath = IndexPath(row: insertIndex, section: 0)
			collectionView.insertItems(at: [indexPath])
			if let textCursor = collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
				textCursor.moveToEnd()
			}
		}
	}
	
	func indent(headline: Headline, attributedText: NSAttributedString) {
//		outline?.updateHeadline(headline: headline, attributedText: attributedText)
//		outline?.indentHeadline(headline: headline)
	}
	
	func outdent(headline: Headline, attributedText: NSAttributedString) {
		
	}
	
	func moveUp(headline: Headline) {
	}
	
	func moveDown(headline: Headline) {
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
