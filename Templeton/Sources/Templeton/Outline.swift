//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let OutlineMetaDataDidChange = Notification.Name(rawValue: "OutlineMetaDataDidChange")
	static let OutlineNameDidChange = Notification.Name(rawValue: "OutlineNameDidChange")
	static let OutlineBodyDidChange = Notification.Name(rawValue: "OutlineBodyDidChange")
	static let OutlineDidDelete = Notification.Name(rawValue: "OutlineDidDelete")
}

public final class Outline: HeadlineContainer, Identifiable, Equatable, Codable {
	
	public struct ShadowTableChanges {
		let deletes: [Int]?
		let inserts: [Int]?
		
		var sortedDeletes: [Int] {
			return (deletes ?? [Int]()).sorted(by: { $0 > $1 })
		}

		var sortedInserts: [Int] {
			return (inserts ?? [Int]()).sorted(by: { $0 < $1 })
		}
	}
	
	public var id: EntityID
	public var title: String?
	public var isFavorite: Bool?
	public var created: Date?
	public var updated: Date?
	
	public var headlines: [Headline]?
	
	public var shadowTable: [Headline]?
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var folder: Folder? {
		let folderID = EntityID.folder(id.accountID, id.folderUUID)
		return AccountManager.shared.findFolder(folderID)
	}

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case title = "title"
		case isFavorite = "isFavorite"
		case created = "created"
		case updated = "updated"
	}

	private var headlinesFile: HeadlinesFile?
	
	init(parentID: EntityID, title: String) {
		self.id = EntityID.outline(parentID.accountID, parentID.folderUUID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		headlinesFile = HeadlinesFile(outline: self)
	}

	public func toggleFavorite() {
		isFavorite = !(isFavorite ?? false)
		outlineMetaDataDidChange()
	}
	
	public func update(title: String) {
		self.title = title
		self.updated = Date()
		outlineNameDidChange()
	}
	
	public func deleteHeadline(headline: Headline) {
		var headlines = self.headlines ?? [Headline]()
		
		if let parent = headline.parent {
			headlines = parent.headlines ?? [Headline]()
		}
		
		headlines = headlines.filter { $0 != headline }
		
		if let parent = headline.parent {
			parent.headlines = headlines
		} else {
			self.headlines = headlines
		}
		
		outlineBodyDidChange()
	}
	
	public func createHeadline(afterHeadline: Headline? = nil) -> Int {
		
		var headlines = self.headlines ?? [Headline]()
		
		if let parent = afterHeadline?.parent {
			headlines = parent.headlines ?? [Headline]()
		}
		
		let insertIndex = headlines.firstIndex(where: { $0 == afterHeadline}) ?? 0
		let headline = Headline()
		
		headlines.insert(headline, at: insertIndex + 1)
		
		if let parent = afterHeadline?.parent {
			parent.headlines = headlines
		} else {
			self.headlines = headlines
		}
		
		outlineBodyDidChange()

		let afterShadowTableIndex = afterHeadline?.shadowTableIndex ?? 0
		let headlineShadowTableIndex = afterShadowTableIndex + 1
		shadowTable?.insert(headline, at: headlineShadowTableIndex)
		
		headline.parent = afterHeadline?.parent
		headline.indentLevel = afterHeadline?.indentLevel ?? 0
		headline.shadowTableIndex = headlineShadowTableIndex
		
		return headlineShadowTableIndex
	}
	
	public func updateHeadline(headline: Headline, attributedText: NSAttributedString) {
		headline.attributedText = attributedText
		outlineBodyDidChange()
	}
	
	public func toggleDisclosure(headline: Headline) -> ShadowTableChanges {
		let changes: ShadowTableChanges
		if headline.isExpanded ?? true {
			headline.isExpanded = false
			changes = collapseHeadline(headline: headline)
		} else {
			headline.isExpanded = true
			changes = expandHeadline(headline: headline)
		}

		outlineBodyDidChange()
		return changes
	}

	public func indentHeadline(headlineID: String) {
//		guard let headline = headlineDictionary[headlineID] else { return nil }
//
//		if let parentID = headline.parentID,
//		   let parentHeadline = headlineDictionary[parentID],
//		   let headlineIndex = parentHeadline.headlines?.firstIndex(of: headline),
//		   headlineIndex > 0,
//		   let sibling = parentHeadline.headlines?[headlineIndex - 1] {
//
//			var siblingHeadlines = sibling.headlines ?? [Headline]()
//			siblingHeadlines.insert(headline, at: 0)
//			sibling.headlines = siblingHeadlines
//			parentHeadline.headlines = parentHeadline.headlines?.filter { $0.id != headline.id }
//
//			outlineBodyDidChange()
//			return (headline, sibling)
//		}
//
//		// This is a top level moving to the next one down
//
//		guard let headlineIndex = headlines?.firstIndex(of: headline),
//			  headlineIndex > 0,
//			  let sibling = headlines?[headlineIndex - 1] else { return nil }
//
//		var siblingHeadlines = sibling.headlines ?? [Headline]()
//		siblingHeadlines.insert(headline, at: 0)
//		sibling.headlines = siblingHeadlines
//		headlines = headlines?.filter { $0.id != headline.id }
//
//		outlineBodyDidChange()
//		return (headline, sibling)
	}
	
	public func load() {
		headlinesFile = HeadlinesFile(outline: self)
		headlinesFile!.load()
		
		if headlines?.isEmpty ?? true {
			headlines = [Headline()]
		}
		
		visitHeadlines()
	}
	
	public func save() {
		headlinesFile?.save()
	}
	
	public func forceSave() {
		headlinesFile?.markAsDirty()
		headlinesFile?.save()
	}
	
	public func delete() {
		if headlinesFile == nil {
			headlinesFile = HeadlinesFile(outline: self)
		}
		headlinesFile?.delete()
	}
	
	public func suspend() {
		headlinesFile?.save()
		headlinesFile = nil
		headlines = nil
		shadowTable = nil
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
}

// MARK: CustomDebugStringConvertible

extension Outline: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		var output = ""
		for headline in headlines ?? [Headline]() {
			output.append(dumpHeadline(level: 0, headline: headline))
		}
		return output
	}
	
	private func dumpHeadline(level: Int, headline: Headline) -> String {
		var output = ""
		for _ in 0..<level {
			output.append(" -- ")
		}
		output.append(headline.debugDescription)
		output.append("\n")
		
		for child in headline.headlines ?? [Headline]() {
			output.append(dumpHeadline(level: level + 1, headline: child))
		}
		
		return output
	}
	
}

// MARK: Helpers

private extension Outline {
	
	func outlineNameDidChange() {
		NotificationCenter.default.post(name: .OutlineNameDidChange, object: self, userInfo: nil)
	}

	func outlineMetaDataDidChange() {
		NotificationCenter.default.post(name: .OutlineMetaDataDidChange, object: self, userInfo: nil)
	}

	func outlineBodyDidChange() {
		self.updated = Date()
		outlineMetaDataDidChange()
		headlinesFile?.markAsDirty()
		NotificationCenter.default.post(name: .OutlineBodyDidChange, object: self, userInfo: nil)
	}
	
	func outlineDidDelete() {
		NotificationCenter.default.post(name: .OutlineDidDelete, object: self, userInfo: nil)
	}

	private func expandHeadline(headline: Headline) -> ShadowTableChanges {
		var inserts = [Int]()
		return ShadowTableChanges(deletes: nil, inserts: inserts)
	}
	
	private func collapseHeadline(headline: Headline) -> ShadowTableChanges {
		var deletes = [Int]()
		return ShadowTableChanges(deletes: deletes, inserts: nil)
	}
	
	func visitHeadlines() {
		let transient = TransientDataVisitor()
		headlines?.forEach { headline in
			headline.visit(visitor: transient.visitor(_:))
		}
		self.shadowTable = transient.shadowTable
	}
	
}
