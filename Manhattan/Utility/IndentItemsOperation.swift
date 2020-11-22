//
//  IndentItemsOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/22/20.
//

import UIKit

class IndentItemsOperation<S: Hashable, I: Hashable>: MainThreadOperationBase {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var section: S
	private var items: [I]
	private var newParentItem: I
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>, section: S, items: [I], newParentItem: I, animated: Bool) {
		self.dataSource = dataSource
		self.section = section
		self.items = items
		self.newParentItem = newParentItem
		self.animated = animated
	}
	
	override func run() {
		var sectionSnapshot = dataSource.snapshot(for: section)
		sectionSnapshot.delete(items)
		
		var children = sectionSnapshot.snapshot(of: newParentItem)
		if children.items.count == 0 {
			children.append(items)
		} else {
			children.insert(items, before: children.items.first!)
		}
		
		sectionSnapshot.replace(childrenOf: newParentItem, using: children)
		
		dataSource.apply(sectionSnapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
