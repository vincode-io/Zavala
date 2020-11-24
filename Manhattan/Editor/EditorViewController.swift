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
		return 10
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		// TODO: Do a look up for the Headline in the Outline
		let headline = Headline(plainText: "Just some testing...")
		return collectionView.dequeueConfiguredReusableCell(using: editorRegistration!, for: indexPath, item: headline)
	}
	
}

extension EditorViewController: EditorCollectionViewCellDelegate {

	func textChanged(headline: Headline, attributedText: NSAttributedString) {
		if headline.attributedText != attributedText {
			outline?.updateHeadline(headline: headline, attributedText: attributedText)
		}
	}
	
	func deleteHeadline(headline: Headline) {
		outline?.deleteHeadline(headline: headline)
	}
	
	// TODO: Need to take into consideration expanded state when placing the new Headline
	func createHeadline(headline: Headline) {
		outline?.createHeadline(afterHeadline: headline)
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
