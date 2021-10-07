//
//  ZavalaIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/7/21.
//

import UIKit
import Templeton

protocol ZavalaIntentHandler {
	
}

extension ZavalaIntentHandler {
	
	func resume() {
		if UIApplication.shared.applicationState == .background {
			AccountManager.shared.resume()
		}
	}
	
	func suspend() {
		if UIApplication.shared.applicationState == .background {
			AccountManager.shared.suspend()
		}
	}
	
}
