//
//  GetOutlinesIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/9/21.
//

import Intents
import Templeton

class GetOutlinesIntentHandler: NSObject, ZavalaIntentHandler, GetOutlinesIntentHandling {
	
	func resolveAccountType(for intent: GetOutlinesIntent, with completion: @escaping (IntentAccountTypeResolutionResult) -> Void) {
		completion(.success(with: intent.accountType))
	}
	
	func resolveOutlineNames(for intent: GetOutlinesIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
		guard let names = intent.outlineNames else {
			completion([INStringResolutionResult]())
			return
		}
		completion(names.map { return .success(with: $0) })
	}
	
	func provideTagNamesOptionsCollection(for intent: GetOutlinesIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
		let tagNames: [String]
		switch intent.accountType {
		case .onMyDevice:
			tagNames = AccountManager.shared.localAccount.tags?.compactMap({ $0.name as String }) ?? [String]()
		case .iCloud:
			tagNames = AccountManager.shared.cloudKitAccount?.tags?.compactMap({ $0.name as String }) ?? [String]()
		default:
			var names = Set<String>()
			names.formUnion(Set(AccountManager.shared.localAccount.tags?.compactMap({ $0.name as String }) ?? [String]()))
			names.formUnion(Set(AccountManager.shared.cloudKitAccount?.tags?.compactMap({ $0.name as String }) ?? [String]()))
			tagNames = Array(names)
		}
		
		completion(INObjectCollection<NSString>(items: tagNames.sorted().map({ $0 as NSString })), nil)
	}
	
	func resolveTagNames(for intent: GetOutlinesIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
		guard let names = intent.tagNames else {
			completion([INStringResolutionResult]())
			return
		}
		completion(names.map { return .success(with: $0) })
	}

	func resolveCreatedStartDate(for intent: GetOutlinesIntent, with completion: @escaping (INDateComponentsResolutionResult) -> Void) {
		guard let date = intent.createdStartDate else {
			completion(.notRequired())
			return
		}
		completion(.success(with: date))
	}
	
	func resolveCreatedEndDate(for intent: GetOutlinesIntent, with completion: @escaping (INDateComponentsResolutionResult) -> Void) {
		guard let date = intent.createdEndDate else {
			completion(.notRequired())
			return
		}
		completion(.success(with: date))
	}
	
	func resolveUpdatedStartDate(for intent: GetOutlinesIntent, with completion: @escaping (INDateComponentsResolutionResult) -> Void) {
		guard let date = intent.updatedStartDate else {
			completion(.notRequired())
			return
		}
		completion(.success(with: date))
	}
	
	func resolveUpdatedEndDate(for intent: GetOutlinesIntent, with completion: @escaping (INDateComponentsResolutionResult) -> Void) {
		guard let date = intent.updatedEndDate else {
			completion(.notRequired())
			return
		}
		completion(.success(with: date))
	}
		
	func handle(intent: GetOutlinesIntent, completion: @escaping (GetOutlinesIntentResponse) -> Void) {
		var documents: [Document]
		
		switch intent.accountType {
		case .onMyDevice:
			documents = AccountManager.shared.localAccount.documents ?? [Document]()
		case .iCloud:
			documents = AccountManager.shared.cloudKitAccount?.documents ?? [Document]()
		default:
			documents = AccountManager.shared.documents
		}
			
		if let outlineNames = intent.outlineNames, !outlineNames.isEmpty {
			var foundDocuments = Set<Document>()
			for tagName in outlineNames {
				guard let outlineNameRegEx = tagName.searchRegEx() else {
					continue
				}
				for document in documents {
					let searchTitle = (document.title ?? "").makeSearchable()
					if outlineNameRegEx.anyMatch(in: searchTitle) {
						foundDocuments.insert(document)
					}
				}
			}
			documents = Array(foundDocuments)
		}

		if let tagNames = intent.tagNames, !tagNames.isEmpty {
			var foundDocuments = Set<Document>()
			for tagName in tagNames {
				for document in documents {
					for tag in document.tags ?? [Tag]() {
						if tagName.caseInsensitiveCompare(tag.name) == .orderedSame {
							foundDocuments.insert(document)
						}
					}
				}
			}
			documents = Array(foundDocuments)
		}
		
		if let createdStartDate = intent.createdStartDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let createdDate = document.created, Calendar.current.compare(createdStartDate, to: createdDate, toGranularity: .day) != .orderedAscending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		if let createdEndDate = intent.createdEndDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let createdDate = document.created, Calendar.current.compare(createdEndDate, to: createdDate, toGranularity: .day) != .orderedDescending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		
		if let updatedStartDate = intent.updatedStartDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let updatedDate = document.updated, Calendar.current.compare(updatedStartDate, to: updatedDate, toGranularity: .day) != .orderedAscending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		if let updatedEndDate = intent.updatedEndDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let updatedDate = document.updated, Calendar.current.compare(updatedEndDate, to: updatedDate, toGranularity: .day) != .orderedDescending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}
		
		documents = documents.sorted(by: { $0.title ?? "" < $1.title ?? "" })
		
		let response = GetOutlinesIntentResponse(code: .success, userActivity: nil)
		response.outlines = documents.compactMap({ $0.outline }).map({ IntentOutline(outline: $0) })
		completion(response)
	}
	
}
