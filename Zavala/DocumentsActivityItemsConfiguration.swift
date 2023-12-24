//
//  DocumentsActivityItemsConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/27/22.
//

import UIKit
import UniformTypeIdentifiers
import LinkPresentation
import VinOutlineKit

protocol DocumentsActivityItemsConfigurationDelegate: AnyObject {
	var selectedDocuments: [Document] { get }
}

class DocumentsActivityItemsConfiguration: NSObject {
	
	private weak var delegate: DocumentsActivityItemsConfigurationDelegate?
	private var heldDocuments: [Document]?
	
	var selectedDocuments: [Document] {
		return heldDocuments ?? delegate?.selectedDocuments ?? []
	}
	
	init(delegate: DocumentsActivityItemsConfigurationDelegate) {
		self.delegate = delegate
	}
	
	init(selectedDocuments: [Document]) {
		heldDocuments = selectedDocuments
	}
}

extension DocumentsActivityItemsConfiguration: UIActivityItemsConfigurationReading {
	
	@objc var applicationActivitiesForActivityItemsConfiguration: [UIActivity]? {
		guard !selectedDocuments.isEmpty else {
			return nil
		}
		
		return [CopyDocumentLinkActivity(documents: selectedDocuments)]
	}
	
	var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
		guard !selectedDocuments.isEmpty else {
			return [NSItemProvider]()
		}
		
		let itemProviders: [NSItemProvider] = selectedDocuments.compactMap { document in
			let itemProvider = NSItemProvider()
			
			itemProvider.registerDataRepresentation(for: UTType.utf8PlainText, visibility: .all) { completion in
				if Thread.isMainThread {
					let data = document.formattedPlainText.data(using: .utf8)
					completion(data, nil)
				} else {
					DispatchQueue.main.async {
						let data = document.formattedPlainText.data(using: .utf8)
						completion(data, nil)
					}
				}
				return nil
			}
			
			return itemProvider
		}
		
		return itemProviders
	}
	
	func activityItemsConfigurationMetadataForItem(at: Int, key: UIActivityItemsConfigurationMetadataKey) -> Any? {
		guard !selectedDocuments.isEmpty else {
			return nil
		}

		switch key {
		case .title:
			return selectedDocuments[at].title
		case .linkPresentationMetadata:
			let iconView = UIImageView(image: ZavalaImageAssets.outline)
			iconView.backgroundColor = .accentColor
			iconView.tintColor = .label
			iconView.contentMode = .scaleAspectFit
			iconView.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
			let metadata = LPLinkMetadata()
			metadata.title = selectedDocuments[at].title
			metadata.iconProvider = NSItemProvider(object: iconView.asImage())
			return metadata
		default:
			return nil
		}
	}

}
