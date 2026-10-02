//
//  NoteIndexer.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import CoreSpotlight
import VinOutlineKit

/// Makes notes available to Siri and Apple Intelligence by associating a NoteAppEntity with each Outline's item in
/// the Spotlight index maintained by DocumentIndexer, and keeps the FolderAppEntity index in sync with the Accounts' Tags.
@available(iOS 27.0, *)
@MainActor
enum NoteIndexer {

	private static var folderChangeObservers = [NSObjectProtocol]()
	private static var reindexFoldersTask: Task<Void, Never>?

	static func start() {
		DocumentIndexer.prepareSearchableItem = { searchableItem, document in
			associateNote(with: searchableItem, for: document)
		}
		DocumentIndexer.didRemoveIndex = { document in
			removeIndex(for: document)
		}

		let folderChanges: [Notification.Name] = [.AccountTagsDidChange, .AccountDidReload, .AccountManagerAccountsDidChange]
		folderChangeObservers = folderChanges.map { name in
			NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
				MainActor.assumeIsolated {
					reindexFolders()
				}
			}
		}

		reindexFolders()
		reindexNotesIfNewVersion()
	}

	/// Reindexes the given Outlines' Spotlight items, which associates their notes with them. Locked Outlines are
	/// removed from Spotlight instead, the same as when they change through sync. Yields between Outlines because
	/// each one's text is loaded to index it.
	static func reindex(_ documents: [Document]) async {
		for document in documents {
			if document.isLocked {
				DocumentIndexer.removeIndex(for: document)
			} else {
				DocumentIndexer.updateIndex(for: document)
			}
			await Task.yield()
		}
	}

	/// Reindexes every Outline once per app version. Outlines indexed before notes were associated with them, or
	/// reindexed by the Spotlight extension (which can't associate them), otherwise wouldn't have their notes for
	/// Siri until they next change.
	private static func reindexNotesIfNewVersion() {
		let info = Bundle.main.infoDictionary
		let version = "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
		guard AppDefaults.shared.lastNoteReindexVersion != version else { return }

		Task {
			// Let launch finish before loading every Outline
			try? await Task.sleep(for: .seconds(5))

			await reindex(appDelegate.accountManager.activeDocuments)
			AppDefaults.shared.lastNoteReindexVersion = version
		}
	}

	/// Associates the Outline's NoteAppEntity with its Spotlight item, so that there's one item per Outline in
	/// Spotlight that Siri and Apple Intelligence can also find as a note. Locked Outlines aren't associated
	/// because NoteAppEntityQuery doesn't return them.
	static func associateNote(with searchableItem: CSSearchableItem, for document: Document) {
		guard let outline = document.outline, !document.isLocked else { return }
		searchableItem.associateAppEntity(NoteAppEntity(outline: outline))
	}

	/// Removes any note that was indexed on its own rather than through its Outline's Spotlight item.
	static func removeIndex(for document: Document) {
		let entityID = document.id
		Task {
			try? await retryingIfUnreachable {
				try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: [entityID], ofType: NoteAppEntity.self)
			}
		}
	}

	/// Brings the folder index up to date with the current Tags. The index is only touched when the Tags have
	/// changed since they were last indexed, so that Siri's index built from it isn't disturbed on every launch.
	/// Current folders are indexed again, which replaces their existing entries, and only the folders that no
	/// longer exist are deleted. Waits briefly so that a burst of changes, such as during a sync, updates it once.
	static func reindexFolders() {
		reindexFoldersTask?.cancel()
		reindexFoldersTask = Task {
			try? await Task.sleep(for: .seconds(1))
			guard !Task.isCancelled else { return }

			let folders = FolderAppEntityQuery.allFolders()
			let entries = folders.map { folderIndexEntry(for: $0) }
			let previousEntries = AppDefaults.shared.lastIndexedFolders

			guard Set(entries) != Set(previousEntries) else { return }

			let currentIDs = Set(folders.map(\.id.description))
			let removedIDs = previousEntries
				.compactMap { $0.split(separator: "\t", omittingEmptySubsequences: false).first.map(String.init) }
				.filter { !currentIDs.contains($0) }
				.compactMap { EntityID(description: $0) }

			do {
				if !removedIDs.isEmpty {
					try await retryingIfUnreachable {
						try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: removedIDs, ofType: FolderAppEntity.self)
					}
				}
				try await retryingIfUnreachable {
					try await CSSearchableIndex.default().indexAppEntities(folders)
				}
				AppDefaults.shared.lastIndexedFolders = entries
			} catch {
				// The folders aren't recorded, so indexing them is tried again at the next change or launch
			}
		}
	}

	/// Describes everything about a folder that its index entry depends on, so a change to any of it is noticed.
	private static func folderIndexEntry(for folder: FolderAppEntity) -> String {
		return [folder.id.description, folder.name, folder.parentFolder?.id.description ?? ""].joined(separator: "\t")
	}

	/// Spotlight's indexing service can briefly be unreachable, such as right after launch. Its documentation says
	/// to retry when indexing fails, so the operation is retried with an increasing delay when the service couldn't
	/// be reached. Other errors, and the last failure, are thrown.
	private static func retryingIfUnreachable(_ operation: () async throws -> Void) async throws {
		let maxAttempts = 4
		var delay = Duration.seconds(1)

		for attempt in 1...maxAttempts {
			do {
				try await operation()
				return
			} catch let error as CSIndexError where attempt < maxAttempts && (error.code == .remoteConnectionError || error.code == .indexUnavailableError) {
				try await Task.sleep(for: delay)
				delay *= 2
			}
		}
	}

}
