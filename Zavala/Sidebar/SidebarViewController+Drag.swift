//
//  SidebarViewController+Drag.swift
//  Zavala
//
//  Created by Maurice Parker on 11/8/21.
//

import UIKit
import Templeton

extension SidebarViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		let itemProvider = NSItemProvider()
		
		guard let item = dataSource.itemIdentifier(for: indexPath),
			  case .documentContainer(let entityID) = item.id,
			  let container = AccountManager.shared.findDocumentContainer(entityID)	else {
			return []
		}

		let userActivity = NSUserActivity(activityType: NSUserActivity.ActivityType.newWindow)
		var userInfo = [AnyHashable: Any]()
		userInfo[Pin.UserInfoKeys.pin] = Pin(containers: [container]).userInfo
		userActivity.userInfo = userInfo
		itemProvider.registerObject(userActivity, visibility: .all)

		let dragItem = UIDragItem(itemProvider: itemProvider)
		return [dragItem]
	}
	
}
