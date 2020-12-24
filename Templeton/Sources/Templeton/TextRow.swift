//
//  Headline.swift
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

public final class TextRow: NSObject, NSCopying, RowContainer, Identifiable, Codable {
	
	public weak var parent: RowContainer?
	public var shadowTableIndex: Int?

	public var isAncestorComplete: Bool {
		if let parentHeadline = parent as? TextRow {
			return parentHeadline.isComplete ?? false || parentHeadline.isAncestorComplete
		}
		return false
	}
	
	public var indentLevel: Int {
		var parentCount = 0
		var p = parent as? TextRow
		while p != nil {
			parentCount = parentCount + 1
			p = p?.parent as? TextRow
		}
		return parentCount
	}
	
	public var id: String
	public var topic: Data?
	public var note: Data?
	public var isExpanded: Bool?
	public var isComplete: Bool?
	public var rows: [TextRow]?

	public var isExpandable: Bool {
		guard let rows = rows, !rows.isEmpty else { return false }
		return !(isExpanded ?? true)
	}

	public var isCollapsable: Bool {
		guard let headlines = rows, !headlines.isEmpty else { return false }
		return isExpanded ?? true
	}

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case topic = "topic"
		case note = "note"
		case isExpanded = "isExpanded"
		case isComplete = "isComplete"
		case rows = "rows"
	}
	
	public override init() {
		self.id = UUID().uuidString
		super.init()
		rows = [TextRow]()
	}
	
	public init(plainText: String, notePlainText: String? = nil) {
		self.id = UUID().uuidString
		super.init()

		topicAttributedText = NSAttributedString(markdownRepresentation: plainText, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		if let notePlainText = notePlainText {
			noteAttributedText = NSAttributedString(markdownRepresentation: notePlainText, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		}
											
		rows = [TextRow]()
	}
	
	public var isNoteEmpty: Bool {
		return notePlainText?.isEmpty ?? true
	}
	
	public var topicPlainText: String? {
		return topicAttributedText?.markdownRepresentation
	}
	
	public var notePlainText: String? {
		return noteAttributedText?.markdownRepresentation
	}
	
	private var _topicAttributedText: NSAttributedString?
	public var topicAttributedText: NSAttributedString? {
		get {
			guard let topic = topic else { return nil }
			if _topicAttributedText == nil {
				_topicAttributedText = try? NSAttributedString(data: topic,
															   options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
															   documentAttributes: nil)
			}
			return _topicAttributedText
		}
		set {
			_topicAttributedText = newValue
			if let attrText = newValue {
				topic = try? attrText.data(from: .init(location: 0, length: attrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			} else {
				topic = nil
			}
		}
	}
	
	private var _noteAttributedText: NSAttributedString?
	public var noteAttributedText: NSAttributedString? {
		get {
			guard let note = note else { return nil }
			if _noteAttributedText == nil {
				_noteAttributedText = try? NSAttributedString(data: note,
															  options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
															  documentAttributes: nil)
			}
			return _noteAttributedText
		}
		set {
			_noteAttributedText = newValue
			if let noteAttrText = newValue {
				note = try? noteAttrText.data(from: .init(location: 0, length: noteAttrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			} else {
				note = nil
			}
		}
	}
	
	public var textRowStrings: TextRowStrings {
		get {
			return TextRowStrings(topic: topicAttributedText, note: noteAttributedText)
		}
		set {
			topicAttributedText = newValue.topic
			noteAttributedText = newValue.note
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
	
	public func opml() -> String {
		let indent = String(repeating: " ", count: (indentLevel + 1) * 2)
		let escapedText = topicPlainText?.escapingSpecialXMLCharacters ?? ""
		
		var opml = indent + "<outline text=\"\(escapedText)\""
		if let escapedNote = notePlainText?.escapingSpecialXMLCharacters {
			opml.append(" _note=\"\(escapedNote)\"")
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

	public func isDecendent(_ headline: TextRow) -> Bool {
		if let parentHeadline = parent as? TextRow, parentHeadline == headline || parentHeadline.isDecendent(headline) {
			return true
		}
		return false
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
	
	func visit(visitor: (TextRow) -> Void) {
		visitor(self)
	}
	
}

// MARK: CustomDebugStringConvertible

extension TextRow {
	override public var debugDescription: String {
		return "\(topicPlainText ?? "") (\(id))"
	}
}
