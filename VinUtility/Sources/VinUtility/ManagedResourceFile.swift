//
//  Created by Maurice Parker on 9/13/19.
//

import Foundation
import AsyncAlgorithms
import OSLog

open class ManagedResourceFile: NSObject, NSFilePresenter {
	
	private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinUtility")

	private var isDirty = false
	private let fileURL: URL
	private let operationQueue: OperationQueue
	private var saveTask: Task<(), Never>?
	private var saveChannel = AsyncChannel<(() -> Void)>()
	private var lastModificationDate: Date?

	public var presentedItemURL: URL? {
		return fileURL
	}
	
	public var presentedItemOperationQueue: OperationQueue {
		return operationQueue
	}
	
	public init(fileURL: URL) {
		
		self.fileURL = fileURL
		
		operationQueue = OperationQueue()
		operationQueue.qualityOfService = .userInteractive
		operationQueue.maxConcurrentOperationCount = 1
	
		super.init()
		
		NSFileCoordinator.addFilePresenter(self)
		
		startSaveTask()
	}
	
	public func presentedItemDidChange() {
		guard !isDirty else { return }
		Task { @MainActor in
			self.load()
		}
	}
	
	public func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
		saveIfNecessary()
		completionHandler(nil)
	}
	
	public func relinquishPresentedItem(toReader reader: @escaping ((() -> Void)?) -> Void) {
		stopSaveTask()
		reader() {
			self.startSaveTask()
		}
	}
	
	public func relinquishPresentedItem(toWriter writer: @escaping ((() -> Void)?) -> Void) {
		stopSaveTask()
		writer() {
			self.startSaveTask()
		}
	}
	
	public func markAsDirty() {
		isDirty = true
		debounceSaveToDisk()
	}
	
	public func load() {
		guard !isDirty else { return }
		loadFile()
	}
	
	public func saveIfNecessary() {
		if isDirty {
			isDirty = false
			saveFile()
		}
	}

	public func delete() {
		suspend()
		deleteFile()
	}

	public func resume() {
		NSFileCoordinator.addFilePresenter(self)
		startSaveTask()
	}
	
	public func suspend() {
		saveTask?.cancel()
		saveTask = nil
		saveChannel.finish()
		NSFileCoordinator.removeFilePresenter(self)
	}
	
	open func fileDidLoad(data: Data) {
		fatalError("Function not implemented")
	}
	
	open func fileWillSave() -> Data? {
		fatalError("Function not implemented")
	}

}

// MARK: Helpers

private extension ManagedResourceFile {
	
	func startSaveTask() {
		saveTask = Task {
			for await save in saveChannel.debounce(for: .seconds(5.0)) {
				if !Task.isCancelled {
					save()
				}
			}
		}
	}
	
	func stopSaveTask() {
		saveTask?.cancel()
		saveTask = nil
	}
	
	func debounceSaveToDisk() {
		Task {
			await saveChannel.send(saveIfNecessary)
		}
	}
	
	func restartActivityMonitoring() {
		stopSaveTask()
		startSaveTask()
	}

	func loadFile() {
		var fileData: Data? = nil
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: self)
		
		fileCoordinator.coordinate(readingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { readURL in
			do {
				let resourceValues = try readURL.resourceValues(forKeys: [.contentModificationDateKey])
				if lastModificationDate != resourceValues.contentModificationDate {
					lastModificationDate = resourceValues.contentModificationDate
					fileData = try Data(contentsOf: readURL)
				}
			} catch {
				logger.error("Account read from disk failed: \(error.localizedDescription, privacy: .public)")
			}
		})
		
		if let error = errorPointer?.pointee {
			logger.error("Account read from disk coordination failed: \(error.localizedDescription, privacy: .public)")
		}

		guard let fileData else { return }
		
		fileDidLoad(data: fileData)
	}
	
	func saveFile() {
		guard let fileData = fileWillSave() else { return }

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: self)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try fileData.write(to: writeURL)
				let resourceValues = try writeURL.resourceValues(forKeys: [.contentModificationDateKey])
				lastModificationDate = resourceValues.contentModificationDate
			} catch let error as NSError {
				logger.error("Save to disk failed: \(error.localizedDescription, privacy: .public)")
			}
		})
		
		if let error = errorPointer?.pointee {
			logger.error("Save to disk coordination failed: \(error.localizedDescription, privacy: .public)")
		}
	}
	
	func deleteFile() {
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: self)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [.forDeleting], error: errorPointer, byAccessor: { writeURL in
			do {
				if FileManager.default.fileExists(atPath: writeURL.path) {
					try FileManager.default.removeItem(atPath: writeURL.path)
				}
			} catch let error as NSError {
				logger.error("Delete from disk failed: \(error.localizedDescription, privacy: .public)")
			}
		})
		
		if let error = errorPointer?.pointee {
			logger.error("Delete from disk coordination failed: \(error.localizedDescription, privacy: .public)")
		}
	}

}
