//
//  EditorViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit
import MobileCoreServices
import Templeton

extension EditorViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		guard session.localDragSession == nil else { return true }
		return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeUTF8PlainText as String, Row.typeIdentifier])
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		if !isSearching {
			guard !(destinationIndexPath?.section == Outline.Section.title.rawValue || destinationIndexPath?.section == Outline.Section.tags.rawValue) else {
				return UICollectionViewDropProposal(operation: .cancel)
			}
		}
		
		if destinationIndexPath == nil  {
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
		
		if targetIndexPath.section > adjustedRowsSection {
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
			localRowDrop(coordinator: coordinator, targetIndexPath: targetIndexPath)
		} else if coordinator.session.hasItemsConforming(toTypeIdentifiers: [Row.typeIdentifier]) {
			remoteRowDrop(coordinator: coordinator, targetIndexPath: targetIndexPath)
		} else {
			remoteTextDrop(coordinator: coordinator, targetIndexPath: targetIndexPath)
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
			return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
		}
	}
	
	private func localRowDrop(coordinator: UICollectionViewDropCoordinator, targetIndexPath: IndexPath?) {
		guard let outline = outline, let shadowTable = outline.shadowTable else { return }
		
		let rows = coordinator.items.compactMap { $0.dragItem.localObject as? Row }

		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath, let dropInIndexPath = targetIndexPath {
			localRowDrop(coordinator: coordinator, rows: rows, toParent: shadowTable[dropInIndexPath.row], toChildIndex: 0)
			return
		}
		
		// Drop into the first entry in the Outline
		if targetIndexPath == IndexPath(row: 0, section: adjustedRowsSection) {
			localRowDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: 0)
			return
		}
		
		// If we don't have a destination index, drop it at the back
		guard let targetIndexPath = targetIndexPath else {
			localRowDrop(coordinator: coordinator, rows: rows, toParent: outline, toChildIndex: outline.rowCount)
			return
		}

		// This is where most of the sibling moves happen at
		var newParent: RowContainer
		var newIndex: Int
		
		// The target index path points to the following row, but we want the preceding row to be the sibling
		var newSiblingTargetIndexPath = targetIndexPath.row > 0 ? targetIndexPath.row - 1 : 0

		// Adjust the index path when dragging downward
		for row in rows {
			if row.shadowTableIndex ?? 0 < targetIndexPath.row {
				newSiblingTargetIndexPath = newSiblingTargetIndexPath + 1
				break
			}
		}

		let newSiblingCandidate = shadowTable[newSiblingTargetIndexPath]

		// We have to handle dropping into the first entry in a parent in a special way
		if newSiblingTargetIndexPath + 1 < shadowTable.count {
			let newSiblingCandidateChildCandidate = shadowTable[newSiblingTargetIndexPath + 1]
			if newSiblingCandidate.containsRow(newSiblingCandidateChildCandidate) && targetIndexPath.section == adjustedRowsSection {
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
	
	private func localRowDrop(coordinator: UICollectionViewDropCoordinator, rows: [Row], toParent: RowContainer, toChildIndex: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = LocalDropRowCommand(undoManager: undoManager,
										  delegate: self,
										  outline: outline,
										  rows: rows,
										  toParent: toParent,
										  toChildIndex: toChildIndex)
		
		runCommand(command)
	}
	
	private func remoteRowDrop(coordinator: UICollectionViewDropCoordinator, targetIndexPath: IndexPath?) {
		let itemProviders = coordinator.items.compactMap { dropItem -> NSItemProvider? in
			if dropItem.dragItem.itemProvider.hasItemConformingToTypeIdentifier(Row.typeIdentifier) {
				return dropItem.dragItem.itemProvider
			}
			return nil
		}
		
		guard !itemProviders.isEmpty else { return }

		let group = DispatchGroup()
		var rowGroups = [RowGroup]()
		
		for itemProvider in itemProviders {
			group.enter()
			itemProvider.loadDataRepresentation(forTypeIdentifier: Row.typeIdentifier) { [weak self] (data, error) in
				if let data = data {
					do {
						rowGroups.append(try RowGroup.fromData(data))
						group.leave()
					} catch {
						self?.presentError(error)
						group.leave()
					}
				}
			}
		}

		group.notify(queue: DispatchQueue.main) {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, targetIndexPath: targetIndexPath)
		}
	}

	private func remoteTextDrop(coordinator: UICollectionViewDropCoordinator, targetIndexPath: IndexPath?) {
		guard let outline = outline else { return }
		
		let itemProviders = coordinator.items.compactMap { dropItem -> NSItemProvider? in
			if dropItem.dragItem.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeUTF8PlainText as String) {
				return dropItem.dragItem.itemProvider
			}
			return nil
		}
		
		guard !itemProviders.isEmpty else { return }

		let group = DispatchGroup()
		var texts = [String]()
		
		for itemProvider in itemProviders {
			group.enter()
			itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String) { (data, error) in
				if let data = data, let itemText = String(data: data, encoding: .utf8) {
					texts.append(itemText)
					group.leave()
				}
			}
		}

		group.notify(queue: DispatchQueue.main) {
			let text = texts.joined(separator: "\n")
			guard !text.isEmpty else { return }
			
			var rowGroups = [RowGroup]()
			let textRows = text.split(separator: "\n").map { String($0) }
			for textRow in textRows {
				let row = Row.text(TextRow(outline: outline, topicPlainText: textRow.trimmingWhitespace))
				rowGroups.append(RowGroup(row))
			}
			
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, targetIndexPath: targetIndexPath)
		}
	}
	
	private func remoteRowDrop(coordinator: UICollectionViewDropCoordinator, rowGroups: [RowGroup], targetIndexPath: IndexPath?) {
		guard !rowGroups.isEmpty, let outline = self.outline, let shadowTable = outline.shadowTable else { return }

		// Dropping into a Row is easy peasy
		if coordinator.proposal.intent == .insertIntoDestinationIndexPath, let dropInIndexPath = targetIndexPath {
			let newParent = shadowTable[dropInIndexPath.row]
			
			// We only have to set the parent for dropping into.  Otherwise Templeton figures it out on its own.
			rowGroups.forEach { rowGroup in
				rowGroup.row.parent = newParent
			}
			
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: newParent)
			return
		}
		
		// Drop into the first entry in the Outline
		if targetIndexPath == IndexPath(row: 0, section: adjustedRowsSection) {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: nil)
			return
		}
		
		// If we don't have a destination index, drop it at the back
		guard let targetIndexPath = targetIndexPath else {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: nil, prefersEnd: true)
			return
		}

		if shadowTable.count > 0 && targetIndexPath.row > 0 {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: shadowTable[targetIndexPath.row - 1])
		} else {
			self.remoteRowDrop(coordinator: coordinator, rowGroups: rowGroups, afterRow: nil)
		}
	}
	
	private func remoteRowDrop(coordinator: UICollectionViewDropCoordinator, rowGroups: [RowGroup], afterRow: Row?, prefersEnd: Bool = false) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = RemoteDropRowCommand(undoManager: undoManager,
										   delegate: self,
										   outline: outline,
										   rowGroups: rowGroups,
										   afterRow: afterRow,
										   prefersEnd: prefersEnd)
		
		runCommand(command)
	}
	
}
