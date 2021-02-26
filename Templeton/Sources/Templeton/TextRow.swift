//
//  TextRow.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import MarkdownAttributedString

public struct TextRowStrings {
	public var topic: NSAttributedString?
	public var note: NSAttributedString?
	
	public init(topic: NSAttributedString?, note: NSAttributedString?) {
		self.topic = topic
		self.note = note
	}
}

public final class TextRow: BaseRow, Codable {

	public internal(set) var isComplete: Bool

	public var isNoteEmpty: Bool {
		return notePlainText == nil
	}
	
	public var topicPlainText: String? {
		return topic?.markdownRepresentation
	}
	
	public var notePlainText: String? {
		return note?.markdownRepresentation
	}
	
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
			outline?.requestCloudKitUpdate(for: id)
		}
	}
	
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
			outline?.requestCloudKitUpdate(for: id)
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
	
	var topicData: Data? {
		didSet {
			if let topic = topicData {
				_topic = try? NSAttributedString(data: topic,
												 options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
												 documentAttributes: nil)
			} else {
				_topic = nil
			}
		}
	}
	
	var noteData: Data? {
		didSet {
			if let note = noteData {
				_note = try? NSAttributedString(data: note,
												options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
												documentAttributes: nil)
			} else {
				_note = nil
			}
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case topicData = "topicData"
		case noteData = "noteData"
		case isExpanded = "isExpanded"
		case isComplete = "isComplete"
		case rowOrder = "rowOrder"
	}
	
	private var _topic: NSAttributedString?
	private var _note: NSAttributedString?

	public init(document: Document) {
		self.isComplete = false
		super.init()
		self.id = .row(document.id.accountID, document.id.documentUUID, UUID().uuidString)
		self.isExpanded = true
	}

	public init(document: Document, topicPlainText: String, notePlainText: String? = nil) {
		self.isComplete = false
		super.init()
		self.id = .row(document.id.accountID, document.id.documentUUID, UUID().uuidString)
		self.isExpanded = true
		topic = NSAttributedString(markdownRepresentation: topicPlainText, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		if let notePlainText = notePlainText {
			note = NSAttributedString(markdownRepresentation: notePlainText, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		}
	}
	
	internal init(id: EntityID, topicData: Data? = nil, noteData: Data? = nil, isComplete: Bool, isExpanded: Bool, rowOrder: [EntityID]) {
		self.isComplete = false
		super.init()
		self.id = id
		self.topicData = topicData
		self.noteData = noteData
		self.isComplete = isComplete
		self.isExpanded = isExpanded
		self.rowOrder = rowOrder
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let isComplete = try? container.decode(Bool.self, forKey: .isComplete) {
			self.isComplete = isComplete
		} else {
			self.isComplete = false
		}

		super.init()

		id = try container.decode(EntityID.self, forKey: .id)
		topicData = try? container.decode(Data.self, forKey: .topicData)
		noteData = try? container.decode(Data.self, forKey: .noteData)

		if let isExpanded = try? container.decode(Bool.self, forKey: .isExpanded) {
			self.isExpanded = isExpanded
		} else {
			self.isExpanded = true
		}
		
		if let rowOrder = try? container.decode([EntityID].self, forKey: .rowOrder) {
			self.rowOrder = rowOrder
		} else {
			self.rowOrder = [EntityID]()
		}
	}
	
	init(id: EntityID) {
		self.isComplete = false
		super.init()
		self.id = id
		self.isExpanded = true
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(topicData, forKey: .topicData)
		try container.encode(noteData, forKey: .noteData)
		try container.encode(isExpanded, forKey: .isExpanded)
		try container.encode(isComplete, forKey: .isComplete)
		try container.encode(rowOrder, forKey: .rowOrder)
	}
	
	public override func clone(newOutlineID: EntityID) -> Row {
		let id = EntityID.row(newOutlineID.accountID, newOutlineID.documentUUID, UUID().uuidString)
		let result = TextRow(id: id, topicData: topicData, noteData: noteData, isComplete: isComplete, isExpanded: isExpanded, rowOrder: rowOrder)
		return .text(result)
	}
	
	public func complete() {
		isComplete = true
		outline?.requestCloudKitUpdate(for: id)
	}
	
	public func uncomplete() {
		isComplete = false
		outline?.requestCloudKitUpdate(for: id)
	}
	
	public override func markdown(indentLevel: Int = 0) -> String {
		var md = String(repeating: "\t", count: indentLevel)
		md.append("* \(topicPlainText ?? "")")
		
		if let notePlainText = notePlainText {
			md.append("\n  \(notePlainText)")
		}
		
		rows.forEach {
			md.append("\n")
			md.append($0.markdown(indentLevel: indentLevel + 1))
		}
		
		return md
	}
	
	public override func opml(indentLevel: Int = 0) -> String {
		let indent = String(repeating: " ", count: (indentLevel + 1) * 2)
		let escapedText = topicPlainText?.escapingSpecialXMLCharacters ?? ""
		
		var opml = indent + "<outline text=\"\(escapedText)\""
		if let escapedNote = notePlainText?.escapingSpecialXMLCharacters {
			opml.append(" _note=\"\(escapedNote)\"")
		}

		if isComplete {
			opml.append(" _status=\"checked\"")
		}
		
		if rowCount == 0 {
			opml.append("/>\n")
		} else {
			opml.append(">\n")
			rows.forEach { opml.append($0.opml()) }
			opml.append(indent + "</outline>\n")
		}
		
		return opml
	}

}

// MARK: CustomDebugStringConvertible

extension TextRow {
	override public var debugDescription: String {
		return "\(topicPlainText ?? "") (\(id))"
	}
}
