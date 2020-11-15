//
//  ManagedResourceFile.swift
//
//
//  Created by Maurice Parker on 9/13/19.
//

import Foundation
import RSCore

public final class ManagedResourceFile: NSObject, NSFilePresenter {
	
	private var isDirty = false {
		didSet {
			queueSaveToDiskIfNeeded()
		}
	}
	
	private var isLoading = false
	private let fileURL: URL
	private let operationQueue: OperationQueue
	private let saveQueue = CoalescingQueue(name: "Save Queue", interval: 2.0)

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
		operationQueue.maxConcurrentOperationCount = 1
	
		super.init()
		
		NSFileCoordinator.addFilePresenter(self)
	}
	
	public func presentedItemDidChange() {
		DispatchQueue.main.async {
			self.load()
		}
	}
	
	public func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
		saveIfNecessary()
		completionHandler(nil)
	}
	
	public func relinquishPresentedItem(toReader reader: @escaping ((() -> Void)?) -> Void) {
		saveQueue.isPaused = true
		reader() {
			self.saveQueue.isPaused = false
		}
	}
	
	public func relinquishPresentedItem(toWriter writer: @escaping ((() -> Void)?) -> Void) {
		saveQueue.isPaused = true
		writer() {
			self.saveQueue.isPaused = false
		}
	}
	
	public func markAsDirty() {
		if !isLoading {
			isDirty = true
		}
	}
	
	public func queueSaveToDiskIfNeeded() {
		saveQueue.add(self, #selector(saveToDiskIfNeeded))
	}

	public func load() {
		isLoading = true
		loadCallback()
		isLoading = false
	}
	
	public func saveIfNecessary() {
		saveQueue.performCallsImmediately()
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
