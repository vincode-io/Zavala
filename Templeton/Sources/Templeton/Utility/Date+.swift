//
//  Date+.swift
//  
//
//  Created by Maurice Parker on 12/19/20.
//
// RFC822 code comes from here: https://stackoverflow.com/a/36748856

import Foundation

private let rfc822dateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	dateFormatter.locale = Locale(identifier: "en_US_POSIX")
	dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

	return dateFormatter
}()

private let rfc822dateFormatsWithComma = ["EEE, d MMM yyyy HH:mm:ss zzz", "EEE, d MMM yyyy HH:mm zzz", "EEE, d MMM yyyy HH:mm:ss", "EEE, d MMM yyyy HH:mm"]
private let rfc822dateFormatsWithoutComma = ["d MMM yyyy HH:mm:ss zzz", "d MMM yyyy HH:mm zzz", "d MMM yyyy HH:mm:ss", "d MMM yyyy HH:mm"]

private var rfc822LastUsedDateFormat: String?

extension Date {
	
	var rfc822String: String? {
		if rfc822LastUsedDateFormat != rfc822dateFormatsWithComma[0] {
			rfc822dateFormatter.dateFormat = rfc822dateFormatsWithComma[0]
		}
		return rfc822dateFormatter.string(from: self)
	}
	
	static func dateFromRFC822(rfc822String: String) -> Date? {
		let rfc822String = rfc822String.uppercased()

		if rfc822LastUsedDateFormat != nil {
			if let date = rfc822dateFormatter.date(from: rfc822String) {
				return date
			}
		}

		if rfc822String.contains(",") {
			for dateFormat in rfc822dateFormatsWithComma {
				rfc822dateFormatter.dateFormat = dateFormat
				if let date = rfc822dateFormatter.date(from: rfc822String) {
					rfc822LastUsedDateFormat = dateFormat
					return date
				}
			}
		} else {
			for dateFormat in rfc822dateFormatsWithoutComma {
				rfc822dateFormatter.dateFormat = dateFormat
				if let date = rfc822dateFormatter.date(from: rfc822String) {
					rfc822LastUsedDateFormat = dateFormat
					return date
				}
			}
		}

		return nil
	}
	
}
