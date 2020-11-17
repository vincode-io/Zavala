//
//  MainThreadOperationBase.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import Foundation

import UIKit
import RSCore

class MainThreadOperationBase: MainThreadOperation {
	
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
	
	func run() {
		self.operationDelegate?.operationDidComplete(self)
	}
	
}
