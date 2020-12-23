//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let OutlineMetaDataDidChange = Notification.Name(rawValue: "OutlineMetaDataDidChange")
	static let OutlineTitleDidChange = Notification.Name(rawValue: "OutlineTitleDidChange")
	static let OutlineBodyDidChange = Notification.Name(rawValue: "OutlineBodyDidChange")
	static let OutlineDidDelete = Notification.Name(rawValue: "OutlineDidDelete")
}

public final class Outline: HeadlineContainer, Identifiable, Equatable, Codable {
	
	public var id: EntityID
	public var title: String? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var created: Date? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var updated: Date? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var ownerName: String? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var ownerEmail: String? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var ownerURL: String? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var verticleScrollState: Int? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var isFavorite: Bool? {
		didSet {
			outlineMetaDataDidChange()
		}
	}
	
	public var isFiltered: Bool? {
		didSet {
			outlineMetaDataDidChange()
		}
	}

	public var headlines: [Headline]? {
		didSet {
			headlineDictionaryNeedUpdate = true
		}
	}
	
	public var shadowTable: [Headline]?
	
	public var isEmpty: Bool {
		return (title == nil || title?.isEmpty ?? true) && (headlines == nil || headlines?.isEmpty ?? true)
	}
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var folder: Folder? {
		let folderID = EntityID.folder(id.accountID, id.folderUUID)
		return AccountManager.shared.findFolder(folderID)
	}

	public var expansionState: String {
		get {
			var currentRow = 0
			var expandedRows = [String]()
			
			func expandedRowVisitor(_ visited: Headline) {
				if visited.isExpanded ?? true {
					expandedRows.append(String(currentRow))
				}
				currentRow = currentRow + 1
				visited.headlines?.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			headlines?.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
			
			return expandedRows.joined(separator: ",")
		}
		set {
			let expandedRows = newValue.split(separator: ",")
				.map({ String($0).trimmingWhitespace })
				.filter({ !$0.isEmpty })
				.compactMap({ Int($0) })
			
			var currentRow = 0
			
			func expandedRowVisitor(_ visited: Headline) {
				visited.isExpanded = expandedRows.contains(currentRow)
				currentRow = currentRow + 1
				visited.headlines?.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			headlines?.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
		}
	}
	
	public var cursorCoordinates: CursorCoordinates? {
		get {
			guard let headlineID = cursorHeadlineID,
				  let headline = findHeadline(id: headlineID),
				  let isInNotes = cursorIsInNotes,
				  let position = cursorPosition else {
				return nil
			}
			return CursorCoordinates(headline: headline, isInNotes: isInNotes, cursorPosition: position)
		}
		set {
			cursorHeadlineID = newValue?.headline.id
			cursorIsInNotes = newValue?.isInNotes
			cursorPosition = newValue?.cursorPosition
			outlineMetaDataDidChange()
		}
	}
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case title = "title"
		case created = "created"
		case updated = "updated"
		case ownerName = "ownerName"
		case ownerEmail = "ownerEmail"
		case ownerURL = "ownerURL"
		case verticleScrollState = "verticleScrollState"
		case isFavorite = "isFavorite"
		case isFiltered = "isFiltered"
		case cursorHeadlineID = "cursorHeadlineID"
		case cursorIsInNotes = "cursorIsInNotes"
		case cursorPosition = "cursorPosition"
	}

	private var cursorHeadlineID: String?
	private var cursorIsInNotes: Bool?
	private var cursorPosition: Int?
	
	private var headlinesFile: HeadlinesFile?
	
	private var headlineDictionaryNeedUpdate = true
	private var _idToHeadlineDictionary = [String: Headline]()
	private var idToHeadlineDictionary: [String: Headline] {
		if headlineDictionaryNeedUpdate {
			rebuildHeadlineDictionary()
		}
		return _idToHeadlineDictionary
	}
	
	init(parentID: EntityID, title: String?) {
		self.id = EntityID.outline(parentID.accountID, parentID.folderUUID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		headlinesFile = HeadlinesFile(outline: self)
	}

	public func findHeadline(id: String) -> Headline? {
		return idToHeadlineDictionary[id]
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		var returnToSuspend = false
		if headlines == nil {
			returnToSuspend = true
			load()
		}
		
		var md = "# \(title ?? "")\n\n"
		headlines?.forEach { md.append($0.markdown(indentLevel: 0)) }
		
		if returnToSuspend {
			suspend()
		}
		
		return md
	}
	
	public func opml() -> String {
		var returnToSuspend = false
		if headlines == nil {
			returnToSuspend = true
			load()
		}

		var opml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		opml.append("<!-- OPML generated by Zavala -->\n")
		opml.append("<opml version=\"2.0\">\n")
		opml.append("<head>\n")
		opml.append("  <title>\(title?.escapingSpecialXMLCharacters ?? "")</title>\n")
		if let dateCreated = created?.rfc822String {
			opml.append("  <dateCreated>\(dateCreated)</dateCreated>\n")
		}
		if let dateModified = updated?.rfc822String {
			opml.append("  <dateModified>\(dateModified)</dateModified>\n")
		}
		if let ownerName = ownerName {
			opml.append("  <ownerName>\(ownerName)</ownerName>\n")
		}
		if let ownerEmail = ownerEmail {
			opml.append("  <ownerEmail>\(ownerEmail)</ownerEmail>\n")
		}
		if let ownerURL = ownerURL {
			opml.append("  <ownerID>\(ownerURL)</ownerID>\n")
		}
		opml.append("  <expansionState>\(expansionState)</expansionState>\n")
		if let verticleScrollState = verticleScrollState {
			opml.append("  <vertScrollState>\(verticleScrollState)</vertScrollState>\n")
		}
		opml.append("</head>\n")
		opml.append("<body>\n")
		headlines?.forEach { opml.append($0.opml()) }
		opml.append("</body>\n")
		opml.append("</opml>\n")

		if returnToSuspend {
			suspend()
		}

		return opml
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
		outlineTitleDidChange()
	}
	
	public func createNote(headline: Headline, attributedTexts: HeadlineTexts) -> ShadowTableChanges {
		headline.attributedTexts = attributedTexts
		
		if headline.noteAttributedText == nil {
			headline.noteAttributedText = NSAttributedString()
		}
		
		outlineBodyDidChange()
		
		guard let shadowTableIndex = shadowTable?.firstIndex(of: headline) else { return ShadowTableChanges() }
		return ShadowTableChanges(reloads: [shadowTableIndex])
	}
	
	public func deleteNote(headline: Headline, attributedTexts: HeadlineTexts) -> ShadowTableChanges {
		headline.attributedTexts = attributedTexts
		headline.noteAttributedText = nil
		
		outlineBodyDidChange()
		
		guard let shadowTableIndex = shadowTable?.firstIndex(of: headline) else { return ShadowTableChanges() }
		return ShadowTableChanges(reloads: [shadowTableIndex])
	}
	
	public func deleteHeadline(headline: Headline, attributedTexts: HeadlineTexts? = nil) -> ShadowTableChanges {
		if let texts = attributedTexts {
			headline.attributedTexts = texts
		}
		headline.parent?.headlines?.removeFirst(object: headline)
		
		outlineBodyDidChange()
		
		guard let headlineShadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		var deletes = [headlineShadowTableIndex]
		
		func deleteVisitor(_ visited: Headline) {
			if let index = visited.shadowTableIndex {
				deletes.append(index)
			}
			if visited.isExpanded ?? true {
				visited.headlines?.forEach { $0.visit(visitor: deleteVisitor) }
			}
		}

		if headline.isExpanded ?? true {
			headline.headlines?.forEach { $0.visit(visitor: deleteVisitor(_:)) }
		}

		for index in deletes.reversed() {
			shadowTable?.remove(at: index)
		}
		
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)
		
		if headlineShadowTableIndex > 0 {
			return ShadowTableChanges(deletes: Set(deletes), reloads: [headlineShadowTableIndex - 1])
		} else {
			return ShadowTableChanges(deletes: Set(deletes))
		}
			
	}
	
	public func joinHeadline(topHeadline: Headline, bottomHeadline: Headline) -> ShadowTableChanges {
		guard let topText = topHeadline.attributedText,
			  let topShadowTableIndex = topHeadline.shadowTableIndex,
			  let bottomText = bottomHeadline.attributedText else { return ShadowTableChanges() }
		
		let mutableText = NSMutableAttributedString(attributedString: topText)
		mutableText.append(bottomText)
		topHeadline.attributedText = mutableText
		
		var changes = deleteHeadline(headline: bottomHeadline)
		changes.append(ShadowTableChanges(reloads: Set([topShadowTableIndex])))
		return changes
	}
	
	public func createHeadline(headline: Headline, beforeHeadline: Headline, attributedTexts: HeadlineTexts? = nil) -> ShadowTableChanges {
		if let texts = attributedTexts {
			beforeHeadline.attributedTexts = texts
		}

		guard let parent = beforeHeadline.parent,
			  let index = parent.headlines?.firstIndex(of: beforeHeadline),
			  let shadowTableIndex = beforeHeadline.shadowTableIndex else {
			return ShadowTableChanges()
		}
		
		parent.headlines?.insert(headline, at: index)
		headline.parent = parent
		
		outlineBodyDidChange()

		shadowTable?.insert(headline, at: shadowTableIndex)
		resetShadowTableIndexes(startingAt: shadowTableIndex)
		return ShadowTableChanges(inserts: [shadowTableIndex])
	}
	
	public func createHeadline(headline: Headline, afterHeadline: Headline? = nil, attributedTexts: HeadlineTexts? = nil) -> ShadowTableChanges {
		if let texts = attributedTexts {
			afterHeadline?.attributedTexts = texts
		}

		if let parent = headline.parent, parent as? Headline == afterHeadline {
			parent.headlines?.insert(headline, at: 0)
		} else if let parent = headline.parent {
			var headlines = parent.headlines ?? [Headline]()
			let insertIndex = headlines.firstIndex(where: { $0 == afterHeadline}) ?? headlines.count - 1
			headlines.insert(headline, at: insertIndex + 1)
			parent.headlines = headlines
		} else if afterHeadline?.isExpanded ?? true && !(afterHeadline?.headlines?.isEmpty ?? true) {
			afterHeadline!.headlines!.insert(headline, at: 0)
			headline.parent = afterHeadline
		} else if let parent = afterHeadline?.parent {
			var headlines = parent.headlines ?? [Headline]()
			let insertIndex = headlines.firstIndex(where: { $0 == afterHeadline}) ?? -1
			headlines.insert(headline, at: insertIndex + 1)
			headline.parent = afterHeadline?.parent
			parent.headlines = headlines
		} else {
			var headlines = self.headlines ?? [Headline]()
			let insertIndex = headlines.firstIndex(where: { $0 == afterHeadline}) ?? -1
			headlines.insert(headline, at: insertIndex + 1)
			headline.parent = self
			self.headlines = headlines
		}
		
		outlineBodyDidChange()

		var headlines = [headline]
		
		func insertVisitor(_ visited: Headline) {
			headlines.append(visited)
			if visited.isExpanded ?? true {
				visited.headlines?.forEach { $0.visit(visitor: insertVisitor) }
			}
		}

		if headline.isExpanded ?? true {
			headline.headlines?.forEach { $0.visit(visitor: insertVisitor(_:)) }
		}
		
		let afterShadowTableIndex = afterHeadline?.shadowTableIndex ?? -1
		let headlineShadowTableIndex = afterShadowTableIndex + 1

		var inserts = Set<Int>()
		for i in 0..<headlines.count {
			let shadowTableIndex = headlineShadowTableIndex + i
			inserts.insert(shadowTableIndex)
			shadowTable?.insert(headlines[i], at: shadowTableIndex)
		}
		
		headline.shadowTableIndex = headlineShadowTableIndex
		resetShadowTableIndexes(startingAt: headlineShadowTableIndex)
		
		return ShadowTableChanges(inserts: inserts)
	}
	
	public func splitHeadline(newHeadline: Headline, headline: Headline, attributedText: NSAttributedString, cursorPosition: Int) -> ShadowTableChanges {
		let newHeadlineRange = NSRange(location: cursorPosition, length: attributedText.length - cursorPosition)
		let newHeadlineText = attributedText.attributedSubstring(from: newHeadlineRange)
		newHeadline.attributedText = newHeadlineText
		
		let headlineRange = NSRange(location: 0, length: cursorPosition)
		let headlineText = attributedText.attributedSubstring(from: headlineRange)
		headline.attributedText = headlineText

		var changes = createHeadline(headline: newHeadline, afterHeadline: headline)
		if let headlineShadowTableIndex = headline.shadowTableIndex {
			changes.append(ShadowTableChanges(reloads: Set([headlineShadowTableIndex])))
		}
		return changes
	}

	public func updateHeadline(headline: Headline, attributedTexts: HeadlineTexts) -> ShadowTableChanges {
		headline.attributedTexts = attributedTexts
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
	
	public func isExpandAllUnavailable(container: HeadlineContainer) -> Bool {
		if let headline = container as? Headline, headline.isExpandable {
			return false
		}

		var unavailable = true
		
		func expandedRowVisitor(_ visited: Headline) {
			for headline in visited.headlines ?? [Headline]() {
				unavailable = !headline.isExpandable
				if !unavailable {
					break
				}
				headline.visit(visitor: expandedRowVisitor)
				if !unavailable {
					break
				}
			}
		}

		for headline in container.headlines ?? [Headline]() {
			unavailable = !headline.isExpandable
			if !unavailable {
				break
			}
			headline.visit(visitor: expandedRowVisitor)
			if !unavailable {
				break
			}
		}
		
		return unavailable
	}
	
	public func expandAll(container: HeadlineContainer) -> ([Headline], ShadowTableChanges) {
		var expanded = [Headline]()
		
		if let headline = container as? Headline, headline.isExpandable {
			headline.isExpanded = true
			expanded.append(headline)
		}
		
		func expandVisitor(_ visited: Headline) {
			if visited.isExpandable {
				visited.isExpanded = true
				expanded.append(visited)
			}
			visited.headlines?.forEach { $0.visit(visitor: expandVisitor) }
		}

		container.headlines?.forEach { $0.visit(visitor: expandVisitor(_:)) }
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(expanded.compactMap { $0.shadowTableIndex })
		changes.append(ShadowTableChanges(reloads: reloads))
		
		return (expanded, changes)
	}

	public func expand(headlines: [Headline]) -> ShadowTableChanges {
		expandCollapse(headlines: headlines, isExpanded: true)
	}
	
	public func isCollapseAllUnavailable(container: HeadlineContainer) -> Bool {
		if let headline = container as? Headline, headline.isCollapsable {
			return false
		}
		
		var unavailable = true
		
		func collapsedRowVisitor(_ visited: Headline) {
			for headline in visited.headlines ?? [Headline]() {
				unavailable = !headline.isCollapsable
				if !unavailable {
					break
				}
				headline.visit(visitor: collapsedRowVisitor)
				if !unavailable {
					break
				}
			}
		}

		for headline in container.headlines ?? [Headline]() {
			unavailable = !headline.isCollapsable
			if !unavailable {
				break
			}
			headline.visit(visitor: collapsedRowVisitor)
			if !unavailable {
				break
			}
		}
		
		return unavailable
	}
	
	public func collapseAll(container: HeadlineContainer) -> ([Headline], ShadowTableChanges) {
		var collapsed = [Headline]()
		
		if let headline = container as? Headline, headline.isCollapsable {
			headline.isExpanded = false
			collapsed.append(headline)
		}
		
		func collapseVisitor(_ visited: Headline) {
			if visited.isCollapsable {
				visited.isExpanded = false
				collapsed.append(visited)
			}
			visited.headlines?.forEach { $0.visit(visitor: collapseVisitor) }
		}

		var reloads: [Headline]
		if let headline = container as? Headline {
			reloads = [headline]
		} else {
			reloads = [Headline]()
		}
		
		container.headlines?.forEach {
			reloads.append($0)
			$0.visit(visitor: collapseVisitor(_:))
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
	
		let reloadIndexes = Set(reloads.compactMap { $0.shadowTableIndex })
		changes.append(ShadowTableChanges(reloads: reloadIndexes))
		
		return (collapsed, changes)
	}

	public func collapse(headlines: [Headline]) -> ShadowTableChanges {
		expandCollapse(headlines: headlines, isExpanded: false)
	}
	
	public func toggleComplete(headline: Headline, attributedTexts: HeadlineTexts) -> ShadowTableChanges {
		headline.attributedTexts = attributedTexts
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

	public func isIndentHeadlineUnavailable(headline: Headline) -> Bool {
		let container: HeadlineContainer
		if let oldParentHeadline = headline.parent {
			container = oldParentHeadline
		} else {
			container = self
		}
		
		if let headlineIndex = container.headlines?.firstIndex(of: headline), headlineIndex > 0 {
			return false
		}
		
		return true
	}
	
	public func indentHeadline(headline: Headline, attributedTexts: HeadlineTexts) -> ShadowTableChanges {
		headline.attributedTexts = attributedTexts
		
		guard let container = headline.parent,
			  let headlineIndex = container.headlines?.firstIndex(of: headline),
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
		container.headlines?.removeFirst(object: headline)

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
	
	public func isOutdentHeadlineUnavailable(headline: Headline) -> Bool {
		return headline.indentLevel == 0
	}
		
	public func outdentHeadline(headline: Headline, attributedTexts: HeadlineTexts) -> ShadowTableChanges {
		headline.attributedTexts = attributedTexts

		guard let oldParent = headline.parent as? Headline,
			  let oldParentHeadlines = oldParent.headlines,
			  let oldParentShadowTableIndex = oldParent.shadowTableIndex,
			  let originalHeadlineShadowTableIndex = headline.shadowTableIndex else { return ShadowTableChanges() }
		
		guard let oldHeadlineIndex = oldParentHeadlines.firstIndex(of: headline) else { return ShadowTableChanges() }
		var siblingsToMove = [Headline]()
		for i in (oldHeadlineIndex + 1)..<oldParentHeadlines.count {
			siblingsToMove.append(oldParentHeadlines[i])
		}

		oldParent.headlines?.removeFirst(object: headline)

		if let newParent = oldParent.parent, let oldParentIndex = newParent.headlines?.firstIndex(of: oldParent) {
			newParent.headlines?.insert(headline, at: oldParentIndex + 1)
		} else {
			if let oldParentIndex = headlines?.firstIndex(of: oldParent) {
				headlines?.insert(headline, at: oldParentIndex + 1)
			}
		}
		headline.parent = oldParent.parent

		outlineBodyDidChange()

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
	
	public func moveHeadline(_ headline: Headline, attributedTexts: HeadlineTexts? = nil, toParent: HeadlineContainer, childIndex: Int) -> ShadowTableChanges {
		if let texts = attributedTexts {
			headline.attributedTexts = texts
		}

		// Move the headline in the tree
		headline.parent?.headlines?.removeFirst(object: headline)
		if toParent.headlines == nil {
			toParent.headlines = [headline]
		} else {
			toParent.headlines!.insert(headline, at: childIndex)
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		guard let shadowTableIndex = shadowTable?.firstIndex(of: headline) else {
			return changes
		}

		var reloads = [shadowTableIndex]
		if shadowTableIndex > 0 {
			reloads.append(shadowTableIndex - 1)
		}
		
		func reloadVisitor(_ visited: Headline) {
			if let index = visited.shadowTableIndex {
				reloads.append(index)
			}
			if visited.isExpanded ?? true {
				visited.headlines?.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		if headline.isExpanded ?? true {
			headline.headlines?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
		}

		changes.append(ShadowTableChanges(reloads: Set(reloads)))
		return changes
	}
	
	public func load() {
		headlinesFile = HeadlinesFile(outline: self)
		headlinesFile!.load()
		rebuildTransientData()
	}
	
	public func save() {
		headlinesFile?.save()
	}
	
	public func forceSave() {
		if headlinesFile == nil {
			headlinesFile = HeadlinesFile(outline: self)
		}
		headlinesFile?.markAsDirty()
		headlinesFile?.save()
	}
	
	public func delete() {
		if headlinesFile == nil {
			headlinesFile = HeadlinesFile(outline: self)
		}
		headlinesFile?.delete()
		headlinesFile = nil
		outlineDidDelete()
	}
	
	public func suspend() {
		headlinesFile?.save()
		headlinesFile = nil
		headlines = nil
		shadowTable = nil
		_idToHeadlineDictionary = [String: Headline]()
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
	
	private func outlineTitleDidChange() {
		NotificationCenter.default.post(name: .OutlineTitleDidChange, object: self, userInfo: nil)
	}

	private func outlineMetaDataDidChange() {
		NotificationCenter.default.post(name: .OutlineMetaDataDidChange, object: self, userInfo: nil)
	}

	private func outlineBodyDidChange() {
		self.updated = Date()
		outlineMetaDataDidChange()
		headlineDictionaryNeedUpdate = true
		headlinesFile?.markAsDirty()
		NotificationCenter.default.post(name: .OutlineBodyDidChange, object: self, userInfo: nil)
	}
	
	private func outlineDidDelete() {
		NotificationCenter.default.post(name: .OutlineDidDelete, object: self, userInfo: nil)
	}

	private func expandCollapse(headlines: [Headline], isExpanded: Bool) -> ShadowTableChanges {
		for headline in headlines {
			headline.isExpanded = isExpanded
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(headlines.compactMap { $0.shadowTableIndex })
		changes.append(ShadowTableChanges(reloads: reloads))
		
		return changes
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
	
	func rebuildHeadlineDictionary() {
		var idDictionary = [String: Headline]()
		
		func dictBuildVisitor(_ visited: Headline) {
			idDictionary[visited.id] = visited
			visited.headlines?.forEach { $0.visit(visitor: dictBuildVisitor) }
		}

		headlines?.forEach { $0.visit(visitor: dictBuildVisitor(_:)) }
		
		_idToHeadlineDictionary = idDictionary
		headlineDictionaryNeedUpdate = false
	}
	
	private func rebuildShadowTable() -> ShadowTableChanges {
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
		
		return ShadowTableChanges(deletes: deletes, inserts: inserts, moves: moves)
	}
	
	private func rebuildTransientData() {
		let transient = TransientDataVisitor(isFiltered: isFiltered ?? false)
		headlines?.forEach { headline in
			headline.parent = self
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
