//
//  TextRow.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import UIKit
import MarkdownAttributedString

public struct TextRowStrings {
	public var topic: NSAttributedString?
	public var note: NSAttributedString?
	
	public init(topic: NSAttributedString?, note: NSAttributedString?) {
		self.topic = topic
		self.note = note
	}
}

public final class TextRow: NSObject, NSCopying, OPMLImporter, Identifiable, Codable {
	
	public var parent: RowContainer?
	public var shadowTableIndex: Int?

	public var id: String
	public var isExpanded: Bool?
	public var isComplete: Bool?
	public var rows: [Row]?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case topicData = "topicData"
		case noteData = "noteData"
		case isExpanded = "isExpanded"
		case isComplete = "isComplete"
		case rows = "rows"
	}
	
	private var topicData: Data?
	private var noteData: Data?

	public override init() {
		self.id = UUID().uuidString
		super.init()
		rows = [Row]()
	}
	
	public init(topicPlainText: String, notePlainText: String? = nil) {
		self.id = UUID().uuidString
		super.init()

		topic = NSAttributedString(markdownRepresentation: topicPlainText, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		if let notePlainText = notePlainText {
			note = NSAttributedString(markdownRepresentation: notePlainText, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		}
											
		rows = [Row]()
	}
	
	public var isNoteEmpty: Bool {
		return notePlainText?.isEmpty ?? true
	}
	
	public var topicPlainText: String? {
		return topic?.markdownRepresentation
	}
	
	public var notePlainText: String? {
		return note?.markdownRepresentation
	}
	
	private var _topic: NSAttributedString?
	public var topic: NSAttributedString? {
		get {
			guard let topic = topicData else { return nil }
			if _topic == nil {
				_topic = try? NSAttributedString(data: topic,
												 options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
												 documentAttributes: nil)
			}
			return _topic
		}
		set {
			_topic = newValue
			if let attrText = newValue {
				topicData = try? attrText.data(from: .init(location: 0, length: attrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			} else {
				topicData = nil
			}
		}
	}
	
	private var _note: NSAttributedString?
	public var note: NSAttributedString? {
		get {
			guard let note = noteData else { return nil }
			if _note == nil {
				_note = try? NSAttributedString(data: note,
												options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
												documentAttributes: nil)
			}
			return _note
		}
		set {
			_note = newValue
			if let noteAttrText = newValue {
				noteData = try? noteAttrText.data(from: .init(location: 0, length: noteAttrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			} else {
				noteData = nil
			}
		}
	}
	
	public var textRowStrings: TextRowStrings {
		get {
			return TextRowStrings(topic: topic, note: note)
		}
		set {
			topic = newValue.topic
			note = newValue.note
		}
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		var md = String(repeating: "\t", count: indentLevel)
		md.append("* \(topicPlainText ?? "")\n")
		
		if let notePlainText = notePlainText {
			md.append("  \(notePlainText)\n")
		}
		
		rows?.forEach { md.append($0.markdown(indentLevel: indentLevel + 1)) }
		
		return md
	}
	
	public func opml(indentLevel: Int = 0) -> String {
		let indent = String(repeating: " ", count: (indentLevel + 1) * 2)
		let escapedText = topicPlainText?.escapingSpecialXMLCharacters ?? ""
		
		var opml = indent + "<outline text=\"\(escapedText)\""
		if let escapedNote = notePlainText?.escapingSpecialXMLCharacters {
			opml.append(" _note=\"\(escapedNote)\"")
		}

		if isComplete ?? false {
			opml.append(" _status=\"checked\"")
		}
		
		if rows?.count ?? 0 == 0 {
			opml.append("/>\n")
		} else {
			opml.append(">\n")
			rows?.forEach { opml.append($0.opml()) }
			opml.append(indent + "</outline>\n")
		}
		
		return opml
	}

	public override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? TextRow else { return false }
		if self === other { return true }
		return id == other.id
	}
	
	public override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		return hasher.finalize()
	}
	
	public func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}

// MARK: CustomDebugStringConvertible

extension TextRow {
	override public var debugDescription: String {
		return "\(topicPlainText ?? "") (\(id))"
	}
}
