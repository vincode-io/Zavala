//
//  ToolbarButtonGroup.swift
//  Zavala
//
//  Created by Maurice Parker on 2/13/22.
//

import UIKit

struct ButtonGroup {
	
	class Button: UIButton {
		override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
			return bounds.insetBy(dx: -10, dy: -10).contains(point)
		}
	}
	
	enum Location: CGFloat {
		case navBar = 16
		case toolBar = 14
	}
	
	private let target: Any
	private let stackView: UIStackView
	
	init(target: Any, location: Location) {
		self.target = target
		
		stackView = UIStackView()
		stackView.alignment = .center
		stackView.spacing = location.rawValue
	}
	
	func addButton(label: String, image: UIImage, selector: String? = nil, showMenu: Bool = false) -> UIButton {
		let button = Button(type: .system)
		
		button.accessibilityLabel = label
		button.setImage(image, for: .normal)
		if let selector {
			button.addTarget(target, action: Selector(selector), for: .touchUpInside)
		}
		button.isAccessibilityElement = true
		button.showsMenuAsPrimaryAction = showMenu
		
		stackView.addArrangedSubview(button)
		
		return button
	}
	
	func buildBarButtonItem() -> UIBarButtonItem {
		return UIBarButtonItem(customView: stackView)
	}
	
}
