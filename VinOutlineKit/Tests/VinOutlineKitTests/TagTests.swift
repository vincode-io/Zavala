//
//  Created by Maurice Parker on 6/8/24.
//

import Foundation
import Testing
@testable import VinOutlineKit

@MainActor
final class TagTests {

	@Test func parentName() throws {
		let tag = Tag(name: "work/project1/presentation")
		#expect(tag.parentName == "work/project1")
	}

	@Test func normalizeName() {
		let normalizedName = Tag.normalize(name: "/ work / project 1 /")
		#expect(normalizedName == "work/project 1")
	}
	
	@Test func renamePath() {
		let tag = Tag(name: "work/project1/presentation")
		tag.renamePath(from: "work/project1", to: "test")
		#expect(tag.name == "test/presentation")
	}
	
}
