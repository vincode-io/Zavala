//
//  ScrollToIndexPathOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 1/6/24.
//

import UIKit
import VinUtility

class ScrollToIndexPathOperation: BaseMainThreadOperation {
	
	private var collectionView: UICollectionView
	private var indexPath: IndexPath
	private var scrollPosition: UICollectionView.ScrollPosition
	private var animated: Bool

	init(collectionView: UICollectionView, at indexPath: IndexPath, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
		self.collectionView = collectionView
		self.indexPath = indexPath
		self.scrollPosition = scrollPosition
		self.animated = animated
	}
	
	override func run() {
		if animated {
			CATransaction.begin()
			CATransaction.setCompletionBlock {
				self.operationDelegate?.operationDidComplete(self)
			}
			self.collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
			CATransaction.commit()
		} else {
			collectionView.deselectAll(animated: animated)
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
