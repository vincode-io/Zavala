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
	func cloudKitDidModify(changed: [CKRecord], deleted: [CloudKitRecordKey], completion: @escaping (Result<Void, Error>) -> Void);
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
	func subscribeToZoneChanges()
	
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

	func retryIfPossible(after: Double, block: @escaping () -> ()) {
		Task {
			try await Task.sleep(for: .seconds(after))
			block()
		}
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
						self.retryIfPossible(after: timeToWait) {
							Task {
								do {
									let recordZone = try await self.fetchRecordZone()
									continuation.resume(returning: recordZone)
								} catch {
									continuation.resume(throwing: error)
								}
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

	/// Creates the zone record
	@available(*, renamed: "createRecordZone()")
	func createRecordZone(completion: @escaping (Result<Void, Error>) -> Void) {
		Task {
			do {
				try await createRecordZone()
				completion(.success(()))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	
	func createRecordZone() async throws {
		guard let database else {
			throw VCKError.unknown
		}
		
		try await database.save(CKRecordZone(zoneID: zoneID))
	}

	/// Subscribes to zone changes
	func subscribeToZoneChanges() {
		let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "\(zoneID.zoneName)-changes")
        
		let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        
		Task {
			do {
				try await save(subscription)
			} catch {
				self.logger.error("\(self.zoneID.zoneName, privacy: .public) subscribe to changes error: \(error.localizedDescription, privacy: .public)")
			}
		}
    }

	/// Fetch a CKRecord by using its externalID
	@available(*, deprecated, renamed: "fetch()", message: "Move to the new async version.")
	func fetch(externalID: String, completion: @escaping (Result<CKRecord, Error>) -> Void) {
		Task { @MainActor in
			do {
				let record = try await fetch(externalID: externalID)
				completion(.success(record))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	/// Fetch a CKRecord by using its externalID
	func fetch(externalID: String) async throws -> CKRecord {
		let recordID = CKRecord.ID(recordName: externalID, zoneID: zoneID)
		
		do {
			if let record = try await database?.record(for: recordID) {
				return record
			} else {
				throw VCKError.corruptAccount
			}
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
	func modify(modelsToSave: [VCKModel],
				recordIDsToDelete: [CKRecord.ID],
				strategy: VCKModifyStrategy,
				completion: @escaping (Result<([CKRecord], [CKRecord.ID]), Error>) -> Void) {
		
		guard !(modelsToSave.isEmpty && recordIDsToDelete.isEmpty) else {
			DispatchQueue.main.async {
				completion(.success(([], [])))
			}
			return
		}

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
				case .batchRequestFailed:
					// Nothing wrong with this record, it was just part of the batch that failed.
					if let model = modelsToSave.first(where: { $0.cloudKitRecordID == recordID }) {
						modelsToRetry.append(model)
					}
				case .unknownItem:
					// The record was deleted by another device or user, so don't try to update it.
					break
				default:
					// Merge the model and try to save it again
					if let model = modelsToSave.first(where: { $0.cloudKitRecordID == recordID }) {
						model.apply(ckError)
						modelsToRetry.append(model)
					}
				}
			}
		}
		
		op.perRecordDeleteBlock = { recordID, result in
			switch result {
			case .success:
				deletedRecordIDs.append(recordID)
			case .failure:
				deletesToRetry.append(recordID)
			}
		}
		
		op.modifyRecordsResultBlock = { [weak self] result in
			guard let self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch result {
			case .success:
				if modelsToRetry.isEmpty && deletesToRetry.isEmpty {
					DispatchQueue.main.async {
						self.logger.info("Successfully modified \(savedRecords.count, privacy: .public) records and deleted \(deletedRecordIDs.count, privacy: .public) records.")
						completion(.success((savedRecords, deletedRecordIDs)))
					}
				} else {
					self.logger.info("Modify failed. \(modelsToRetry.count, privacy: .public) records resolved. Attempting Modify again...")
					self.modify(modelsToSave: modelsToRetry, recordIDsToDelete: deletesToRetry, strategy: strategy, completion: completion)

				}
			case .failure(let error):
				let refinedResult = VCKResult.refine(error)
				
				switch refinedResult {
				case .zoneNotFound:
					self.createRecordZone() { result in
						switch result {
						case .success:
							self.modify(modelsToSave: modelsToSave, recordIDsToDelete: recordIDsToDelete, strategy: strategy, completion: completion)
						case .failure(let error):
							DispatchQueue.main.async {
								completion(.failure(error))
							}
						}
					}
				case .userDeletedZone:
					DispatchQueue.main.async {
						completion(.failure(VCKError.userDeletedZone))
					}
				case .retry(let timeToWait):
					self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone modify retry in \(timeToWait, privacy: .public) seconds.")
					self.retryIfPossible(after: timeToWait) {
						self.modify(modelsToSave: modelsToSave, recordIDsToDelete: recordIDsToDelete, strategy: strategy, completion: completion)
					}
				case .limitExceeded:
					var modelsToSaveChunks = modelsToSave.chunked(into: 200)
					var recordIDsToDeleteChunks = recordIDsToDelete.chunked(into: 200)

					func saveChunks(completion: @escaping (Result<Void, Error>) -> Void) {
						if !modelsToSaveChunks.isEmpty {
							let modelsToSaveChunk = modelsToSaveChunks.removeFirst()
							self.modify(modelsToSave: modelsToSaveChunk, recordIDsToDelete: [], strategy: strategy) { result in
								switch result {
								case .success:
									self.logger.info("Modified \(modelsToSaveChunk.count, privacy: .public) chunked records.")
									saveChunks(completion: completion)
								case .failure(let error):
									completion(.failure(error))
								}
							}
						} else {
							completion(.success(()))
						}
					}
					
					func deleteChunks() {
						if !recordIDsToDeleteChunks.isEmpty {
							let recordIDsToDeleteChunk = recordIDsToDeleteChunks.removeFirst()
							self.modify(modelsToSave: [], recordIDsToDelete: recordIDsToDeleteChunk, strategy: strategy) { result in
								switch result {
								case .success:
									self.logger.error("Deleted \(recordIDsToDeleteChunk.count, privacy: .public) chunked records.")
									deleteChunks()
								case .failure(let error):
									DispatchQueue.main.async {
										completion(.failure(error))
									}
								}
							}
						} else {
							DispatchQueue.main.async {
								completion(.success(([], [])))
							}
						}
					}
					
					saveChunks() { result in
						switch result {
						case .success:
							deleteChunks()
						case .failure(let error):
							DispatchQueue.main.async {
								completion(.failure(error))
							}
						}
					}
					
				case .serverRecordChanged(let ckError):
					self.logger.info("Modify failed: \(ckError.localizedDescription, privacy: .public). Attempting to recover...")
					modelsToSave[0].apply(ckError)
					self.logger.info("\(modelsToSave.count, privacy: .public) records resolved. Attempting Modify again...")
					self.modify(modelsToSave: modelsToSave, recordIDsToDelete: recordIDsToDelete, strategy: strategy, completion: completion)

				default:
					DispatchQueue.main.async {
						completion(.failure(error))
					}
				}
			}
		}

		database?.add(op)
	}
	
	/// Fetch all the changes in the CKZone since the last time we checked
	func fetchChangesInZone(incremental: Bool = true, completion: @escaping (Result<Void, Error>) -> Void) {

		var updatedRecords = [CKRecord]()
		var deletedRecordKeys = [CloudKitRecordKey]()
		
		func wasChanged(updated: [CKRecord], deleted: [CloudKitRecordKey], token: CKServerChangeToken?, completion: @escaping (Error?) -> Void) {
			logger.debug("Received \(updated.count, privacy: .public) updated records and \(deleted.count, privacy: .public) delete requests.")

			let op = CloudKitZoneApplyChangesOperation(delegate: delegate, updated: updated, deleted: deleted, changeToken: token)
			
			op.completionBlock = { [weak self] mainThreadOperation in
				guard let self, let zoneOperation = mainThreadOperation as? CloudKitZoneApplyChangesOperation else {
					completion(nil)
					return
				}
				
				if let error = zoneOperation.error {
					completion(error)
				} else {
					if let changeToken = zoneOperation.changeToken {
						self.changeToken = changeToken
					}
					completion(nil)
				}
			}
			
			DispatchQueue.main.async {
				CloudKitZoneApplyChangesOperation.mainThreadOperationQueue.add(op)
			}
			
		}
		
		let zoneConfig = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
		zoneConfig.previousServerChangeToken = changeToken
		let op = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], configurationsByRecordZoneID: [zoneID: zoneConfig])
        op.fetchAllChanges = true
		op.qualityOfService = Self.qualityOfService

        op.recordZoneChangeTokensUpdatedBlock = { zoneID, token, _ in
			guard incremental else { return }
			
			wasChanged(updated: updatedRecords, deleted: deletedRecordKeys, token: token) { error in
				if let error {
					op.cancel()
					completion(.failure(error))
				}
			}
			updatedRecords = [CKRecord]()
			deletedRecordKeys = [CloudKitRecordKey]()
        }

        op.recordWasChangedBlock = { _, result in
			switch result {
			case .success(let record):
				updatedRecords.append(record)
			case .failure:
				break // I'm not even clear on how we could get an error here...
			}
        }

        op.recordWithIDWasDeletedBlock = { recordID, recordType in
			let recordKey = CloudKitRecordKey(recordType: recordType, recordID: recordID)
			deletedRecordKeys.append(recordKey)
        }

        op.recordZoneFetchResultBlock = { zoneID, result in
			switch result {
			case .success((let token, _, _)):
				wasChanged(updated: updatedRecords, deleted: deletedRecordKeys, token: token) { error in
					if let error {
						op.cancel()
						completion(.failure(error))
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
				completion(.failure(VCKError.unknown))
				return
			}

			switch result {
			case .success:
				let op = CloudKitZoneApplyChangesOperation()
				op.completionBlock = { _ in
					completion(.success(()))
				}
				
				DispatchQueue.main.async {
					CloudKitZoneApplyChangesOperation.mainThreadOperationQueue.add(op)
				}
			case .failure(let error):
				switch VCKResult.refine(error) {
				case .zoneNotFound:
					self.createRecordZone() { result in
						switch result {
						case .success:
							self.fetchChangesInZone(incremental: incremental, completion: completion)
						case .failure(let error):
							DispatchQueue.main.async {
								completion(.failure(error))
							}
						}
					}
				case .userDeletedZone:
					DispatchQueue.main.async {
						completion(.failure(VCKError.userDeletedZone))
					}
				case .retry(let timeToWait):
					self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone fetch changes retry in \(timeToWait, privacy: .public) seconds.")
					self.retryIfPossible(after: timeToWait) {
						self.fetchChangesInZone(incremental: incremental, completion: completion)
					}
				case .changeTokenExpired:
					DispatchQueue.main.async {
						self.changeToken = nil
						self.fetchChangesInZone(incremental: incremental, completion: completion)
					}
				default:
					DispatchQueue.main.async {
						completion(.failure(error))
					}
				}

			}
        }

        database?.add(op)
    }
	
}

private class CloudKitZoneApplyChangesOperation: MainThreadOperation {
	
	static let mainThreadOperationQueue = MainThreadOperationQueue()

	// MainThreadOperation
	public var isCanceled = false
	public var id: Int?
	public weak var operationDelegate: MainThreadOperationDelegate?
	public var name: String? = "CloudKitReceiveStatusOperation"
	public var completionBlock: MainThreadOperation.MainThreadOperationCompletionBlock?

	private weak var delegate: VCKZoneDelegate?
	private var updated: [CKRecord]
	private var deleted: [CloudKitRecordKey]
	
	private(set) var error: Error?
	private(set) var changeToken: CKServerChangeToken?
	
	/// Used to queue up the final success call so that it doesn't happen before we are done processing records
	init() {
		updated = []
		deleted = []
	}
	
	/// Used for regular record processing
	init(delegate: VCKZoneDelegate?, updated: [CKRecord], deleted: [CloudKitRecordKey], changeToken: CKServerChangeToken?) {
		self.delegate = delegate
		self.updated = updated
		self.deleted = deleted
		self.changeToken = changeToken
	}
	
	func run() {
		guard let delegate else {
			self.operationDelegate?.operationDidComplete(self)
			return
		}
		
		delegate.cloudKitDidModify(changed: updated, deleted: deleted) { [weak self] result in
			guard let self else { return }
			
			switch result {
			case .success:
				self.operationDelegate?.operationDidComplete(self)
			case .failure(let error):
				self.error = error
				self.operationDelegate?.cancelOperation(self)
			}
		}

	}
	
}
