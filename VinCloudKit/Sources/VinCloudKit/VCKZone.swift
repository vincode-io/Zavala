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
		let delayTime = DispatchTime.now() + after
		DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
			block()
		})
	}
	
	func receiveRemoteNotification(userInfo: [AnyHashable : Any], incrementalFetch: Bool = true, completion: @escaping () -> Void) {
		let note = CKRecordZoneNotification(fromRemoteNotificationDictionary: userInfo)
		guard note?.recordZoneID?.zoneName == zoneID.zoneName else {
			completion()
			return
		}
		
		fetchChangesInZone(incremental: incrementalFetch) { result in
			if case .failure(let error) = result {
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone remote notification fetch error: \(error.localizedDescription, privacy: .public)")
			}
			completion()
		}
	}

	/// Retrieves the zone record for this zone only. If the record isn't found it will be created.
	func fetchZoneRecord(completion: @escaping (Result<CKRecordZone?, Error>) -> Void) {
		let op = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
		op.qualityOfService = Self.qualityOfService

		op.fetchRecordZonesCompletionBlock = { [weak self] (zoneRecords, error) in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
			case .success:
				completion(.success(zoneRecords?[self.zoneID]))
			case .zoneNotFound, .userDeletedZone:
				self.createZoneRecord() { result in
					switch result {
					case .success:
						self.fetchZoneRecord(completion: completion)
					case .failure(let error):
						DispatchQueue.main.async {
							completion(.failure(error))
						}
					}
				}
			case .retry(let timeToWait):
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone fetch changes retry in \(timeToWait, privacy: .public) seconds.")
				self.retryIfPossible(after: timeToWait) {
					self.fetchZoneRecord(completion: completion)
				}
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
			}
			
		}

		database?.add(op)
	}

	/// Creates the zone record
	func createZoneRecord(completion: @escaping (Result<Void, Error>) -> Void) {
		guard let database = database else {
			completion(.failure(VCKError.unknown))
			return
		}

		database.save(CKRecordZone(zoneID: zoneID)) { (recordZone, error) in
			if let error = error {
				DispatchQueue.main.async {
					completion(.failure(error))
				}
			} else {
				DispatchQueue.main.async {
					completion(.success(()))
				}
			}
		}
	}

	/// Subscribes to zone changes
	func subscribeToZoneChanges() {
		let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "\(zoneID.zoneName)-changes")
        
		let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        
		save(subscription) { result in
			if case .failure(let error) = result {
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) subscribe to changes error: \(error.localizedDescription, privacy: .public)")
			}
		}
    }
		
	/// Issue a CKQuery and return the resulting CKRecords.
	func query(_ ckQuery: CKQuery, desiredKeys: [String]? = nil, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
		var records = [CKRecord]()
		
		let op = CKQueryOperation(query: ckQuery)
		op.qualityOfService = Self.qualityOfService
		
		if let desiredKeys = desiredKeys {
			op.desiredKeys = desiredKeys
		}
		
		op.recordFetchedBlock = { record in
			records.append(record)
		}
		
		op.queryCompletionBlock = { [weak self] (cursor, error) in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
            case .success:
				DispatchQueue.main.async {
					if let cursor = cursor {
						self.query(cursor: cursor, desiredKeys: desiredKeys, carriedRecords: records, completion: completion)
					} else {
						completion(.success(records))
					}
				}
			case .zoneNotFound:
				self.createZoneRecord() { result in
					switch result {
					case .success:
						self.query(ckQuery, desiredKeys: desiredKeys, completion: completion)
					case .failure(let error):
						DispatchQueue.main.async {
							completion(.failure(error))
						}
					}
				}
			case .retry(let timeToWait):
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone query retry in \(timeToWait, privacy: .public) seconds.")
				self.retryIfPossible(after: timeToWait) {
					self.query(ckQuery, desiredKeys: desiredKeys, completion: completion)
				}
			case .userDeletedZone:
				DispatchQueue.main.async {
					completion(.failure(VCKError.userDeletedZone))
				}
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
			}
		}
		
		database?.add(op)
	}
	
	/// Query CKRecords using a CKQuery Cursor
	func query(cursor: CKQueryOperation.Cursor, desiredKeys: [String]? = nil, carriedRecords: [CKRecord], completion: @escaping (Result<[CKRecord], Error>) -> Void) {
		var records = carriedRecords
		
		let op = CKQueryOperation(cursor: cursor)
		op.qualityOfService = Self.qualityOfService
		
		if let desiredKeys = desiredKeys {
			op.desiredKeys = desiredKeys
		}
		
		op.recordFetchedBlock = { record in
			records.append(record)
		}
		
		op.queryCompletionBlock = { [weak self] (newCursor, error) in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
			case .success:
				DispatchQueue.main.async {
					if let newCursor = newCursor {
						self.query(cursor: newCursor, desiredKeys: desiredKeys, carriedRecords: records, completion: completion)
					} else {
						completion(.success(records))
					}
				}
			case .zoneNotFound:
				self.createZoneRecord() { result in
					switch result {
					case .success:
						self.query(cursor: cursor, desiredKeys: desiredKeys, carriedRecords: records, completion: completion)
					case .failure(let error):
						DispatchQueue.main.async {
							completion(.failure(error))
						}
					}
				}
			case .retry(let timeToWait):
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone query retry in \(timeToWait, privacy: .public) seconds.")
				self.retryIfPossible(after: timeToWait) {
					self.query(cursor: cursor, desiredKeys: desiredKeys, carriedRecords: records, completion: completion)
				}
			case .userDeletedZone:
				DispatchQueue.main.async {
					completion(.failure(VCKError.userDeletedZone))
				}
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
			}
		}

		database?.add(op)
	}
	

	/// Fetch a CKRecord by using its externalID
	func fetch(externalID: String?, completion: @escaping (Result<CKRecord, Error>) -> Void) {
		guard let externalID = externalID else {
			completion(.failure(VCKError.corruptAccount))
			return
		}

		let recordID = CKRecord.ID(recordName: externalID, zoneID: zoneID)
		
		database?.fetch(withRecordID: recordID) { [weak self] record, error in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
            case .success:
				DispatchQueue.main.async {
					if let record = record {
						completion(.success(record))
					} else {
						completion(.failure(VCKError.unknown))
					}
				}
			case .zoneNotFound:
				self.createZoneRecord() { result in
					switch result {
					case .success:
						self.fetch(externalID: externalID, completion: completion)
					case .failure(let error):
						DispatchQueue.main.async {
							completion(.failure(error))
						}
					}
				}
			case .retry(let timeToWait):
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone fetch retry in \(timeToWait, privacy: .public) seconds.")
				self.retryIfPossible(after: timeToWait) {
					self.fetch(externalID: externalID, completion: completion)
				}
			case .userDeletedZone:
				DispatchQueue.main.async {
					completion(.failure(VCKError.userDeletedZone))
				}
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
			}
		}
	}
	
	/// Save the CKSubscription
	func save(_ subscription: CKSubscription, completion: @escaping (Result<CKSubscription, Error>) -> Void) {
		database?.save(subscription) { [weak self] savedSubscription, error in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
			case .success:
				DispatchQueue.main.async {
					completion(.success((savedSubscription!)))
				}
			case .zoneNotFound:
				self.createZoneRecord() { result in
					switch result {
					case .success:
						self.save(subscription, completion: completion)
					case .failure(let error):
						DispatchQueue.main.async {
							completion(.failure(error))
						}
					}
				}
			case .retry(let timeToWait):
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone save subscription retry in \(timeToWait, privacy: .public) seconds.")
				self.retryIfPossible(after: timeToWait) {
					self.save(subscription, completion: completion)
				}
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
			}
		}
	}
	
	/// Delete CKRecords using a CKQuery
	func delete(ckQuery: CKQuery, completion: @escaping (Result<([CKRecord], [CKRecord.ID]), Error>) -> Void) {
		
		var records = [CKRecord]()
		
		let op = CKQueryOperation(query: ckQuery)
		op.qualityOfService = Self.qualityOfService
		op.recordFetchedBlock = { record in
			records.append(record)
		}
		
		op.queryCompletionBlock = { [weak self] (cursor, error) in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}


			if let cursor = cursor {
				self.delete(cursor: cursor, carriedRecords: records, completion: completion)
			} else {
				guard !records.isEmpty else {
					DispatchQueue.main.async {
						completion(.success(([], [])))
					}
					return
				}
				
				let recordIDs = records.map { $0.recordID }
				self.modify(modelsToSave: [], recordIDsToDelete: recordIDs, strategy: .overWriteServerValue, completion: completion)
			}
			
		}
		
		database?.add(op)
	}
	
	/// Delete CKRecords using a CKQuery
	func delete(cursor: CKQueryOperation.Cursor, carriedRecords: [CKRecord], completion: @escaping (Result<([CKRecord], [CKRecord.ID]), Error>) -> Void) {
		
		var records = [CKRecord]()
		
		let op = CKQueryOperation(cursor: cursor)
		op.qualityOfService = Self.qualityOfService
		op.recordFetchedBlock = { record in
			records.append(record)
		}
		
		op.queryCompletionBlock = { [weak self] (cursor, error) in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			records.append(contentsOf: carriedRecords)
			
			if let cursor = cursor {
				self.delete(cursor: cursor, carriedRecords: records, completion: completion)
			} else {
				let recordIDs = records.map { $0.recordID }
				self.modify(modelsToSave: [], recordIDsToDelete: recordIDs, strategy: .overWriteServerValue, completion: completion)
			}
			
		}
		
		database?.add(op)
	}
	
	/// Delete a CKRecord using its recordID
	func delete(recordID: CKRecord.ID, completion: @escaping (Result<([CKRecord], [CKRecord.ID]), Error>) -> Void) {
		modify(modelsToSave: [], recordIDsToDelete: [recordID], strategy: .overWriteServerValue, completion: completion)
	}
		
	/// Delete CKRecords
	func delete(recordIDs: [CKRecord.ID], completion: @escaping (Result<([CKRecord], [CKRecord.ID]), Error>) -> Void) {
		modify(modelsToSave: [], recordIDsToDelete: recordIDs, strategy: .overWriteServerValue, completion: completion)
	}

	/// Delete a CKRecord using its externalID
	func delete(externalID: String?, completion: @escaping (Result<([CKRecord], [CKRecord.ID]), Error>) -> Void) {
		guard let externalID = externalID else {
			completion(.failure(VCKError.corruptAccount))
			return
		}

		let recordID = CKRecord.ID(recordName: externalID, zoneID: zoneID)
		modify(modelsToSave: [], recordIDsToDelete: [recordID], strategy: .overWriteServerValue, completion: completion)
	}
	
	/// Delete a CKSubscription
	func delete(subscriptionID: String, completion: @escaping (Result<Void, Error>) -> Void) {
		database?.delete(withSubscriptionID: subscriptionID) { [weak self] _, error in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
			case .success:
				DispatchQueue.main.async {
					completion(.success(()))
				}
			case .retry(let timeToWait):
                self.logger.error("\(self.zoneID.zoneName, privacy: .public) zone delete subscription retry in \(timeToWait, privacy: .public) seconds.")
				self.retryIfPossible(after: timeToWait) {
					self.delete(subscriptionID: subscriptionID, completion: completion)
				}
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
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

		let recordsToSave = modelsToSave.compactMap { $0.buildRecord() }
		let op = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
		op.savePolicy = strategy.recordSavePolicy
		op.isAtomic = true
		op.qualityOfService = Self.qualityOfService

		op.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecordIDs, error) in
			
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			let refinedResult = VCKResult.refine(error)
			
			switch refinedResult {
			case .success:
				DispatchQueue.main.async {
					self.logger.info("Successfully modified \(savedRecords?.count ?? 0, privacy: .public) records and deleted \(deletedRecordIDs?.count ?? 0, privacy: .public) records.")
					completion(.success((savedRecords ?? [], deletedRecordIDs ?? [])))
				}
			case .zoneNotFound:
				self.createZoneRecord() { result in
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

			case .partialFailure(let ckError):
				self.logger.info("Modify failed: \(ckError.localizedDescription, privacy: .public). Attempting to recover...")
				
				let remainingModelsToSave: [VCKModel] = modelsToSave.compactMap { modelToSave in
					guard let ckErrorForRecord = ckError.partialErrorsByItemID?[modelToSave.cloudKitRecordID] as? CKError else {
						return nil
					}
					
					switch ckErrorForRecord.code {
					case .batchRequestFailed:
						// Nothing wrong with this record, it was just part of the batch that failed.
						return modelToSave
					case .unknownItem:
						// The record was deleted while the user was offline, so treat it as new
						var modelToChange = modelToSave
						modelToChange.cloudKitMetaData = nil
						return modelToChange
					default:
						// Merge the model and try to save it again
						modelToSave.apply(ckErrorForRecord)
						return modelToSave
					}
					
				}
				
				self.logger.info("\(remainingModelsToSave.count, privacy: .public) records resolved. Attempting Modify again...")
				self.modify(modelsToSave: remainingModelsToSave, recordIDsToDelete: recordIDsToDelete, strategy: strategy, completion: completion)
			default:
				DispatchQueue.main.async {
					completion(.failure(error!))
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
				guard let self = self, let zoneOperation = mainThreadOperation as? CloudKitZoneApplyChangesOperation else {
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

        op.recordChangedBlock = { record in
			updatedRecords.append(record)
        }

        op.recordWithIDWasDeletedBlock = { recordID, recordType in
			let recordKey = CloudKitRecordKey(recordType: recordType, recordID: recordID)
			deletedRecordKeys.append(recordKey)
        }

        op.recordZoneFetchCompletionBlock = { zoneID ,token, _, finalChange, error in
			if case .success = VCKResult.refine(error) {
				wasChanged(updated: updatedRecords, deleted: deletedRecordKeys, token: token) { error in
					if let error {
						op.cancel()
						completion(.failure(error))
					}
				}
			}
			updatedRecords = [CKRecord]()
			deletedRecordKeys = [CloudKitRecordKey]()
        }

        op.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
			guard let self = self else {
				completion(.failure(VCKError.unknown))
				return
			}

			switch VCKResult.refine(error) {
			case .success:
				let op = CloudKitZoneApplyChangesOperation()
				
				op.completionBlock = { _ in
					completion(.success(()))
				}
				
				DispatchQueue.main.async {
					CloudKitZoneApplyChangesOperation.mainThreadOperationQueue.add(op)
				}
			case .zoneNotFound:
				self.createZoneRecord() { result in
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
					completion(.failure(error!))
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
		guard let delegate = delegate else {
			self.operationDelegate?.operationDidComplete(self)
			return
		}
		
		delegate.cloudKitDidModify(changed: updated, deleted: deleted) { [weak self] result in
			guard let self = self else { return }
			
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
