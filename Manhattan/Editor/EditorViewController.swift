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
				applySnapshot(animated: false)
				moveCursorToInitialPosition()
			}
		}
		
	}
	
	private var favoriteBarButtonItem: UIBarButtonItem?
	
	private let dataSourceQueue = MainThreadOperationQueue()
	private var dataSource: UICollectionViewDiffableDataSource<Int, EditorItem>!
	
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
		configureDataSource()

		updateUI()
		applySnapshot(animated: false)
		moveCursorToInitialPosition()
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
	
	private func configureDataSource() {
		let editorRegistration = UICollectionView.CellRegistration<EditorCollectionViewCell, EditorItem> { (cell, indexPath, item) in
			cell.editorItem = item
			cell.delegate = self
		}

		dataSource = UICollectionViewDiffableDataSource<Int, EditorItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: editorRegistration, for: indexPath, item: item)
		}
		
		dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] item in
			self?.outline?.expandHeadline(headlineID: item.id)
		}
		
		dataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] item in
			self?.outline?.collapseHeadline(headlineID: item.id)
		}
		
	}
	
	private func delete(items: [EditorItem], animated: Bool) {
		dataSourceQueue.add(DeleteItemsOperation(dataSource: dataSource, section: 0, items: items, animated: animated))
	}

	private func insert(items: [EditorItem], afterItem: EditorItem, animated: Bool) {
		dataSourceQueue.add(InsertItemsOperation(dataSource: dataSource, section: 0, items: items, afterItem: afterItem, animated: animated))
	}

	private func indent(items: [EditorItem], newParentItem: EditorItem, animated: Bool) {
		dataSourceQueue.add(IndentItemsOperation(dataSource: dataSource, collectionView: collectionView, section: 0, items: items, newParentItem: newParentItem, animated: animated))
	}

	private func reload(items: [EditorItem], animated: Bool) {
		dataSourceQueue.add(ReloadItemsOperation(dataSource: dataSource, collectionView: collectionView, section: 0, items: items, animated: animated))
	}

	private func moveCursor(item: EditorItem, direction: MoveCursorOperation.Direction) {
		dataSourceQueue.add(MoveCursorOperation(dataSource: dataSource, collectionView: collectionView, item: item, direction: direction))
	}
	
	private func applySnapshot(animated: Bool) {
		var snapshot = NSDiffableDataSourceSectionSnapshot<EditorItem>()
		
		if let items = outline?.headlines?.map({ EditorItem.editorItem($0) }) {
			snapshot.append(items)
			applySnapshot(&snapshot, items: items)
		}
		
		dataSourceQueue.add(ApplySnapshotOperation(dataSource: dataSource, section: 0, snapshot: snapshot, animated: animated))
	}
	
	private func applySnapshot( _ snapshot: inout NSDiffableDataSourceSectionSnapshot<EditorItem>, items: [EditorItem]) {
		expandAndCollapse(snapshot: &snapshot, items: items)
		for item in items {
			snapshot.append(item.children, to: item)
			if !item.children.isEmpty {
				applySnapshot(&snapshot, items: item.children)
			}
		}
	}
	
	private func expandAndCollapse(snapshot: inout NSDiffableDataSourceSectionSnapshot<EditorItem>, items: [EditorItem]) {
		var expandItems = [EditorItem]()
		var collapseItems = [EditorItem]()
		
		for item in items {
			if item.isExpanded {
				expandItems.append(item)
			} else {
				collapseItems.append(item)
			}
		}
		
		snapshot.expand(expandItems)
		snapshot.collapse(collapseItems)
	}
	
}

extension EditorViewController: EditorCollectionViewCellDelegate {

	func textChanged(item: EditorItem, attributedText: NSAttributedString) {
		if item.attributedText != attributedText {
			outline?.updateHeadline(headlineID: item.id, attributedText: attributedText)
			item.attributedText = attributedText
			self.reload(items: [item], animated: false)
		}
	}
	
	func deleteHeadline(item: EditorItem) {
		outline?.deleteHeadline(headlineID: item.id)
		moveCursor(item: item, direction: .up)
		delete(items: [item], animated: true)
	}
	
	// TODO: Need to take into consideration expanded state when placing the new Headline
	func createHeadline(item: EditorItem) {
		guard let headline = outline?.createHeadline(afterHeadlineID: item.id) else { return }
		let newItem = EditorItem.editorItem(headline)
		insert(items: [newItem], afterItem: item, animated: false)
		moveCursor(item: newItem, direction: .none)
	}
	
	func indent(item: EditorItem, attributedText: NSAttributedString) {
		outline?.updateHeadline(headlineID: item.id, attributedText: attributedText)
//		print("================================")
//		print(outline!)
		guard let (headline, newParentHeadline) = outline?.indentHeadline(headlineID: item.id) else { return }
//		print(outline!)
//		print("================================")

		let headlineItem = EditorItem.editorItem(headline)
		let newParentItem = EditorItem.editorItem(newParentHeadline)
		indent(items: [headlineItem], newParentItem: newParentItem, animated: true)
	}
	
	func outdent(item: EditorItem, attributedText: NSAttributedString) {
		
	}
	
	func moveUp(item: EditorItem) {
		moveCursor(item: item, direction: .up)
	}
	
	func moveDown(item: EditorItem) {
		moveCursor(item: item, direction: .down)
	}
	
}

// MARK: Helpers

private extension EditorViewController {
	
	private func moveCursorToInitialPosition() {
		guard let headline = outline?.headlines?.first else { return }
		let item = EditorItem.editorItem(headline)
		moveCursor(item: item, direction: .none)
	}
	
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
