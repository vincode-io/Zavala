//
//  WebImportQueue.swift
//  Zavala
//
//  A file-based queue for passing web page URLs from the Share extension to the main app.
//  Uses NSFileCoordinator for safe cross-process access via the shared app group container.
//
//  This single source file is compiled into both the Zavala app and the ShareExtension target
//  so that the write side (`enqueue`) and read side (`drain`) share one file name, location, and
//  JSON format, and cannot drift out of sync.
//

import Foundation

enum WebImportQueue {

	private static let queueFileName = "PendingWebImports.json"

	/// The location of the queue file in the shared app group container, or `nil` if the app group
	/// is unavailable.
	static var fileURL: URL? {
		guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String,
			  let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
			return nil
		}
		return containerURL.appendingPathComponent(queueFileName)
	}

	/// Appends a URL to the queue file using a coordinated write. Called by the Share extension.
	static func enqueue(_ url: URL) {
		guard let fileURL else { return }

		let coordinator = NSFileCoordinator()
		var coordinatorError: NSError?

		coordinator.coordinate(writingItemAt: fileURL, options: .forMerging, error: &coordinatorError) { actualURL in
			var urls: [String]
			if let data = try? Data(contentsOf: actualURL),
			   let decoded = try? JSONDecoder().decode([String].self, from: data) {
				urls = decoded
			} else {
				urls = []
			}
			urls.append(url.absoluteString)
			if let encoded = try? JSONEncoder().encode(urls) {
				try? encoded.write(to: actualURL, options: .atomic)
			}
		}
	}

	/// Reads all queued URLs and clears the file using a coordinated write. Called by the main app.
	static func drain() -> [URL] {
		guard let fileURL,
			  FileManager.default.fileExists(atPath: fileURL.path) else {
			return []
		}

		var result = [URL]()
		let coordinator = NSFileCoordinator()
		var coordinatorError: NSError?

		coordinator.coordinate(writingItemAt: fileURL, options: .forDeleting, error: &coordinatorError) { actualURL in
			if let data = try? Data(contentsOf: actualURL),
			   let decoded = try? JSONDecoder().decode([String].self, from: data) {
				result = decoded.compactMap { URL(string: $0) }
			}
			if !result.isEmpty {
				try? Data("[]".utf8).write(to: actualURL, options: .atomic)
			}
		}

		return result
	}

}
