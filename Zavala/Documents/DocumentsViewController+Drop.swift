//
//  DocumentsViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import VinOutlineKit

extension DocumentsViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		guard documentContainers?.uniqueAccount != nil else { return false }
		return session.hasItemsConforming(toTypeIdentifiers: [DataRepresentation.opml.typeIdentifier])
	}
		
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let account = documentContainers?.uniqueAccount else { return }

		let tags = documentContainers?.compactMap { ($0 as? TagDocuments)?.tag }

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
	}
	
}
