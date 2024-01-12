//
//  ReloadAllOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 1/6/24.
//

import UIKit
import VinUtility

class ReloadAllOperation: BaseMainThreadOperation {
	
	private var collectionView: UICollectionView
	
	init(collectionView: UICollectionView) {
		self.collectionView = collectionView
	}
	
	override func run() {
		collectionView.reloadData()
		self.operationDelegate?.operationDidComplete(self)
	}
	
}
