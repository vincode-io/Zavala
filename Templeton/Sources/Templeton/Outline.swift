//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let OutlineBodyDidChange = Notification.Name(rawValue: "OutlineBodyDidChange")
}

public final class Outline: RowContainer, OPMLImporter, Identifiable, Equatable, Codable {
	
	public var id: EntityID
	public var title: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var created: Date? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var updated: Date? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var ownerName: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var ownerEmail: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var ownerURL: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var verticleScrollState: Int? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var isFavorite: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var isFiltered: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var isNotesHidden: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var rows: [Row]? {
		didSet {
			rowDictionaryNeedUpdate = true
		}
	}
	
	public var shadowTable: [Row]?
	
	public var isEmpty: Bool {
		return (title == nil || title?.isEmpty ?? true) && (rows == nil || rows?.isEmpty ?? true)
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
			
			func expandedRowVisitor(_ visited: Row) {
				if visited.isExpanded ?? true {
					expandedRows.append(String(currentRow))
				}
				currentRow = currentRow + 1
				visited.rows?.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows?.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
			
			return expandedRows.joined(separator: ",")
		}
		set {
			let expandedRows = newValue.split(separator: ",")
				.map({ String($0).trimmingWhitespace })
				.filter({ !$0.isEmpty })
				.compactMap({ Int($0) })
			
			var currentRow = 0
			
			func expandedRowVisitor(_ visited: Row) {
				var mutatingVisited = visited
				mutatingVisited.isExpanded = expandedRows.contains(currentRow)
				currentRow = currentRow + 1
				visited.rows?.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows?.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
		}
	}
	
	public var cursorCoordinates: CursorCoordinates? {
		get {
			guard let rowID = cursorRowID,
				  let row = findRow(id: rowID),
				  let isInNotes = cursorIsInNotes,
				  let position = cursorPosition else {
				return nil
			}
			return CursorCoordinates(row: row, isInNotes: isInNotes, cursorPosition: position)
		}
		set {
			cursorRowID = newValue?.row.id
			cursorIsInNotes = newValue?.isInNotes
			cursorPosition = newValue?.cursorPosition
			documentMetaDataDidChange()
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
		case isNotesHidden = "isNotesHidden"
		case cursorRowID = "cursorRowID"
		case cursorIsInNotes = "cursorIsInNotes"
		case cursorPosition = "cursorPosition"
	}

	private var cursorRowID: String?
	private var cursorIsInNotes: Bool?
	private var cursorPosition: Int?
	
	private var rowsFile: RowsFile?
	
	private var rowDictionaryNeedUpdate = true
	private var _idToRowDictionary = [String: Row]()
	private var idToRowDictionary: [String: Row] {
		if rowDictionaryNeedUpdate {
			rebuildRowDictionary()
		}
		return _idToRowDictionary
	}
	
	init(parentID: EntityID, title: String?) {
		self.id = EntityID.document(parentID.accountID, parentID.folderUUID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
	}

	public func findRow(id: String) -> Row? {
		return idToRowDictionary[id]
	}
	
	public func childrenIndexes(forIndex: Int) -> [Int] {
		guard let row = shadowTable?[forIndex] else { return [Int]() }
		var children = [Int]()
		
		func childrenVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				children.append(index)
			}
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: childrenVisitor) }
			}
		}

		if row.isExpanded ?? true {
			row.rows?.forEach { $0.visit(visitor: childrenVisitor(_:)) }
		}
		
		return children
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		var returnToSuspend = false
		if rows == nil {
			returnToSuspend = true
			load()
		}
		
		var md = "# \(title ?? "")\n\n"
		rows?.forEach { md.append($0.markdown(indentLevel: 0)) }
		
		if returnToSuspend {
			suspend()
		}
		
		return md
	}
	
	public func opml() -> String {
		var returnToSuspend = false
		if rows == nil {
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
		rows?.forEach { opml.append($0.opml()) }
		opml.append("</body>\n")
		opml.append("</opml>\n")

		if returnToSuspend {
			suspend()
		}

		return opml
	}
	
	public func toggleFavorite() {
		isFavorite = !(isFavorite ?? false)
		documentMetaDataDidChange()
	}
	
	public func toggleFilter() -> ShadowTableChanges {
		isFiltered = !(isFiltered ?? false)
		documentMetaDataDidChange()
		return rebuildShadowTable()
	}
	
	public func toggleNotesHidden() -> ShadowTableChanges {
		isNotesHidden = !(isNotesHidden ?? false)
		documentMetaDataDidChange()
		
		if let reloads = shadowTable?.filter({ !(($0.associatedRow as? TextRow)?.isNoteEmpty ?? true) }).compactMap({ $0.shadowTableIndex }) {
			return ShadowTableChanges(reloads: Set(reloads))
		} else {
			return ShadowTableChanges()
		}
	}
	
	public func update(title: String) {
		self.title = title
		self.updated = Date()
		documentTitleDidChange()
	}
	
	public func isCreateNoteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if let textRow = row.textRow, textRow.isNoteEmpty {
				return false
			}
		}
		return true
	}
	
	public func createNote(row: Row, textRowStrings: TextRowStrings?) -> ShadowTableChanges {
		guard let textRow = row.textRow else { return ShadowTableChanges() }
		if let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}

		if textRow.note == nil {
			textRow.note = NSAttributedString()
		}
		
		outlineBodyDidChange()
		
		guard let shadowTableIndex = shadowTable?.firstIndex(of: row) else { return ShadowTableChanges() }
		return ShadowTableChanges(reloads: [shadowTableIndex])
	}
	
	public func isDeleteNoteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if let textRow = row.textRow, !textRow.isNoteEmpty {
				return false
			}
		}
		return true
	}
	
	public func deleteNote(row: Row, textRowStrings: TextRowStrings?) -> ShadowTableChanges {
		guard let textRow = row.textRow else { return ShadowTableChanges() }
		if let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		textRow.note = nil
		
		outlineBodyDidChange()
		
		guard let shadowTableIndex = shadowTable?.firstIndex(of: row) else { return ShadowTableChanges() }
		return ShadowTableChanges(reloads: [shadowTableIndex])
	}
	
	public func deleteRow(_ row: Row, textRowStrings: TextRowStrings? = nil) -> ShadowTableChanges {
		if let textRow = row.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}
		
		var mutatingRow = row
		mutatingRow.parent?.rows?.removeFirst(object: row)
		
		outlineBodyDidChange()
		
		guard let rowShadowTableIndex = row.shadowTableIndex else { return ShadowTableChanges() }
		var deletes = [rowShadowTableIndex]
		
		func deleteVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				deletes.append(index)
			}
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: deleteVisitor) }
			}
		}

		if row.isExpanded ?? true {
			row.rows?.forEach { $0.visit(visitor: deleteVisitor(_:)) }
		}

		for index in deletes.reversed() {
			shadowTable?.remove(at: index)
		}
		
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		
		if rowShadowTableIndex > 0 {
			return ShadowTableChanges(deletes: Set(deletes), reloads: [rowShadowTableIndex - 1])
		} else {
			return ShadowTableChanges(deletes: Set(deletes))
		}
			
	}
	
	public func joinRows(topRow: Row, bottomRow: Row) -> ShadowTableChanges {
		guard let topTextRow = topRow.textRow,
			  let topTopic = topTextRow.topic,
			  let topShadowTableIndex = topRow.shadowTableIndex,
			  let bottomTopic = bottomRow.textRow?.topic else { return ShadowTableChanges() }
		
		let mutableText = NSMutableAttributedString(attributedString: topTopic)
		mutableText.append(bottomTopic)
		topTextRow.topic = mutableText
		
		var changes = deleteRow(bottomRow)
		changes.append(ShadowTableChanges(reloads: Set([topShadowTableIndex])))
		return changes
	}
	
	public func createRow(_ row: Row, beforeRow: Row, textRowStrings: TextRowStrings? = nil) -> ShadowTableChanges {
		if let beforeTextRow = beforeRow.textRow, let texts = textRowStrings {
			beforeTextRow.textRowStrings = texts
		}

		guard var parent = beforeRow.parent,
			  let index = parent.rows?.firstIndex(of: beforeRow),
			  let shadowTableIndex = beforeRow.shadowTableIndex else {
			return ShadowTableChanges()
		}
		
		parent.rows?.insert(row, at: index)
		var mutatingRow = row
		mutatingRow.parent = parent
		
		outlineBodyDidChange()

		shadowTable?.insert(row, at: shadowTableIndex)
		resetShadowTableIndexes(startingAt: shadowTableIndex)
		return ShadowTableChanges(inserts: [shadowTableIndex])
	}
	
	public func createRow(_ row: Row, afterRow: Row? = nil, textRowStrings: TextRowStrings? = nil) -> ShadowTableChanges {
		if let afterTextRow = afterRow?.textRow, let texts = textRowStrings {
			afterTextRow.textRowStrings = texts
		}

		if var parent = row.parent, parent as? Row == afterRow {
			parent.rows?.insert(row, at: 0)
		} else if var parent = row.parent {
			var rows = parent.rows ?? [Row]()
			let insertIndex = rows.firstIndex(where: { $0 == afterRow}) ?? rows.count - 1
			rows.insert(row, at: insertIndex + 1)
			parent.rows = rows
		} else if afterRow?.isExpanded ?? true && !(afterRow?.rows?.isEmpty ?? true) {
			var mutatingAfterRow = afterRow
			mutatingAfterRow!.rows!.insert(row, at: 0)
			var mutatingRow = row
			mutatingRow.parent = afterRow
		} else if var parent = afterRow?.parent {
			var rows = parent.rows ?? [Row]()
			let insertIndex = rows.firstIndex(where: { $0 == afterRow}) ?? -1
			rows.insert(row, at: insertIndex + 1)
			var mutatingRow = row
			mutatingRow.parent = afterRow?.parent
			parent.rows = rows
		} else {
			var rows = self.rows ?? [Row]()
			let insertIndex = rows.firstIndex(where: { $0 == afterRow}) ?? -1
			rows.insert(row, at: insertIndex + 1)
			var mutatingRow = row
			mutatingRow.parent = self
			self.rows = rows
		}
		
		outlineBodyDidChange()

		var rows = [row]
		
		func insertVisitor(_ visited: Row) {
			rows.append(visited)
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: insertVisitor) }
			}
		}

		if row.isExpanded ?? true {
			row.rows?.forEach { $0.visit(visitor: insertVisitor(_:)) }
		}
		
		let afterShadowTableIndex = afterRow?.shadowTableIndex ?? -1
		let rowShadowTableIndex = afterShadowTableIndex + 1

		var inserts = Set<Int>()
		for i in 0..<rows.count {
			let shadowTableIndex = rowShadowTableIndex + i
			inserts.insert(shadowTableIndex)
			shadowTable?.insert(rows[i], at: shadowTableIndex)
		}
		
		var mututingRow = row
		mututingRow.shadowTableIndex = rowShadowTableIndex
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		
		return ShadowTableChanges(inserts: inserts)
	}
	
	public func splitRow(newRow: Row, row: Row, topic: NSAttributedString, cursorPosition: Int) -> ShadowTableChanges {
		guard let newTextRow = newRow.textRow, let textRow = row.textRow else { return ShadowTableChanges() }
		
		let newTopicRange = NSRange(location: cursorPosition, length: topic.length - cursorPosition)
		let newTopicText = topic.attributedSubstring(from: newTopicRange)
		newTextRow.topic = newTopicText
		
		let topicRange = NSRange(location: 0, length: cursorPosition)
		let topicText = topic.attributedSubstring(from: topicRange)
		textRow.topic = topicText

		var changes = createRow(newRow, afterRow: row)
		if let rowShadowTableIndex = textRow.shadowTableIndex {
			changes.append(ShadowTableChanges(reloads: Set([rowShadowTableIndex])))
		}
		return changes
	}

	public func updateRow(_ row: Row, textRowStrings: TextRowStrings?) -> ShadowTableChanges {
		if let textRow = row.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		outlineBodyDidChange()
		guard let shadowTableIndex = row.shadowTableIndex else { return ShadowTableChanges() }
		return ShadowTableChanges(reloads: [shadowTableIndex])
	}
	
	public func expand(rows: [Row]) -> ([Row], ShadowTableChanges) {
		if rows.count == 1, let row = rows.first {
			return ([row], expand(row: row))
		}
		return expandCollapse(rows: rows, isExpanded: true)
	}
	
	public func collapse(rows: [Row]) -> ([Row], ShadowTableChanges) {
		if rows.count == 1, let row = rows.first {
			return ([row], collapse(row: row))
		}
		return expandCollapse(rows: rows, isExpanded: false)
	}
	
	public func isExpandAllUnavailable(containers: [RowContainer]) -> Bool {
		for container in containers {
			if !isExpandAllUnavailable(container: container) {
				return false
			}
		}
		return true
	}
	
	public func expandAll(containers: [RowContainer]) -> ([Row], ShadowTableChanges) {
		var impacted = [Row]()
		
		for container in containers {
			if let row = container as? Row, row.isExpandable {
				var mutatingRow = row
				mutatingRow.isExpanded = true
				impacted.append(row)
			}
			
			func expandVisitor(_ visited: Row) {
				if visited.isExpandable {
					var mutatingVisited = visited
					mutatingVisited.isExpanded = true
					impacted.append(visited)
				}
				visited.rows?.forEach { $0.visit(visitor: expandVisitor) }
			}

			container.rows?.forEach { $0.visit(visitor: expandVisitor(_:)) }
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(impacted.compactMap { $0.shadowTableIndex })
		changes.append(ShadowTableChanges(reloads: reloads))
		
		return (impacted, changes)
	}

	public func isCollapseAllUnavailable(containers: [RowContainer]) -> Bool {
		for container in containers {
			if !isCollapseAllUnavailable(container: container) {
				return false
			}
		}
		return true
	}
	
	public func collapseAll(containers: [RowContainer]) -> ([Row], ShadowTableChanges) {
		var impacted = [Row]()
		var reloads = [Row]()

		for container in containers {
			if let row = container as? Row, row.isCollapsable {
				var mutatingRow = row
				mutatingRow.isExpanded = false
				impacted.append(row)
			}
			
			func collapseVisitor(_ visited: Row) {
				if visited.isCollapsable {
					var mutatingVisited = visited
					mutatingVisited.isExpanded = false
					impacted.append(visited)
				}
				visited.rows?.forEach { $0.visit(visitor: collapseVisitor) }
			}

			if let row = container as? Row {
				reloads.append(row)
			}
			
			container.rows?.forEach {
				reloads.append($0)
				$0.visit(visitor: collapseVisitor(_:))
			}
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
	
		let reloadIndexes = Set(reloads.compactMap { $0.shadowTableIndex })
		changes.append(ShadowTableChanges(reloads: reloadIndexes))
		
		return (impacted, changes)
	}

	public func isCompleteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.isCompletable {
				return false
			}
		}
		return true
	}
	
	public func complete(rows: [Row], textRowStrings: TextRowStrings?) -> ([Row], ShadowTableChanges) {
		return completeUncomplete(rows: rows, isComplete: true, textRowStrings: textRowStrings)
	}
	
	public func isUncompleteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.isUncompletable {
				return false
			}
		}
		return true
	}
	
	public func uncomplete(rows: [Row], textRowStrings: TextRowStrings?) -> ([Row], ShadowTableChanges) {
		return completeUncomplete(rows: rows, isComplete: false, textRowStrings: textRowStrings)
	}
	
	public func isIndentRowsUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if let rowIndex = row.parent?.rows?.firstIndex(of: row), rowIndex > 0 {
				return false
			}
		}
		return true
	}
	
	public func indentRow(_ row: Row, textRowStrings: TextRowStrings?) -> ShadowTableChanges {
		if let textRow = row.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		
		guard var container = row.parent,
			  let rowIndex = container.rows?.firstIndex(of: row),
			  rowIndex > 0,
			  var newParentRow = container.rows?[rowIndex - 1] else { return ShadowTableChanges() }

		var expandChange = expand(row: newParentRow)
		
		// Null out the chevron row reload since we are going to add it below
		expandChange.reloads = nil
		
		guard let rowShadowTableIndex = row.shadowTableIndex,
			  let newParentRowShadowTableIndex = newParentRow.shadowTableIndex else { return expandChange }

		var siblingRows = newParentRow.rows ?? [Row]()
		var mutatingRow = row
		mutatingRow.parent = newParentRow
		siblingRows.append(row)
		newParentRow.rows = siblingRows
		container.rows?.removeFirst(object: row)

		newParentRow.isExpanded = true
		outlineBodyDidChange()
		
		var reloads = Set<Int>()
		reloads.insert(newParentRowShadowTableIndex)
		reloads.insert(rowShadowTableIndex)

		func reloadVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		if row.isExpanded ?? true {
			row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
		}

		expandChange.append(ShadowTableChanges(reloads: reloads))
		return expandChange

	}
	
	public func isOutdentRowsUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.indentLevel != 0 {
				return false
			}
		}
		return true
	}
		
	public func outdentRow(_ row: Row, textRowStrings: TextRowStrings?) -> ShadowTableChanges {
		if let textRow = row.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}

		guard var oldParent = row.parent as? Row,
			  let oldParentRows = oldParent.rows,
			  let oldParentShadowTableIndex = oldParent.shadowTableIndex,
			  let originalRowShadowTableIndex = row.shadowTableIndex else { return ShadowTableChanges() }
		
		guard let oldRowIndex = oldParentRows.firstIndex(of: row) else { return ShadowTableChanges() }
		var siblingsToMove = [Row]()
		for i in (oldRowIndex + 1)..<oldParentRows.count {
			siblingsToMove.append(oldParentRows[i])
		}

		oldParent.rows?.removeFirst(object: row)

		if var newParent = oldParent.parent, let oldParentIndex = newParent.rows?.firstIndex(of: oldParent) {
			newParent.rows?.insert(row, at: oldParentIndex + 1)
		} else {
			if let oldParentIndex = rows?.firstIndex(of: oldParent) {
				rows?.insert(row, at: oldParentIndex + 1)
			}
		}
		
		var mutatingRow = row
		mutatingRow.parent = oldParent.parent

		outlineBodyDidChange()

		var reloads = Set([oldParentShadowTableIndex])
		var moves = Set<ShadowTableChanges.Move>()
		var workingShadowTableIndex = originalRowShadowTableIndex
		
		if siblingsToMove.isEmpty {
			reloads.insert(originalRowShadowTableIndex)
			
			func reloadVisitor(_ visited: Row) {
				if let index = visited.shadowTableIndex {
					reloads.insert(index)
				}
				if visited.isExpanded ?? true {
					visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
				}
			}
			
			if row.isExpanded ?? true {
				row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		} else {
			
			func shadowTableRemoveVisitor(_ visited: Row) {
				if visited.isExpanded ?? true {
					visited.rows?.reversed().forEach {	$0.visit(visitor: shadowTableRemoveVisitor)	}
				}
				if let visitedShadowTableIndex = visited.shadowTableIndex {
					shadowTable?.remove(at: visitedShadowTableIndex)
				}
			}

			if row.isExpanded ?? true {
				row.rows?.reversed().forEach { $0.visit(visitor: shadowTableRemoveVisitor(_:)) }
			}
			shadowTable?.remove(at: originalRowShadowTableIndex)

			func movingUpVisitor(_ visited: Row) {
				if let visitedShadowTableIndex = visited.shadowTableIndex {
					moves.insert(ShadowTableChanges.Move(visitedShadowTableIndex, workingShadowTableIndex))
					workingShadowTableIndex = workingShadowTableIndex + 1
				}
				if visited.isExpanded ?? true {
					visited.rows?.forEach { $0.visit(visitor: movingUpVisitor)	}
				}
			}

			for sibling in siblingsToMove {
				if let siblineShadowTableIndex = sibling.shadowTableIndex {
					moves.insert(ShadowTableChanges.Move(siblineShadowTableIndex, workingShadowTableIndex))
					workingShadowTableIndex = workingShadowTableIndex + 1
					if sibling.isExpanded ?? true {
						sibling.rows?.forEach { $0.visit(visitor: movingUpVisitor(_:)) }
					}
				}
			}
			
			moves.insert(ShadowTableChanges.Move(originalRowShadowTableIndex, workingShadowTableIndex))
			reloads.insert(workingShadowTableIndex)
			shadowTable?.insert(row, at: workingShadowTableIndex)

			func shadowTableInsertVisitor(_ visited: Row) {
				if let visitedShadowTableIndex = visited.shadowTableIndex {
					workingShadowTableIndex = workingShadowTableIndex + 1
					shadowTable?.insert(visited, at: workingShadowTableIndex)
					moves.insert(ShadowTableChanges.Move(visitedShadowTableIndex, workingShadowTableIndex))
					reloads.insert(workingShadowTableIndex)
				}
				if visited.isExpanded ?? true {
					visited.rows?.forEach { $0.visit(visitor: shadowTableInsertVisitor) }
				}
			}

			if row.isExpanded ?? true {
				row.rows?.forEach { $0.visit(visitor: shadowTableInsertVisitor(_:)) }
			}
		}
		
		resetShadowTableIndexes(startingAt: originalRowShadowTableIndex)
		return ShadowTableChanges(moves: moves, reloads: reloads)
	}
	
	public func moveRow(_ row: Row, textRowStrings: TextRowStrings? = nil, toParent: RowContainer, childIndex: Int) -> ShadowTableChanges {
		if let textRow = row.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		// Move the row in the tree
		var mutatingRow = row
		var mutatingToParent = toParent
		mutatingRow.parent?.rows?.removeFirst(object: row)
		if toParent.rows == nil {
			mutatingToParent.rows = [row]
		} else {
			mutatingToParent.rows!.insert(row, at: childIndex)
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		guard let shadowTableIndex = shadowTable?.firstIndex(of: row) else {
			return changes
		}

		var reloads = [shadowTableIndex]
		if shadowTableIndex > 0 {
			reloads.append(shadowTableIndex - 1)
		}
		
		func reloadVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				reloads.append(index)
			}
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		if row.isExpanded ?? true {
			row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
		}

		changes.append(ShadowTableChanges(reloads: Set(reloads)))
		return changes
	}
	
	public func load() {
		rowsFile = RowsFile(outline: self)
		rowsFile!.load()
		rebuildTransientData()
	}
	
	public func save() {
		rowsFile?.save()
	}
	
	public func forceSave() {
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		rowsFile?.markAsDirty()
		rowsFile?.save()
	}
	
	public func delete() {
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		rowsFile?.delete()
		rowsFile = nil
		outlineDidDelete()
	}
	
	public func suspend() {
		rowsFile?.save()
		rowsFile = nil
		rows = nil
		shadowTable = nil
		_idToRowDictionary = [String: Row]()
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
}

// MARK: CustomDebugStringConvertible

extension Outline: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		var output = ""
		for row in rows ?? [Row]() {
			output.append(dumpRow(level: 0, row: row))
		}
		return output
	}
	
	private func dumpRow(level: Int, row: Row) -> String {
		var output = ""
		for _ in 0..<level {
			output.append(" -- ")
		}
		output.append(row.debugDescription)
		output.append("\n")
		
		for child in row.rows ?? [Row]() {
			output.append(dumpRow(level: level + 1, row: child))
		}
		
		return output
	}
	
}

// MARK: Helpers

extension Outline {
	
	private func documentTitleDidChange() {
		NotificationCenter.default.post(name: .DocumentTitleDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func documentMetaDataDidChange() {
		NotificationCenter.default.post(name: .DocumentMetaDataDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func outlineBodyDidChange() {
		self.updated = Date()
		documentMetaDataDidChange()
		rowDictionaryNeedUpdate = true
		rowsFile?.markAsDirty()
		NotificationCenter.default.post(name: .OutlineBodyDidChange, object: self, userInfo: nil)
	}
	
	private func outlineDidDelete() {
		NotificationCenter.default.post(name: .DocumentDidDelete, object: Document.outline(self), userInfo: nil)
	}
	
	private func completeUncomplete(rows: [Row], isComplete: Bool, textRowStrings: TextRowStrings?) -> ([Row], ShadowTableChanges) {
		if rows.count == 1, let textRow = rows.first?.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		
		var impacted = [Row]()
		
		for row in rows {
			if isComplete != row.isComplete ?? false {
				row.textRow?.isComplete = isComplete
				impacted.append(row)
			}
		}
		
		outlineBodyDidChange()
		
		if isFiltered ?? false {
			return (impacted, rebuildShadowTable())
		}
		
		var reloads = Set<Int>()
		
		for row in impacted {
			if let shadowTableIndex = row.shadowTableIndex {
				reloads.insert(shadowTableIndex)
			
				func reloadVisitor(_ visited: Row) {
					if let index = visited.shadowTableIndex {
						reloads.insert(index)
					}
					if visited.isExpanded ?? true {
						visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
					}
				}

				if row.isExpanded ?? true {
					row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
				}
			}
		}
		
		return (impacted, ShadowTableChanges(reloads: reloads))
	}

	private func isExpandAllUnavailable(container: RowContainer) -> Bool {
		if let row = container as? Row, row.isExpandable {
			return false
		}

		var unavailable = true
		
		func expandedRowVisitor(_ visited: Row) {
			for row in visited.rows ?? [Row]() {
				unavailable = !row.isExpandable
				if !unavailable {
					break
				}
				row.visit(visitor: expandedRowVisitor)
				if !unavailable {
					break
				}
			}
		}

		for row in container.rows ?? [Row]() {
			unavailable = !row.isExpandable
			if !unavailable {
				break
			}
			row.visit(visitor: expandedRowVisitor)
			if !unavailable {
				break
			}
		}
		
		return unavailable
	}
	
	private func expandCollapse(rows: [Row], isExpanded: Bool) -> ([Row], ShadowTableChanges) {
		var impacted = [Row]()
		
		for row in rows {
			if isExpanded != row.isExpanded ?? true {
				var mutatingRow = row
				mutatingRow.isExpanded = isExpanded
				impacted.append(mutatingRow)
			}
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(rows.compactMap { $0.shadowTableIndex })
		changes.append(ShadowTableChanges(reloads: reloads))
		
		return (impacted, changes)
	}
	
	private func expand(row: Row) -> ShadowTableChanges {
		guard !(row.isExpanded ?? true), let rowShadowTableIndex = row.shadowTableIndex else {
			return ShadowTableChanges()
		}
		
		var mutatingRow = row
		mutatingRow.isExpanded = true

		var shadowTableInserts = [Row]()

		func visitor(_ visited: Row) {
			let shouldFilter = isFiltered ?? false && visited.isComplete ?? false
			
			if !shouldFilter {
				shadowTableInserts.append(visited)

				if visited.isExpanded ?? true {
					visited.rows?.forEach {
						$0.visit(visitor: visitor)
					}
				}
			}
		}

		row.rows?.forEach { row in
			row.visit(visitor: visitor(_:))
		}
		
		var inserts = Set<Int>()
		for i in 0..<shadowTableInserts.count {
			let newIndex = i + rowShadowTableIndex + 1
			shadowTable?.insert(shadowTableInserts[i], at: newIndex)
			inserts.insert(newIndex)
		}
		
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		return ShadowTableChanges(inserts: inserts, reloads: [rowShadowTableIndex])
	}

	private func isCollapseAllUnavailable(container: RowContainer) -> Bool {
		if let row = container as? Row, row.isCollapsable {
			return false
		}
		
		var unavailable = true
		
		func collapsedRowVisitor(_ visited: Row) {
			for row in visited.rows ?? [Row]() {
				unavailable = !row.isCollapsable
				if !unavailable {
					break
				}
				row.visit(visitor: collapsedRowVisitor)
				if !unavailable {
					break
				}
			}
		}

		for row in container.rows ?? [Row]() {
			unavailable = !row.isCollapsable
			if !unavailable {
				break
			}
			row.visit(visitor: collapsedRowVisitor)
			if !unavailable {
				break
			}
		}
		
		return unavailable
	}
	
	private func collapse(row: Row) -> ShadowTableChanges {
		guard row.isExpanded ?? true else { return ShadowTableChanges() }

		var mutatingRow = row
		mutatingRow.isExpanded = false
			
		var reloads = Set<Int>()

		func visitor(_ visited: Row) {
			if let shadowTableIndex = visited.shadowTableIndex {
				reloads.insert(shadowTableIndex)
			}

			if visited.isExpanded ?? true {
				visited.rows?.forEach {
					$0.visit(visitor: visitor)
				}
			}
		}
		
		row.rows?.forEach { row in
			row.visit(visitor: visitor(_:))
		}
		
		shadowTable?.remove(atOffsets: IndexSet(reloads))
		
		guard let rowShadowTableIndex = row.shadowTableIndex else { return ShadowTableChanges() }
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		return ShadowTableChanges(deletes: reloads, reloads: Set([rowShadowTableIndex]))
	}
	
	func rebuildRowDictionary() {
		var idDictionary = [String: Row]()
		
		func dictBuildVisitor(_ visited: Row) {
			idDictionary[visited.id] = visited
			visited.rows?.forEach { $0.visit(visitor: dictBuildVisitor) }
		}

		rows?.forEach { $0.visit(visitor: dictBuildVisitor(_:)) }
		
		_idToRowDictionary = idDictionary
		rowDictionaryNeedUpdate = false
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
		rows?.forEach { row in
			var mutatingRow = row
			mutatingRow.parent = self
			row.visit(visitor: transient.visitor(_:))
		}
		self.shadowTable = transient.shadowTable
	}
	
	private func resetShadowTableIndexes(startingAt: Int = 0) {
		guard var shadowTable = shadowTable else { return }
		for i in startingAt..<shadowTable.count {
			shadowTable[i].shadowTableIndex = i
		}
	}
	
}
