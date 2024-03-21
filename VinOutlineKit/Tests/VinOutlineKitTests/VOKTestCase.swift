//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest
@testable import VinOutlineKit

class VOKTestCase: XCTestCase, ErrorHandler, OutlineCommandDelegate {

	var undoManager: UndoManager!

	func presentError(_ error: any Error, title: String) {
		print("!!!!!!!!!! \(title)")
		print("!!!!!!!!!! \(error.localizedDescription)")
	}
	
	var currentCoordinates: VinOutlineKit.CursorCoordinates? {
		return nil
	}
	
	func restoreCursorPosition(_: VinOutlineKit.CursorCoordinates) {
	}
	
	override func setUpWithError() throws {
		try commonSetup()
	}

	override func tearDownWithError() throws {
		try commonTearDown()
	}

	func commonSetup() throws {
		let tempDirectory = FileManager.default.temporaryDirectory
		let tempAccountDirectory = tempDirectory.appendingPathComponent("Accounts")
		AccountManager.shared = AccountManager(accountsFolderPath: tempAccountDirectory.path(), errorHandler: self)
		
		undoManager = UndoManager()
	}

	func commonTearDown() throws {
		AccountManager.shared.deleteLocalAccount()
	}

	func loadOutline(_ name: String = "StarterOutline") throws -> Outline {
		guard let opmlLocation = Bundle.module.url(forResource: "Resources/\(name)", withExtension: "opml"),
			  let outline = try AccountManager.shared.localAccount.importOPML(opmlLocation, tags: nil).outline else {
			fatalError()
		}
		outline.load()
		return outline
	}
	
	func loadOPML(_ name: String) -> String {
		guard let opmlLocation = Bundle.module.url(forResource: "Resources/\(name)", withExtension: "opml"),
			  let opml = try? String(contentsOf: opmlLocation) else {
			fatalError()
		}
		return opml
	}
	
}
