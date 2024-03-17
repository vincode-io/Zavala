//
//  OPMLImport.swift
//  
//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest

final class OPMLImport: VOKTestCase {

	override func setUpWithError() throws {
		try commonSetup()
	}

	override func tearDownWithError() throws {
		try commonTearDown()
	}

    func testImport() throws {
		let outline = try loadOutline()
		XCTAssertEqual(outline.rows.count, 6)
    }

}
