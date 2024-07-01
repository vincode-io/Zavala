//
//  Row.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation
import UniformTypeIdentifiers
import MarkdownAttributedString
import OrderedCollections

public enum RowStrings {
	case topicMarkdown(String?)
	case noteMarkdown(String?)
	case topic(NSAttributedString?)
	case note(NSAttributedString?)
	case both(NSAttributedString?, NSAttributedString?)
}

public struct AltLinkResolvingActions: OptionSet, Sendable {
	
	public static let fixedAltLink = AltLinkResolvingActions(rawValue: 1)
	public static let foundAltLink = AltLinkResolvingActions(rawValue: 2)
	
	public let rawValue: Int
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
}

public final class Row: NSObject, NSCopying, RowContainer, Identifiable {
	
	public static let typeIdentifier = "io.vincode.Zavala.Row"
	
	public var parent: RowContainer?
	public var shadowTableIndex: Int?
	
	public var isCloudKit: Bool {
		return outline?.isCloudKit ?? false
	}
	
	public var cloudKitMetaData: Data? {
		didSet {
			outline?.rowsFile?.markAsDirty()
		}
	}
	
	public var isCloudKitMerging: Bool = false
	
	public let id: String
	
	public var isExpanded: Bool
	public internal(set) var rows: [Row] {
		get {
			guard let outline = self.outline else { return [Row]() }
			return rowOrder.compactMap { outline.keyedRows?[$0] }
		}
		set {
			guard let outline = self.outline else { return }
			
			outline.beginCloudKitBatchRequest()
			outline.requestCloudKitUpdate(for: entityID)
			
			for id in rowOrder {
				outline.keyedRows?.removeValue(forKey: id)
				outline.requestCloudKitUpdate(for: entityID)
			}
			
			var order = OrderedSet<String>()
			for row in newValue {
				order.append(row.id)
				outline.keyedRows?[row.id] = row
				outline.requestCloudKitUpdate(for: row.entityID)
			}
			rowOrder = order
			
			outline.endCloudKitBatchRequest()
		}
	}
	
	public var rowCount: Int {
		return rowOrder.count
	}
	
	public var isAnyParentComplete: Bool {
		if let parentRow = parent as? Row {
			return parentRow.isComplete ?? false || parentRow.isAnyParentComplete
		}
		return false
	}
	
	public weak var outline: Outline? {
		didSet {
			if let outline {
				_entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
			}
		}
	}
	
	public var entityID: EntityID {
		guard let entityID = _entityID else {
			fatalError("Missing EntityID for row")
		}
		return entityID
	}
	
	var ancestorRowOrder: OrderedSet<String>?
	var serverRowOrder: OrderedSet<String>?
	var rowOrder: OrderedSet<String>
	
	var isPartOfSearchResult = false {
		didSet {
			guard isPartOfSearchResult else { return }
			
			var parentRow = parent as? Row
			while (parentRow != nil) {
				parentRow!.isPartOfSearchResult = true
				parentRow = parentRow?.parent as? Row
			}
		}
	}
	
	private var _entityID: EntityID?
	
	public var trueLevel: Int {
		var parentCount = 0
		var parentRow = parent as? Row
		
		while parentRow != nil {
			parentCount = parentCount + 1
			parentRow = parentRow?.parent as? Row
		}
		
		return parentCount
	}
	
	public var currentLevel: Int {
		guard self != outline?.focusRow else {
			return 0
		}
		
		var parentCount = outline?.focusRow == nil ? 0 : 1
		var parentRow = parent as? Row
		
		while parentRow != nil && parentRow != outline?.focusRow {
			parentCount = parentCount + 1
			parentRow = parentRow?.parent as? Row
		}
		
		return parentCount
	}
	
	public var isExpandable: Bool {
		guard rowCount > 0 else { return false }
		return !isExpanded
	}
	
	public var isCollapsable: Bool {
		guard rowCount > 0 else { return false }
		return isExpanded
	}
	
	public var isCompletable: Bool {
		return !isUncompletable
	}
	
	public var isAutoCompletable: Bool {
		guard isCompletable else { return false }
		
		var foundOneChildCompleted = false
		var foundOneChildUncompleted = false
		
		for child in rows {
			if child.isUncompletable {
				foundOneChildCompleted = true
			}
			if child.isCompletable {
				foundOneChildUncompleted = true
			}
			if foundOneChildCompleted && foundOneChildUncompleted {
				return false
			}
		}
		
		return foundOneChildCompleted
	}
	
	public var isUncompletable: Bool {
		return isComplete ?? false
	}
	
	public var isAutoUncompletable: Bool {
		guard isUncompletable else { return false }
		
		for child in rows {
			if child.isCompletable {
				return true
			}
		}
		
		return false
	}
	
	var ancestorIsComplete: Bool?
	var serverIsComplete: Bool?
	public internal(set) var isComplete: Bool? {
		willSet {
			if isCloudKit && ancestorIsComplete == nil {
				ancestorIsComplete = isComplete
			}
		}
	}
	
	public var isNoteEmpty: Bool {
		return note == nil
	}
	
	public var topic: NSAttributedString? {
		get {
			guard let topic = topicData else { return nil }
			if topicCache == nil {
				topicCache = topic.toAttributedString()
				topicCache = replaceImages(attrString: topicCache, isNotes: false)
			}
			return topicCache
		}
		set {
			if let attrText = newValue {
				let (cleanAttrText, newImages) = splitOffImages(attrString: attrText, isNotes: false)
				topicData = cleanAttrText.toData()
				
				var notesImages = images?.filter { $0.isInNotes ?? false } ?? [Image]()
				notesImages.append(contentsOf: newImages)
				
				if let images {
					outline?.requestCloudKitUpdates(for: images.filter({ !($0.isInNotes ?? false) }).map({ $0.id }))
				}
				outline?.requestCloudKitUpdates(for: newImages.map({ $0.id }))
				
				images = notesImages
			} else {
				topicData = nil
				images = images?.filter { $0.isInNotes ?? false }
			}
			outline?.requestCloudKitUpdate(for: entityID)
		}
	}
	
	public var note: NSAttributedString? {
		get {
			guard let note = noteData else { return nil }
			if noteCache == nil {
				noteCache = note.toAttributedString()
				noteCache = replaceImages(attrString: noteCache, isNotes: true)
			}
			return noteCache
		}
		set {
			if let attrText = newValue {
				let (cleanAttrText, newImages) = splitOffImages(attrString: attrText, isNotes: true)
				noteData = cleanAttrText.toData()
				
				var topicImages = images?.filter { !($0.isInNotes ?? false) } ?? [Image]()
				topicImages.append(contentsOf: newImages)
				
				if let images {
					outline?.requestCloudKitUpdates(for: images.filter({ $0.isInNotes ?? false }).map({ $0.id }))
				}
				outline?.requestCloudKitUpdates(for: newImages.map({ $0.id }))
				
				images = topicImages
			} else {
				noteData = nil
				images = images?.filter { !($0.isInNotes ?? false) }
			}
			outline?.requestCloudKitUpdate(for: entityID)
		}
	}
	
	public var rowStrings: RowStrings {
		get {
			return RowStrings.both(topic, note)
		}
		set {
			switch newValue {
			case .topicMarkdown(let topicMarkdown):
				self.topic = convertMarkdown(topicMarkdown, isInNotes: false)
			case .noteMarkdown(let noteMarkdown):
				self.note = convertMarkdown(noteMarkdown, isInNotes: true)
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
	
	var ancestorTopicData: Data?
	var serverTopicData: Data?
	var topicData: Data? {
		willSet {
			if isCloudKit && ancestorTopicData == nil {
				ancestorTopicData = topicData
			}
		}
		didSet {
			topicCache = nil
		}
	}
	
	var ancestorNoteData: Data?
	var serverNoteData: Data?
	var noteData: Data? {
		willSet {
			if isCloudKit && ancestorNoteData == nil {
				ancestorNoteData = noteData
			}
		}
		didSet {
			noteCache = nil
		}
	}
	
	var images: [Image]? {
		get {
			return outline?.findImages(rowID: id)
		}
		set {
			outline?.updateImages(rowID: id, images: newValue)
			topicCache = nil
			noteCache = nil
		}
	}
	
	private static let markdownImagePattern = "!\\]\\]\\(([^)]+).png\\)"
	
	private var topicCache: NSAttributedString?
	private var noteCache: NSAttributedString?
	
	public init(outline: Outline) {
		self.isComplete = false
		self.id = UUID().uuidString
		self.outline = outline
		self._entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
		self.isExpanded = true
		self.rowOrder = OrderedSet<String>()
		super.init()
	}
	
	init(outline: Outline, id: String) {
		self.outline = outline
		self.id = id
		self.isExpanded = true
		self.rowOrder = OrderedSet<String>()
		super.init()
	}
	
	
	public init(outline: Outline, topicMarkdown: String?, noteMarkdown: String? = nil) {
		self.isComplete = false
		self.id = UUID().uuidString
		self.outline = outline
		self._entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
		self.isExpanded = true
		self.rowOrder = OrderedSet<String>()
		super.init()
		self.topic = convertMarkdown(topicMarkdown, isInNotes: false)
		self.note = convertMarkdown(noteMarkdown, isInNotes: true)
	}
	
	public override init() {
		self.isComplete = false
		self.id = UUID().uuidString
		self.isExpanded = true
		self.rowOrder = OrderedSet<String>()
		super.init()
	}
	
	init(coder: RowCoder) {
		self.cloudKitMetaData = coder.cloudKitMetaData
		self.id = coder.id
		self.ancestorTopicData = coder.ancestorTopicData
		self.topicData = coder.topicData
		self.ancestorNoteData = coder.ancestorNoteData
		self.noteData = coder.noteData
		self.isExpanded = coder.isExpanded
		self.ancestorIsComplete = coder.ancestorIsComplete
		self.isComplete = coder.isComplete
		self.ancestorRowOrder = coder.ancestorRowOrder
		self.rowOrder = coder.rowOrder
	}
	
	public func topicMarkdown(representation: DataRepresentation, useAltLinks: Bool = false) -> String? {
		return convertAttrString(topic, isInNotes: false, representation: representation, useAltLinks: useAltLinks)
	}
	
	public func noteMarkdown(representation: DataRepresentation, useAltLinks: Bool = false) -> String? {
		return convertAttrString(note, isInNotes: true, representation: representation, useAltLinks: useAltLinks)
	}
	
	public func duplicate(newOutline: Outline) -> Row {
		let row = Row(outline: newOutline)
		
		row.topicData = topicData
		row.noteData = noteData
		row.isExpanded = isExpanded
		row.isComplete = isComplete
		row.rowOrder = rowOrder
		row.images = images?.map { $0.duplicate(outline: newOutline, accountID: newOutline.id.accountID, documentUUID: newOutline.id.documentUUID, rowUUID: row.id) }

		return row
	}
	
	public func importRow(topicMarkdown: String?, noteMarkdown: String?, images: [String: Data]?) {
		guard let regEx = try? NSRegularExpression(pattern: Self.markdownImagePattern, options: []) else {
			return
		}
		
		var matchedImages = [Image]()
		
		func importMarkdown(_ markdown: String?, isInNotes: Bool) -> NSAttributedString? {
			
#if canImport(UIKit)
			if let markdown {
				let mangledMarkdown = markdown.replacingOccurrences(of: "![", with: "!]")
				let attrString = NSMutableAttributedString(markdownRepresentation: mangledMarkdown, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
				let strippedString = attrString.string
				let matches = regEx.allMatches(in: strippedString)
				
				for match in matches {
					guard let wholeRange = Range(match.range(at: 0), in: strippedString), let captureRange = Range(match.range(at: 1), in: strippedString) else {
						continue
					}
					
					let currentString = attrString.string
					let wholeString = strippedString[wholeRange]
					guard let wholeStringRange = currentString.range(of: wholeString) else {
						continue
					}
					
					let offset = currentString[currentString.startIndex..<wholeStringRange.lowerBound].utf16.count
					attrString.replaceCharacters(in: NSRange(location: offset, length: wholeString.utf16.count), with: "")
					
					let imageUUID = String(strippedString[captureRange])
					if let data = images?[imageUUID] {
						let imageID = EntityID.image(entityID.accountID, entityID.documentUUID, entityID.rowUUID, imageUUID)
						matchedImages.append(Image(outline: outline!, id: imageID, isInNotes: isInNotes, offset: offset, data: data))
					}
				}
				
				resolveAltLinks(attrString: attrString)
				
				return attrString
			}
#endif
			
			return nil
		}
		
		self.topic = importMarkdown(topicMarkdown, isInNotes: false)
		self.note = importMarkdown(noteMarkdown, isInNotes: true)
		
		detectData()
		
		outline?.updateImages(rowID: id, images: matchedImages)
	}
	
	public func findImage(id: EntityID) -> Image? {
		return images?.first(where: { $0.id == id })
	}
	
	public func saveImage(_ image: Image) {
		var foundImages = images
		
		if foundImages == nil {
			images = [image]
		} else {
			if let index = foundImages!.firstIndex(where: { $0.id == image.id }) {
				foundImages!.remove(at: index)
			}
			foundImages!.append(image)
			images = foundImages
		}
		
		topicCache = nil
		noteCache = nil
	}
	
	public func deleteImage(id: EntityID) {
		images?.removeAll(where: { $0.id == id })
		topicCache = nil
		noteCache = nil
	}
	
	public func complete() {
		guard isCompletable else { return }
		isComplete = true
		outline?.requestCloudKitUpdate(for: entityID)
	}
	
	public func uncomplete() {
		guard isUncompletable else { return }
		isComplete = false
		outline?.requestCloudKitUpdate(for: entityID)
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rowOrder.firstIndex(of: row.id)
	}
	
	public func containsRow(_ row: Row) -> Bool {
		return rowOrder.contains(row.id)
	}
	
	public func insertRow(_ row: Row, at: Int) {
		if isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}
		
		rowOrder.insert(row.id, at: at)
		outline?.keyedRows?[row.id] = row
		
		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}
	
	public func removeRow(_ row: Row) {
		if isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}
		
		rowOrder.remove(row.id)
		outline?.keyedRows?.removeValue(forKey: row.id)
		
		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}
	
	public func appendRow(_ row: Row) {
		if isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}
		
		rowOrder.append(row.id)
		outline?.keyedRows?[row.id] = row
		
		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}
	
	public func isDecendent(_ row: Row) -> Bool {
		if let parentRow = parent as? Row, parentRow.id == row.id || parentRow.isDecendent(row) {
			return true
		}
		return false
	}
	
	/// Returns itself or the first ancestor that shares a parent with the given row
	public func ancestorSibling(_ row: Row) -> Row? {
		guard let parent else { return nil }
		
		if parent.containsRow(row) || containsRow(row) {
			return self
		}
		
		if let parentRow = parent as? Row {
			return parentRow.ancestorSibling(row)
		}
		
		return nil
	}
	
	public func hasSameParent(_ row: Row) -> Bool {
		if let parentOutline = parent as? Outline, let rowOutline = row.parent as? Outline {
			return parentOutline.id == rowOutline.id
		}
		if let parentRow = parent as? Row, let rowRow = row.parent as? Row {
			return parentRow.id == rowRow.id
		}
		return false
	}
	
	public func markdownList() -> String {
		let visitor = MarkdownListVisitor(useAltLinks: false)
		visit(visitor: visitor.visitor)
		return visitor.markdown
	}
	
	public func resolveAltLinks() -> AltLinkResolvingActions {
		var actionsTaken = AltLinkResolvingActions()
		
		if let topic {
			let mutableTopic = NSMutableAttributedString(attributedString: topic)
			actionsTaken.formUnion(resolveAltLinks(attrString: mutableTopic))
			self.topic = mutableTopic
		}
		
		if let note {
			let mutableNote = NSMutableAttributedString(attributedString: note)
			actionsTaken.formUnion(resolveAltLinks(attrString: mutableNote))
			self.note = mutableNote
		}
		
		return actionsTaken
	}
	
	public func detectData() {
		if let topic = self.topic {
			let mutableTopic = NSMutableAttributedString(attributedString: topic)
			mutableTopic.detectData()
			self.topic = mutableTopic
		}
		
		if let note = self.note {
			let mutableNote = NSMutableAttributedString(attributedString: note)
			mutableNote.detectData()
			self.note = mutableNote
		}
	}
	
	public func clearSearchResults() {
		isPartOfSearchResult = false
		searchResultCoordinates = NSHashTable<SearchResultCoordinates>.weakObjects()
	}
	
	public func visit(visitor: (Row) -> Void) {
		visitor(self)
	}
	
	public override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? Self else { return false }
		if self === other { return true }
		return id == other.id
	}
	
	public override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		return hasher.finalize()
	}
	
	nonisolated public func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
	func toCoder() -> RowCoder {
		return RowCoder(cloudKitMetaData: cloudKitMetaData, 
						id: id,
						ancestorTopicData: ancestorTopicData,
						topicData: topicData,
						ancestorNoteData: ancestorNoteData,
						noteData: noteData,
						isExpanded: isExpanded,
						ancestorIsComplete: ancestorIsComplete,
						isComplete: isComplete,
						ancestorRowOrder: ancestorRowOrder,
						rowOrder: rowOrder)
	}
	
}

// MARK: CustomDebugStringConvertible

extension Row {
	override public var debugDescription: String {
		return "\(topic?.string ?? "") (\(id))"
	}
}

// MARK: Helpers

private extension Row {
	
	func replaceImages(attrString: NSAttributedString?, isNotes: Bool) -> NSAttributedString? {
		guard let attrString else { return nil }
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		for image in images?.sorted(by: { $0.offset ?? 0 < $1.offset ?? 0 }) ?? [Image]() {
			if image.isInNotes == isNotes {
				insertImageAttachment(attrString: mutableAttrString, image: image, offset: image.offset ?? 0)
			}
		}
		
//		let attachment = MetadataTextAttachment(data: nil, ofType: DataRepresentation.opml.typeIdentifier)
//		attachment.configure(key: "Due", value: "12/25/2021", level: level)
//		let metaAttrText = NSAttributedString(attachment: attachment)
//		mutableAttrString.insert(metaAttrText, at: mutableAttrString.length)
		
		return mutableAttrString
	}
	
	func splitOffImages(attrString: NSAttributedString, isNotes: Bool) -> (NSMutableAttributedString, [Image]) {
		guard let outline else {
			fatalError("Missing Outline")
		}
		
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		var images = [Image]()
		
		#if canImport(UIKit)
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (value, range, _) in
			if let imageTextAttachment = value as? ImageTextAttachment, let imageUUID = imageTextAttachment.imageUUID, let pngData = imageTextAttachment.image?.pngData() {
				let entityID = EntityID.image(outline.id.accountID, outline.id.documentUUID, id, imageUUID)
				
				if let image = findImage(id: entityID) {
					image.offset = range.location
					images.append(image)
				} else {
					let image = Image(outline: outline, id: entityID, isInNotes: isNotes, offset: range.location, data: pngData)
					images.append(image)
				}
			}
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		#endif
		
		return (mutableAttrString, images)
	}
	
	func convertAttrString(_ attrString: NSAttributedString?, isInNotes: Bool, representation: DataRepresentation, useAltLinks: Bool) -> String? {
		guard let attrString else { return nil	}

		let result = NSMutableAttributedString(attributedString: attrString)
		
		if useAltLinks {
			result.enumerateAttribute(.link, in: .init(location: 0, length: result.length), options: []) { (value, range, _) in
				guard let url = value as? URL,
					  let entityID = EntityID(url: url),
					  let document = AccountManager.shared.findDocument(entityID),
					  let newURL = URL(string: document.filename(representation: representation)) else { return }
				
				result.removeAttribute(.link, range: range)
				result.addAttribute(.link, value: newURL, range: range)
			}
		}

		if let images = images?.filter({ $0.isInNotes == isInNotes }), !images.isEmpty {
			let sortedImages = images.sorted(by: { $0.offset ?? 0 > $1.offset ?? 0 })
			for image in sortedImages {
				let markdown = NSAttributedString(string: "![](\(image.id.imageUUID).png)")
				result.insert(markdown, at: image.offset ?? 0)
			}
		}

		return result.markdownRepresentation
	}
	
	func convertMarkdown(_ markdown: String?, isInNotes: Bool) -> NSAttributedString? {
		guard let markdown, let regEx = try? NSRegularExpression(pattern: Self.markdownImagePattern, options: []) else {
			return nil
		}

		#if canImport(UIKit)
		let mangledMarkdown = markdown.replacingOccurrences(of: "![", with: "!]")
		let result = NSMutableAttributedString(markdownRepresentation: mangledMarkdown, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		let strippedString = result.string
		let matches = regEx.allMatches(in: strippedString)
		
		for match in matches {
			guard let wholeRange = Range(match.range(at: 0), in: strippedString), let captureRange = Range(match.range(at: 1), in: strippedString) else {
				continue
			}
			
			let currentString = result.string
			let wholeString = strippedString[wholeRange]
			guard let wholeStringRange = currentString.range(of: wholeString) else {
				continue
			}
			
			let offset = currentString[currentString.startIndex..<wholeStringRange.lowerBound].utf16.count
			result.replaceCharacters(in: NSRange(location: offset, length: wholeString.utf16.count), with: "")

			let imageUUID = String(strippedString[captureRange])
			let imageID = EntityID.image(entityID.accountID, entityID.documentUUID, entityID.rowUUID, imageUUID)
			if let image = findImage(id: imageID) {
				insertImageAttachment(attrString: result, image: image, offset: offset)
			}
		}
		
		resolveAltLinks(attrString: result)

		return result
		#else
		return nil
		#endif
	}
	
	func insertImageAttachment(attrString: NSMutableAttributedString, image: Image, offset: Int) {
		#if canImport(UIKit)
		let attachment = ImageTextAttachment(data: image.data, ofType: UTType.png.identifier)
		attachment.imageUUID = image.id.imageUUID
		let imageAttrText = NSAttributedString(attachment: attachment)
		
		// Even though this should never happen, I have seen it. Let's just make sure we don't crash and recover best we can.
		if offset <= attrString.length {
			attrString.insert(imageAttrText, at: offset)
		} else {
			attrString.insert(imageAttrText, at: attrString.length)
		}
		#endif
	}
	
	@discardableResult
	func resolveAltLinks(attrString: NSMutableAttributedString) -> AltLinkResolvingActions {
		var actionsTaken = AltLinkResolvingActions()
		
		attrString.enumerateAttribute(.link, in: .init(location: 0, length: attrString.length), options: []) { (value, range, _) in
			guard let url = value as? URL, url.scheme == nil else { return }

			if let documentURL = outline?.account?.findDocument(filename: url.path)?.id.url {
				attrString.removeAttribute(.link, range: range)
				attrString.addAttribute(.link, value: documentURL, range: range)
				actionsTaken.insert(.fixedAltLink)
			} else {
				outline?.hasAltLinks = true
				actionsTaken.insert(.foundAltLink)
			}
		}
		
		return actionsTaken
	}
	
}
