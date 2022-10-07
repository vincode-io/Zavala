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
	
	enum Alighment {
		case left
		case right
	}
	
	private let target: Any
	private let alignment: Alighment
	private let stackView: UIStackView
	
	init(target: Any, alignment: Alighment) {
		self.target = target
		self.alignment = alignment
		
		stackView = UIStackView()
		stackView.distribution = .fillEqually
		stackView.isLayoutMarginsRelativeArrangement = true
		
		if alignment == .left {
			stackView.layoutMargins = UIEdgeInsets(top: 0, left: -12, bottom: 0, right: 12)
		} else {
			stackView.layoutMargins = UIEdgeInsets(top: 0, left:12, bottom: 0, right: -12)
		}
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
		stackView.widthAnchor.constraint(equalToConstant: Double(36 * stackView.arrangedSubviews.count)).isActive = true
		return UIBarButtonItem(customView: stackView)
	}
	
}
