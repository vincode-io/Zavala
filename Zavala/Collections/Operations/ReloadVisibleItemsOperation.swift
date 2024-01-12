//
//  ReloadVisibleItemsOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 10/24/21.
//

import UIKit
import VinUtility

class ReloadVisibleItemsOperation<S: Hashable, I: Hashable>: BaseMainThreadOperation {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var collectionView: UICollectionView
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>, collectionView: UICollectionView) {
		self.dataSource = dataSource
		self.collectionView = collectionView
	}
	
	override func run() {
		let visibleIndexPaths = collectionView.indexPathsForVisibleItems
		let items = visibleIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
		var snapshot = dataSource.snapshot()
		snapshot.reloadItems(items)
		dataSource.apply(snapshot)
		operationDelegate?.operationDidComplete(self)
	}
	
}
