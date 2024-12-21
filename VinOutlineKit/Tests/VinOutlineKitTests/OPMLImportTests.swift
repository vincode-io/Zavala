//
//  OPMLImport.swift
//  
//
//  Created by Maurice Parker on 3/16/24.
//

import Foundation
import Testing

final class OPMLImportTests: VOKTestCase {

    @Test func importOPML() async throws {
		let accountManager = buildAccountManager()
		
		let outline = try await loadOutline(accountManager: accountManager)
		#expect(outline.rows.count == 6)
		
		deleteAccountManager(accountManager)
    }

}
