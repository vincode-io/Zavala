//
//  UINavigationBar+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/4/22.
//

import UIKit

extension UINavigationController {
	
	func configureNavBar() {
//		let standard = UINavigationBarAppearance()
//		standard.configureWithDefaultBackground()
//		standard.shadowColor = .opaqueSeparator
//		standard.shadowImage = UIImage()
//		
//		navigationBar.standardAppearance = standard
//		navigationBar.compactAppearance = standard

//		if let parentNavController = parent as? UINavigationController {
//			parentNavController.configureNavBar()
//			return
//		}

		let scrollEdge = UINavigationBarAppearance()
		scrollEdge.configureWithDefaultBackground()
		scrollEdge.shadowColor = nil
		scrollEdge.shadowImage = UIImage()

		navigationBar.scrollEdgeAppearance = scrollEdge
		if #available(iOS 15, *) {
			navigationBar.compactScrollEdgeAppearance = scrollEdge
		}
		
	}

}
