//
//  DocumentsActivityItemsConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/27/22.
//

import UIKit
import MobileCoreServices
import LinkPresentation
import Templeton

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
			
			itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
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

		if #available(iOS 15.0, *) {
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
		} else {
			switch key {
			case .title:
				return selectedDocuments[at].title
			default:
				return nil
			}
		}
	}

}

private class CopyDocumentLinkActivity: UIActivity {
	
	private let documents: [Document]
	
	init(documents: [Document]) {
		self.documents = documents
	}
	
	override var activityTitle: String? {
		if documents.count > 1 {
			return AppStringAssets.copyDocumentLinksControlLabel
		} else {
			return AppStringAssets.copyDocumentLinkControlLabel
		}
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.copyDocumentLink")
	}
	
	override var activityImage: UIImage? {
		ZavalaImageAssets.documentLink
	}
	
	override class var activityCategory: UIActivity.Category {
		.action
	}
	
	override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		true
	}
	
	override func prepare(withActivityItems activityItems: [Any]) {
		
	}
	
	override func perform() {
		UIPasteboard.general.strings = documents.compactMap { $0.id.url?.absoluteString }
		activityDidFinish(true)
	}
}
