//
//  RowsFile.swift
//  
//
//  Created by Maurice Parker on 11/15/20.
//

import Foundation
import os.log
import RSCore

struct OutlineRows: Codable {
	var rowOrder: [EntityID]
	var keyedRows: [EntityID: Row]
}

final class RowsFile {
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "RowsFile")

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
		let localAccountFolder = AccountManager.shared.accountsFolder.appendingPathComponent(account.type.folderName)
		fileURL = localAccountFolder.appendingPathComponent("\(outline.id.documentUUID).plist")
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
				os_log(.error, log: log, "RowsFile delete from disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "RowsFile delete from disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}

private extension RowsFile {

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
			os_log(.error, log: log, "RowsFile read from disk coordination failed: %@.", error.localizedDescription)
		}

		// As we migrate to compressed data, the previous data may still be uncompressed
//		if let decompressedData = try? (fileData as NSData?)?.decompressed(using: .lz4) as Data? {
//			fileData = decompressedData
//		}
		
		guard let rowsData = fileData else {
			return
		}

		let decoder = PropertyListDecoder()
		let outlineRows: OutlineRows
		do {
			outlineRows = try decoder.decode(OutlineRows.self, from: rowsData)
		} catch {
			os_log(.error, log: log, "RowsFile read deserialization failed: %@.", error.localizedDescription)
			return
		}

		outline?.rowOrder = outlineRows.rowOrder
		outline?.keyedRows = outlineRows.keyedRows
	}
	
	func saveCallback() {
		guard let rowOrder = outline?.rowOrder, let keyedRows = outline?.keyedRows else { return }
		let outlineRows = OutlineRows(rowOrder: rowOrder, keyedRows: keyedRows)

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		var rowsData: Data
		do {
			rowsData = try encoder.encode(outlineRows)
		} catch {
			os_log(.error, log: log, "RowsFile read deserialization failed: %@.", error.localizedDescription)
			return
		}

//		if let compressedData = try? (rowsData as NSData?)?.compressed(using: .lz4) as Data? {
//			rowsData = compressedData
//		}
		
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try rowsData.write(to: writeURL)
				let resourceValues = try writeURL.resourceValues(forKeys: [.contentModificationDateKey])
				lastModificationDate = resourceValues.contentModificationDate
			} catch let error as NSError {
				os_log(.error, log: log, "RowsFile save to disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "RowsFile save to disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}

