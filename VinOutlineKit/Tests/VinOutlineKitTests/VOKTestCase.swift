//
//  Created by Maurice Parker on 3/16/24.
//

import Foundation
import Testing
@testable import VinOutlineKit

class VOKTestCase: ErrorHandler, OutlineCommandDelegate {

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

	func buildAccountManager() -> AccountManager {
		let tempDirectory = FileManager.default.temporaryDirectory
		let tempAccountDirectory = tempDirectory.appendingPathComponent("Accounts-\(UUID().uuidString)")
		return AccountManager(accountsFolderPath: tempAccountDirectory.path(), errorHandler: self)
	}
	
	func deleteAccountManager(_ accountManager: AccountManager) {
		accountManager.deleteLocalAccount()
	}
	
	func loadOutline(_ name: String = "StarterOutline", accountManager: AccountManager) async throws -> Outline {
		guard let opmlLocation = Bundle.module.url(forResource: "Resources/\(name)", withExtension: "opml"),
			  let outline = try await accountManager.localAccount?.importOPML(opmlLocation, tags: nil).outline else {
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
