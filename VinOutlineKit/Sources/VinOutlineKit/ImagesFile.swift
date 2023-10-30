//
//  ImagesFile.swift
//
//  Created by Maurice Parker on 7/31/21.
//

import Foundation
import os.log
import VinUtility

final class ImagesFile {
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Templeton")

	private weak var outline: Outline?
	private let fileURL: URL
	private lazy var managedFile = ManagedResourceFile(fileURL: fileURL,
													   load: { [weak self] in self?.loadCallback() },
													   save: { [weak self] in self?.saveCallback() })
	private var lastModificationDate: Date?
	
	init?(outline: Outline) {
		guard let account = outline.account else {
			return nil
		}
		self.outline = outline
		let accountFolder = AccountManager.shared.accountsFolder.appendingPathComponent(account.type.folderName)
		fileURL = accountFolder.appendingPathComponent("\(outline.id.documentUUID)_images.plist")
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
	
	func suspend() {
		managedFile.suspend()
	}
	
	func resume() {
		managedFile.resume()
	}
	
	func delete() {
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [.forDeleting], error: errorPointer, byAccessor: { writeURL in
			do {
				if FileManager.default.fileExists(atPath: writeURL.path) {
					try FileManager.default.removeItem(atPath: writeURL.path)
				}
			} catch let error as NSError {
				os_log(.error, log: log, "ImagesFile delete from disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "ImagesFile delete from disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}

// MARK: Helpers

private extension ImagesFile {

	func loadCallback() {
		var fileData: Data? = nil
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(readingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { readURL in
			do {
				let resourceValues = try readURL.resourceValues(forKeys: [.contentModificationDateKey])
				guard lastModificationDate != resourceValues.contentModificationDate else {
					return
				}
				lastModificationDate = resourceValues.contentModificationDate

				fileData = try Data(contentsOf: readURL)
			} catch {
				// Ignore this.  It will get called everytime we create a new Outline
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "ImagesFile read from disk coordination failed: %@.", error.localizedDescription)
		}

		guard let imagesData = fileData else {
			return
		}

		let decoder = PropertyListDecoder()
		let outlineImages: [String: [Image]]
		do {
			outlineImages = try decoder.decode([String: [Image]].self, from: imagesData)
		} catch {
			os_log(.error, log: log, "ImagesFile read deserialization failed: %@.", error.localizedDescription)
			return
		}

		outline?.images = outlineImages
	}
	
	func saveCallback() {
		guard let outlineImages = outline?.images, !outlineImages.isEmpty else {
			delete()
			return
		}

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		var imagesData: Data
		do {
			imagesData = try encoder.encode(outlineImages)
		} catch {
			os_log(.error, log: log, "ImagesFile read deserialization failed: %@.", error.localizedDescription)
			return
		}

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try imagesData.write(to: writeURL)
				let resourceValues = try writeURL.resourceValues(forKeys: [.contentModificationDateKey])
				lastModificationDate = resourceValues.contentModificationDate
			} catch let error as NSError {
				os_log(.error, log: log, "ImagesFile save to disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "ImagesFile save to disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}
