//
//  VinOutlineKitStringAssets.swift
//  
//
//  Created by Maurice Parker on 10/6/22.
//
import Foundation

struct VinOutlineKitStringAssets {
	
	static var accountOnMyMac = String(localized: "On My Mac", comment: "Local Account Name: On My Mac")
	static var accountOnMyIPad = String(localized: "On My iPad", comment: "Local Account Name: On My iPad")
	static var accountOnMyIPhone = String(localized: "On My iPhone", comment: "Local Account Name: On My iPhone")
	static var accountICloud = String(localized: "iCloud", comment: "iCloud Account Name: iCloud")

	static var all = String(localized: "All", comment: "Collection: Search Documents")
	static var search = String(localized: "Search", comment: "Collection: Search Documents")

	static var accountErrorScopedResource =	String(localized: "Unable to access security scoped resource.",
												   comment: "Error Message: Unable to access security scoped resource.")
	
	static var accountErrorImportRead = String(localized: "Unable to read the import file.",
											   comment: "Error Message: Unable to read the import file.")
	static var accountErrorOPMLParse = String(localized: "Unable to process the OPML data.",
											   comment: "Error Message: Unable to read the import file.")

}

private extension String {
	
	init(localized: String, comment: String? = nil) {
		self = localized
	}
	
}
