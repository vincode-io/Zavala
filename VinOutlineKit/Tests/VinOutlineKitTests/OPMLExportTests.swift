//
//  Created by Maurice Parker on 3/16/24.
//

import Foundation
import Testing
@testable import VinOutlineKit
import VinXML

final class OPMLExportTests: VOKTestCase {
	
    @Test func exportOPML() throws {
		let accountManager = buildAccountManager()
		
		let document = accountManager.localAccount?.createOutline(title: "Test Case")
		let outline = try #require(document?.outline)
		
		guard let opmlNode = try? VinXML.XMLDocument(xml: outline.opml(), caseSensitive: false)?.root else {
			throw AccountError.opmlParserError
		}
		
		let headNode = opmlNode["head"]?.first
		
		let title = headNode?["title"]?.first?.content
		#expect(title == "Test Case")
		
		deleteAccountManager(accountManager)
    }

}
