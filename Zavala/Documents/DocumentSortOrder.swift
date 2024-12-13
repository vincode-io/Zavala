//
//  Created by Maurice Parker on 12/11/24.
//

struct DocumentSortOrder: Codable {
	
	static let `default` = DocumentSortOrder(field: .title, ordered: .ascending)
	
	enum Field: String, Codable {
		case title
		case created
		case updated
	}
	
	enum Ordered: String, Codable {
		case ascending
		case descending
	}
	
	var field: Field
	var ordered: Ordered

	var userInfo: [AnyHashable: AnyHashable] {
		var userInfo = [AnyHashable: AnyHashable]()
		userInfo["field"] = field.rawValue
		userInfo["ordered"] = ordered.rawValue
		return userInfo
	}
	
	init(field: Field, ordered: Ordered) {
		self.field = field
		self.ordered = ordered
	}
	
	init(userInfo: [AnyHashable: AnyHashable]) {
		self.field = Field(rawValue: userInfo["field"] as? String ?? "") ?? .title
		self.ordered = Ordered(rawValue: userInfo["ordered"] as? String ?? "") ?? .ascending
	}
	
}
