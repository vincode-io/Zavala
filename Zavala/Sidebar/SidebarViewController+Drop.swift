//
//  SidebarViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/3/20.
//

import UIKit
import Templeton

extension SidebarViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		guard let destinationIndexPath = destinationIndexPath,
			  let sidebarItem = dataSource.itemIdentifier(for: destinationIndexPath),
			  let folderEntityID = sidebarItem.entityID,
			  let folder = AccountManager.shared.findFolder(folderEntityID) else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		guard sidebarItem.isFolder else {
			return UICollectionViewDropProposal(operation: .forbidden)
		}
		
		if let outline = session.localDragSession?.localContext as? Outline, folder == outline.folder {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		if session.localDragSession == nil {
			return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let dragItem = coordinator.items.first?.dragItem,
			  let destinationIndexPath = coordinator.destinationIndexPath,
			  let sidebarItem = dataSource.itemIdentifier(for: destinationIndexPath),
			  let folderEntityID = sidebarItem.entityID,
			  let folder = AccountManager.shared.findFolder(folderEntityID) else { return }
		
		if let document = dragItem.localObject as? Document {
			document.load()
			document.folder?.deleteDocument(document)
			folder.createDocument(document)
			document.forceSave()
		} else {
			for dropItem in coordinator.items {
				let provider = dropItem.dragItem.itemProvider
				provider.loadDataRepresentation(forTypeIdentifier: "org.opml.opml") { (opmlData, error) in
					guard let opmlData = opmlData else { return }
					DispatchQueue.main.async {
						folder.importOPML(opmlData)
					}
				}
			}
		}

	}
	
	
}
