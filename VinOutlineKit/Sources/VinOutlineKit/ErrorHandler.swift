//
//  ErrorHandler.swift
//  File
//
//  Created by Maurice Parker on 7/16/21.
//

import Foundation

@MainActor
public protocol ErrorHandler: AnyObject {
	func presentError(_ error: Error, title: String)
}
