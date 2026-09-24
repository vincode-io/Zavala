//
//  MarkdownDocHeadingLinks.swift
//
//
//  Created by Maurice Parker on 9/24/26.
//

import Foundation
import UniformTypeIdentifiers
import VinUtility

/// Builds the links that the Markdown Doc export uses for Row Links that point at a Row which is
/// exported as a heading.
///
/// Row Links into the Outline being exported become a link to the heading's anchor. Row Links into
/// other Outlines become a link to the other Outline's exported file and heading anchor, but only
/// when alt links are requested. Alt links indicate that the other Outlines are being exported
/// alongside this one.
@MainActor
struct MarkdownDocHeadingLinks {

	let outline: Outline
	let linkType: UTType
	let useAltLinks: Bool

	/// Maps the ID of each Row that can be linked to onto the link that the export should use for it.
	func build() -> [String: String] {
		var headingLinks = [String: String]()

		for (rowID, slug) in headingSlugs(for: outline) {
			headingLinks[rowID] = "#\(escaped(slug))"
		}

		guard useAltLinks else { return headingLinks }

		for documentID in linkedDocumentIDs() {
			guard let document = outline.account?.accountManager?.findDocument(documentID),
				  let linkedOutline = document.outline else { continue }

			let filename = escaped(document.filename(type: linkType))

			linkedOutline.load()

			for (rowID, slug) in headingSlugs(for: linkedOutline) {
				headingLinks[rowID] = "\(filename)#\(escaped(slug))"
			}

			Task {
				await linkedOutline.unload()
			}
		}

		return headingLinks
	}

}

private extension MarkdownDocHeadingLinks {

	/// Maps the ID of each Row that the given Outline exports as a heading onto the heading's slug.
	/// The export itself is used to find the headings, which guarantees that we only generate slugs
	/// for Rows that really do render as a heading.
	func headingSlugs(for outline: Outline) -> [String: String] {
		let visitor = MarkdownDocVisitor(useAltLinks: false, useSidecar: false, linkType: linkType)
		outline.rows.forEach {
			$0.visit(visitor: visitor.visitor)
		}

		var slugs = [String: String]()
		var slugCounts = [String: Int]()

		for headingRow in visitor.headingRows {
			let slug = Self.slug(for: headingRow.topic?.string ?? "")
			guard !slug.isEmpty else { continue }

			// Markdown renderers disambiguate repeated headings by appending the number of times
			// that they have already seen the slug.
			let slugCount = slugCounts[slug] ?? 0
			slugCounts[slug] = slugCount + 1
			slugs[headingRow.id] = slugCount == 0 ? slug : "\(slug)-\(slugCount)"
		}

		return slugs
	}

	/// The EntityIDs of the other Documents that the Outline being exported has Row Links into.
	func linkedDocumentIDs() -> Set<EntityID> {
		var documentIDs = Set<EntityID>()

		func visitor(_ visited: Row) {
			for attrString in [visited.topic, visited.note].compactMap({ $0 }) {
				attrString.enumerateAttribute(.link, in: .init(location: 0, length: attrString.length), options: []) { (value, _, _) in
					guard let url = value as? URL,
						  case .row(let accountID, let documentUUID, _)? = EntityID(url: url),
						  documentUUID != outline.id.documentUUID else { return }

					documentIDs.insert(.document(accountID, documentUUID))
				}
			}

			visited.rows.forEach {
				$0.visit(visitor: visitor)
			}
		}

		outline.rows.forEach {
			$0.visit(visitor: visitor)
		}

		return documentIDs
	}

	func escaped(_ urlComponent: String) -> String {
		// Anything that would be mistaken for a URL delimiter, especially the pound sign that
		// separates a filename from its anchor, has to be percent encoded.
		return urlComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? urlComponent
	}

}

extension MarkdownDocHeadingLinks {

	/// Converts heading text into the slug that Markdown renderers generate for its anchor. The text
	/// is lowercased, spaces become hyphens and everything other than letters, numbers, hyphens and
	/// underscores is dropped.
	static func slug(for text: String) -> String {
		var slug = String()

		for character in text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
			if character.isLetter || character.isNumber || character == "-" || character == "_" {
				slug.append(character)
			} else if character.isWhitespace {
				slug.append("-")
			}
		}

		return slug
	}

}
