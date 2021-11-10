//
//  DataRepresentation.swift
//  
//
//  Created by Maurice Parker on 11/10/21.
//

import Foundation

public struct DataRepresentation {
	
	public let suffix: String
	public let typeIdentifier: StringLiteralType
	
	public static let opml = DataRepresentation(suffix: "opml", typeIdentifier: "org.opml.opml")
	public static let markdown = DataRepresentation(suffix: "md", typeIdentifier: "net.daringfireball.markdown")
	public static let pdf = DataRepresentation(suffix: "pdf", typeIdentifier: "com.adobe.pdf")

}
