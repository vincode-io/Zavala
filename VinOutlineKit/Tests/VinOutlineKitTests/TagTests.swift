//
//  Created by Maurice Parker on 6/8/24.
//

import XCTest
@testable import VinOutlineKit

final class TagTests: VOKTestCase {

	func testParentName() throws {
		let tag = Tag(name: "work/project1/presentation")
		XCTAssertEqual(tag.parentName, "work/project1")
	}

	func testNormalizeName() {
		XCTAssertEqual(Tag.normalize(name: "/ work / project 1 /"), "work/project 1")
	}
	
	func testRenamePath() {
		let tag = Tag(name: "work/project1/presentation")
		tag.renamePath(from: "work/project1", to: "test")
		XCTAssertEqual(tag.name, "test/presentation")
	}
	
}
