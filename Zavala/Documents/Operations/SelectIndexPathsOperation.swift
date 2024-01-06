//
//  SelectCellsOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 1/6/24.
//

import UIKit
import VinUtility

class SelectIndexPathsOperation: BaseMainThreadOperation {
	
	private var collectionView: UICollectionView
	private var indexPaths: [IndexPath]
	private var scrollPosition: UICollectionView.ScrollPosition
	private var animated: Bool

	init(collectionView: UICollectionView, at indexPaths: [IndexPath], scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
		self.collectionView = collectionView
		self.indexPaths = indexPaths
		self.scrollPosition = scrollPosition
		self.animated = animated
	}
	
	override func run() {
		if !indexPaths.isEmpty {
			CATransaction.begin()
			CATransaction.setCompletionBlock {
				self.operationDelegate?.operationDidComplete(self)
			}
			for indexPath in indexPaths {
				collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
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
	}
	
}
