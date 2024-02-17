//
//  Created by Maurice Parker on 12/19/20.
//
// RFC822 code comes from here: https://stackoverflow.com/a/36748856

import Foundation

public extension Date {
	
	var rfc822String: String? {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
		dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
		return dateFormatter.string(from: self)
	}
	
	static func dateFromRFC822(rfc822String: String) -> Date? {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

		let rfc822dateFormatsWithComma = ["EEE, d MMM yyyy HH:mm:ss zzz", "EEE, d MMM yyyy HH:mm zzz", "EEE, d MMM yyyy HH:mm:ss", "EEE, d MMM yyyy HH:mm"]
		let rfc822dateFormatsWithoutComma = ["d MMM yyyy HH:mm:ss zzz", "d MMM yyyy HH:mm zzz", "d MMM yyyy HH:mm:ss", "d MMM yyyy HH:mm"]

		let rfc822String = rfc822String.uppercased()

		if rfc822String.contains(",") {
			for dateFormat in rfc822dateFormatsWithComma {
				dateFormatter.dateFormat = dateFormat
				if let date = dateFormatter.date(from: rfc822String) {
					return date
				}
			}
		} else {
			for dateFormat in rfc822dateFormatsWithoutComma {
				dateFormatter.dateFormat = dateFormat
				if let date = dateFormatter.date(from: rfc822String) {
					return date
				}
			}
		}

		return nil
	}
	
}
