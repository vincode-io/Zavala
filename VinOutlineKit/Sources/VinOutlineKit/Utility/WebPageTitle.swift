//
//  WebPageTitle.swift
//  Zavala
//
//  Created by Maurice Parker on 9/30/22.
//

import Foundation
import OSLog
import VinUtility
import VinXML

struct WebPageTitle {
	
	private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")

	static func find(forURL url: URL) async -> String? {
		guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
			  let scheme = urlComponents.scheme,
			  scheme.starts(with: "http") else {
			return nil
		}

		guard let (data, _) = try? await URLSession.shared.data(from: url) else {
			return nil
		}
		
		guard let html = String(data: data, encoding: .utf8) else {
			logger.error("Unable to convert result to String for URL: \(url.absoluteString, privacy: .public)")
			return nil
		}
		
		guard let doc = try? VinXML.XMLDocument(html: html) else {
			logger.error("Unable to parse using VinXML.XMLDocument for URL: \(url.absoluteString, privacy: .public)")
			return nil
		}
		
		do {
			return try Self.extractTitle(doc: doc)
		} catch {
			logger.error("Can't extract Title for URL: \(url.absoluteString, privacy: .public) with error: \(error.localizedDescription, privacy: .public)")
			return nil
		}
	}
	
}

private extension WebPageTitle {
	
	private static func extractTitle(doc: VinXML.XMLDocument) throws -> String? {
		var title: String?
		
		let titlePath = "//*/meta[@property='og:title' or @name='og:title' or @property='twitter:title' or @name='twitter:title']"
		if let node = try doc.queryFirst(xpath: titlePath) {
			title = node.attributes["content"]
		}
		
		if title == nil {
			if let node = try doc.queryFirst(xpath: "//*/title") {
				title = node.text
			}
		}
		
		guard let unparsedTitle = title else {
			return nil
		}

		return WebPageTitleCleaner.clean(unparsedTitle)
	}
	
}
