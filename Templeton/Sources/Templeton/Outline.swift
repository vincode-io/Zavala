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
	
	public var id: EntityID
	public var title: String?
	public var isFavorite: Bool?
	public var created: Date?
	public var updated: Date?
	
	public var headlines: [Headline]? {
		didSet {
			updateHeadlines()
		}
	}
	
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

	public var headlineDictionary: [String: Headline] {
		if headlineDictionariesNeedUpdate {
			rebuildHeadlineDictionary()
		}
		return _headlineDictionary
	}
	private var headlineDictionariesNeedUpdate = true
	private var _headlineDictionary = [String: Headline]()

	private var headlinesFile: HeadlinesFile?
	
	init(parentID: EntityID, title: String) {
		self.id = EntityID.outline(parentID.accountID, parentID.folderUUID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
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
	
	public func deleteHeadline(headlineID: String) {
		var headlines = self.headlines ?? [Headline]()
		
		let parentHeadlineID = headlineDictionary[headlineID]?.parentID
		if let parentHeadlineID = parentHeadlineID {
			headlines = headlineDictionary[parentHeadlineID]?.headlines ?? [Headline]()
		}
		
		headlines = headlines.filter { $0.id != headlineID }
		
		if let parentHeadlineID = parentHeadlineID {
			headlineDictionary[parentHeadlineID]?.headlines = headlines
		} else {
			self.headlines = headlines
		}
		
		headlineDictionariesNeedUpdate = true
		outlineBodyDidChange()
	}
	
	public func createHeadline(afterHeadlineID: String? = nil) -> Headline {
		var headlines = self.headlines ?? [Headline]()
		
		let parentHeadlineID = afterHeadlineID != nil ? headlineDictionary[afterHeadlineID!]?.parentID : nil
		if let parentHeadlineID = parentHeadlineID {
			headlines = headlineDictionary[parentHeadlineID]?.headlines ?? [Headline]()
		}
		
		let insertIndex = headlines.firstIndex(where: { $0.id == afterHeadlineID }) ?? 0
		let headline = Headline()
		headlines.insert(headline, at: insertIndex + 1)
		
		if let parentHeadlineID = parentHeadlineID {
			headlineDictionary[parentHeadlineID]?.headlines = headlines
		} else {
			self.headlines = headlines
		}
		
		headlineDictionariesNeedUpdate = true
		outlineBodyDidChange()
		return headline
	}
	
	public func updateHeadline(headlineID: String, attributedText: NSAttributedString) {
		headlineDictionary[headlineID]?.attributedText = attributedText
		outlineBodyDidChange()
	}
	
	public func expandHeadline(headlineID: String) {
		headlineDictionary[headlineID]?.isExpanded = true
		outlineBodyDidChange()
	}
	
	public func collapseHeadline(headlineID: String) {
		headlineDictionary[headlineID]?.isExpanded = false
		outlineBodyDidChange()
	}
	
	public func indentHeadline(headlineID: String) -> (Headline, Headline)? {
		guard let headline = headlineDictionary[headlineID] else { return nil }
		
		if let parentID = headline.parentID,
		   let parentHeadline = headlineDictionary[parentID],
		   let headlineIndex = parentHeadline.headlines?.firstIndex(of: headline),
		   headlineIndex > 0,
		   let sibling = parentHeadline.headlines?[headlineIndex - 1] {
			
			var siblingHeadlines = sibling.headlines ?? [Headline]()
			siblingHeadlines.insert(headline, at: 0)
			sibling.headlines = siblingHeadlines
			parentHeadline.headlines = parentHeadline.headlines?.filter { $0.id != headline.id }

			outlineBodyDidChange()
			return (headline, sibling)
		}
		
		// This is a top level moving to the next one down
		
		guard let headlineIndex = headlines?.firstIndex(of: headline),
			  headlineIndex > 0,
			  let sibling = headlines?[headlineIndex - 1] else { return nil }
		
		var siblingHeadlines = sibling.headlines ?? [Headline]()
		siblingHeadlines.insert(headline, at: 0)
		sibling.headlines = siblingHeadlines
		headlines = headlines?.filter { $0.id != headline.id }

		outlineBodyDidChange()
		return (headline, sibling)
	}
	
	public func load() {
		headlinesFile = HeadlinesFile(outline: self)
		headlinesFile!.load()
		
		if headlines?.isEmpty ?? true {
			headlines = [Headline()]
			headlineDictionariesNeedUpdate = true
		}
	}
	
	public func save() {
		headlinesFile?.save()
	}
	
	public func delete() {
		if headlinesFile == nil {
			headlinesFile = HeadlinesFile(outline: self)
		}
		headlinesFile?.delete()
		headlinesFile = nil
	}
	
	public func suspend() {
		headlinesFile?.save()
		headlinesFile = nil
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
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

	func rebuildHeadlineDictionary() {
		var idDictionary = [String: Headline]()

		func add(_ headline: Headline) {
			idDictionary[headline.id] = headline
			headline.headlines?.forEach { add($0) }
		}
		headlines?.forEach { add($0) }

		_headlineDictionary = idDictionary
		headlineDictionariesNeedUpdate = false
	}

	func updateHeadlines() {
		headlines?.forEach { headline in
			headline.visit(visitor: { visited in
				visited.headlines?.forEach { $0.parentID = visited.id }
			})
		}
	}
	
}
