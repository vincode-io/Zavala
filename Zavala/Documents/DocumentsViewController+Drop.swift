//
//  DocumentsViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import Templeton

extension DocumentsViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		guard documentContainers?.uniqueAccount != nil else { return false }
		return session.hasItemsConforming(toTypeIdentifiers: [DataRepresentation.opml.typeIdentifier])
	}
		
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let account = documentContainers?.uniqueAccount else { return }

		for dropItem in coordinator.items {
			let provider = dropItem.dragItem.itemProvider
			provider.loadDataRepresentation(forTypeIdentifier: DataRepresentation.opml.typeIdentifier) { [weak self] (opmlData, error) in
				guard let opmlData = opmlData else { return }
				DispatchQueue.main.async {
                    let tags = self?.documentContainers?.compactMap { ($0 as? TagDocuments)?.tag }
					let document = account.importOPML(opmlData, tags: tags)
					DocumentIndexer.updateIndex(forDocument: document)
				}
			}
		}
	}
	
}
