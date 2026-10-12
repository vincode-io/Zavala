//
//  HostIsolationTests.swift
//  ZavalaTests
//
//  Guards the test host itself: if these fail, no other ZavalaTests result can be trusted,
//  and the run may have touched real data.
//

import Foundation
import Testing
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Test host isolation", .serialized)
struct HostIsolationTests {

	@Test("The app knows it is running as a test host")
	func testHostIsActive() {
		#expect(TestHost.isActive)
	}

	@Test("Accounts live in a temporary folder, not the app group container")
	func accountsAreTemporary() throws {
		let accountManager = try #require(appDelegate.accountManager)
		let tempPath = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().path
		#expect(accountManager.accountsFolder.resolvingSymlinksInPath().path.hasPrefix(tempPath))
		#expect(!accountManager.accountsFolder.path.contains("Group Containers"))
	}

	@Test("No iCloud account exists")
	func noCloudKitAccount() throws {
		#expect(try #require(appDelegate.accountManager).cloudKitAccount == nil)
		#expect(AppDefaults.shared.enableCloudKit == false)
	}

	@Test("Settings are read from and written to the throwaway test store")
	func settingsUseTestStore() {
		let testStore = UserDefaults(suiteName: TestHost.defaultsSuiteName)!
		let original = AppDefaults.shared.textZoom
		defer { AppDefaults.shared.textZoom = original }

		AppDefaults.shared.textZoom = original + 3
		#expect(testStore.integer(forKey: "textZoom") == original + 3)
	}
}
