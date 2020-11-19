//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let OutlineMetaDataDidChange = Notification.Name(rawValue: "OutlineMetaDataDidChange")
	static let OutlineBodyDidChange = Notification.Name(rawValue: "OutlineBodyDidChange")
	static let OutlineDidDelete = Notification.Name(rawValue: "OutlineDidDelete")
}

public final class Outline: Identifiable, Equatable, Codable {
	
	public var id: EntityID
	public var name: String?
	public var isFavorite: Bool?
	public var created: Date?
	public var updated: Date?
	
	public var headlines: [Headline]? {
		didSet {
			updateHeadlines()
			outlineBodyDidChange()
		}
	}
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var folder: Folder? {
		let folderID = EntityID.folder(id.accountID, id.folderID)
		return AccountManager.shared.findFolder(folderID)
	}

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
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
	

	init(parentID: EntityID, name: String) {
		self.id = EntityID.outline(parentID.accountID, parentID.folderID, UUID().uuidString)
		self.name = name
		self.created = Date()
		self.updated = Date()
	}

	public func toggleFavorite() {
		isFavorite = !(isFavorite ?? false)
		outlineMetaDataDidChange()
	}
	
	public func update(name: String) {
		self.name = name
		self.updated = Date()
		outlineMetaDataDidChange()
	}
	
	public func deleteHeadline(headlineID: String) {
		var headlines = self.headlines ?? [Headline]()
		
		let parentHeadlineID = headlineDictionary[headlineID]?.parent?.id
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
		self.updated = Date()
	}
	
	public func createHeadline(afterHeadlineID: String? = nil) -> Headline {
		var headlines = self.headlines ?? [Headline]()
		
		let parentHeadlineID = afterHeadlineID != nil ? headlineDictionary[afterHeadlineID!]?.parent?.id : nil
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
		self.updated = Date()
		return headline
	}
	
	public func updateHeadline(headlineID: String, attributedText: NSAttributedString) {
		headlineDictionary[headlineID]?.attributedText = attributedText
		outlineBodyDidChange()
		self.updated = Date()
	}
	
	public func indentHeadline(headlineID: String) -> Headline? {
		guard let headline = headlineDictionary[headlineID],
			  let headlineIndex = headline.parent?.headlines?.firstIndex(of: headline),
			  headlineIndex > 0,
			  let sibling = headline.parent?.headlines?[headlineIndex - 1] else { return nil }
		
		headline.parent?.headlines = headline.parent?.headlines?.filter { $0.id != headline.id }
		var siblingHeadlines = sibling.headlines ?? [Headline]()
		siblingHeadlines.insert(headline, at: 0)
		sibling.headlines = siblingHeadlines

		outlineBodyDidChange()
		self.updated = Date()
		return sibling
	}
	
	public func load() {
		headlinesFile = HeadlinesFile(outline: self)
		headlinesFile!.load()
	}
	
	public func save() {
		headlinesFile?.save()
	}
	
	public func suspend() {
		headlinesFile?.save()
		headlinesFile = nil
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
	func outlineDidDelete() {
		NotificationCenter.default.post(name: .OutlineDidDelete, object: self, userInfo: nil)
	}
}

// MARK: Helpers

private extension Outline {
	
	func outlineMetaDataDidChange() {
		NotificationCenter.default.post(name: .OutlineMetaDataDidChange, object: self, userInfo: nil)
	}

	func outlineBodyDidChange() {
		NotificationCenter.default.post(name: .OutlineBodyDidChange, object: self, userInfo: nil)
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
				visited.headlines?.forEach { $0.parent = visited }
			})
		}
	}
	
}
