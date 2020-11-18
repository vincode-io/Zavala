//
//  ReloadItemsOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

class ReloadItemsOperation<S: Hashable, I: Hashable>: MainThreadOperationBase {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var collectionView: UICollectionView
	private var section: S
	private var items: [I]
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>, collectionView: UICollectionView, section: S, items: [I], animated: Bool) {
		self.dataSource = dataSource
		self.collectionView = collectionView
		self.section = section
		self.items = items
		self.animated = animated
	}
	
	override func run() {
		let sectionSnapshot = dataSource.snapshot(for: section)
		let visibleItems = items.filter { sectionSnapshot.visibleItems.contains($0) }

		var snapshot = dataSource.snapshot()
		snapshot.reloadItems(visibleItems)
		
		let textCursorSource = UIResponder.currentFirstResponder as? TextCursorSource
		let item = textCursorSource?.identifier as? I
		let selectedRange = textCursorSource?.selectedTextRange
		
		dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			
			if let item = item, let indexPath = self.dataSource.indexPath(for: item), let textCursor = self.collectionView.cellForItem(at: indexPath) as? TextCursorTarget {
				if let selectedRange = selectedRange {
					textCursor.restoreSelection(selectedRange)
				} else {
					textCursor.moveToEnd()
				}
			}
			
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
