//
//  HeadlinesFile.swift
//  
//
//  Created by Maurice Parker on 11/15/20.
//

import Foundation
import os.log
import RSCore

final class HeadlinesFile {
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "headlinesFile")

	private weak var outline: Outline?
	private let fileURL: URL
	private lazy var managedFile = ManagedResourceFile(fileURL: fileURL, load: loadCallback, save: saveCallback)
	
	init(outline: Outline) {
		self.outline = outline

		let localAccountFolder = AccountManager.shared.accountsFolder.appendingPathComponent(outline.account!.type.folderName)
		fileURL = localAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
	}
	
	func markAsDirty() {
		managedFile.markAsDirty()
	}
	
	func load() {
		managedFile.load()
	}
	
	func save() {
		managedFile.saveIfNecessary()
	}
	
}

private extension HeadlinesFile {

	func loadCallback() {
		var fileData: Data? = nil
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(readingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { readURL in
			do {
				fileData = try Data(contentsOf: readURL)
			} catch {
				os_log(.error, log: log, "Headlines read from disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Headlines read from disk coordination failed: %@.", error.localizedDescription)
		}

		guard let headlinesData = fileData else {
			return
		}

		let decoder = JSONDecoder()
		let headlines: [Headline]
		do {
			headlines = try decoder.decode([Headline].self, from: headlinesData)
		} catch {
			os_log(.error, log: log, "Account read deserialization failed: %@.", error.localizedDescription)
			return
		}

		outline?.headlines = headlines
	}
	
	func saveCallback() {
		
		guard let headlines = outline?.headlines else { return }
		let encoder = JSONEncoder()
		let headlinesData: Data
		do {
			headlinesData = try encoder.encode(headlines)
		} catch {
			os_log(.error, log: log, "Account read deserialization failed: %@.", error.localizedDescription)
			return
		}

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try headlinesData.write(to: writeURL)
			} catch let error as NSError {
				os_log(.error, log: log, "Account save to disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Account save to disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}

