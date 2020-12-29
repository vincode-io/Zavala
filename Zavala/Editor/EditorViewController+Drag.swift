//
//  EditorViewController+Drag.swift
//  Zavala
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit
import MobileCoreServices

extension EditorViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard indexPath.section == 1 else { return [] }
		guard let row = outline?.shadowTable?[indexPath.row] else { return [UIDragItem]() }
		
		session.localContext = row
		
		let itemProvider = NSItemProvider()
		itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
			let data = row.markdown().data(using: .utf8)
			completion(data, nil)
			return nil
		}
		
		var dragItems = [UIDragItem]()
		
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
