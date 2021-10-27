//
//  TextRow.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import MobileCoreServices
import MarkdownAttributedString

public enum TextRowStrings {
	case topic(NSAttributedString?)
	case note(NSAttributedString?)
	case both(NSAttributedString?, NSAttributedString?)
}

enum TextRowError: LocalizedError {
	case unableToDeserialize
	var errorDescription: String? {
		return NSLocalizedString("Unable to deserialize the row data.", comment: "An unexpected CloudKit error occurred.")
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
				
				var notesImages = images?.filter { $0.isInNotes } ?? [Image]()
				notesImages.append(contentsOf: newImages)

				if let images = images {
					outline?.requestCloudKitUpdates(for: images.filter({ !$0.isInNotes }).map({ $0.id }))
				}
				outline?.requestCloudKitUpdates(for: newImages.map({ $0.id }))

				images = notesImages
			} else {
				topicData = nil
				images = images?.filter { $0.isInNotes }
			}
			outline?.requestCloudKitUpdate(for: entityID)
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

				var topicImages = images?.filter { !$0.isInNotes } ?? [Image]()
				topicImages.append(contentsOf: newImages)
				
				if let images = images {
					outline?.requestCloudKitUpdates(for: images.filter({ $0.isInNotes }).map({ $0.id }))
				}
				outline?.requestCloudKitUpdates(for: newImages.map({ $0.id }))

				images = topicImages
			} else {
				noteData = nil
				images = images?.filter { !$0.isInNotes }
			}
			outline?.requestCloudKitUpdate(for: entityID)
		}
	}
	
	public var textRowStrings: TextRowStrings {
		get {
			return TextRowStrings.both(topic, note)
		}
		set {
			switch newValue {
			case .topic(let topic):
				self.topic = topic
			case .note(let note):
				self.note = note
			case .both(let topic, let note):
				self.topic = topic
				self.note = note
			}
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
		get {
			return outline?.findImages(rowID: id)
		}
		set {
			outline?.updateImages(rowID: id, images: newValue)
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
	}
	
	private var topicCache: NSAttributedString?
	private var noteCache: NSAttributedString?

	public init(outline: Outline) {
		self.isComplete = false
		super.init()
		self.outline = outline
		self.id = UUID().uuidString
		self.isExpanded = true
	}

	public init(outline: Outline, topicPlainText: String, notePlainText: String? = nil) {
		self.isComplete = false
		super.init()
		self.outline = outline
		self.id = UUID().uuidString
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

		if let id = try? container.decode(String.self, forKey: .id) {
			self.id = id
		} else if let id = try? container.decode(EntityID.self, forKey: .id) {
			self.id = id.rowUUID
		} else {
			throw TextRowError.unableToDeserialize
		}
		
		topicData = try? container.decode(Data.self, forKey: .topicData)
		noteData = try? container.decode(Data.self, forKey: .noteData)

		if let isExpanded = try? container.decode(Bool.self, forKey: .isExpanded) {
			self.isExpanded = isExpanded
		} else {
			self.isExpanded = true
		}
		
		if let rowOrder = try? container.decode([String].self, forKey: .rowOrder) {
			self.rowOrder = rowOrder
		} else if let rowOrder = try? container.decode([EntityID].self, forKey: .rowOrder) {
			self.rowOrder = rowOrder.map { $0.rowUUID }
		} else {
			throw TextRowError.unableToDeserialize
		}
	}
	
	init(id: String) {
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
	
	public func duplicate(newOutline: Outline) -> TextRow {
		let textRow = TextRow(outline: newOutline)

		textRow.topicData = topicData
		textRow.noteData = noteData
		textRow.isExpanded = isExpanded
		textRow.isComplete = isComplete
		textRow.rowOrder = rowOrder
		textRow.images = images?.map { $0.duplicate(accountID: newOutline.id.accountID, documentUUID: newOutline.id.documentUUID, rowUUID: textRow.id) }
		
		return textRow
	}
	
	public override func findImage(id: EntityID) -> Image? {
		return images?.first(where: { $0.id == id })
	}

	public override func saveImage(_ image: Image) {
		var foundImages = images
		
		if foundImages == nil {
			images = [image]
		} else {
			if !foundImages!.contains(image) {
				foundImages!.append(image)
				images = foundImages
			}
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
		outline?.requestCloudKitUpdate(for: entityID)
	}
	
	public func uncomplete() {
		isComplete = false
		outline?.requestCloudKitUpdate(for: entityID)
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
	
	private func replaceImages(attrString: NSAttributedString?, isNotes: Bool) -> NSAttributedString? {
		guard let attrString = attrString else { return nil }
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		for image in images?.sorted(by: { $0.offset < $1.offset }) ?? [Image]() {
			if image.isInNotes == isNotes {
				let attachment = OutlineTextAttachment(data: image.data, ofType: kUTTypePNG as String)
				let imageAttrText = NSAttributedString(attachment: attachment)
				mutableAttrString.insert(imageAttrText, at: image.offset)
			}
		}
		
		return mutableAttrString
	}
	
	private func splitOffImages(attrString: NSAttributedString, isNotes: Bool) -> (NSAttributedString, [Image]) {
		guard let outline = outline else {
			fatalError("Missing Outline")
		}
		
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		var images = [Image]()
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			if let pngData = (attribute as? NSTextAttachment)?.image?.pngData() {
				let entityID = EntityID.image(outline.id.accountID, outline.id.documentUUID, id, UUID().uuidString)
				let image = Image(id: entityID, isInNotes: isNotes, offset: range.location, data: pngData)
				images.append(image)
			}
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		return (mutableAttrString, images)
	}
	
}
