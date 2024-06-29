//
//  EditorViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit
import UniformTypeIdentifiers
import VinUtility
import VinOutlineKit

extension EditorViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		guard !(session.items.first?.localObject is Row) else { return true }
		return session.hasItemsConforming(toTypeIdentifiers: [UTType.utf8PlainText.identifier, Row.typeIdentifier])
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		if !isSearching {
			guard !(destinationIndexPath?.section == Outline.Section.title.rawValue || destinationIndexPath?.section == Outline.Section.tags.rawValue) else {
				return UICollectionViewDropProposal(operation: .cancel)
			}
		}
		
		guard let destinationIndexPath = correctDestinationIndexPath(session: session) else {
			if session.localDragSession != nil {
				return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
			} else {
				return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
			}
		}

		if destinationIndexPath.section > adjustedRowsSection {
			return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
		}
		
		if session.localDragSession != nil {
			return localDropProposal(session: session, destinationIndexPath: destinationIndexPath)
		} else {
			return remoteDropProposal(session: session, destinationIndexPath: destinationIndexPath)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		let destinationIndexPath = correctDestinationIndexPath(session: coordinator.session)
		
		if coordinator.session.localDragSession != nil {
			localRowDrop(coordinator: coordinator, destinationIndexPath: destinationIndexPath)
		} else if coordinator.session.hasItemsConforming(toTypeIdentifiers: [Row.typeIdentifier]) {
			remoteRowDrop(coordinator: coordinator, destinationIndexPath: destinationIndexPath)
		} else {
			remoteTextDrop(coordinator: coordinator, destinationIndexPath: destinationIndexPath)
		}
	}
	
}

// MARK: Helpers

private extension EditorViewController {
	
	// The destinationIndexPath is worthless.  See https://stackoverflow.com/a/58038185
	func correctDestinationIndexPath(session: UIDropSession) -> IndexPath? {
		let location = session.location(in: collectionView)
		
		var correctDestination: IndexPath?
		collectionView.performUsingPresentationValues {
			correctDestination = collectionView.indexPathForItem(at: location)
		}
		
		return correctDestination
	}
	
	func localDropProposal(session: UIDropSession, destinationIndexPath: IndexPath) -> UICollectionViewDropProposal {
		guard let localDragSession = session.localDragSession else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		guard let destinationCell = collectionView.cellForItem(at: destinationIndexPath) as? EditorRowViewCell, let destinationRow = destinationCell.row else {
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
		
		let rows = localDragSession.items.compactMap { $0.localObject as? Row }

		for row in rows {
			if destinationRow == row {
				return UICollectionViewDropProposal(operation: .cancel)
			}
			if destinationRow.isDecendent(row) {
				return UICollectionViewDropProposal(operation: .forbidden)
			}
		}
			
		if let destinationParent = destinationRow.parent as? Row {
			for row in rows {
				if destinationParent == row {
					return UICollectionViewDropProposal(operation: .cancel)
				}
				if destinationParent.isDecendent(row) {
					return UICollectionViewDropProposal(operation: .forbidden)
				}
			}
		}

		if destinationCell.isDroppable(session: session) {
			return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
	}
	
	func remoteDropProposal(session: UIDropSession, destinationIndexPath: IndexPath) -> UICollectionViewDropProposal {
		guard let destinationCell = collectionView.cellForItem(at: destinationIndexPath) as? EditorRowViewCell else {
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
		
		if destinationCell.isDroppable(session: session) {
			return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
		}
	}
	
	func localRowDrop(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath?) {
		guard let outline, let shadowTable = outline.shadowTable else { return }
		
		let rows = coordinator.items.compactMap { $0.dragItem.localObject as? Row }

		// If we don't have a destination index, drop it at the back
		guard let destinationIndexPath else {
			localRowDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: outline.rowCount)
			return
		}

		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath {
			localRowDrop(coordinator: coordinator, rows: rows, toParent: shadowTable[destinationIndexPath.row], toChildIndex: 0)
			return
		}
		
		// Drop into the first entry in the Outline
		if destinationIndexPath == IndexPath(row: 0, section: adjustedRowsSection) {
			localRowDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: 0)
			return
		}
		
		// This is where most of the sibling moves happen at
		var newParent: RowContainer
		var newIndex: Int
		
		// The target index path points to the following row, but we want the preceding row to be the sibling
		var newSiblingTargetIndexPath = destinationIndexPath.row > 0 ? destinationIndexPath.row - 1 : 0

		// Adjust the index path when dragging downward
		for row in rows {
			if row.shadowTableIndex ?? 0 < destinationIndexPath.row {
				newSiblingTargetIndexPath = newSiblingTargetIndexPath + 1
				break
			}
		}

		let newSiblingCandidate = shadowTable[newSiblingTargetIndexPath]

		// We have to handle dropping into the first entry in a parent in a special way
		if newSiblingTargetIndexPath + 1 < shadowTable.count {
			let newSiblingCandidateChildCandidate = shadowTable[newSiblingTargetIndexPath + 1]
			if newSiblingCandidate.containsRow(newSiblingCandidateChildCandidate) && destinationIndexPath.section == adjustedRowsSection {
				newParent = newSiblingCandidate
				newIndex = 0
			} else {
				guard let parent = newSiblingCandidate.parent, let index = parent.firstIndexOfRow(newSiblingCandidate) else { return }
				newParent = parent
				newIndex = index + 1
			}
		} else {
			guard let parent = newSiblingCandidate.parent, let index = parent.firstIndexOfRow(newSiblingCandidate) else { return }
			newParent = parent
			newIndex = index + 1
		}
		
		localRowDrop(coordinator: coordinator, rows: rows, toParent: newParent, toChildIndex: newIndex)
	}
	
	func localRowDrop(coordinator: UICollectionViewDropCoordinator, rows: [Row], toParent: RowContainer, toChildIndex: Int) {
		guard let undoManager, let outline else { return }

		let command = LocalDropRowCommand(actionName:.moveControlLabel,
										  undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows,
										  toParent: toParent,
										  toChildIndex: toChildIndex)
		
		command.execute()
	}
	
	func remoteRowDrop(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath?) {
		let itemProviders = coordinator.items.compactMap { dropItem -> NSItemProvider? in
			if dropItem.dragItem.itemProvider.hasItemConformingToTypeIdentifier(Row.typeIdentifier) {
				return dropItem.dragItem.itemProvider
			}
			return nil
		}
		
		guard !itemProviders.isEmpty else { return }

		Task {
			do {
				let rowGroups = try await RowGroup.fromRowItemProviders(itemProviders)
				self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, destinationIndexPath: destinationIndexPath)
			} catch {
				presentError(error)
			}
		}
	}

	func remoteTextDrop(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath?) {
		let itemProviders = coordinator.items.compactMap { dropItem -> NSItemProvider? in
			if dropItem.dragItem.itemProvider.hasItemConformingToTypeIdentifier(UTType.utf8PlainText.identifier) {
				return dropItem.dragItem.itemProvider
			}
			return nil
		}
		
		guard !itemProviders.isEmpty else { return }

		Task {
			let rowGroups = await RowGroup.fromTextItemProviders(itemProviders)
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, destinationIndexPath: destinationIndexPath)
		}
	}
	
	func remoteRowDrop(coordinator: UICollectionViewDropCoordinator, rowGroups: [RowGroup], destinationIndexPath: IndexPath?) {
		guard !rowGroups.isEmpty, let outline = self.outline, let shadowTable = outline.shadowTable else { return }

		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath, let dropInIndexPath = destinationIndexPath {
			let newParent = shadowTable[dropInIndexPath.row]
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: newParent, afterRowIsNewParent: true)
			return
		}
		
		// Drop into the first entry in the Outline
		if destinationIndexPath == IndexPath(row: 0, section: adjustedRowsSection) {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: nil)
			return
		}
		
		// If we don't have a destination index, drop it at the back
		guard let destinationIndexPath else {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: nil, prefersEnd: true)
			return
		}

		if shadowTable.count > 0 && destinationIndexPath.row > 0 {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: shadowTable[destinationIndexPath.row - 1])
		} else {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: nil)
		}
	}
	
	func remoteRowDrop(coordinator: UICollectionViewDropCoordinator, rowGroups: [RowGroup], afterRow: Row?, prefersEnd: Bool = false, afterRowIsNewParent: Bool = false) {
		guard let undoManager, let outline else { return }

		let command = RemoteDropRowCommand(actionName: .copyControlLabel,
										   undoManager: undoManager,
										   delegate: self,
										   outline: outline,
										   rowGroups: rowGroups,
										   afterRow: afterRow,
										   prefersEnd: prefersEnd,
										   afterRowIsNewParent: afterRowIsNewParent)
		
		command.execute()
	}
	
}
