//
//  RowsFile.swift
//  
//
//  Created by Maurice Parker on 11/15/20.
//

import Foundation
import OSLog
import OrderedCollections
import VinUtility

final class RowsFile: ManagedResourceFile, @unchecked Sendable {
	
	private weak var outline: Outline?
	
	@MainActor
	init?(outline: Outline) {
		self.outline = outline

		guard let account = outline.account else {
			return nil
		}

		let fileURL = account.folder.appendingPathComponent("\(outline.id.documentUUID).plist")
		super.init(fileURL: fileURL)
	}
	
	public override func fileDidLoad(data: Data) {
		outline?.loadRowFileData(data)
	}
	
	public override func fileWillSave() async -> Data? {
		return outline?.buildRowFileData()
	}
	
}
