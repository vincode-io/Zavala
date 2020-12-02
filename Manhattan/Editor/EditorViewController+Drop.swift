//
//  EditorViewController+Drop.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit
import Templeton

extension EditorViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		return session.localDragSession != nil
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let dragItem = coordinator.items.first?.dragItem,
			  let headline = dragItem.localObject as? Headline,
			  let undoManager = undoManager,
			  let outline = outline else { return }
		
		let destinationIndex = coordinator.destinationIndexPath?.row ?? 0
		
		let toParent: HeadlineContainer
		let toChildIndex: Int
		if destinationIndex == 0 {
			toParent = outline
		} else if destinationIndex >= outline.shadowTable!.count {
			toParent = outline.shadowTable!.last!
		} else {
			toParent = outline.shadowTable![destinationIndex - 1]
		}
		toChildIndex = 0
		
		let command = EditorMoveHeadlineCommand(undoManager: undoManager,
												delegate: self,
												outline: outline,
												headline: headline,
												toParent: toParent,
												toChildIndex: toChildIndex)
		
		runCommand(command)
		
// This needs some work.  We need to be able to do moves in a performing batch updates for it to work
//		coordinator.drop(dragItem, toItemAt: IndexPath(row: destinationIndex, section: 0))
	}
	
	
}
