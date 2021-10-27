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
	let fileVersion = 2
	var rowOrder: [String]
	var keyedRows: [String: Row]

	private enum CodingKeys: String, CodingKey {
		case fileVersion
		case rowOrder
		case keyedRows
	}
	
	public init(rowOrder: [String], keyedRows: [String: Row]) {
		self.rowOrder = rowOrder
		self.keyedRows = keyedRows
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let fileVersion = (try? container.decode(Int.self, forKey: .fileVersion)) ?? 1

		let allRows: [Row]

		switch fileVersion {
		case 1:
			if let rowOrder = try? container.decode([EntityID].self, forKey: .rowOrder) {
				self.rowOrder = rowOrder.map { $0.rowUUID}
			} else {
				self.rowOrder = [String]()
			}
			if let entityKeyedRows = try? container.decode([EntityID: Row].self, forKey: .keyedRows) {
				allRows = Array(entityKeyedRows.values)
			} else {
				allRows = [Row]()
			}
		case 2:
			if let rowOrder = try? container.decode([String].self, forKey: .rowOrder) {
				self.rowOrder = rowOrder
			} else {
				self.rowOrder = [String]()
			}
			if let rows = try? container.decode([Row].self, forKey: .keyedRows) {
				allRows = rows
			} else {
				allRows = [Row]()
			}
		default:
			fatalError("Unrecognized Row File Version")
		}
		
		self.keyedRows = allRows.reduce([String: Row]()) { result, row in
			var mutableResult = result
			mutableResult[row.id] = row
			return mutableResult
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(fileVersion, forKey: .fileVersion)
		try container.encode(rowOrder, forKey: .rowOrder)
		try container.encode(Array(keyedRows.values), forKey: .keyedRows)
	}
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
		let accountFolder = AccountManager.shared.accountsFolder.appendingPathComponent(account.type.folderName)
		fileURL = accountFolder.appendingPathComponent("\(outline.id.documentUUID).plist")
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

