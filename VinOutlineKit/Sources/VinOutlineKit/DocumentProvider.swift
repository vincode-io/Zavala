//
//  DocumentProvider.swift
//  
//
//  Created by Maurice Parker on 11/7/21.
//

import Foundation

public protocol DocumentProvider {
	var documents: [Document] { get async throws }
}
