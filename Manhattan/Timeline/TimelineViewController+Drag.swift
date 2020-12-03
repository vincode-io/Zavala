//
//  TimelineViewController+Drag.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/2/20.
//

import UIKit
import MobileCoreServices

extension TimelineViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard let outline = currentOutline else { return [UIDragItem]() }
		
		session.localContext = outline
		
		let itemProvider = NSItemProvider()
		itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
			let data = outline.markdown().data(using: .utf8)
			completion(data, nil)
			return nil
		}
		
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = outline
		return [dragItem]
	}
	
}
