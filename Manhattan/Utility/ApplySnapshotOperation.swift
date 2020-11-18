//
//  ApplySnapshotOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import RSCore

class ApplySnapshotOperation<S: Hashable, I: Hashable>: MainThreadOperationBase {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var collectionView: UICollectionView?
	private var section: S
	private var snapshot: NSDiffableDataSourceSectionSnapshot<I>
	private var animated: Bool
	
	/**
	The collection view is optional.  It if itsn't passed, then no cursor management will happen which
	is typically what we want.
	*/
	init(dataSource: UICollectionViewDiffableDataSource<S, I>,
		 collectionView: UICollectionView? = nil,
		 section: S,
		 snapshot: NSDiffableDataSourceSectionSnapshot<I>,
		 animated: Bool) {
		
		self.dataSource = dataSource
		self.collectionView = collectionView
		self.section = section
		self.snapshot = snapshot
		self.animated = animated
		
	}
	
	override func run() {		
		let textCursorSource = UIResponder.currentFirstResponder as? TextCursorSource
		let item = textCursorSource?.identifier as? I
		let selectedRange = textCursorSource?.selectedTextRange
		
		dataSource.apply(snapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }

			if let item = item, let indexPath = self.dataSource.indexPath(for: item), let textCursor = self.collectionView?.cellForItem(at: indexPath) as? TextCursorTarget {
				if let selectedRange = selectedRange {
					textCursor.restoreSelection(selectedRange)
				} else {
					textCursor.moveToEnd()
				}
			}

			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
