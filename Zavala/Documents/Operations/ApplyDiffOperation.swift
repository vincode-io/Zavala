//
//  ApplyDiffOperation.swift
//  Zavala
//
//  Created by Maurice Parker on 1/6/24.
//

import UIKit
import VinOutlineKit
import VinUtility

class ApplyDiffOperation: BaseMainThreadOperation {
	
	private var collectionView: UICollectionView
	private var oldDocuments: [Document]
	private var newDocuments: [Document]

	init(collectionView: UICollectionView, oldDocuments: [Document], newDocuments: [Document]) {
		self.collectionView = collectionView
		self.oldDocuments = oldDocuments
		self.newDocuments = newDocuments
	}
	
	override func run() {
		let diff = newDocuments.difference(from: oldDocuments).inferringMoves()

		CATransaction.begin()
		CATransaction.setCompletionBlock {
			self.operationDelegate?.operationDidComplete(self)
		}

		self.collectionView.performBatchUpdates {
			for change in diff {
				switch change {
				case .insert(let offset, _, let associated):
					if let associated {
						self.collectionView.moveItem(at: IndexPath(row: associated, section: 0), to: IndexPath(row: offset, section: 0))
					} else {
						self.collectionView.insertItems(at: [IndexPath(row: offset, section: 0)])
					}
				case .remove(let offset, _, let associated):
					if let associated {
						self.collectionView.moveItem(at: IndexPath(row: offset, section: 0), to: IndexPath(row: associated, section: 0))
					} else {
						self.collectionView.deleteItems(at: [IndexPath(row: offset, section: 0)])
					}
				}
			}
		}

		CATransaction.commit()
	}
	
}
