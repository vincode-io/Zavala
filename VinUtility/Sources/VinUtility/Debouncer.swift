//
//  Created by Maurice Parker on 11/12/23.
//

import Foundation

public struct Debouncer {
	
	private var isPaused = false
	private let duration: Double
	private var workItem: DispatchWorkItem?
	
	public init(duration: Double) {
		self.duration = duration
	}
	
	public mutating func debounce(_ work: @escaping () -> Void) {
		guard !isPaused else { return }
		
		workItem?.cancel()
		
		workItem = DispatchWorkItem {
			work()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem!)
	}
	
	public mutating func pause() {
		guard !isPaused else { return }
		executeNow()
		isPaused = true
	}
	
	public mutating func unpause() {
		guard isPaused else { return }
		isPaused = false
	}
	
	public func executeNow() {
		workItem?.perform()
	}
	
	public func cancel() {
		workItem?.cancel()
	}
	
}
