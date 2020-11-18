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
			visitHeadlines()
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

	public func toggleFavorite(completion: @escaping (Result<Void, Error>) -> Void) {
		func toggleFavorite() {
			isFavorite = !(isFavorite ?? false)
			outlineMetaDataDidChange()
			completion(.success(()))
		}
		
		if account?.type == .cloudKit {
			toggleFavorite()
		} else {
			toggleFavorite()
		}
	}
	
	public func update(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		func update() {
			self.name = name
			self.updated = Date()
			outlineMetaDataDidChange()
			completion(.success(()))
		}
		
		if account?.type == .cloudKit {
			update()
		} else {
			update()
		}
	}
	
	public func deleteHeadline(parentHeadlineID: String?, headlineID: String, completion: @escaping (Result<Void, Error>) -> Void) {
		func deleteHeadline() {
			var headlines = self.headlines ?? [Headline]()
			
			if let parentHeadlineID = parentHeadlineID {
				headlines = headlineDictionary[parentHeadlineID]?.headlines ?? [Headline]()
			}
			
			headlines = headlines.filter { $0.id != headlineID }
			
			if let parentHeadlineID = parentHeadlineID {
				headlineDictionary[parentHeadlineID]?.headlines = headlines
			} else {
				self.headlines = headlines
			}
			
			completion(.success(()))
		}

		if account?.type == .cloudKit {
			deleteHeadline()
		} else {
			deleteHeadline()
		}
	}
	
	public func createHeadline(parentHeadlineID: String?, afterHeadlineID: String? = nil, completion: @escaping (Result<Headline, Error>) -> Void) {
		func createHeadline() {
			var headlines = self.headlines ?? [Headline]()
			
			if let parentHeadlineID = parentHeadlineID {
				headlines = headlineDictionary[parentHeadlineID]?.headlines ?? [Headline]()
			}
			
			let insertIndex = headlines.firstIndex(where: { $0.id == afterHeadlineID }) ?? 0
			let headline = Headline()
			headlines.insert(headline, at: insertIndex)
			
			if let parentHeadlineID = parentHeadlineID {
				headlineDictionary[parentHeadlineID]?.headlines = headlines
			} else {
				self.headlines = headlines
			}
			
			completion(.success((headline)))
		}

		if account?.type == .cloudKit {
			createHeadline()
		} else {
			createHeadline()
		}
	}
	
	public func update(headlineID: String, attributedText: NSAttributedString, completion: @escaping (Result<Void, Error>) -> Void) {
		func update() {
			headlineDictionary[headlineID]?.attributedText = attributedText
			outlineBodyDidChange()
			completion(.success(()))
		}

		if account?.type == .cloudKit {
			update()
		} else {
			update()
		}
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

	func visitHeadlines() {
		headlines?.forEach { headline in
			headline.visit(visitor: { visited in
				visited.headlines?.forEach { $0.parent = visited }
			})
		}
	}
	
}
