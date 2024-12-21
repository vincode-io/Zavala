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
			let markdownListData = outline.markdownList().data(using: .utf8)
			itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { completion in
				completion(markdownListData, nil)
				return nil
			}
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
		
		let userActivity = NSUserActivity(activityType: NSUserActivity.ActivityType.newWindow)
		var userInfo = [AnyHashable: Any]()
		userInfo[Pin.UserInfoKeys.pin] = Pin(accountManager: appDelegate.accountManager, containers: documentContainers, document: document).userInfo
		userActivity.userInfo = userInfo
		itemProvider.registerObject(userActivity, visibility: .all)

		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = document
		return [dragItem]
	}
	
}
