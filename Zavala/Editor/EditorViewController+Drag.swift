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
		
		var dragItems = [UIDragItem]()
		
		let indicatedRow = shadowTable[indexPath.row]
		let rows = currentRows?.sortedWithDecendentsFiltered() ?? [indicatedRow]

		guard indicatedRow == rows.first else { return [] }
		
		for row in rows {
			let itemProvider = NSItemProvider()

			// We only register the text representation on the first one, since it looks like most text editors only support 1 dragged text item
			if row == rows[0] {
				var markdowns = [String]()
				for row in rows {
					markdowns.append(row.markdownList())
				}
				let markdownData = markdowns.joined(separator: "\n").data(using: .utf8)

				itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { completion in
					completion(markdownData, nil)
					return nil
				}
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
				guard let cell = collectionView.cellForItem(at: indexPath) as? EditorRowViewCell else { return nil}
				return UIDragPreview(view: cell, parameters: EditorRowPreviewParameters(cell: cell))
			}
			
			dragItems.append(dragItem)
		}
		
		return dragItems
	}
	
}
