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
	
	private var editorRegistration: UICollectionView.CellRegistration<EditorCollectionViewCell, EditorItem>?
	
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

		editorRegistration = UICollectionView.CellRegistration<EditorCollectionViewCell, EditorItem> { (cell, indexPath, editorItem) in
			cell.editorItem = editorItem
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
		return 10
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let editorItem = EditorItem.editorItem(Headline(plainText: "This is a test..."))
		return collectionView.dequeueConfiguredReusableCell(using: editorRegistration!, for: indexPath, item: editorItem)
	}
	
}

extension EditorViewController: EditorCollectionViewCellDelegate {

	func textChanged(item: EditorItem, attributedText: NSAttributedString) {
		if item.attributedText != attributedText {
			outline?.updateHeadline(headlineID: item.id, attributedText: attributedText)
		}
	}
	
	func deleteHeadline(item: EditorItem) {
		outline?.deleteHeadline(headlineID: item.id)
	}
	
	// TODO: Need to take into consideration expanded state when placing the new Headline
	func createHeadline(item: EditorItem) {
//		guard let headline = outline?.createHeadline(afterHeadlineID: item.id) else { return }
	}
	
	func indent(item: EditorItem, attributedText: NSAttributedString) {
		outline?.updateHeadline(headlineID: item.id, attributedText: attributedText)
		guard let (headline, newParentHeadline) = outline?.indentHeadline(headlineID: item.id) else { return }

	}
	
	func outdent(item: EditorItem, attributedText: NSAttributedString) {
		
	}
	
	func moveUp(item: EditorItem) {
	}
	
	func moveDown(item: EditorItem) {
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
