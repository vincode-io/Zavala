//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest
import VinOutlineKit
import VinXML

final class OPMLExport: VOKTestCase {
	
    override func setUpWithError() throws {
		try commonSetup()
    }

    override func tearDownWithError() throws {
		try commonTearDown()
    }

    func testExample() throws {
		guard let outline = AccountManager.shared.localAccount.createOutline(title: "Test Case").outline else {
			XCTFail()
			return
		}
		
		guard let opmlNode = try? VinXML.XMLDocument(xml: outline.opml(), caseSensitive: false)?.root else {
			throw AccountError.opmlParserError
		}
		
		let headNode = opmlNode["head"]?.first
		let bodyNode = opmlNode["body"]?.first
		let rowNodes = bodyNode?["outline"]
		
		var title = headNode?["title"]?.first?.content
		XCTAssertEqual(title, "Test Case")
    }

}
