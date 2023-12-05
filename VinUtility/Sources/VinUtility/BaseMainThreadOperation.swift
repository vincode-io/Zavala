//
//  Created by Maurice Parker on 11/17/20.
//

import Foundation

open class BaseMainThreadOperation: MainThreadOperation {
	
	public var isCanceled = false
	public var id: Int?
	public weak var operationDelegate: MainThreadOperationDelegate?
	public var name: String? {
		get {
			return String(describing: self)
		}
		set {
		}
	}
	public var completionBlock: MainThreadOperation.MainThreadOperationCompletionBlock?
	public var error: Error?
	
	public init() {
		
	}
	
	open func run() {
		self.operationDelegate?.operationDidComplete(self)
	}
	
}
