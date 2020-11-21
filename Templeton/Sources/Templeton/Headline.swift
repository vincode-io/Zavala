//
//  Headline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import UIKit

public final class Headline: Identifiable, Equatable, Codable {
	
	public var id: String
	public var parentID: String?
	public var text: Data?
	public var isExpanded: Bool?
	public var headlines: [Headline]? {
		didSet {
			updateHeadlines()
		}
	}

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case parentID = "parentID"
		case text = "text"
		case isExpanded = "isExpanded"
		case headlines = "headlines"
	}

	public init() {
		self.id = UUID().uuidString
		headlines = [Headline]()
	}
	
	public init(plainText: String) {
		self.id = UUID().uuidString
		
		var attributes = [NSAttributedString.Key: AnyObject]()
		attributes[.foregroundColor] = UIColor.label
		attributes[.font] = UIFont.preferredFont(forTextStyle: .body)
		attributedText = NSAttributedString(string: plainText, attributes: attributes)
											
		headlines = [Headline]()
	}
	
	public var plainText: String? {
		return attributedText?.string
	}
	
	public var attributedText: NSAttributedString? {
		get {
			guard let text = text else { return nil }
			return try? NSAttributedString(data: text, options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
		}
		set {
			if let attrText = newValue {
				text = try? attrText.data(from: .init(location: 0, length: attrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			} else {
				text = nil
			}
		}
	}
	
	public static func == (lhs: Headline, rhs: Headline) -> Bool {
		return lhs.id == rhs.id
	}
	
	func visit(visitor: (Headline) -> Void) {
		visitor(self)
		headlines?.forEach { $0.visit(visitor: visitor) }
	}
	
}

// MARK: Helpers

private extension Headline {
	
	func updateHeadlines() {
		headlines?.forEach { headline in
			headline.parentID = self.id
			headline.visit(visitor: { visited in
				visited.headlines?.forEach { $0.parentID = visited.id }
			})
		}
	}
	
}
