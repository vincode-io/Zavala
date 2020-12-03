//
//  SidebarViewController+Drop.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/3/20.
//

import UIKit
import Templeton

extension SidebarViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		return session.localDragSession != nil
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		guard let outline = session.localDragSession?.localContext as? Outline,
			  let destinationIndexPath = destinationIndexPath,
			  let sidebarItem = dataSource.itemIdentifier(for: destinationIndexPath),
			  let folderEntityID = sidebarItem.entityID,
			  let folder = AccountManager.shared.findFolder(folderEntityID) else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		guard sidebarItem.isFolder else {
			return UICollectionViewDropProposal(operation: .forbidden)
		}
		
		if folder == outline.folder {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let dragItem = coordinator.items.first?.dragItem,
			  let outline = dragItem.localObject as? Outline,
			  let destinationIndexPath = coordinator.destinationIndexPath,
			  let sidebarItem = dataSource.itemIdentifier(for: destinationIndexPath),
			  let folderEntityID = sidebarItem.entityID,
			  let folder = AccountManager.shared.findFolder(folderEntityID) else { return }
		
		outline.load()
		outline.folder?.deleteOutline(outline)
		folder.createOutline(outline)
		outline.forceSave()

	}
	
	
}
