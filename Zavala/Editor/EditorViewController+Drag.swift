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
		guard indexPath.section == 1, let shadowTable = outline?.shadowTable else { return [] }
		
		var dragItems = [UIDragItem]()
		let row = shadowTable[indexPath.row]

		let itemProvider = NSItemProvider()

		itemProvider.registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
			do {
				let data = try row.asData()
				completion(data, nil)
			} catch {
				completion(nil, error)
			}
			return nil
		}

		itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
			let data = row.markdown().data(using: .utf8)
			completion(data, nil)
			return nil
		}
	
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = row
	
		dragItem.previewProvider = { () -> UIDragPreview? in
			guard let cell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell else { return nil}
			return UIDragPreview(view: cell, parameters: EditorTextRowPreviewParameters(cell: cell, row: row.associatedRow))
		}
		
		dragItems.append(dragItem)
		
//		outline?.childrenRows(forRow: row).forEach { child in
//			let itemProvider = NSItemProvider()
//			let dragItem = UIDragItem(itemProvider: itemProvider)
//			dragItems.append(dragItem)
//		}
		
		return dragItems
	}
	
}
