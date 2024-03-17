//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest
@testable import VinOutlineKit

class VOKTestCase: XCTestCase, ErrorHandler {
	
	func presentError(_ error: any Error, title: String) {
		print("!!!!!!!!!! \(title)")
		print("!!!!!!!!!! \(error.localizedDescription)")
	}
	
	func commonSetup() throws {
		let tempDirectory = FileManager.default.temporaryDirectory
		let tempAccountDirectory = tempDirectory.appendingPathComponent("Accounts")
		AccountManager.shared = AccountManager(accountsFolderPath: tempAccountDirectory.path(), errorHandler: self)
	}

	func commonTearDown() throws {
		AccountManager.shared.deleteLocalAccount()
	}

	func loadOutline() throws -> Outline {
		guard let opmlLocation = Bundle.module.url(forResource: "Resources/StarterOutline", withExtension: "opml"),
			  let outline = try AccountManager.shared.localAccount.importOPML(opmlLocation, tags: nil).outline else {
			fatalError()
		}
		outline.load()
		return outline
	}
}
