//
//  TimelineViewController+Drag.swift
//  Zavala
//
//  Created by Maurice Parker on 12/2/20.
//

import UIKit
import MobileCoreServices
import Templeton

extension TimelineViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard let timelineItem = dataSource.itemIdentifier(for: indexPath),
			  let document = AccountManager.shared.findDocument(timelineItem.id) else { return [UIDragItem]() }
		
		session.localContext = document
		
		let itemProvider = NSItemProvider()

		switch document {
		case .outline(let outline):
			itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
				let data = outline.markdown().data(using: .utf8)
				completion(data, nil)
				return nil
			}
		}
		
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = document
		return [dragItem]
	}
	
}
