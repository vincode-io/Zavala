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

			let fileName = outline.fileName(withSuffix: "opml")
			itemProvider.suggestedName = fileName
			itemProvider.registerFileRepresentation(forTypeIdentifier: "org.opml.opml", visibility: .all) { (completionHandler) -> Progress? in
				let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
				do {
					let opml = outline.opml()
					try opml.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
					completionHandler(tempFile, true, nil)
				} catch {
					completionHandler(nil, false, error)
				}
				return nil
			}
			
			itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
				let data = outline.markdownList().data(using: .utf8)
				completion(data, nil)
				return nil
			}
			
		}
		
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = document
		return [dragItem]
	}
	
}
