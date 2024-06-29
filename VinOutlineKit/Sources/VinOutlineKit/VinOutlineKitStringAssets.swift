//
//  VinOutlineKitStringAssets.swift
//  
//
//  Created by Maurice Parker on 10/6/22.
//
import Foundation

struct VinOutlineKitStringAssets {
	
	static let accountOnMyMac = String(localized: "On My Mac", comment: "Local Account Name: On My Mac")
	static let accountOnMyIPad = String(localized: "On My iPad", comment: "Local Account Name: On My iPad")
	static let accountOnMyIPhone = String(localized: "On My iPhone", comment: "Local Account Name: On My iPhone")
	static let accountICloud = String(localized: "iCloud", comment: "iCloud Account Name: iCloud")

	static let noTitle = String(localized: "(No Title)", comment: "OPML Export Title: (No Title)")
	static let all = String(localized: "All", comment: "Collection: All Documents")
	static let search = String(localized: "Search", comment: "Collection: Search Documents")

	static let accountErrorImportRead = String(localized: "Unable to read the import file.",
											   comment: "Error Message: Unable to read the import file.")
	static let accountErrorOPMLParse = String(localized: "Unable to process the OPML data.",
											   comment: "Error Message: Unable to read the import file.")
	static let accountErrorRenameTagExists = String(localized: "This Tag name already exists. Please choose a different name.",
												   comment: "Error Message: This Tag name already exists. Please choose a different name.")
	static let accountErrorScopedResource =	String(localized: "Unable to access security scoped resource.",
												   comment: "Error Message: Unable to access security scoped resource.")

	static let rowDeserializationError = String(localized: "Unable to deserialize the row data.",
												comment: "Error Message: Unable to deserialize the row data.")

}
