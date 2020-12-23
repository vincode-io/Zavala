//
//  UpdateSelectionOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import RSCore

class UpdateSelectionOperation<S: Hashable, I: Hashable>: MainThreadOperationBase {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var collectionView: UICollectionView
	private var item: I?
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>, collectionView: UICollectionView, item: I?, animated: Bool) {
		self.dataSource = dataSource
		self.collectionView = collectionView
		self.item = item
		self.animated = animated
	}
	
	override func run() {
		if dataSource.snapshot().numberOfItems > 0 {
			if let item = item, let indexPath = dataSource.indexPath(for: item) {
				CATransaction.begin()
				CATransaction.setCompletionBlock {
					self.operationDelegate?.operationDidComplete(self)
				}
				collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredVertically)
				CATransaction.commit()
			} else {
				if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
					if animated {
						CATransaction.begin()
						CATransaction.setCompletionBlock {
							self.operationDelegate?.operationDidComplete(self)
						}
						collectionView.deselectItem(at: selectedIndexPath, animated: true)
						CATransaction.commit()
					} else {
						collectionView.deselectItem(at: selectedIndexPath, animated: false)
						self.operationDelegate?.operationDidComplete(self)
					}
				} else {
					self.operationDelegate?.operationDidComplete(self)
				}
			}
		} else {
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
