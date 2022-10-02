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
	let range: Range<String.Index>
	let type: ResultType
	
	enum ResultType {
		case url(URL)
		case email(email: String, url: URL)
		case phoneNumber(String)
		case address(components: [NSTextCheckingKey: String])
		case date(Date)
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
	
	func enumerateMatches(in text: String, block: (_ range: NSRange, _ match: DataDetectorResult.ResultType) -> ()) {
		enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) { (result, _, _) in
			guard let result = result else { return }
			guard let range = Range(result.range, in: text) else { return }
			
			guard let match = processMatch(result, range: range) else { return }
			
			block(result.range, match.type)
		}
	}
	
	func findMatches(in text: String) -> [DataDetectorResult] {
		let matches = self.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
		
		return matches.compactMap { (match) -> DataDetectorResult? in
			guard let range = Range(match.range, in: text) else { return nil }
			
			return processMatch(match, range: range)
		}
	}
	
	private func processMatch(_ match: NSTextCheckingResult, range: Range<String.Index>) -> DataDetectorResult? {
		
		if match.resultType == .link {
			guard let url = match.url else { return nil }
			
			if url.absoluteString.hasPrefix("mailto:") {
				let email = url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
				return DataDetectorResult(range: range, type: .email(email: email, url: url))
			} else {
				return DataDetectorResult(range: range, type: .url(url))
			}
		} else if match.resultType == .phoneNumber {
			guard let number = match.phoneNumber else { return nil }
			
			return DataDetectorResult(range: range, type: .phoneNumber(number))
		} else if match.resultType == .address {
			guard let components = match.addressComponents else { return nil }
			
			return DataDetectorResult(range: range, type: .address(components: components))
		} else if match.resultType == .date {
			guard let date = match.date else { return nil }
			
			return DataDetectorResult(range: range, type: .date(date))
		}
		
		return nil
	}
	
	
}
