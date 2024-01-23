//
//  ReloadCellsOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 1/6/24.
//

import UIKit
import VinUtility

class ReloadIndexPathsOperation: BaseMainThreadOperation {
	
	private var collectionView: UICollectionView
	private var indexPaths: [IndexPath]
	
	init(collectionView: UICollectionView, at indexPaths: [IndexPath]) {
		self.collectionView = collectionView
		self.indexPaths = indexPaths
	}
	
	override func run() {
		CATransaction.begin()
		CATransaction.setCompletionBlock {
			self.operationDelegate?.operationDidComplete(self)
		}
		collectionView.reloadItems(at: indexPaths)
		CATransaction.commit()
	}
	
}
