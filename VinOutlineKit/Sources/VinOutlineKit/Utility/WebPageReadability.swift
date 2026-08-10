//
//  WebPageReadability.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 8/5/26.
//

import Foundation
import OSLog
import VinReadability
import VinXML

/// Downloads a web page, extracts its readable article content using VinReadability, and downloads
/// any images referenced by that content so they can be embedded in an Outline.
struct WebPageReadability {

	/// The readable content extracted from a web page.
	struct Content: Sendable {
		/// The article title as determined by Readability, if any.
		let title: String?
		/// The cleaned article HTML produced by Readability.
		let html: String
		/// The downloaded image data, keyed by the `src` attribute value as it appears in `html`.
		let images: [String: Data]
	}

	private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VinOutlineKit", category: "VinOutlineKit")

	/// Fetches the given URL, runs it through Readability, and downloads its images.
	///
	/// - Throws: `AccountError.webPageDownloadError` if the page can't be fetched,
	///   `AccountError.webPageParserError` if Readability can't extract content.
	static func fetch(url: URL) async throws -> Content {
		guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
			  let scheme = urlComponents.scheme,
			  scheme.starts(with: "http") else {
			throw AccountError.webPageDownloadError
		}

		let html: String
		do {
			let (data, _) = try await URLSession.shared.data(from: url)
			guard let decoded = String(data: data, encoding: .utf8) else {
				throw AccountError.webPageDownloadError
			}
			html = decoded
		} catch {
			logger.error("Unable to download web page for URL: \(url.absoluteString, privacy: .public) with error: \(error.localizedDescription, privacy: .public)")
			throw AccountError.webPageDownloadError
		}

		let article: ReadabilityArticle?
		do {
			let readability = try await Readability()
			article = try await readability.parse(html: html, url: url.absoluteString)
		} catch {
			logger.error("Readability failed for URL: \(url.absoluteString, privacy: .public) with error: \(error.localizedDescription, privacy: .public)")
			throw AccountError.webPageParserError
		}

		guard let content = article?.content, !content.isEmpty else {
			throw AccountError.webPageParserError
		}

		// Readability can hand back double-encoded content, so an escaped non-breaking space
		// arrives as "&amp;amp;nbsp;". Unwind the extra "&amp;" layers first (a single pass
		// can't, since replacing doesn't re-scan text it just inserted), then collapse the
		// resulting "&nbsp;" and literal non-breaking spaces.
		var cleanedContent = content
		while cleanedContent.contains("&amp;") {
			cleanedContent = cleanedContent.replacing("&amp;", with: "&")
		}
		cleanedContent = cleanedContent
			.replacing("&nbsp;", with: " ")
			.replacing("\u{00A0}", with: " ")

		let images = await downloadImages(contentHTML: cleanedContent, baseURL: url)

		return Content(title: article?.title, html: cleanedContent, images: images)
	}

}

private extension WebPageReadability {

	/// Reads an `<img>` element's source, preferring `src` and falling back to `data-src`.
	/// Both this method and `ImportWebPageParser` use it so the download keys line up with lookups.
	static func imageSource(for node: VinXML.XMLNode) -> String? {
		node.attributes["src"] ?? node.attributes["data-src"]
	}

	/// Downloads every image referenced in the content HTML, keyed by the original `src` value.
	static func downloadImages(contentHTML: String, baseURL: URL) async -> [String: Data] {
		// Do all VinXML work synchronously up front so no non-Sendable node crosses an await.
		var sources = [String]()
		if let doc = try? VinXML.XMLDocument(html: contentHTML),
		   let imageNodes = try? doc.query(xpath: "//img") {
			for node in imageNodes {
				if let source = imageSource(for: node), !sources.contains(source) {
					sources.append(source)
				}
			}
		}

		guard !sources.isEmpty else { return [:] }

		return await withTaskGroup(of: (String, Data?).self) { group in
			for source in sources {
				group.addTask {
					guard let resolved = URL(string: source, relativeTo: baseURL)?.absoluteURL,
						  let scheme = resolved.scheme,
						  scheme.starts(with: "http") else {
						return (source, nil)
					}
					let data = try? await URLSession.shared.data(from: resolved).0
					return (source, data)
				}
			}

			var results = [String: Data]()
			for await (source, data) in group {
				if let data {
					results[source] = data
				}
			}
			return results
		}
	}

}
