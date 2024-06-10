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

}
