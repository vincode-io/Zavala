import Foundation
import Testing
@testable import VinOutlineKit

final class ReplaceSearchResultCommandTests: VOKTestCase {
    @Test("ReplaceSearchResultCommand replaces a search result and is undoable")
    func replaceSearchResultAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let newString = "Replaced"
        let coordinates = [SearchResultCoordinates(isCurrentResult: true, row: row, isInNotes: false, range: NSRange(location: 0, length: row.topic?.length ?? 0))]
        let command = ReplaceSearchResultCommand(actionName: "ReplaceSearchResult", undoManager: undoManager, delegate: self, outline: outline, coordinates: coordinates, replacementText: newString)
        command.execute()
        #expect(row.topic?.string == "Replaced")
        undoManager.undo()
        #expect(row.topic?.string != "Replaced")
        undoManager.redo()
        #expect(row.topic?.string == "Replaced")
        deleteAccountManager(accountManager)
    }
}
