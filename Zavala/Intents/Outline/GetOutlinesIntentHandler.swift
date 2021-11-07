//
//  GetOutlinesIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/9/21.
//

import Intents
import Templeton

class GetOutlinesIntentHandler: NSObject, ZavalaIntentHandler, GetOutlinesIntentHandling {
	
	private var search: Search?

	func resolveSearch(for intent: GetOutlinesIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let search = intent.search else {
			completion(.notRequired())
			return
		}
		completion(.success(with: search))
	}
	
	func resolveAccountType(for intent: GetOutlinesIntent, with completion: @escaping (IntentAccountTypeResolutionResult) -> Void) {
		completion(.success(with: intent.accountType))
	}
	
	func provideOutlineNamesOptionsCollection(for intent: GetOutlinesIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
		let outlineNames: [String]
		switch intent.accountType {
		case .onMyDevice:
			outlineNames = AccountManager.shared.localAccount.documents?.compactMap({ $0.title ?? "" as String }) ?? [String]()
		case .iCloud:
			outlineNames = AccountManager.shared.cloudKitAccount?.documents?.compactMap({ $0.title ?? "" as String }) ?? [String]()
		default:
			var names = Set<String>()
			names.formUnion(Set(AccountManager.shared.localAccount.documents?.compactMap({ $0.title ?? "" as String }) ?? [String]()))
			names.formUnion(Set(AccountManager.shared.cloudKitAccount?.documents?.compactMap({ $0.title ?? "" as String }) ?? [String]()))
			outlineNames = Array(names)
		}
		
		completion(INObjectCollection<NSString>(items: outlineNames.sorted().map({ $0 as NSString })), nil)
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
		resume()
		
		guard let searchText = intent.search, !searchText.isEmpty else {
			filter(documents: AccountManager.shared.documents, intent: intent, completion: completion)
			return
		}

		search = Search(searchText: searchText)
		
		search!.documents { result in
			switch result {
			case .success(let documents):
				self.filter(documents: documents, intent: intent, completion: completion)
			case .failure:
				completion(.init(code: .failure, userActivity: nil))
			}
		}
	}
	
}

extension GetOutlinesIntentHandler {
	
	private func filter(documents: [Document], intent: GetOutlinesIntent, completion: @escaping (GetOutlinesIntentResponse) -> Void) {
		var documents = documents
		
		switch intent.accountType {
		case .onMyDevice:
			documents = documents.filter { $0.id.accountID == AccountType.local.rawValue }
		case .iCloud:
			documents = documents.filter { $0.id.accountID == AccountType.cloudKit.rawValue }
		default:
			break
		}
		
		if let outlineNames = intent.outlineNames, !outlineNames.isEmpty {
			var foundDocuments = Set<Document>()
			for outlineName in outlineNames {
				for document in documents {
					if outlineName.caseInsensitiveCompare(document.title ?? "") == .orderedSame {
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
				if let createdDate = document.created, Calendar.current.compare(createdStartDate, to: createdDate, toGranularity: .day) != .orderedDescending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		if let createdEndDate = intent.createdEndDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let createdDate = document.created, Calendar.current.compare(createdEndDate, to: createdDate, toGranularity: .day) != .orderedAscending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		
		if let updatedStartDate = intent.updatedStartDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let updatedDate = document.updated, Calendar.current.compare(updatedStartDate, to: updatedDate, toGranularity: .day) != .orderedDescending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		if let updatedEndDate = intent.updatedEndDate?.date {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let updatedDate = document.updated, Calendar.current.compare(updatedEndDate, to: updatedDate, toGranularity: .day) != .orderedAscending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}
		
		documents = documents.sorted(by: { $0.title ?? "" < $1.title ?? "" })
		
		suspend()
		
		let response = GetOutlinesIntentResponse(code: .success, userActivity: nil)
		response.outlines = documents.compactMap({ $0.outline }).map({ IntentOutline($0) })
		completion(response)
	}
	
}
