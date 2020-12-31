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

		let correctDestination = correctDestinationIndexPath(session: session)
		guard let targetIndexPath = correctDestination else {
			return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
		}
		
		if session.localDragSession != nil {
			return localDropProposal(session: session, targetIndexPath: targetIndexPath)
		} else {
			return remoteDropProposal(session: session, targetIndexPath: targetIndexPath)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		let targetIndexPath = correctDestinationIndexPath(session: coordinator.session)

		if coordinator.session.localDragSession != nil {
			localDrop(coordinator: coordinator, targetIndexPath: targetIndexPath)
		} else {
			remoteDrop(coordinator: coordinator, targetIndexPath: targetIndexPath)
		}
	}
	
}

// MARK: Helpers

extension EditorViewController {
	
	// The destinationIndexPath is worthless.  See https://stackoverflow.com/a/58038185
	private func correctDestinationIndexPath(session: UIDropSession) -> IndexPath? {
		let location = session.location(in: collectionView)
		
		var correctDestination: IndexPath?
		collectionView.performUsingPresentationValues {
			correctDestination = collectionView.indexPathForItem(at: location)
		}
		
		return correctDestination
	}
	
	private func droppingInto(session: UIDropSession, targetIndexPath: IndexPath) -> Bool {
		if let destCell = collectionView.cellForItem(at: targetIndexPath) {
			let fractionHeight = destCell.bounds.height / 20
			let yInCell = session.location(in: destCell).y
			return fractionHeight < yInCell && yInCell < fractionHeight * 19
		}
		return false
	}
	
	private func localDropProposal(session: UIDropSession, targetIndexPath: IndexPath) -> UICollectionViewDropProposal {
		guard let localDragSession = session.localDragSession,
			  let shadowTable = outline?.shadowTable else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		let rows = localDragSession.items.compactMap { $0.localObject as? Row }
		let isDroppingInto = droppingInto(session: session, targetIndexPath: targetIndexPath)
		
		if isDroppingInto {
			let dropInRow = shadowTable[targetIndexPath.row]

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
		
		if let proposedParent = shadowTable[targetIndexPath.row].parent as? Row {

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
	
	private func remoteDropProposal(session: UIDropSession, targetIndexPath: IndexPath) -> UICollectionViewDropProposal {
		if droppingInto(session: session, targetIndexPath: targetIndexPath) {
			return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
	}
	
	private func localDrop(coordinator: UICollectionViewDropCoordinator, targetIndexPath: IndexPath?) {
		guard let outline = outline, let shadowTable = outline.shadowTable else { return }
		
		let rows = coordinator.items.compactMap { $0.dragItem.localObject as? Row }

		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath, let dropInIndexPath = targetIndexPath {
			localDrop(coordinator: coordinator, rows: rows, toParent: shadowTable[dropInIndexPath.row], toChildIndex: 0)
			return
		}
		
		// Drop into the first entry in the Outline
		if targetIndexPath == IndexPath(row: 1, section: 0) {
			localDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: 0)
			return
		}
		
		// If we don't have a destination index, drop it at the back
		guard let targetIndexPath = targetIndexPath else {
			if let outlineRows = outline.rows {
				localDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: outlineRows.count - 1)
			}
			return
		}

		// THis is where most of the sibling moves happen at
		let newSibling = shadowTable[targetIndexPath.row]
		guard let newParent = newSibling.parent, var newIndex = newParent.rows?.firstIndex(of: newSibling) else { return }

		// I don't know why this works.  This is definately in the category of, "Just try stuff until it works.".
		for row in rows {
			if (row.parent as? Row) != (newParent as? Row) && row.shadowTableIndex ?? 0 < targetIndexPath.row {
				newIndex = newIndex + 1
				break
			}
		}
		
		localDrop(coordinator: coordinator, rows: rows, toParent: newParent, toChildIndex: newIndex)
	}
	
	private func localDrop(coordinator: UICollectionViewDropCoordinator, rows: [Row], toParent: RowContainer, toChildIndex: Int) {
		guard let undoManager = undoManager,
			  let outline = outline,
			  let dragItem = coordinator.items.first?.dragItem else { return }

		let command = LocalDropRowCommand(undoManager: undoManager,
									 delegate: self,
									 outline: outline,
									 rows: rows,
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
	
	private func remoteDrop(coordinator: UICollectionViewDropCoordinator, targetIndexPath: IndexPath?) {
		guard let outline = outline, let shadowTable = outline.shadowTable else { return }
		
		let rows = coordinator.items.compactMap { $0.dragItem.localObject as? Row }

		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath, let dropInIndexPath = targetIndexPath {
			localDrop(coordinator: coordinator, rows: rows, toParent: shadowTable[dropInIndexPath.row], toChildIndex: 0)
			return
		}
		
		// Drop into the first entry in the Outline
		if targetIndexPath == IndexPath(row: 1, section: 0) {
			localDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: 0)
			return
		}
		
		// If we don't have a destination index, drop it at the back
		guard let targetIndexPath = targetIndexPath else {
			if let outlineRows = outline.rows {
				localDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: outlineRows.count - 1)
			}
			return
		}

		// THis is where most of the sibling moves happen at
		let newSibling = shadowTable[targetIndexPath.row]
		guard let newParent = newSibling.parent, var newIndex = newParent.rows?.firstIndex(of: newSibling) else { return }

		// I don't know why this works.  This is definately in the category of, "Just try stuff until it works.".
		for row in rows {
			if (row.parent as? Row) != (newParent as? Row) && row.shadowTableIndex ?? 0 < targetIndexPath.row {
				newIndex = newIndex + 1
				break
			}
		}
		
		localDrop(coordinator: coordinator, rows: rows, toParent: newParent, toChildIndex: newIndex)
	}

	private func remoteDrop(coordinator: UICollectionViewDropCoordinator, rows: [Row], toParent: RowContainer, toChildIndex: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = RemoteDropRowCommand(undoManager: undoManager,
										   delegate: self,
										   outline: outline,
										   rows: rows,
										   toParent: toParent,
										   toChildIndex: toChildIndex)
		
		runCommand(command)
		deselectAll()
	}
	

}
