//
//  Created by Maurice Parker on 6/27/24.
//

import Foundation

struct ImageCoder: Codable {

	public let cloudKitMetaData: Data?
	public let id: EntityID
	public let ancestorIsInNotes: Bool?
	public let isInNotes: Bool?
	public let ancestorOffset: Int?
	public let offset: Int?
	public let ancestorData: Data?
	public let data: Data?

	private enum CodingKeys: String, CodingKey {
		case cloudKitMetaData
		case id
		case ancestorIsInNotes
		case isInNotes
		case ancestorOffset
		case offset
		case ancestorData
		case data
	}
	
}
