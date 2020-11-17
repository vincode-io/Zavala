//
//  ReloadItemsOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

class ReloadItemsOperation<S: Hashable, I: Hashable>: MainThreadOperationBase {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var section: S
	private var items: [I]
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>,
		 section: S,
		 items: [I],
		 animated: Bool) {
		
		self.dataSource = dataSource
		self.section = section
		self.items = items
		self.animated = animated
		
	}
	
	override func run() {
		let sectionSnapshot = dataSource.snapshot(for: section)
		let visibleItems = items.filter { sectionSnapshot.visibleItems.contains($0) }

		var snapshot = dataSource.snapshot()
		snapshot.reloadItems(visibleItems)
		dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
