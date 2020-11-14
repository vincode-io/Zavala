//
//  SidebarApplySnapshotOperation.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import RSCore

class SidebarApplySnapshotOperation: MainThreadOperation {
	
	// MainThreadOperation
	public var isCanceled = false
	public var id: Int?
	public weak var operationDelegate: MainThreadOperationDelegate?
	public var name: String? = "MasterFeedDataSourceOperation"
	public var completionBlock: MainThreadOperation.MainThreadOperationCompletionBlock?

	private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>
	private var section: SidebarSection
	private var snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>
	private var animated: Bool
	
	init(dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>,
		 section: SidebarSection,
		 snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>,
		 animated: Bool) {
		
		self.dataSource = dataSource
		self.section = section
		self.snapshot = snapshot
		self.animated = animated
		
	}
	
	func run() {
		dataSource.apply(snapshot, to: section, animatingDifferences: animated) { [weak self] in
			guard let self = self else { return }
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
