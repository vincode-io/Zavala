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
			  let entityID = sidebarItem.entityID,
			  let container = AccountManager.shared.findDocumentContainer(entityID) else {
			return UICollectionViewDropProposal(operation: .cancel)
		}
		
		guard !(container is RecentDocuments) else {
			return UICollectionViewDropProposal(operation: .forbidden)
		}
		
		guard session.localDragSession != nil else {
			return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
		}
		
		let sourceAccount = (session.localDragSession?.localContext as? Document)?.account
		let destinationAccount = container.account
		
		if sourceAccount == destinationAccount {
			if let tag = (container as? TagDocuments)?.tag {
				if let document = session.localDragSession?.localContext as? Document, document.hasTag(tag) {
					return UICollectionViewDropProposal(operation: .cancel)
				}
			}
			return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
		} else {
			return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
		}
		
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let dragItem = coordinator.items.first?.dragItem,
			  let destinationIndexPath = coordinator.destinationIndexPath,
			  let sidebarItem = dataSource.itemIdentifier(for: destinationIndexPath),
			  let entityID = sidebarItem.entityID,
			  let container = AccountManager.shared.findDocumentContainer(entityID) else { return }
		
		// Dragging an OPML file into the sidebar
		guard let document = dragItem.localObject as? Document else {
			for dropItem in coordinator.items {
				let provider = dropItem.dragItem.itemProvider
				provider.loadDataRepresentation(forTypeIdentifier: "org.opml.opml") { (opmlData, error) in
					guard let opmlData = opmlData else { return }
					DispatchQueue.main.async {
						let tag = (container as? TagDocuments)?.tag
						if let document = container.account?.importOPML(opmlData, tag: tag) {
							DocumentIndexer.updateIndex(forDocument: document)
						}
					}
				}
			}
			return
		}

		// Local copy between accounts
		guard document.account == container.account else {
			document.load()
			
			var tagNames = [String]()
			for tag in document.tags ?? [Tag]() {
				document.deleteTag(tag)
				document.account?.deleteTag(tag)
				tagNames.append(tag.name)
			}
			
			document.account?.deleteDocument(document)
			container.account?.createDocument(document)
			
			for tagName in tagNames {
				if let tag = container.account?.createTag(name: tagName) {
					document.createTag(tag)
				}
			}
			
			document.forceSave()
			document.suspend(documentMayHaveChanged: true)
			return
		}
		
		// Adding a tag by dragging a document to it
		guard let tag = (container as? TagDocuments)?.tag else {
			return
		}
		
		document.createTag(tag)
	}
	
	
}
