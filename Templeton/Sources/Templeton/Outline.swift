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
	public var isFiltered: Bool?
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
		case isFiltered = "isFiltered"
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
	
	public func toggleFilter() -> ShadowTableChanges {
		isFiltered = !(isFiltered ?? false)
		outlineMetaDataDidChange()
		return rebuildShadowTable()
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
	
	public func createHeadline(headline: Headline = Headline(), afterHeadline: Headline? = nil) -> ShadowTableChanges {
		if let parent = headline.parent, parent == afterHeadline {
			parent.headlines?.insert(headline, at: 0)
		} else if afterHeadline?.isExpanded ?? true && !(afterHeadline?.headlines?.isEmpty ?? true) {
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
	
	public func updateHeadline(headline: Headline, attributedText: NSAttributedString) -> ShadowTableChanges {
		headline.attributedText = attributedText
		outlineBodyDidChange()
		guard let shadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		return ShadowTableChanges(reloads: [shadowTableIndex])
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

	public func toggleComplete(headline: Headline, attributedText: NSAttributedString) -> ShadowTableChanges {
		headline.attributedText = attributedText
		headline.isComplete = !(headline.isComplete ?? false)
		outlineBodyDidChange()
		
		if isFiltered ?? false {
			return rebuildShadowTable()
		}
		
		guard let shadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		var reloads = Set([shadowTableIndex])
		
		func reloadVisitor(_ visited: Headline) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded ?? true {
				visited.headlines?.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		if headline.isExpanded ?? true {
			headline.headlines?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
		}
		
		return ShadowTableChanges(reloads: reloads)
	}

	public func indentHeadline(headline: Headline, attributedText: NSAttributedString) -> ShadowTableChanges {
		headline.attributedText = attributedText
		
		let container: HeadlineContainer
		if let oldParentHeadline = headline.parent {
			container = oldParentHeadline
		} else {
			container = self
		}

		guard let headlineIndex = container.headlines?.firstIndex(of: headline),
			  headlineIndex > 0,
			  let newParentHeadline = container.headlines?[headlineIndex - 1] else { return ShadowTableChanges() }

		var expandChange = expandHeadline(headline: newParentHeadline)
		
		// Null out the chevron row reload since we are going to add it below
		expandChange.reloads = nil
		
		guard let headlineShadowTableIndex = headline.shadowTableIndex,
			  let newParentHeadlineShadowTableIndex = newParentHeadline.shadowTableIndex else { return expandChange }

		var siblingHeadlines = newParentHeadline.headlines ?? [Headline]()
		headline.parent = newParentHeadline
		siblingHeadlines.append(headline)
		newParentHeadline.headlines = siblingHeadlines
		container.headlines = container.headlines?.filter { $0 != headline }

		newParentHeadline.isExpanded = true
		outlineBodyDidChange()
		
		var reloads = Set<Int>()
		reloads.insert(newParentHeadlineShadowTableIndex)
		reloads.insert(headlineShadowTableIndex)

		func reloadVisitor(_ visited: Headline) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded ?? true {
				visited.headlines?.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		if headline.isExpanded ?? true {
			headline.headlines?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
		}

		expandChange.append(ShadowTableChanges(reloads: reloads))
		return expandChange

	}
	
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
		} else {
			if let oldParentIndex = headlines?.firstIndex(of: oldParent) {
				headlines?.insert(headline, at: oldParentIndex + 1)
			}
		}
		headline.parent = oldParent.parent

		var reloads = Set([oldParentShadowTableIndex])
		var moves = Set<ShadowTableChanges.Move>()
		var workingShadowTableIndex = originalHeadlineShadowTableIndex
		
		if siblingsToMove.isEmpty {
			reloads.insert(originalHeadlineShadowTableIndex)
			
			func reloadVisitor(_ visited: Headline) {
				if let index = visited.shadowTableIndex {
					reloads.insert(index)
				}
				if visited.isExpanded ?? true {
					visited.headlines?.forEach { $0.visit(visitor: reloadVisitor) }
				}
			}
			
			if headline.isExpanded ?? true {
				headline.headlines?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
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
					moves.insert(ShadowTableChanges.Move(visitedShadowTableIndex, workingShadowTableIndex))
					workingShadowTableIndex = workingShadowTableIndex + 1
				}
				if visited.isExpanded ?? true {
					visited.headlines?.forEach { $0.visit(visitor: movingUpVisitor)	}
				}
			}

			for sibling in siblingsToMove {
				if let siblineShadowTableIndex = sibling.shadowTableIndex {
					moves.insert(ShadowTableChanges.Move(siblineShadowTableIndex, workingShadowTableIndex))
					workingShadowTableIndex = workingShadowTableIndex + 1
					if sibling.isExpanded ?? true {
						sibling.headlines?.forEach { $0.visit(visitor: movingUpVisitor(_:)) }
					}
				}
			}
			
			moves.insert(ShadowTableChanges.Move(originalHeadlineShadowTableIndex, workingShadowTableIndex))
			reloads.insert(workingShadowTableIndex)
			shadowTable?.insert(headline, at: workingShadowTableIndex)

			func shadowTableInsertVisitor(_ visited: Headline) {
				if let visitedShadowTableIndex = visited.shadowTableIndex {
					workingShadowTableIndex = workingShadowTableIndex + 1
					shadowTable?.insert(visited, at: workingShadowTableIndex)
					moves.insert(ShadowTableChanges.Move(visitedShadowTableIndex, workingShadowTableIndex))
					reloads.insert(workingShadowTableIndex)
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
	}
	
	public func moveHeadline(_ headline: Headline, attributedText: NSAttributedString? = nil, toParent: HeadlineContainer, childIndex: Int) -> ShadowTableChanges {
		if let text = attributedText {
			headline.attributedText = text
		}

		let fromParent: HeadlineContainer
		if let oldParentHeadline = headline.parent {
			fromParent = oldParentHeadline
		} else {
			fromParent = self
		}
		
		// Move the headline in the tree
		fromParent.headlines = fromParent.headlines?.filter{ $0 != headline }
		if toParent.headlines == nil {
			toParent.headlines = [headline]
		} else {
			toParent.headlines!.insert(headline, at: childIndex)
		}
		
		return rebuildShadowTable(reloadEverything: true)
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

extension Outline {
	
	private func outlineNameDidChange() {
		NotificationCenter.default.post(name: .OutlineNameDidChange, object: self, userInfo: nil)
	}

	private func outlineMetaDataDidChange() {
		NotificationCenter.default.post(name: .OutlineMetaDataDidChange, object: self, userInfo: nil)
	}

	private func outlineBodyDidChange() {
		self.updated = Date()
		outlineMetaDataDidChange()
		headlinesFile?.markAsDirty()
		NotificationCenter.default.post(name: .OutlineBodyDidChange, object: self, userInfo: nil)
	}
	
	private func outlineDidDelete() {
		NotificationCenter.default.post(name: .OutlineDidDelete, object: self, userInfo: nil)
	}

	private func expandHeadline(headline: Headline) -> ShadowTableChanges {
		guard !(headline.isExpanded ?? true), let headlineShadowTableIndex = headline.shadowTableIndex else {
			return ShadowTableChanges()
		}
		
		headline.isExpanded = true

		var shadowTableInserts = [Headline]()

		func visitor(_ visited: Headline) {
			let shouldFilter = isFiltered ?? false && visited.isComplete ?? false
			
			if !shouldFilter {
				shadowTableInserts.append(visited)

				if visited.isExpanded ?? true {
					visited.headlines?.forEach {
						$0.visit(visitor: visitor)
					}
				}
			}
		}

		headline.headlines?.forEach { headline in
			headline.visit(visitor: visitor(_:))
		}
		
		var inserts = Set<Int>()
		for i in 0..<shadowTableInserts.count {
			let newIndex = i + headlineShadowTableIndex + 1
			shadowTable?.insert(shadowTableInserts[i], at: newIndex)
			inserts.insert(newIndex)
		}
		
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)
		return ShadowTableChanges(inserts: inserts, reloads: [headlineShadowTableIndex])
	}
	
	private func collapseHeadline(headline: Headline) -> ShadowTableChanges {
		guard headline.isExpanded ?? true else { return ShadowTableChanges() }

		headline.isExpanded = false
			
		var reloads = Set<Int>()

		func visitor(_ visited: Headline) {
			if let shadowTableIndex = visited.shadowTableIndex {
				reloads.insert(shadowTableIndex)
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
		
		shadowTable?.remove(atOffsets: IndexSet(reloads))
		
		guard let headlineShadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)
		return ShadowTableChanges(deletes: reloads, reloads: Set([headlineShadowTableIndex]))
	}
	
	private func rebuildShadowTable(reloadEverything: Bool = false) -> ShadowTableChanges {
		guard let oldShadowTable = shadowTable else { return ShadowTableChanges() }
		rebuildTransientData()
		
		var moves = Set<ShadowTableChanges.Move>()
		var inserts = Set<Int>()
		var deletes = Set<Int>()
		
		let diff = shadowTable!.difference(from: oldShadowTable).inferringMoves()
		for change in diff {
			switch change {
			case .insert(let offset, _, let associated):
				if let associated = associated {
					moves.insert(ShadowTableChanges.Move(associated, offset))
				} else {
					inserts.insert(offset)
				}
			case .remove(let offset, _, let associated):
				if let associated = associated {
					moves.insert(ShadowTableChanges.Move(offset, associated))
				} else {
					deletes.insert(offset)
				}
			}
		}
		
		var reloads = Set<Int>()
		if reloadEverything {
			moves.forEach {
				reloads.insert($0.from)
				reloads.insert($0.to)
			}
		}
		
		return ShadowTableChanges(deletes: deletes, inserts: inserts, moves: moves, reloads: reloads)
	}
	
	private func rebuildTransientData() {
		let transient = TransientDataVisitor(isFiltered: isFiltered ?? false)
		headlines?.forEach { headline in
			headline.visit(visitor: transient.visitor(_:))
		}
		self.shadowTable = transient.shadowTable
	}
	
	private func resetShadowTableIndexes(startingAt: Int = 0) {
		guard let shadowTable = shadowTable else { return }
		for i in startingAt..<shadowTable.count {
			shadowTable[i].shadowTableIndex = i
		}
	}
	
}
