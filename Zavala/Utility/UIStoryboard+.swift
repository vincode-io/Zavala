//
//  UIStoryboard+.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit

extension UIStoryboard {
	
	static let preferredContentSizeForFormSheetDisplay = CGSize(width: 460.0, height: 400.0)
	
	static var main: UIStoryboard {
		return UIStoryboard(name: "Main", bundle: nil)
	}
	
	static var settings: UIStoryboard {
		return UIStoryboard(name: "Settings", bundle: nil)
	}
	
	static var dialog: UIStoryboard {
		return UIStoryboard(name: "Dialog", bundle: nil)
	}
	
	static var openQuickly: UIStoryboard {
		return UIStoryboard(name: "OpenQuickly", bundle: nil)
	}
	
	static var image: UIStoryboard {
		return UIStoryboard(name: "Image", bundle: nil)
	}
	
	func instantiateController<T>(ofType type: T.Type = T.self) -> T where T: UIViewController {
		
		let storyboardId = String(describing: type)
		guard let viewController = instantiateViewController(withIdentifier: storyboardId) as? T else {
			print("Unable to load view with Scene Identifier: \(storyboardId)")
			fatalError()
		}
		
		return viewController
		
	}
	
}
