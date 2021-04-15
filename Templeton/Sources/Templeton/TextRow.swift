//
//  TextRow.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import MobileCoreServices
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
		return noteMarkdown == nil
	}
	
	public var topicMarkdown: String? {
		return topic?.markdownRepresentation
	}
	
	public var noteMarkdown: String? {
		return note?.markdownRepresentation
	}
	
	public var topic: NSAttributedString? {
		get {
			guard let topic = topicData else { return nil }
			if topicCache == nil {
				topicCache = try? NSAttributedString(data: topic,
													 options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
													 documentAttributes: nil)
				topicCache = replaceImages(attrString: topicCache, isNotes: false)
			}
			return topicCache
		}
		set {
			if let attrText = newValue {
				let (cleanAttrText, newImages) = splitOffImages(attrString: attrText, isNotes: false)
				
				topicData = try? cleanAttrText.data(from: .init(location: 0, length: cleanAttrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
				
				var topicImages = images?.filter { $0.isInNotes } ?? [Image]()
				topicImages.append(contentsOf: newImages)
				images = topicImages
			} else {
				topicData = nil
				images = images?.filter { $0.isInNotes }
			}
			outline?.requestCloudKitUpdate(for: id)
		}
	}
	
	public var note: NSAttributedString? {
		get {
			guard let note = noteData else { return nil }
			if noteCache == nil {
				noteCache = try? NSAttributedString(data: note,
													options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
													documentAttributes: nil)
				noteCache = replaceImages(attrString: noteCache, isNotes: true)
			}
			return noteCache
		}
		set {
			if let attrText = newValue {
				let (cleanAttrText, newImages) = splitOffImages(attrString: attrText, isNotes: true)
				
				noteData = try? cleanAttrText.data(from: .init(location: 0, length: cleanAttrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])

				var noteImages = images?.filter { !$0.isInNotes } ?? [Image]()
				noteImages.append(contentsOf: newImages)
				images = noteImages
			} else {
				noteData = nil
				images = images?.filter { !$0.isInNotes }
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
	
	public var searchResultCoordinates = NSHashTable<SearchResultCoordinates>.weakObjects()

	var topicData: Data? {
		didSet {
			topicCache = nil
		}
	}
	
	var noteData: Data? {
		didSet {
			noteCache = nil
		}
	}
	
	override var images: [Image]? {
		didSet {
			topicCache = nil
			noteCache = nil
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case syncID = "syncID"
		case topicData = "topicData"
		case noteData = "noteData"
		case isExpanded = "isExpanded"
		case isComplete = "isComplete"
		case rowOrder = "rowOrder"
		case images = "images"
	}
	
	private var topicCache: NSAttributedString?
	private var noteCache: NSAttributedString?

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

		if let images = try? container.decode([Image].self, forKey: .images) {
			self.images = images
		} else {
			self.images = [Image]()
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
		try container.encode(images, forKey: .images)
	}
	
	public override func findImage(id: EntityID) -> Image? {
		return images?.first(where: { $0.id == id })
	}

	public override func saveImage(_ image: Image) {
		if images == nil {
			images = [Image]()
		}

		if !images!.contains(image) {
			images!.append(image)
		}
		
		topicCache = nil
		noteCache = nil
	}

	public override func deleteImage(id: EntityID) {
		images?.removeAll(where: { $0.id == id })
		topicCache = nil
		noteCache = nil
	}

	public func complete() {
		isComplete = true
		outline?.requestCloudKitUpdate(for: id)
	}
	
	public func uncomplete() {
		isComplete = false
		outline?.requestCloudKitUpdate(for: id)
	}

	public override func clone(newOutlineID: EntityID) -> Row {
		let textRow = TextRow(id: EntityID.row(newOutlineID.accountID, newOutlineID.documentUUID, UUID().uuidString))
		textRow.topicData = topicData
		textRow.noteData = noteData
		textRow.isExpanded = isExpanded
		textRow.isComplete = isComplete
		textRow.rowOrder = rowOrder
		textRow.images = images
		return .text(textRow)
	}

	public override func markdownOutline(indentLevel: Int = 0) -> String {
		var md = String(repeating: "\t", count: indentLevel)
		
		if isComplete {
			md.append("* ~~\(topicMarkdown ?? "")~~")
		} else {
			md.append("* \(topicMarkdown ?? "")")
		}
		
		if let notePlainText = noteMarkdown {
			md.append("\n  \(notePlainText)")
		}
		
		rows.forEach {
			md.append("\n")
			md.append($0.markdownOutline(indentLevel: indentLevel + 1))
		}
		
		return md
	}
	
	public override func markdownPost(indentLevel: Int = 0) -> String {
		var md = String(repeating: "#", count: indentLevel + 2)
		md.append(" \(topicMarkdown ?? "")")
		
		if let notePlainText = noteMarkdown {
			md.append("\n\n\(notePlainText)")
		}
		
		rows.forEach {
			md.append("\n\n")
			md.append($0.markdownPost(indentLevel: indentLevel + 1))
		}
		
		return md
	}
	
}

// MARK: CustomDebugStringConvertible

extension TextRow {
	override public var debugDescription: String {
		return "\(topic?.string ?? "") (\(id))"
	}
}

// MARK: Helpers

extension TextRow {
	
	func replaceImages(attrString: NSAttributedString?, isNotes: Bool) -> NSAttributedString? {
		guard let attrString = attrString else { return nil }
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		for image in images ?? [Image]() {
			if image.isInNotes == isNotes {
				let attachment = OutlineTextAttachment(data: image.data, ofType: kUTTypePNG as String)
				let imageAttrText = NSAttributedString(attachment: attachment)
				mutableAttrString.insert(imageAttrText, at: image.offset)
			}
		}
		
		return mutableAttrString
	}
	
	func splitOffImages(attrString: NSAttributedString, isNotes: Bool) -> (NSAttributedString, [Image]) {
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		var images = [Image]()
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			if let pngData = (attribute as? NSTextAttachment)?.image?.pngData() {
				let entityID = EntityID.image(id.accountID, id.documentUUID, id.rowUUID, UUID().uuidString)
				let image = Image(id: entityID, isInNotes: isNotes, offset: range.location, data: pngData)
				images.append(image)
			}
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		return (mutableAttrString, images)
	}
	
}
