//
//  NSItemProvider+.swift
//  Zavala
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation
import MobileCoreServices

public extension NSItemProvider {
	
	convenience init(row: Row) {
		self.init()
		
		registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
			do {
				let data = try row.asData()
				completion(data, nil)
			} catch {
				completion(nil, error)
			}
			return nil
		}

		registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
			let data = row.markdown().data(using: .utf8)
			completion(data, nil)
			return nil
		}
	}
	
}
