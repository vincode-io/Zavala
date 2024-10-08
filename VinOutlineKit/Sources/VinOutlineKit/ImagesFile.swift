//
//  ImagesFile.swift
//
//  Created by Maurice Parker on 7/31/21.
//

import Foundation
import OSLog
import VinUtility

final class ImagesFile: ManagedResourceFile, @unchecked Sendable {
	
	private weak var outline: Outline?
	
	@MainActor
	init?(outline: Outline) {
		self.outline = outline

		guard let account = outline.account else {
			return nil
		}

		let fileURL = account.folder.appendingPathComponent("\(outline.id.documentUUID)_images.plist")
		super.init(fileURL: fileURL)
	}
	
	public override func fileDidLoad(data: Data) {
		outline?.loadImageFileData(data)
	}
	
	public override func fileWillSave() async -> Data? {
		return outline?.buildImageFileData()
	}
	
}
