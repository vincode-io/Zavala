//
//  Created by Maurice Parker on 9/13/19.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public final class ManagedResourceFile: NSObject, NSFilePresenter {
	
	private var isDirty = false {
		didSet {
			debounceSaveToDiskIfNeeded()
		}
	}
	
	private var isLoading = false
	private let fileURL: URL
	private let operationQueue: OperationQueue
	private var saveDebouncer = Debouncer(duration: 5)

	private let loadCallback: () -> Void
	private let saveCallback: () -> Void

	public var presentedItemURL: URL? {
		return fileURL
	}
	
	public var presentedItemOperationQueue: OperationQueue {
		return operationQueue
	}
	
	public init(fileURL: URL, load: @escaping () -> Void, save: @escaping () -> Void) {
		
		self.fileURL = fileURL
		self.loadCallback = load
		self.saveCallback = save
		
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
	
	public func debounceSaveToDiskIfNeeded() {
		saveDebouncer.debounce { [weak self] in
			if Thread.isMainThread {
				self?.saveToDiskIfNeeded()
			} else {
				DispatchQueue.main.async {
					self?.saveToDiskIfNeeded()
				}
			}
		}
	}

	public func load() {
		isLoading = true
		loadCallback()
		isLoading = false
	}
	
	public func saveIfNecessary() {
		saveDebouncer.executeNow()
	}
	
	public func resume() {
		NSFileCoordinator.addFilePresenter(self)
	}
	
	public func suspend() {
		NSFileCoordinator.removeFilePresenter(self)
	}
	
}

private extension ManagedResourceFile {
	
	@objc func saveToDiskIfNeeded() {
		if isDirty {
			isDirty = false
			saveCallback()
		}
	}

}
