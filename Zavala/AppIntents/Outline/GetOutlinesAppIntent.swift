//
//  GetOutlines.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit
import VinUtility

struct GetOutlinesAppIntent: AppIntent, CustomIntentMigratedAppIntent, ZavalaAppIntent {
    static let intentClassName = "GetOutlinesIntent"
    static let title: LocalizedStringResource = "Get Outlines"
    static let description = IntentDescription("Get Outlines based on search criteria.")

    @Parameter(title: "Search")
    var search: String?

    @Parameter(title: "Account Type")
	var accountType: AccountTypeAppEnum?

    @Parameter(title: "Tag", optionsProvider: TagStringOptionsProvider())
    var tagNames: [String]?

    @Parameter(title: "Outline", optionsProvider: OutlineStringOptionsProvider())
    var outlineNames: [String]?

    @Parameter(title: "Created Start Date")
    var createdStartDate: DateComponents?

    @Parameter(title: "Created End Date")
    var createdEndDate: DateComponents?

    @Parameter(title: "Updated Start Date")
    var updatedStartDate: DateComponents?

    @Parameter(title: "Updated End Date")
    var updatedEndDate: DateComponents?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Outlines") {
            \.$accountType
            \.$outlineNames
            \.$tagNames
            \.$createdStartDate
            \.$createdEndDate
            \.$updatedStartDate
            \.$updatedEndDate
            \.$search
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<[OutlineAppEntity]> {
        await resume()

		guard let searchText = search, !searchText.isEmpty else {
			let outlines = await filter(documents: appDelegate.accountManager.documents)
			await suspend()
			return .result(value: outlines)
		}

		let searchContainer = await Search(accountManager: appDelegate.accountManager, searchText: searchText)
		let documents = try await searchContainer.documents
		let outlines = await filter(documents: documents)

		await suspend()
		return .result(value: outlines)
    }
	
}

// MARK: Helpers

private extension GetOutlinesAppIntent {
	
	struct TagStringOptionsProvider: DynamicOptionsProvider, ZavalaAppIntent {

		@MainActor
		func results() async throws -> [String] {
			resume()
			let results = Set(appDelegate.accountManager.activeTags.compactMap({ $0.name }))
			await suspend()
			return results.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
		}

	}

	struct OutlineStringOptionsProvider: DynamicOptionsProvider, ZavalaAppIntent {
		
		@MainActor
		func results() async throws -> [String] {
			resume()
			let results = Set(appDelegate.accountManager.activeDocuments.compactMap({ $0.title ?? "" as String }))
			await suspend()
			return results.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
		}
		
	}

	@MainActor
	func filter(documents: [Document]) async -> [OutlineAppEntity] {
		var documents = documents
		
		switch accountType {
		case .onMyDevice:
			documents = documents.filter { $0.id.accountID == AccountType.local.rawValue }
		case .iCloud:
			documents = documents.filter { $0.id.accountID == AccountType.cloudKit.rawValue }
		default:
			break
		}
		
		if let outlineNames, !outlineNames.isEmpty {
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

		if let tagNames, !tagNames.isEmpty {
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
		
		if let createdStartDate = createdStartDate?.startOfDay {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let createdDate = document.created, Calendar.current.compare(createdStartDate, to: createdDate, toGranularity: .day) != .orderedDescending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		if let createdEndDate = createdEndDate?.startOfDay {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let createdDate = document.created, Calendar.current.compare(createdEndDate, to: createdDate, toGranularity: .day) != .orderedAscending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		
		if let updatedStartDate = updatedStartDate?.startOfDay {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let updatedDate = document.updated, Calendar.current.compare(updatedStartDate, to: updatedDate, toGranularity: .day) != .orderedDescending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}

		if let updatedEndDate = updatedEndDate?.startOfDay {
			var foundDocuments = Set<Document>()
			for document in documents {
				if let updatedDate = document.updated, Calendar.current.compare(updatedEndDate, to: updatedDate, toGranularity: .day) != .orderedAscending {
					foundDocuments.insert(document)
				}
			}
			documents = Array(foundDocuments)
		}
		
		documents = documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare(($1.title ?? "")) == .orderedAscending })
		
		return documents.compactMap({ $0.outline }).map({ OutlineAppEntity(outline: $0) })
	}
	
}
