//
//  UIWindow+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/19/21.
//

import UIKit

public extension UIWindow {
	
	var nsWindow: NSObject? {
		guard let nsWindows = NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows") as? [NSObject] else { return nil }
		for nsWindow in nsWindows {
			if nsWindow.responds(to: NSSelectorFromString("uiWindows")) {
				let uiWindows = nsWindow.value(forKeyPath: "uiWindows") as? [UIWindow] ?? []
				if uiWindows.contains(self) {
					return nsWindow
				}
			}
		}
		return nil
	}
	
}
