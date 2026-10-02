//
//  ZavalaAppIntent+AppIntentsForSiri.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import VinOutlineKit

@available(iOS 27.0, *)
extension ZavalaAppIntent {

	@MainActor
	func findOutline(_ note: NoteAppEntity) -> Outline? {
		return findOutline(note.id)
	}

	/// Finds the Account and Tag that a Notes domain folder represents.
	@MainActor
	func findAccountAndTag(_ folder: FolderAppEntity) -> (account: Account, tag: Tag)? {
		guard case .tagDocuments(let accountID, let tagID) = folder.id,
			  let account = appDelegate.accountManager.findAccount(accountID: accountID),
			  let tag = account.tags?.first(where: { $0.id == tagID }) else {
			return nil
		}
		return (account, tag)
	}

}
