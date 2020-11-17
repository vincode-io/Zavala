//
//  InsertItemsOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

class InsertItemsOperation<S: Hashable, I: Hashable>: MainThreadOperationBase {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var section: S
	private var items: [I]
	private var afterItem: I
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>, section: S, items: [I], afterItem: I, animated: Bool) {
		self.dataSource = dataSource
		self.section = section
		self.items = items
		self.afterItem = afterItem
		self.animated = animated
	}
	
	override func run() {
		var sectionSnapshot = dataSource.snapshot(for: section)
		sectionSnapshot.insert(items, after: afterItem)
		dataSource.apply(sectionSnapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
