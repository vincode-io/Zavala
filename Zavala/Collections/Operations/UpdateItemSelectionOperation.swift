//
//  UpdateItemSelectionOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import VinUtility

class UpdateItemSelectionOperation<S: Hashable, I: Hashable>: BaseMainThreadOperation {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var collectionView: UICollectionView
	private var items: [I]
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>, collectionView: UICollectionView, items: [I], animated: Bool) {
		self.dataSource = dataSource
		self.collectionView = collectionView
		self.items = items
		self.animated = animated
	}
	
	override func run() {
		if dataSource.snapshot().numberOfItems > 0 {
            let indexPaths = items.compactMap { dataSource.indexPath(for: $0) }
            if !indexPaths.isEmpty {
                CATransaction.begin()
				CATransaction.setCompletionBlock {
					self.operationDelegate?.operationDidComplete(self)
				}
                for indexPath in indexPaths {
                    collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredVertically)
                }
				CATransaction.commit()
			} else {
                if animated {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock {
                        self.operationDelegate?.operationDidComplete(self)
                    }
                    collectionView.deselectAll(animated: animated)
                    CATransaction.commit()
                } else {
                    collectionView.deselectAll(animated: animated)
                    self.operationDelegate?.operationDidComplete(self)
                }
			}
		} else {
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
