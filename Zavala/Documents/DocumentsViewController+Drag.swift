//
//  DocumentsViewController+Drag.swift
//  Zavala
//
//  Created by Maurice Parker on 12/2/20.
//

import UIKit
import UniformTypeIdentifiers
import VinOutlineKit

extension DocumentsViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		let document = documents[indexPath.row]
		session.localContext = document
		
		let itemProvider = NSItemProvider()

		switch document {
		case .outline(let outline):
			let filename = outline.filename(type: .opml)
			itemProvider.suggestedName = filename
			
			itemProvider.registerFileRepresentation(forTypeIdentifier: UTType.opml.identifier, visibility: .all) { completion -> Progress? in
				let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
				Task { @MainActor in
					do {
						let opml = outline.opml()
						try opml.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
						completion(tempFile, true, nil)
					} catch {
						completion(nil, false, error)
					}
				}
				return nil
			}
			
			itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
				Task { @MainActor in
					let data = outline.markdownList().data(using: .utf8)
					completion(data, nil)
				}
				return nil
			}
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
		
		let userActivity = NSUserActivity(activityType: NSUserActivity.ActivityType.newWindow)
		var userInfo = [AnyHashable: Any]()
		userInfo[Pin.UserInfoKeys.pin] = Pin(containers: documentContainers, document: document).userInfo
		userActivity.userInfo = userInfo
		itemProvider.registerObject(userActivity, visibility: .all)

		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = document
		return [dragItem]
	}
	
}
