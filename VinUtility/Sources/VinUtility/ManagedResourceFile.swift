//
//  Created by Maurice Parker on 9/13/19.
//

import Foundation
import OSLog

open class ManagedResourceFile: NSObject, NSFilePresenter, @unchecked Sendable {
	
	private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinUtility")
	private let fileURL: URL
	private let operationQueue: OperationQueue

	private let _isDirty = OSAllocatedUnfairLock<Bool>(initialState: false)
	private var isDirty: Bool {
		get {
			_isDirty.withLock { $0 }
		}
		set {
			_isDirty.withLock { $0 = newValue }
		}
	}

	private let _lastModificationDate = OSAllocatedUnfairLock<Date?>(initialState: nil)
	private var lastModificationDate: Date? {
		get {
			_lastModificationDate.withLock { $0 }
		}
		set {
			_lastModificationDate.withLock { $0 = newValue }
		}
	}

	private var saveLock = OSAllocatedUnfairLock()
	private var saveWorkItem: DispatchWorkItem?

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
	}
	
	public func presentedItemDidChange() {
		guard !isDirty else { return }
		Task { @MainActor in
			self.load()
		}
	}
	
	public func savePresentedItemChanges(completionHandler: @escaping @Sendable (Error?) -> Void) {
		Task {
			await saveIfNecessary()
			completionHandler(nil)
		}
	}
	
	public func relinquishPresentedItem(toReader reader: @escaping @Sendable (( @Sendable() -> Void)?) -> Void) {
		performWorkItem()
		reader() {}
	}
	
	public func relinquishPresentedItem(toWriter writer: @escaping @Sendable (( @Sendable () -> Void)?) -> Void) {
		performWorkItem()
		writer() {}
	}
	
	public func markAsDirty() {
		isDirty = true
		debounceSaveToDisk()
	}
	
	@MainActor
	public func load() {
		guard !isDirty else { return }
		loadFile()
	}
	
	public func saveIfNecessary() async {
		if isDirty {
			isDirty = false
			await saveFile()
		}
	}

	public func delete() {
		suspend()
		deleteFile()
	}

	public func resume() {
		NSFileCoordinator.addFilePresenter(self)
	}
	
	public func suspend() {
		performWorkItem()
		NSFileCoordinator.removeFilePresenter(self)
	}
	
	@MainActor
	open func fileDidLoad(data: Data) {
		fatalError("Function not implemented")
	}
	
	@MainActor
	open func fileWillSave() async -> Data? {
		fatalError("Function not implemented")
	}

}

// MARK: Helpers

private extension ManagedResourceFile {
	
	func debounceSaveToDisk() {
		saveLock.lock()
		defer { saveLock.unlock() }
		
		saveWorkItem?.cancel()
		saveWorkItem = DispatchWorkItem { [weak self] in
			guard let self = self else { return }
			Task {
				await self.saveIfNecessary()
			}
		}
		
		DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5.0, execute: saveWorkItem!)
	}
	
	func performWorkItem() {
		saveLock.lock()
		defer { saveLock.unlock() }

		saveWorkItem?.perform()
		saveWorkItem = nil
	}
	
	@MainActor
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
	
	func saveFile() async {
		guard let fileData = await fileWillSave() else { return }

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
