//
//  TestHost.swift
//  Zavala
//

import Foundation

/// True only when the ZavalaTests scheme launches the app as a test host.
/// The app then uses a throwaway accounts folder and settings store, and skips
/// iCloud, indexing, and the share-extension import queue.
enum TestHost {
	static let isActive = ProcessInfo.processInfo.environment["ZAVALA_TEST_HOST"] == "1"
	static let accountsFolderPath = FileManager.default.temporaryDirectory
		.appending(path: "ZavalaTestHost-\(UUID().uuidString)/Accounts").path
	static let defaultsSuiteName = "ZavalaTestHost"
}
