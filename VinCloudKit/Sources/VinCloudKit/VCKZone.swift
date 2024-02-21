//
//  CloudKitZone.swift
//
//  Created by Maurice Parker on 3/21/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import CloudKit
import OSLog
import VinUtility

public struct VCKChangeTokenKey: Hashable, Codable {
	public let zoneName: String
	public let ownerName: String
}

public enum VCKModifyStrategy {
	case overWriteServerValue
	case onlyIfServerUnchanged
	
	var recordSavePolicy: CKModifyRecordsOperation.RecordSavePolicy {
		switch self {
		case .overWriteServerValue:
			return .changedKeys
		case .onlyIfServerUnchanged:
			return .ifServerRecordUnchanged
		}
	}
}

public protocol VCKZoneDelegate: AnyObject {
	func store(changeToken: Data?, key: VCKChangeTokenKey)
	func findChangeToken(key: VCKChangeTokenKey) -> Data?
	func cloudKitDidModify(changed: [CKRecord], deleted: [CloudKitRecordKey]) async throws;
}

public typealias CloudKitRecordKey = (recordType: CKRecord.RecordType, recordID: CKRecord.ID)

public protocol VCKZone: AnyObject {
	
	static var qualityOfService: QualityOfService { get }

	var logger: Logger { get }
	var zoneID: CKRecordZone.ID { get }

	var container: CKContainer? { get }
	var database: CKDatabase? { get }
	var delegate: VCKZoneDelegate? { get }

	/// Generates a new CKRecord.ID using a UUID for the record's name
	func generateRecordID() -> CKRecord.ID
	
	/// Subscribe to changes at a zone level
	func subscribeToZoneChanges() async throws
	
}

public extension VCKZone {
	
	// My observation has been that QoS is treated differently for CloudKit operations on macOS vs iOS.
	// .userInitiated is too aggressive on iOS and can lead the UI slowing down and appearing to block.
	// .default (or lower) on macOS will sometimes hang for extended periods of time and appear to hang.
	static var qualityOfService: QualityOfService {
		#if os(macOS) || targetEnvironment(macCatalyst)
		return .userInitiated
		#else
		return .default
		#endif
	}
	
	private var oldChangeTokenKey: String {
		return "cloudkit.server.token.\(zoneID.zoneName).\(zoneID.ownerName)"
	}

	private var changeTokenKey: VCKChangeTokenKey {
		return VCKChangeTokenKey(zoneName: zoneID.zoneName, ownerName: zoneID.ownerName)
	}
	
	private var changeToken: CKServerChangeToken? {
		get {
			guard let tokenData = delegate!.findChangeToken(key: changeTokenKey) else { return nil }
			return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
		}
		set {
			guard let token = newValue, let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) else {
				return
			}
			delegate!.store(changeToken: tokenData, key: changeTokenKey)
		}
	}

	/// Moves the change token to the new key name.  This can eventually be removed.
	func migrateChangeToken() {
		if let tokenData = UserDefaults.standard.object(forKey: oldChangeTokenKey) as? Data {
			delegate!.store(changeToken: tokenData, key: changeTokenKey)
			UserDefaults.standard.removeObject(forKey: oldChangeTokenKey)
		}
	}
	
	func generateRecordID() -> CKRecord.ID {
		return CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
	}

	func fetchRecordZone() async throws -> CKRecordZone {
		return try await withCheckedThrowingContinuation { continuation in
			let op = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
			op.qualityOfService = Self.qualityOfService

			op.perRecordZoneResultBlock = { [weak self] _, result in
				guard let self else {
					continuation.resume(throwing: VCKError.unknown)
					return
				}

				switch result {
				case .success(let recordZone):
					continuation.resume(returning: recordZone)
				case .failure(let error):
					switch VCKResult.refine(error) {
					case .zoneNotFound, .userDeletedZone:
						Task {
							do {
								try await self.createRecordZone()
								let recordZone = try await self.fetchRecordZone()
								continuation.resume(returning: recordZone)
							} catch {
								continuation.resume(throwing: error)
							}
						}
					case .retry(let timeToWait):
						self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone fetch changes retry in \(timeToWait, privacy: .public) seconds.")
						Task {
							do {
								try await Task.sleep(for: .seconds(timeToWait))
								let recordZone = try await self.fetchRecordZone()
								continuation.resume(returning: recordZone)
							} catch {
								continuation.resume(throwing: error)
							}
						}
					default:
						continuation.resume(throwing: error)
					}
				}
			}

			database?.add(op)
		}
	}
	
	/// Creates the record zone
	func createRecordZone() async throws {
		guard let database else {
			throw VCKError.unknown
		}
		
		try await database.save(CKRecordZone(zoneID: zoneID))
	}

	/// Subscribes to zone changes
	func subscribeToZoneChanges() async throws {
		let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "\(zoneID.zoneName)-changes")
        
		let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        
		try await save(subscription)
    }

	/// Fetch a CKRecord by using its externalID
	func fetch(externalID: String) async throws -> CKRecord? {
		let recordID = CKRecord.ID(recordName: externalID, zoneID: zoneID)
		
		do {
			return try await database?.record(for: recordID)
		} catch {
			switch VCKResult.refine(error) {
			case .zoneNotFound:
				try await createRecordZone()
				return try await fetch(externalID: externalID)
			case .retry(let timeToWait):
				logger.error("\(self.zoneID.zoneName, privacy: .public) zone fetch retry in \(timeToWait, privacy: .public) seconds.")
				try await Task.sleep(for: .seconds(timeToWait))
				return try await self.fetch(externalID: externalID)
			case .userDeletedZone:
				throw VCKError.userDeletedZone
			default:
				throw error
			}
		}
	}
	
	/// Save the CKSubscription
	@discardableResult
	func save(_ subscription: CKSubscription) async throws -> CKSubscription {
		guard let database else {
			throw VCKError.unknown
		}
		
		do {
			return try await database.save(subscription)
		} catch {
			switch VCKResult.refine(error) {
			case .zoneNotFound:
				try await createRecordZone()
				return try await save(subscription)
			case .retry(let timeToWait):
				self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone save subscription retry in \(timeToWait, privacy: .public) seconds.")
				try await Task.sleep(for: .seconds(timeToWait))
				return try await save(subscription)
			default:
				throw error
			}
		}
	}

	
	/// Modify and delete the supplied CKRecords and CKRecord.IDs
	func modify(modelsToSave: [VCKModel], recordIDsToDelete: [CKRecord.ID], strategy: VCKModifyStrategy) async throws -> ([CKRecord], [CKRecord.ID]) {
		guard !(modelsToSave.isEmpty && recordIDsToDelete.isEmpty) else {
			return ([], [])
		}

		return try await withCheckedThrowingContinuation { continuation in
			
			var perRecordError: Error?
			
			var savedRecords = [CKRecord]()
			var deletedRecordIDs = [CKRecord.ID]()
			
			var modelsToRetry = [VCKModel]()
			var deletesToRetry = [CKRecord.ID]()
			
			let recordsToSave = modelsToSave.compactMap { $0.buildRecord() }
			let op = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
			op.savePolicy = strategy.recordSavePolicy
			op.isAtomic = true
			op.qualityOfService = Self.qualityOfService
			
			op.perRecordSaveBlock = { recordID, result in
				switch result {
				case .success(let record):
					savedRecords.append(record)
				case .failure(let error):
					guard let ckError = error as? CKError else { break }
					
					switch ckError.code {
					case .zoneNotFound, .userDeletedZone:
						perRecordError = error
						op.cancel()
					case .batchRequestFailed:
						// Nothing wrong with this record, it was just part of the batch that failed.
						if let model = modelsToSave.first(where: { $0.cloudKitRecordID == recordID }) {
							modelsToRetry.append(model)
						}
					case .unknownItem:
						// The record was deleted by another device or user, so don't try to update it.
						break
					case .serverRecordChanged:
						// Merge the model and try to save it again
						if let model = modelsToSave.first(where: { $0.cloudKitRecordID == recordID }) {
							model.apply(ckError)
							modelsToRetry.append(model)
						}
					default:
						// Won't sync and I don't know why
						if let errorDescription = ckError.errorDescription {
							self.logger.error("Unhandled per record error:  \(errorDescription, privacy: .public).")
						}
						break
					}
				}
			}
			
			op.perRecordDeleteBlock = { recordID, result in
				switch result {
				case .success:
					deletedRecordIDs.append(recordID)
				case .failure(let error):
					guard let ckError = error as? CKError else { break }
					switch ckError.code {
					case .zoneNotFound, .userDeletedZone:
						perRecordError = error
						op.cancel()
					default:
						deletesToRetry.append(recordID)

					}
				}
			}
			
			op.modifyRecordsResultBlock = { [weak self] result in
				guard let self else {
					continuation.resume(throwing: VCKError.unknown)
					return
				}
				
				func handleError(_ error: Error) {
					let modelsToSend = modelsToSave
					let deletesToSend = recordIDsToDelete

					let refinedResult = VCKResult.refine(error)
					switch refinedResult {
					case .zoneNotFound, .userDeletedZone:
						continuation.resume(throwing: error)
					case .retry(let timeToWait):
						self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone modify retry in \(timeToWait, privacy: .public) seconds.")
						Task {
							do {
								try await Task.sleep(for: .seconds(timeToWait))
								let result = try await self.modify(modelsToSave: modelsToSend, recordIDsToDelete: deletesToSend, strategy: strategy)
								continuation.resume(returning: result)
							} catch {
								continuation.resume(throwing: error)
							}
						}
					case .limitExceeded:
						Task {
							do {
								let modelsToSaveChunks = modelsToSave.chunked(into: 200)
								let recordIDsToDeleteChunks = recordIDsToDelete.chunked(into: 200)
								
								var savedRecords = [CKRecord]()
								var deletedRecordIDs = [CKRecord.ID]()

								for modelsToSaveChunk in modelsToSaveChunks {
									let result = try await self.modify(modelsToSave: modelsToSaveChunk, recordIDsToDelete: [], strategy: strategy)
									savedRecords.append(contentsOf: result.0)
								}

								for recordIDsToDeleteChunk in recordIDsToDeleteChunks {
									let result = try await self.modify(modelsToSave: [], recordIDsToDelete: recordIDsToDeleteChunk, strategy: strategy)
									deletedRecordIDs.append(contentsOf: result.1)
								}

								continuation.resume(returning: (savedRecords, deletedRecordIDs))
							} catch {
								continuation.resume(throwing: error)
							}
						}

					case .serverRecordChanged(let ckError):
						self.logger.info("Modify failed: \(ckError.localizedDescription, privacy: .public). Attempting to recover...")
						modelsToSave[0].apply(ckError)
						self.logger.info("\(modelsToSave.count, privacy: .public) records resolved. Attempting Modify again...")
						Task {
							do {
								let result = try await self.modify(modelsToSave: modelsToSave, recordIDsToDelete: recordIDsToDelete, strategy: strategy)
								continuation.resume(returning: result)
							} catch {
								continuation.resume(throwing: error)
							}
						}
						
					default:
						continuation.resume(throwing: error)
					}
				}
				
				switch result {
				case .success:
					if modelsToRetry.isEmpty && deletesToRetry.isEmpty {
						self.logger.info("Successfully modified \(savedRecords.count, privacy: .public) records and deleted \(deletedRecordIDs.count, privacy: .public) records.")
						continuation.resume(returning: (savedRecords, deletedRecordIDs))
					} else {
						self.logger.info("Modify failed. \(modelsToRetry.count, privacy: .public) records resolved. Attempting Modify again...")
						let modelsToSend = modelsToRetry
						let deletesToSend = deletesToRetry
						Task {
							do {
								let result = try await self.modify(modelsToSave: modelsToSend, recordIDsToDelete: deletesToSend, strategy: strategy)
								continuation.resume(returning: result)
							} catch {
								continuation.resume(throwing: error)
							}
						}
					}
				case .failure(let error):
					if let perRecordError {
						handleError(perRecordError)
					} else {
						handleError(error)
					}
				}
			}
			
			database?.add(op)
		}
	}
	
	/// Fetch all the changes in the CKZone since the last time we checked
	func fetchChangesInZone(incremental: Bool = true) async throws {

		var updatedRecords = [CKRecord]()
		var deletedRecordKeys = [CloudKitRecordKey]()
		
		@Sendable func wasChanged(updated: [CKRecord], deleted: [CloudKitRecordKey], token: CKServerChangeToken?) async throws {
			logger.debug("Received \(updated.count, privacy: .public) updated records and \(deleted.count, privacy: .public) delete requests.")
			try await delegate?.cloudKitDidModify(changed: updated, deleted: deleted)
			self.changeToken = token
		}
		
		return try await withCheckedThrowingContinuation { continuation in
			
			var perRecordError: Error?
			
			let zoneConfig = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
			zoneConfig.previousServerChangeToken = changeToken
			let op = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], configurationsByRecordZoneID: [zoneID: zoneConfig])
			op.fetchAllChanges = true
			op.qualityOfService = Self.qualityOfService
			
			op.recordZoneChangeTokensUpdatedBlock = { zoneID, token, _ in
				guard incremental else { return }

				let updatedRecordsToSend = updatedRecords
				let deletedRecordKeysToSend = deletedRecordKeys

				Task {
					do {
						try await wasChanged(updated: updatedRecordsToSend, deleted: deletedRecordKeysToSend, token: token)
					} catch {
						op.cancel()
						continuation.resume(throwing: error)
					}
				}

				updatedRecords = [CKRecord]()
				deletedRecordKeys = [CloudKitRecordKey]()
			}
			
			op.recordWasChangedBlock = { _, result in
				switch result {
				case .success(let record):
					updatedRecords.append(record)
				case .failure(let error):
					perRecordError = error
					op.cancel()
				}
			}
			
			op.recordWithIDWasDeletedBlock = { recordID, recordType in
				let recordKey = CloudKitRecordKey(recordType: recordType, recordID: recordID)
				deletedRecordKeys.append(recordKey)
			}
			
			op.recordZoneFetchResultBlock = { zoneID, result in
				switch result {
				case .success((let token, _, _)):
					let updatedRecordsToSend = updatedRecords
					let deletedRecordKeysToSend = deletedRecordKeys
					Task {
						do {
							try await wasChanged(updated: updatedRecordsToSend, deleted: deletedRecordKeysToSend, token: token)
						} catch {
							op.cancel()
							continuation.resume(throwing: error)
						}
					}
				case .failure:
					break
				}
				updatedRecords = [CKRecord]()
				deletedRecordKeys = [CloudKitRecordKey]()
			}
			
			op.fetchRecordZoneChangesResultBlock = { [weak self] result in
				guard let self else {
					continuation.resume(throwing: VCKError.unknown)
					return
				}
				
				func handleError(_ error: Error) {
					switch VCKResult.refine(error) {
					case .zoneNotFound, .userDeletedZone:
						continuation.resume(throwing: error)
					case .retry(let timeToWait):
						self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone fetch changes retry in \(timeToWait, privacy: .public) seconds.")
						Task {
							do {
								try await Task.sleep(for: .seconds(timeToWait))
								try await self.fetchChangesInZone(incremental: incremental)
								continuation.resume()
							} catch {
								continuation.resume(throwing: error)
							}
						}
					case .changeTokenExpired:
						Task {
							self.changeToken = nil
							try await self.fetchChangesInZone(incremental: incremental)
							continuation.resume()
						}
					default:
						continuation.resume(throwing: error)
					}
				}
				
				switch result {
				case .success:
					continuation.resume()
				case .failure(let error):
					if let perRecordError {
						handleError(perRecordError)
					} else {
						handleError(error)
					}
				}
			}
			
			database?.add(op)
			
		}
    }
	
}
