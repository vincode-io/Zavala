//
//  EditorViewController+Drag.swift
//  Zavala
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit
import UniformTypeIdentifiers
import VinOutlineKit

extension EditorViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard indexPath.section == adjustedRowsSection, let shadowTable = outline?.shadowTable else { return [] }
		
		let row = shadowTable[indexPath.row]
		
		for currentRow in currentRows ?? [] {
			if row.isDecendent(currentRow) {
				return []
			}
		}
		
		let itemProvider = NSItemProvider()

		let markdownData = row.markdownList(numberingStyle: .none).data(using: .utf8)
		itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { completion in
			completion(markdownData, nil)
			return nil
		}
		
		if let rowData = try? RowGroup(row).asData() {
			itemProvider.registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
				completion(rowData, nil)
				return nil
			}
		}
		
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = row
	
		dragItem.previewProvider = { () -> UIDragPreview? in
			guard let shadowTableIndex = row.shadowTableIndex else { return nil }
			let indexPath = IndexPath(row: shadowTableIndex, section: indexPath.section)
			guard let cell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return nil}
			return UIDragPreview(view: cell, parameters: EditorRowPreviewParameters(cell: cell))
		}
		
		return [dragItem]
	}
	
}
