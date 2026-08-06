//
//  WebPageTitleCleaner.swift
//  Zavala
//
//  Created by Maurice Parker on 8/6/26.
//

import Foundation
import VinUtility

/// Cleans up the compound titles that web designers like to append to web page titles, such as
/// "Article Name - Site Name" or "Article Name | Site Name", leaving just the meaningful portion.
struct WebPageTitleCleaner {

	/// The delimiters used to separate the meaningful part of a title from the site branding that
	/// often follows it.
	private static let compoundDelimiters = Set([": ", " | ", " • ", " › ", " :: ", " » ", " - ", " — ", " · "])

	/// Strips trailing site branding from a web page title and trims surrounding whitespace.
	/// - Parameter title: The raw title extracted from a web page.
	/// - Returns: The cleaned title, or `nil` if the title is empty after trimming.
	static func clean(_ title: String) -> String? {
		// Fix these messed up compound titles that web designers like to use.
		var allRanges = [Range<String.Index>]()
		for compoundDelimiter in compoundDelimiters {
			if let range = title.range(of: compoundDelimiter, options: .backwards) {
				allRanges.append(range)
			}
		}

		// If there is lots of the compound delimiters in the title, we'll allow one of them
		switch allRanges.count {
		case 0:
			return title.trimmed()
		case 1:
			return String(title[..<allRanges[0].lowerBound]).trimmed()
		default:
			let sortedRanges = allRanges.sorted(by: { $0.lowerBound < $1.lowerBound } )
			return String(title[..<sortedRanges[1].lowerBound]).trimmed()
		}
	}

}
