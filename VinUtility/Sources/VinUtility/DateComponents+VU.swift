//
//  DateComponents+VU.swift
//  
//
//  Created by Maurice Parker on 7/8/24.
//

import Foundation

public extension DateComponents {
	
	var startOfDay : Date? {
		guard let result = Calendar.current.date(from: self) else { return nil }
		return Calendar.current.startOfDay(for: result)
	}
	
}
