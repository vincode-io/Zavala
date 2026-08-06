//
//  SharedWebImportQueue.swift
//  ShareExtension
//
//  File-based queue for passing web page URLs from the Share extension to the main app.
//  Uses NSFileCoordinator for safe cross-process access. The app's SceneDelegate reads and clears
//  this same file (same name, container, and JSON format).
//

import Foundation

enum SharedWebImportQueue {

	private static let queueFileName = "PendingWebImports.json"

	static var queueFileURL: URL? {
		guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String,
			  let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
			return nil
		}
		return containerURL.appendingPathComponent(queueFileName)
	}

	/// Appends a URL to the queue file using a coordinated write.
	static func enqueue(_ url: URL) {
		guard let fileURL = queueFileURL else { return }

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

}
