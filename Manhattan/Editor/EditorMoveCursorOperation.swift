//
//  EditorMoveCursorOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import RSCore

class EditorMoveCursorOperation: MainThreadOperationBase {
	
	enum Direction {
		case up
		case down
		case none
	}
	
	private var dataSource: UICollectionViewDiffableDataSource<Int, EditorItem>
	private var collectionView: UICollectionView
	private var item: EditorItem
	private var direction: Direction
	
	init(dataSource: UICollectionViewDiffableDataSource<Int, EditorItem>, collectionView: UICollectionView, item: EditorItem, direction: Direction) {
		self.dataSource = dataSource
		self.collectionView = collectionView
		self.item = item
		self.direction = direction
	}
	
	override func run() {
		let nextItem: EditorItem

		switch direction {
		case .up:
			let visibleItems = dataSource.snapshot(for: 0).visibleItems
			guard let itemIndex = visibleItems.firstIndex(of: item), itemIndex - 1 > -1 else {
				self.operationDelegate?.operationDidComplete(self)
				return
			}
			nextItem = visibleItems[itemIndex - 1]
		case .down:
			let visibleItems = dataSource.snapshot(for: 0).visibleItems
			guard let itemIndex = visibleItems.firstIndex(of: item), itemIndex + 1 != visibleItems.count else {
				self.operationDelegate?.operationDidComplete(self)
				return
			}
			nextItem = visibleItems[itemIndex + 1]
		case .none:
			nextItem = item
		}

		guard let indexPath = dataSource.indexPath(for: nextItem) else { return }
		guard let editorCell = collectionView.cellForItem(at: indexPath) as? EditorCollectionViewCell else {
			self.operationDelegate?.operationDidComplete(self)
			return
		}

		editorCell.takeCursor()
		self.operationDelegate?.operationDidComplete(self)
	}
	
}
