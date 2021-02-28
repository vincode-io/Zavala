//
//  EditorViewController+Share.swift
//  Zavala
//
//  Created by Maurice Parker on 2/27/21.
//

import Foundation

extension EditorViewController {
	
	var isShareUnavailable: Bool {
		return outline == nil || !outline!.isCloudKit
	}
	
	// MARK: API
	
	func share() {
		
	}
	
}
