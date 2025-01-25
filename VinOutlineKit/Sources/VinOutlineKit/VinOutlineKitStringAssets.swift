//
//  VinOutlineKitStringAssets.swift
//  
//
//  Created by Maurice Parker on 10/6/22.
//
import Foundation

struct VinOutlineKitStringAssets {
	
    static let accountOnMyMac = String(localized: "label.text.on-my-mac", bundle: .module, comment: "Local Account Name: On My Mac")
	static let accountOnMyIPad = String(localized: "label.text.on-my-ipad", bundle: .module, comment: "Local Account Name: On My iPad")
	static let accountOnMyIPhone = String(localized: "label.text.on-my-iphone", bundle: .module, comment: "Local Account Name: On My iPhone")
	static let accountICloud = String(localized: "iCloud", bundle: .module, comment: "iCloud Account Name: iCloud")

	static let noTitle = String(localized: "label.text.no-title", bundle: .module, comment: "Label: (No Title)")
	static let all = String(localized: "label.text.all", bundle: .module, comment: "Label: All")
	static let search = String(localized: "label.text.search", bundle: .module,  comment: "Label: Search")

	static let accountErrorImportRead = String(localized: "label.text.unable-to-read-import-file",
                                               bundle: .module, comment: "Label: Unable to read the import file.")
	static let accountErrorOPMLParse = String(localized: "label.text.unable-to-process-opml",
                                              bundle: .module, comment: "Label: Unable to process the OPML data.")
	static let accountErrorRenameTagExists = String(localized: "label.text.tag-already-exists",
                                                    bundle: .module, comment: "Label: This Tag name already exists. Please choose a different name.")
	static let accountErrorScopedResource =	String(localized: "label.text.unable-to-access-security-scoped-resoruces",
                                                   bundle: .module, comment: "Label: Unable to access security scoped resource.")

	static let rowDeserializationError = String(localized: "label.text.unable-to-deserialize-row-data",
                                                bundle: .module, comment: "Label: Unable to deserialize the row data.")

}
