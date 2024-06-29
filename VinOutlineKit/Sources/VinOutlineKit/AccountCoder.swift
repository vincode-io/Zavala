//
//  Created by Maurice Parker on 6/25/24.
//

import Foundation
import VinCloudKit

struct AccountCoder: Codable {
	
	public let type: AccountType
	public let isActive: Bool
	public let tags: [TagCoder]?
	public let documents: [DocumentCoder]?
	public let sharedDatabaseChangeToken: Data?
	public let zoneChangeTokens: [VCKChangeTokenKey: Data]?
	
	enum CodingKeys: String, CodingKey {
		case type = "type"
		case isActive = "isActive"
		case tags = "tags"
		case documents = "documents"
		case sharedDatabaseChangeToken = "sharedDatabaseChangeToken"
		case zoneChangeTokens = "zoneChangeTokens"
	}

}
