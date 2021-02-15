//
//  ApplySnapshotOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import Templeton
import RSCore

class ApplySnapshotOperation<S: Hashable, I: Hashable>: BaseMainThreadOperation {
	
	private var dataSource: UICollectionViewDiffableDataSource<S, I>
	private var section: S
	private var snapshot: NSDiffableDataSourceSectionSnapshot<I>
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<S, I>,
		 section: S,
		 snapshot: NSDiffableDataSourceSectionSnapshot<I>,
		 animated: Bool) {
		
		self.dataSource = dataSource
		self.section = section
		self.snapshot = snapshot
		self.animated = animated

		super.init()
	}
	
	override func run() {		
		dataSource.apply(snapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
