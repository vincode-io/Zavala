//
//  NSDataDetector+.swift
//  DataDetectors
//
//  Created by Filip Němeček on 31/01/2021.
//  My experiments making the NSDataDetector more "Swifty" with extensions and strongly typed parameters and results
//

import Foundation

enum DataDetectorType: CaseIterable {
	case url
	case date
	case address
	case phoneNumber
	
	var nsDetectorType: NSTextCheckingResult.CheckingType {
		switch self {
		case .url:
			return .link
		case .address:
			return .address
		case .phoneNumber:
			return .phoneNumber
		case .date:
			return .date
		}
	}
}

struct DataDetectorResult {
	let range: NSRange
	let matchText: String
	let type: ResultType
	
	enum ResultType {
		case url(URL)
		case phoneNumber(String)
		case address
		case date(Date)
	}
	
	var url: URL? {
		switch type {
		case .url(let url):
			return url
		case .phoneNumber(let phoneNumber):
			guard let phoneNumber = phoneNumber.queryEncoded, let phoneURL = URL(string: "tel://\(phoneNumber)") else { return nil }
			return phoneURL
		case .address:
			guard let address = matchText.queryEncoded, let addressURL = URL(string: "http://maps.apple.com/?q=\(address)") else { return nil }
			return addressURL
		default:
			return nil
		}
	}
	
	func attributedString(withAttributes attributes: [NSAttributedString.Key : Any]) -> NSAttributedString? {
		guard let url else { return nil }
		
		var newAttributes = attributes
		newAttributes.removeValue(forKey: .link)

		let attrString = NSMutableAttributedString(linkText: matchText, linkURL: url)
		attrString.addAttributes(newAttributes)
		
		return attrString
	}
}

extension NSDataDetector {
	convenience init(dataTypes: [DataDetectorType]) {
		if dataTypes.isEmpty {
			preconditionFailure("dataTypes array cannot be empty")
		}
		
		var result = dataTypes.first!.nsDetectorType.rawValue
		// Improvements to this code are welcome
		for type in dataTypes.dropFirst() {
			result = result | type.nsDetectorType.rawValue
		}
		
		try! self.init(types: result)
	}
	
	func enumerateMatches(in text: String, completion: (DataDetectorResult) -> ()) {
		enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) { (result, _, _) in
			guard let result else { return }
			guard let range = Range(result.range, in: text) else { return }
			let matchText = String(text[range])
			guard let match = processMatch(result, matchText: matchText) else { return }
			completion(match)
		}
	}
	
	func findMatches(in text: String) -> [DataDetectorResult] {
		let matches = self.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
		
		return matches.compactMap { (match) -> DataDetectorResult? in
			guard let range = Range(match.range, in: text) else { return nil }
			let matchText = String(text[range])
			return processMatch(match, matchText: matchText)
		}
	}
	
	private func processMatch(_ match: NSTextCheckingResult, matchText: String) -> DataDetectorResult? {
		if match.resultType == .link {
			guard let url = match.url else { return nil }
			return DataDetectorResult(range: match.range, matchText: matchText, type: .url(url))
		} else if match.resultType == .phoneNumber {
			guard let number = match.phoneNumber else { return nil }
			return DataDetectorResult(range: match.range, matchText: matchText, type: .phoneNumber(number))
		} else if match.resultType == .address {
			return DataDetectorResult(range: match.range, matchText: matchText, type: .address)
		} else if match.resultType == .date {
			guard let date = match.date else { return nil }
			return DataDetectorResult(range: match.range, matchText: matchText, type: .date(date))
		}
		
		return nil
	}
	
	
}
