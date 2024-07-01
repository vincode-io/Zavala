//
//  CollectionsViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/3/20.
//

import UIKit
import VinOutlineKit

extension CollectionsViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		guard !(session.items.first?.localObject is Document) else { return true }
		return session.hasItemsConforming(toTypeIdentifiers: [DataRepresentation.opml.typeIdentifier])
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		guard let destinationIndexPath,
			  let item = dataSource.itemIdentifier(for: destinationIndexPath),
			  let entityID = item.entityID,
			  let container = AccountManager.shared.findDocumentContainer(entityID) else {
			return UICollectionViewDropProposal(operation: .cancel)
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
		guard let destinationIndexPath = coordinator.destinationIndexPath,
			  let item = dataSource.itemIdentifier(for: destinationIndexPath),
			  let entityID = item.entityID,
			  let container = AccountManager.shared.findDocumentContainer(entityID),
			  let account = container.account else { return }
		
		var tags: [Tag]? = nil
		if let tag = (container as? TagDocuments)?.tag {
			tags = [tag]
		}

		// Dragging an OPML file into the Collections View
		guard coordinator.items.first?.dragItem.localObject != nil else {
			for dropItem in coordinator.items {
				let provider = dropItem.dragItem.itemProvider
				provider.loadDataRepresentation(forTypeIdentifier: DataRepresentation.opml.typeIdentifier) { (opmlData, error) in
					guard let opmlData else { return }
					Task { @MainActor in
						if let document = try? await account.importOPML(opmlData, tags: tags) {
							DocumentIndexer.updateIndex(forDocument: document)
						}
					}
				}
			}
			return
		}

		for dropItem in coordinator.items {
			if let document = dropItem.dragItem.localObject as? Document {
				Task {
					guard document.account != container.account else {
						guard let tag = (container as? TagDocuments)?.tag else {
							return
						}
						
						// Adding a tag by dragging a document to it within the same account
						document.createTag(tag)
						return
					}
					
					// Local copy between accounts
					document.load()
					
					var tagNames = [String]()
					for tag in document.tags ?? [Tag]() {
						document.deleteTag(tag)
						document.account?.deleteTag(tag)
						tagNames.append(tag.name)
					}
					
					guard let containerAccount = container.account, let outline = document.outline else { return }
					
					let newDocument = document.duplicate(accountID: containerAccount.id.accountID)
					document.account?.deleteDocument(document)
					containerAccount.createDocument(newDocument)
					
					if let tag = (container as? TagDocuments)?.tag {
						newDocument.createTag(tag)
					}
					
					newDocument.deleteAllBacklinks()
					
					await newDocument.forceSave()
					await newDocument.unload()
				}
			}
		}
	}
	
	
}
