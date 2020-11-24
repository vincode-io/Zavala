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
	private var section: S
	private var snapshot: NSDiffableDataSourceSectionSnapshot<I>
	private var animated: Bool
	
	/**
	The collection view is optional.  It if itsn't passed, then no cursor management will happen which
	is typically what we want.
	*/
	init(dataSource: UICollectionViewDiffableDataSource<S, I>,
		 section: S,
		 snapshot: NSDiffableDataSourceSectionSnapshot<I>,
		 animated: Bool) {
		
		self.dataSource = dataSource
		self.section = section
		self.snapshot = snapshot
		self.animated = animated
		
	}
	
	override func run() {		
		dataSource.apply(snapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
