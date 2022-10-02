//
//  WebPageTitle.swift
//  Zavala
//
//  Created by Maurice Parker on 9/30/22.
//

import Foundation
import RSCore
import VinXML

struct WebPageTitle: Logging {
	
	static func find(forURL url: URL, completion: @escaping (String?) -> ()) {
		func finish(_ result:String? = nil) {
			DispatchQueue.main.async {
				completion(result)
			}
		}
		
		guard let scheme = URLComponents(url: url, resolvingAgainstBaseURL: false)?.scheme, scheme.starts(with: "http") else {
			finish()
			return
		}

		
		let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
			if let error = error {
				logger.error("Download failed for URL: \(url.absoluteString, privacy: .public) with error: \(error.localizedDescription, privacy: .public)")
				finish()
				return
			}
			
			guard let data = data, let html = String(data: data, encoding: .utf8) else {
				logger.error("Unable to convert result to String for URL: \(url.absoluteString, privacy: .public)")
				finish()
				return
			}
			
			guard let doc = try? VinXML.XMLDocument(html: html) else {
				logger.error("Unable to parse using VinXML.XMLDocument for URL: \(url.absoluteString, privacy: .public)")
				finish()
				return
			}
			
			do {
				try finish(Self.extractTitle(doc: doc))
			} catch {
				logger.error("Can't extract Title for URL: \(url.absoluteString, privacy: .public) with error: \(error.localizedDescription, privacy: .public)")
				finish()
			}
		}
		
		dataTask.resume()
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
		
		// Fix these messed up compound titles that web designers like to use.
		for weird in [" | ", " • ", " › ", " :: ", " » ", " - ", " : ", " — ", " · "] {
			if let range = unparsedTitle.range(of: weird) {
				let result = String(unparsedTitle[..<range.lowerBound]).trimmingWhitespace
				return result.isEmpty ? nil : result
			}
		}
		
		let result = unparsedTitle.trimmingWhitespace
		return result.isEmpty ? nil : result
	}
	
}
