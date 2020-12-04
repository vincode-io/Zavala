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
		guard let headline = session.localDragSession?.localContext as? Headline,
			let toParent = destinationHeadlineContainer(destinationIndexPath) else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		if let toHeadline = toParent as? Headline {
			if toHeadline == headline {
				return UICollectionViewDropProposal(operation: .cancel)
			}
			if toHeadline.isDecendent(headline) {
				return UICollectionViewDropProposal(operation: .forbidden)
			}
		}
		
		
		return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let dragItem = coordinator.items.first?.dragItem,
			  let headline = dragItem.localObject as? Headline,
			  let undoManager = undoManager,
			  let outline = outline,
			  let toParent = destinationHeadlineContainer(coordinator.destinationIndexPath) else { return }
		
		let toChildIndex = 0
		
		let command = EditorMoveHeadlineCommand(undoManager: undoManager,
												delegate: self,
												outline: outline,
												headline: headline,
												toParent: toParent,
												toChildIndex: toChildIndex)
		
		runCommand(command)
	}
	
	
}

// MARK: Helpers

extension EditorViewController {
	
	private func destinationHeadlineContainer(_ indexPath: IndexPath?) -> HeadlineContainer? {
		guard let outline = outline, let shadowTable = outline.shadowTable else { return nil }
		
		let destinationIndex = indexPath?.row ?? 0
		
		let destination: HeadlineContainer?
		if destinationIndex == 0 {
			destination = outline
		} else if destinationIndex >= outline.shadowTable!.count {
			destination = shadowTable.last
		} else {
			destination = shadowTable[destinationIndex - 1]
		}

		return destination
	}
	
}
