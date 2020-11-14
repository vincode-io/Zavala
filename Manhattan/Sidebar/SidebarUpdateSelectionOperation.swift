//
//  SidebarUpdateSelectionOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import RSCore

class SidebarUpdateSelectionOperation: MainThreadOperation {
	
	// MainThreadOperation
	public var isCanceled = false
	public var id: Int?
	public weak var operationDelegate: MainThreadOperationDelegate?
	public var name: String? = "UpdateSelectionOperation"
	public var completionBlock: MainThreadOperation.MainThreadOperationCompletionBlock?

	private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>
	private var collectionView: UICollectionView
	private var item: SidebarItem?
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>, collectionView: UICollectionView, item: SidebarItem?, animated: Bool) {
		self.dataSource = dataSource
		self.collectionView = collectionView
		self.item = item
		self.animated = animated
	}
	
	func run() {
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
