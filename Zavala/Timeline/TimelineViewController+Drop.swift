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
		guard documentContainer is Folder else { return false }
		return session.hasItemsConforming(toTypeIdentifiers: ["org.opml.opml"])
	}
		
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard let folder = documentContainer as? Folder else { return }

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
