//
//  EditorViewController+Drag.swift
//  Zavala
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit
import MobileCoreServices
import Templeton

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
				itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
					var markdowns = [String]()
					for row in rows {
						markdowns.append(row.markdownOutline())
					}
					let data = markdowns.joined(separator: "\n").data(using: .utf8)
					completion(data, nil)
					return nil
				}
			}
			
			itemProvider.registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
				do {
					let data = try RowGroup(row).asData()
					completion(data, nil)
				} catch {
					completion(nil, error)
				}
				return nil
			}
			
			let dragItem = UIDragItem(itemProvider: itemProvider)
			dragItem.localObject = row
		
			dragItem.previewProvider = { () -> UIDragPreview? in
				guard let cell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell else { return nil}
				return UIDragPreview(view: cell, parameters: EditorTextRowPreviewParameters(cell: cell, row: row.associatedRow))
			}
			
			dragItems.append(dragItem)
		}
		
		return dragItems
	}
	
}
