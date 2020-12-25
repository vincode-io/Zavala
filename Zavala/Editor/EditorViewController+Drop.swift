//
//  EditorViewController+Drop.swift
//  Zavala
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
		if destinationIndexPath == nil || (destinationIndexPath?.section == 0 && destinationIndexPath?.row == 1) {
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}

		guard destinationIndexPath?.section ?? 0 != 0,
			  let row = session.localDragSession?.localContext as? Row,
			  let rowShadowTableIndex = row.shadowTableIndex,
			  let shadowTable = outline?.shadowTable,
			  let targetIndexPath = destinationIndexPath else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		var droppingInto = false
		if rowShadowTableIndex > targetIndexPath.row {
			if let destCell = collectionView.cellForItem(at: targetIndexPath) {
				droppingInto = session.location(in: destCell).y >= destCell.bounds.height / 2
			}
		}
		if rowShadowTableIndex < targetIndexPath.row {
			if let destCell = collectionView.cellForItem(at: targetIndexPath) {
				droppingInto = session.location(in: destCell).y <= destCell.bounds.height / 2
			}
		}

		if droppingInto {
			let dropInRow = shadowTable[targetIndexPath.row]
			if dropInRow == row {
				return UICollectionViewDropProposal(operation: .cancel)
			}

			if dropInRow.isDecendent(row) {
				return UICollectionViewDropProposal(operation: .forbidden)
			}
			
			return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
		}
		
		if let proposedParent = shadowTable[targetIndexPath.row].parent as? Row {
			if proposedParent == row {
				return UICollectionViewDropProposal(operation: .cancel)
			}
			
			if proposedParent.isDecendent(row) {
				return UICollectionViewDropProposal(operation: .forbidden)
			}
		}
		
		return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let dragItem = coordinator.items.first?.dragItem,
			  let row = dragItem.localObject as? Row,
			  let rowShadowTableIndex = row.shadowTableIndex,
			  let outline = outline,
			  let shadowTable = outline.shadowTable else { return }
		
		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath, let dropInIndexPath = coordinator.destinationIndexPath {
			drop(coordinator: coordinator, row: row, toParent: shadowTable[dropInIndexPath.row], toChildIndex: 0)
			return
		}
		
		// Drop into the first entry in the Outline
		if coordinator.destinationIndexPath == IndexPath(row: 1, section: 0) {
			drop(coordinator: coordinator, row: row, toParent: outline, toChildIndex: 0)
			return
		}
		
		// If we don't have a destination index, drop it at the back
		guard let targetIndexPath = coordinator.destinationIndexPath else {
			drop(coordinator: coordinator, row: row, toParent: outline, toChildIndex: outline.rows?.count ?? 0)
			return
		}

		// THis is where most of the sibling moves happen at
		let newSibling = shadowTable[targetIndexPath.row]
		guard let newParent = newSibling.parent, var newIndex = newParent.rows?.firstIndex(of: newSibling) else { return }

		// This shouldn't happen, but does.  We probably need to beef up the dropSessionDidUpdate code to prevent it.
		if let newParentRow = newParent as? Row, newParentRow == row || newParentRow.isDecendent(row) {
			return
		}
		
		// I don't know why this works.  This is definately in the category of, "Just try stuff until it works.".
		if (row.parent as? Row) != (newParent as? Row) && rowShadowTableIndex < targetIndexPath.row {
			newIndex = newIndex + 1
		}
		
		drop(coordinator: coordinator, row: row, toParent: newParent, toChildIndex: newIndex)
	}
	
	
}

// MARK: Helpers

extension EditorViewController {
	
	private func drop(coordinator: UICollectionViewDropCoordinator, row: Row, toParent: RowContainer, toChildIndex: Int) {
		guard let undoManager = undoManager,
			  let outline = outline,
			  let dragItem = coordinator.items.first?.dragItem else { return }

		let command = DropRowCommand(undoManager: undoManager,
										   delegate: self,
										   outline: outline,
										   row: row,
										   toParent: toParent,
										   toChildIndex: toChildIndex)
		
		runCommand(command)
		
		let targetIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: outline.shadowTable!.count - 1, section: 1)

		if let moves = command.changes?.moveIndexPaths, !moves.isEmpty {
			collectionView.performBatchUpdates({
				for move in moves {
					collectionView.moveItem(at: move.0, to: move.1)
				}
			}, completion: { _ in
				coordinator.drop(dragItem, toItemAt: targetIndexPath)
			})
		}

	}
	
}
