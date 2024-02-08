//
//  Created by Maurice Parker on 9/13/19.
//

import Foundation
import OSLog

open class ManagedResourceFile: NSObject, NSFilePresenter {
	
	private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinUtility")

	private var isDirty = false {
		didSet {
			debounceSaveToDiskIfNeeded()
		}
	}
	
	private var isLoading = false
	private let fileURL: URL
	private let operationQueue: OperationQueue
	private var saveDebouncer = Debouncer(duration: 5)
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
	}
	
	public func presentedItemDidChange() {
		guard !isDirty else { return }
		DispatchQueue.main.async {
			self.load()
		}
	}
	
	public func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
		saveIfNecessary()
		completionHandler(nil)
	}
	
	public func relinquishPresentedItem(toReader reader: @escaping ((() -> Void)?) -> Void) {
		saveDebouncer.pause()
		reader() {
			self.saveDebouncer.unpause()
		}
	}
	
	public func relinquishPresentedItem(toWriter writer: @escaping ((() -> Void)?) -> Void) {
		saveDebouncer.pause()
		writer() {
			self.saveDebouncer.unpause()
		}
	}
	
	public func markAsDirty() {
		if !isLoading {
			isDirty = true
		}
	}
	
	public func load() {
		isLoading = true
		loadFile()
		isLoading = false
	}
	
	public func saveIfNecessary() {
		saveDebouncer.executeNow()
	}

	public func delete() {
		deleteFile()
	}

	public func resume() {
		NSFileCoordinator.addFilePresenter(self)
	}
	
	public func suspend() {
		NSFileCoordinator.removeFilePresenter(self)
	}
	
	open func fileDidLoad(data: Data) {
		fatalError("Function not implemented")
	}
	
	open func fileWillSave() -> Data? {
		fatalError("Function not implemented")
	}

}

private extension ManagedResourceFile {
	
	func debounceSaveToDiskIfNeeded() {
		saveDebouncer.debounce { [weak self] in
			self?.saveToDiskIfNeeded()
		}
	}

	func saveToDiskIfNeeded() {
		if isDirty {
			isDirty = false
			saveFile()
		}
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

		print("****** saveFile: \(fileURL.absoluteString)")

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
