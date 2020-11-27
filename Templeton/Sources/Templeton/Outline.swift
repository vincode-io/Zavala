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
		public var deletes: [Int]?
		public var inserts: [Int]?
		public var moves: [(Int, Int)]?
		public var reloads: [Int]?
		
		public var isEmpty: Bool {
			return deletes == nil && inserts == nil && reloads == nil
		}
		
		public var deleteIndexPaths: [IndexPath]? {
			guard let deletes = deletes else { return nil }
			return deletes.map { IndexPath(row: $0, section: 0) }
		}
		
		public var insertIndexPaths: [IndexPath]? {
			guard let inserts = inserts else { return nil }
			return inserts.map { IndexPath(row: $0, section: 0) }
		}
		
		public var moveIndexPaths: [(IndexPath, IndexPath)]? {
			guard let moves = moves else { return nil }
			return moves.map { (IndexPath(row: $0.0, section: 0), IndexPath(row: $0.1, section: 0)) }
		}
		
		public var reloadIndexPaths: [IndexPath]? {
			guard let reloads = reloads else { return nil }
			return reloads.map { IndexPath(row: $0, section: 0) }
		}
		
		init(deletes: [Int]? = nil, inserts: [Int]? = nil, moves: [(Int, Int)]? = nil, reloads: [Int]? = nil) {
			self.deletes = deletes
			self.inserts = inserts
			self.moves = moves
			self.reloads = reloads
		}
		
		mutating func append(_ changes: ShadowTableChanges) {
			if let changeDeletes = changes.deletes {
				if deletes == nil {
					deletes = changeDeletes
				} else {
					self.deletes!.append(contentsOf: changeDeletes)
				}
			}

			if let changeInserts = changes.inserts {
				if inserts == nil {
					inserts = changeInserts
				} else {
					self.inserts!.append(contentsOf: changeInserts)
				}
			}

			if let changeMoves = changes.moves {
				if moves == nil {
					moves = changeMoves
				} else {
					self.moves!.append(contentsOf: changeMoves)
				}
			}
			
			if let changeReloads = changes.reloads {
				if reloads == nil {
					reloads = changeReloads
				} else {
					self.reloads!.append(contentsOf: changeReloads)
				}
			}
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
	
	public func deleteHeadline(headline: Headline) -> ShadowTableChanges {
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
		
		guard let headlineShadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		shadowTable?.remove(at: headlineShadowTableIndex)
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)
		
		if headlineShadowTableIndex > 0 {
			return ShadowTableChanges(deletes: [headlineShadowTableIndex], reloads: [headlineShadowTableIndex - 1])
		} else {
			return ShadowTableChanges(deletes: [headlineShadowTableIndex])
		}
			
	}
	
	public func createHeadline(afterHeadline: Headline? = nil) -> ShadowTableChanges {
		let headline = Headline()

		if afterHeadline?.isExpanded ?? true && !(afterHeadline?.headlines?.isEmpty ?? true) {
			afterHeadline!.headlines!.insert(headline, at: 0)
			headline.parent = afterHeadline
		} else if let parent = afterHeadline?.parent {
			var headlines = parent.headlines ?? [Headline]()
			let insertIndex = headlines.firstIndex(where: { $0 == afterHeadline}) ?? 0
			headlines.insert(headline, at: insertIndex + 1)
			headline.parent = afterHeadline?.parent
			parent.headlines = headlines
		} else {
			var headlines = self.headlines ?? [Headline]()
			let insertIndex = headlines.firstIndex(where: { $0 == afterHeadline}) ?? 0
			headlines.insert(headline, at: insertIndex + 1)
			headline.parent = afterHeadline?.parent
			self.headlines = headlines
		}
		
		outlineBodyDidChange()

		let afterShadowTableIndex = afterHeadline?.shadowTableIndex ?? 0
		let headlineShadowTableIndex = afterShadowTableIndex + 1
		shadowTable?.insert(headline, at: headlineShadowTableIndex)
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)

		headline.shadowTableIndex = headlineShadowTableIndex
		
		return ShadowTableChanges(inserts: [headlineShadowTableIndex])
	}
	
	public func updateHeadline(headline: Headline, attributedText: NSAttributedString) {
		headline.attributedText = attributedText
		outlineBodyDidChange()
	}
	
	public func toggleDisclosure(headline: Headline) -> ShadowTableChanges {
		let changes: ShadowTableChanges
		if headline.isExpanded ?? true {
			changes = collapseHeadline(headline: headline)
		} else {
			changes = expandHeadline(headline: headline)
		}

		outlineBodyDidChange()
		return changes
	}

	public func indentHeadline(headline: Headline, attributedText: NSAttributedString) -> ShadowTableChanges {
		headline.attributedText = attributedText
		
		var reloads = [Int]()
		
		func visitor(_ visited: Headline) {
			if let index = visited.shadowTableIndex {
				reloads.append(index)
			}
		}

		if let oldParentHeadline = headline.parent,
		   let headlineShadowTableIndex = headline.shadowTableIndex,
		   let headlineIndex = oldParentHeadline.headlines?.firstIndex(of: headline),
		   headlineIndex > 0,
		   let newParentHeadline = oldParentHeadline.headlines?[headlineIndex - 1],
		   let newParentHeadlineShadowTableIndex = newParentHeadline.shadowTableIndex {

			var siblingHeadlines = newParentHeadline.headlines ?? [Headline]()
			headline.parent = newParentHeadline
			siblingHeadlines.append(headline)
			newParentHeadline.headlines = siblingHeadlines
			oldParentHeadline.headlines = oldParentHeadline.headlines?.filter { $0 != headline }

			newParentHeadline.isExpanded = true
			outlineBodyDidChange()
			
			reloads.append(newParentHeadlineShadowTableIndex)
			reloads.append(headlineShadowTableIndex)

			if headline.isExpanded ?? true {
				headline.headlines?.forEach { $0.visit(visitor: visitor(_:)) }
			}

			return ShadowTableChanges(reloads: reloads)
		}

		// This is a top level moving to the next one down

		guard let headlineIndex = headlines?.firstIndex(of: headline),
			  headlineIndex > 0,
			  let newParentHeadline = headlines?[headlineIndex - 1],
			  let headlineShadowTableIndex = headline.shadowTableIndex,
			  let newParentHeadlineShadowTableIndex = newParentHeadline.shadowTableIndex else { return ShadowTableChanges() }

		var siblingHeadlines = newParentHeadline.headlines ?? [Headline]()
		headline.parent = newParentHeadline
		siblingHeadlines.append(headline)
		newParentHeadline.headlines = siblingHeadlines
		headlines = headlines?.filter { $0 != headline }

		newParentHeadline.isExpanded = true
		outlineBodyDidChange()
		
		reloads.append(newParentHeadlineShadowTableIndex)
		reloads.append(headlineShadowTableIndex)

		if headline.isExpanded ?? true {
			headline.headlines?.forEach { $0.visit(visitor: visitor(_:)) }
		}

		return ShadowTableChanges(reloads: reloads)	}
	
	public func outdentHeadline(headline: Headline, attributedText: NSAttributedString) -> ShadowTableChanges {
		headline.attributedText = attributedText

		guard let oldParent = headline.parent,
			  let oldParentHeadlines = oldParent.headlines,
			  let oldParentShadowTableIndex = oldParent.shadowTableIndex,
			  let originalHeadlineShadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		
		guard let oldHeadlineIndex = oldParentHeadlines.firstIndex(of: headline) else { return ShadowTableChanges() }
		var siblingsToMove = [Headline]()
		for i in (oldHeadlineIndex + 1)..<oldParentHeadlines.count {
			siblingsToMove.append(oldParentHeadlines[i])
		}

		oldParent.headlines = oldParent.headlines?.filter { $0 != headline }

		if let newParent = oldParent.parent, let oldParentIndex = newParent.headlines?.firstIndex(of: oldParent) {
			
			newParent.headlines?.insert(headline, at: oldParentIndex + 1)
			headline.parent = newParent

			var reloads = [oldParentShadowTableIndex]
			var moves = [(Int, Int)]()
			var workingShadowTableIndex = originalHeadlineShadowTableIndex
			
			if siblingsToMove.isEmpty {
				reloads.append(originalHeadlineShadowTableIndex)
			} else {
				
				func shadowTableRemoveVisitor(_ visited: Headline) {
					if visited.isExpanded ?? true {
						visited.headlines?.reversed().forEach {	$0.visit(visitor: shadowTableRemoveVisitor)	}
					}
					if let visitedShadowTableIndex = visited.shadowTableIndex {
						shadowTable?.remove(at: visitedShadowTableIndex)
					}
				}

				if headline.isExpanded ?? true {
					headline.headlines?.reversed().forEach { $0.visit(visitor: shadowTableRemoveVisitor(_:)) }
				}
				shadowTable?.remove(at: originalHeadlineShadowTableIndex)

				func movingUpVisitor(_ visited: Headline) {
					if let visitedShadowTableIndex = visited.shadowTableIndex {
						moves.append((visitedShadowTableIndex, workingShadowTableIndex))
						workingShadowTableIndex = workingShadowTableIndex + 1
					}
					if visited.isExpanded ?? true {
						visited.headlines?.forEach { $0.visit(visitor: movingUpVisitor)	}
					}
				}

				for sibling in siblingsToMove {
					if let siblineShadowTableIndex = sibling.shadowTableIndex {
						moves.append((siblineShadowTableIndex, workingShadowTableIndex))
						workingShadowTableIndex = workingShadowTableIndex + 1
						if sibling.isExpanded ?? true {
							sibling.headlines?.forEach { $0.visit(visitor: movingUpVisitor(_:)) }
						}
					}
				}
				
				moves.append((originalHeadlineShadowTableIndex, workingShadowTableIndex))
				reloads.append(workingShadowTableIndex)
				shadowTable?.insert(headline, at: workingShadowTableIndex)

				func shadowTableInsertVisitor(_ visited: Headline) {
					if let visitedShadowTableIndex = visited.shadowTableIndex {
						workingShadowTableIndex = workingShadowTableIndex + 1
						shadowTable?.insert(visited, at: workingShadowTableIndex)
						moves.append((visitedShadowTableIndex, workingShadowTableIndex))
						reloads.append(workingShadowTableIndex)
					}
					if visited.isExpanded ?? true {
						visited.headlines?.forEach { $0.visit(visitor: shadowTableInsertVisitor) }
					}
				}

				if headline.isExpanded ?? true {
					headline.headlines?.forEach { $0.visit(visitor: shadowTableInsertVisitor(_:)) }
				}
			}
			
			resetShadowTableIndexes(startingAt: originalHeadlineShadowTableIndex)
			return ShadowTableChanges(moves: moves, reloads: reloads)
		} else if let oldParentIndex = headlines?.firstIndex(of: oldParent) {
			headlines?.insert(headline, at: oldParentIndex + 1)
			headline.parent = nil
			
		}
		
		return ShadowTableChanges()
	}
	
	public func load() {
		headlinesFile = HeadlinesFile(outline: self)
		headlinesFile!.load()
		
		if headlines?.isEmpty ?? true {
			headlines = [Headline()]
		}
		
		rebuildTransientData()
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
		guard let headlineShadowTableIndex = headline.shadowTableIndex else {
			return ShadowTableChanges()
		}
		
		headline.isExpanded = true

		var shadowTableInserts = [Headline]()

		func visitor(_ visited: Headline) {
			shadowTableInserts.append(visited)

			if visited.isExpanded ?? true {
				visited.headlines?.forEach {
					$0.visit(visitor: visitor)
				}
			}
		}

		headline.headlines?.forEach { headline in
			headline.visit(visitor: visitor(_:))
		}
		
		var inserts = [Int]()
		for i in 0..<shadowTableInserts.count {
			let newIndex = i + headlineShadowTableIndex + 1
			shadowTable?.insert(shadowTableInserts[i], at: newIndex)
			inserts.append(newIndex)
		}
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)
		
		return ShadowTableChanges(inserts: inserts)
	}
	
	private func collapseHeadline(headline: Headline) -> ShadowTableChanges {
		headline.isExpanded = false
			
		var shadowTableIndexes = [Int]()

		func visitor(_ visited: Headline) {
			if let shadowTableIndex = visited.shadowTableIndex {
				shadowTableIndexes.append(shadowTableIndex)
			}

			if visited.isExpanded ?? true {
				visited.headlines?.forEach {
					$0.visit(visitor: visitor)
				}
			}
		}
		
		headline.headlines?.forEach { headline in
			headline.visit(visitor: visitor(_:))
		}
		
		shadowTable?.remove(atOffsets: IndexSet(shadowTableIndexes))
		if let startingAt = headline.shadowTableIndex {
			resetShadowTableIndexes(startingAt: startingAt)
		}
		
		return ShadowTableChanges(deletes: shadowTableIndexes)
	}
	
	func rebuildTransientData() {
		let transient = TransientDataVisitor()
		headlines?.forEach { headline in
			headline.visit(visitor: transient.visitor(_:))
		}
		self.shadowTable = transient.shadowTable
	}
	
	func resetShadowTableIndexes(startingAt: Int = 0) {
		guard let shadowTable = shadowTable else { return }
		for i in startingAt..<shadowTable.count {
			shadowTable[i].shadowTableIndex = i
		}
	}
	
}
