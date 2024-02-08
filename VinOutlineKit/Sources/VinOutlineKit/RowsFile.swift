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


final class RowsFile: ManagedResourceFile {
	
	private weak var outline: Outline?
	
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
	
	public override func fileWillSave() -> Data? {
		return outline?.buildRowFileData()
	}
	
}
