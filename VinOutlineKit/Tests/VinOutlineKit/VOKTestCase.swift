//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest
import VinOutlineKit
import VinXML

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

}
