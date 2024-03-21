//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest
@testable import VinOutlineKit
import VinXML

final class OPMLExportTests: VOKTestCase {
	
    func testExport() throws {
		guard let outline = AccountManager.shared.localAccount.createOutline(title: "Test Case").outline else {
			XCTFail()
			return
		}
		
		guard let opmlNode = try? VinXML.XMLDocument(xml: outline.opml(), caseSensitive: false)?.root else {
			throw AccountError.opmlParserError
		}
		
		let headNode = opmlNode["head"]?.first
		
		let title = headNode?["title"]?.first?.content
		XCTAssertEqual(title, "Test Case")
    }

}
