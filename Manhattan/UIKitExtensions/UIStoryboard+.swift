//
//  UIStoryboard+.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit

extension UIStoryboard {
	
	static let preferredContentSizeForFormSheetDisplay = CGSize(width: 460.0, height: 400.0)
	
	static var main: UIStoryboard {
		return UIStoryboard(name: "Main", bundle: nil)
	}
	
	static var add: UIStoryboard {
		return UIStoryboard(name: "Add", bundle: nil)
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
