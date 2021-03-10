//
//  TimelineViewController+Drop.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import Templeton

extension TimelineViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		guard documentContainer?.account != nil else { return false }
		return session.hasItemsConforming(toTypeIdentifiers: ["org.opml.opml"])
	}
		
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let account = documentContainer?.account else { return }

		for dropItem in coordinator.items {
			let provider = dropItem.dragItem.itemProvider
			provider.loadDataRepresentation(forTypeIdentifier: "org.opml.opml") { [weak self] (opmlData, error) in
				guard let opmlData = opmlData else { return }
				DispatchQueue.main.async {
					let tag = (self?.documentContainer as? TagDocuments)?.tag
					let document = account.importOPML(opmlData, tag: tag)
					DocumentIndexer.updateIndex(forDocument: document)
				}
			}
		}
	}
	
}
