//
//  Created by Maurice Parker on 6/25/24.
//

struct DocumentCoder: Codable {
	
	let outline: OutlineCoder

	private enum CodingKeys: String, CodingKey {
		case type
		case outline
	}
	
	init(outline: OutlineCoder) {
		self.outline = outline
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		
		switch type {
		case "outline":
			outline = try container.decode(OutlineCoder.self, forKey: .outline)
		default:
			fatalError()
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode("outline", forKey: .type)
		try container.encode(outline, forKey: .outline)
	}
	

}
