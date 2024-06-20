//
//  Created by Maurice Parker on 6/20/24.
//

import Foundation
import UniformTypeIdentifiers
import Markdown
import VinOutlineKit

extension RowGroup {
	
	@MainActor
	public static func fromRowItemProviders(_ itemProviders: [NSItemProvider]) async throws -> [RowGroup] {
		var rowGroups = [RowGroup]()
		
		for itemProvider in itemProviders {
			let rowGroup = try await withCheckedThrowingContinuation { continuation in
				itemProvider.loadDataRepresentation(forTypeIdentifier: Row.typeIdentifier) { (data, error) in
					if let data {
						do {
							let rowGroup = try RowGroup.fromData(data)
							continuation.resume(returning: rowGroup)
						} catch {
							continuation.resume(throwing: error)
						}
					}
				}
			}
			rowGroups.append(rowGroup)
		}

		return rowGroups
	}

	@MainActor
	public static func fromTextItemProviders(_ itemProviders: [NSItemProvider]) async -> [RowGroup] {
		var textDrops = [TextDrop]()
		
		for itemProvider in itemProviders {
			let itemText: String? = await withCheckedContinuation { continuation in
				itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier) { (data, error) in
					if let data, let itemText = String(data: data, encoding: .utf8) {
						continuation.resume(returning: itemText)
					} else {
						continuation.resume(returning: nil)
					}
				}
			}

			let itemURL: String? = await withCheckedContinuation { continuation in
				itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.url.identifier) { (data, error) in
					if let data, let itemURL = String(data: data, encoding: .utf8) {
						continuation.resume(returning: itemURL)
					} else {
						continuation.resume(returning: nil)
					}
				}
			}

			if let itemText {
				textDrops.append(TextDrop(text: itemText, urlString: itemURL))
			}
		}
		
		guard !textDrops.isEmpty else { return [] }
		
		var text = String()
		for textDrop in textDrops {
			text.append(textDrop.markdownStrings.joined(separator: "\n"))
		}

		let document = Markdown.Document(parsing: text)
		var walker = SimpleRowWalker()
		walker.visit(document)
		
		var rowGroups = [RowGroup]()
		for row in walker.rows {
			rowGroups.append(RowGroup(row))
		}
		return rowGroups
	}

}

private struct TextDrop {
	
	var text: String
	var urlString: String?
	
	init(text: String, urlString: String? = nil) {
		self.text = text
		self.urlString = urlString
	}
	
	var markdownStrings: [String] {
		guard let urlString, let url = URL(string: urlString) else {
			return text.split(separator: "\n").map { NSAttributedString(string: String($0)).markdownRepresentation }
		}
		
		let attrString = NSMutableAttributedString(string: text)
		attrString.setAttributes([NSAttributedString.Key.link: url], range: .init(location: 0, length: text.count))

		return [attrString.markdownRepresentation]
	}
	
}
