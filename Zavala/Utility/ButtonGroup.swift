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
	
	enum ContainerType {
		case navbar
		case toolbar
	}

	enum Alignment {
		case left
		case right
	}

	private let target: Any
	private let containerType: ContainerType
	private let alignment: Alignment
//	private let containerWidth: CGFloat
	private let stackView: UIStackView
	
	private var width: Int {
		switch containerType {
		case .navbar:
			return 48
		case .toolbar:
			return 36
		}
	}
	
	init(target: Any, containerType: ContainerType, alignment: Alignment) {
		self.target = target
		self.containerType = containerType
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
		stackView.widthAnchor.constraint(equalToConstant: Double(width * stackView.arrangedSubviews.count)).isActive = true
		return UIBarButtonItem(customView: stackView)
	}
	
}
