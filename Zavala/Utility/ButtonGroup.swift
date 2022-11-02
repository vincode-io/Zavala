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
		
		var width: Int {
			switch self {
			case .navbar:
				return 48
			case .toolbar:
				return 36
			}
		}
		
		var wideWidth: Int {
			switch self {
			case .navbar:
				return 48
			case .toolbar:
				return 48
			}
		}
		
	}

	enum Alignment {
		case left
		case right
	}

	var containerWidth: CGFloat = 0 {
		didSet {
			if containerWidth > 480 {
				stackViewWidthConstraint.constant = Double(containerType.wideWidth * stackView.arrangedSubviews.count)
			} else {
				stackViewWidthConstraint.constant = Double(containerType.width * stackView.arrangedSubviews.count)
			}
		}
	}

	private let target: Any
	private let containerType: ContainerType
	private let alignment: Alignment
	private let stackView: UIStackView
	private let stackViewWidthConstraint: NSLayoutConstraint
	
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
		
		stackViewWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: 0.0)
		stackViewWidthConstraint.isActive = true
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
		stackViewWidthConstraint.constant = Double(containerType.width * stackView.arrangedSubviews.count)
		return UIBarButtonItem(customView: stackView)
	}
	
}
