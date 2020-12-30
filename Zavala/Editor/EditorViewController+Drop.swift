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
		guard session.localDragSession == nil else { return true }
		return session.hasItemsConforming(toTypeIdentifiers: [Row.typeIdentifier])
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		guard !(destinationIndexPath?.section == 0 && destinationIndexPath?.row == 0) else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		if destinationIndexPath == nil || (destinationIndexPath?.section == 0 && destinationIndexPath?.row == 1) {
			if session.localDragSession != nil {
				return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
			} else {
				return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
			}
		}

		// The destinationIndexPath is worthless.  See https://stackoverflow.com/a/58038185
		let location = session.location(in: collectionView)
		var correctDestination: IndexPath?
		collectionView.performUsingPresentationValues {
			correctDestination = collectionView.indexPathForItem(at: location)
		}
		
		guard let targetIndexPath = correctDestination else {
			return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
		}
		
		if session.localDragSession != nil {
			return localDropProposal(session: session, destinationIndexPath: targetIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
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
	
	private func localDropProposal(session: UIDropSession, destinationIndexPath: IndexPath) -> UICollectionViewDropProposal {
		guard let localDragSession = session.localDragSession,
			  let shadowTable = outline?.shadowTable else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		let rows = localDragSession.items.compactMap { $0.localObject as? Row }
		
		var droppingInto = false
		if let destCell = collectionView.cellForItem(at: destinationIndexPath) {
			let fractionHeight = destCell.bounds.height / 20
			let yInCell = session.location(in: destCell).y
			droppingInto = fractionHeight < yInCell && yInCell < fractionHeight * 19
		}

		if droppingInto {
			let dropInRow = shadowTable[destinationIndexPath.row]

			for row in rows {
				if dropInRow == row {
					return UICollectionViewDropProposal(operation: .cancel)
				}
				if dropInRow.isDecendent(row) {
					return UICollectionViewDropProposal(operation: .forbidden)
				}
			}
			
			return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
		}
		
		if let proposedParent = shadowTable[destinationIndexPath.row].parent as? Row {

			for row in rows {
				if proposedParent == row {
					return UICollectionViewDropProposal(operation: .cancel)
				}
				if proposedParent.isDecendent(row) {
					return UICollectionViewDropProposal(operation: .forbidden)
				}
			}
			
		}
		
		return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
	}
	
	private func drop(coordinator: UICollectionViewDropCoordinator, row: Row, toParent: RowContainer, toChildIndex: Int) {
		guard let undoManager = undoManager,
			  let outline = outline,
			  let dragItem = coordinator.items.first?.dragItem else { return }

		let command = DropRowCommand(undoManager: undoManager,
									 delegate: self,
									 outline: outline,
									 rows: [row],
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

		deselectAll()
	}
	
}
