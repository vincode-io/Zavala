//
//  ButtonGroup.swift
//  Zavala
//
//  Created by Maurice Parker on 2/13/22.
//

import UIKit

class ButtonGroup: NSObject {
	
	class Button: UIButton {
		var popoverButtonGroup: ButtonGroup?
		
		override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
			return bounds.insetBy(dx: -10, dy: -10).contains(point)
		}
	}
	
	enum ContainerType {
		case standard
		case compactable
		
		var height: CGFloat {
			return 44
		}
		
		var width: CGFloat {
			switch self {
			case .standard:
				return 44
			case .compactable:
				return 36
			}
		}
		
		var wideWidth: CGFloat {
			return 44
		}
		
	}

	enum Alignment {
		case left
		case right
		case none
	}

	var containerWidth: CGFloat = 0 {
		didSet {
			updateBarButtonItemWidth()
		}
	}
	
	var size: CGSize {
		return CGSize(width: width, height: height)
	}

	private let stackView: UIStackView
	private var barButtonItem: UIBarButtonItem?

	private let hostController: UIViewController
	private let containerType: ContainerType

	private var popoverController: UIViewController?

	private var width: CGFloat {
		if containerWidth > 480 {
			return containerType.wideWidth * CGFloat(stackView.arrangedSubviews.count)
		} else {
			return containerType.width * CGFloat(stackView.arrangedSubviews.count)
		}
	}
	
	private var height: CGFloat {
		return containerType.height
	}

	init(hostController: UIViewController, containerType: ContainerType, alignment: Alignment) {
		self.hostController = hostController
		self.containerType = containerType
		
		stackView = UIStackView()
		stackView.isLayoutMarginsRelativeArrangement = true

		switch alignment {
		case .left:
			stackView.distribution = .fillEqually
			stackView.layoutMargins = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
		case .right:
			stackView.distribution = .fillEqually
			stackView.layoutMargins = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
		default:
			stackView.distribution = .equalSpacing
		}
	}
	
	func addButton(label: String, image: UIImage, selector: String? = nil, showMenu: Bool = false) -> Button {
		let button = Button(type: .system)
		button.accessibilityLabel = label
		button.setImage(image, for: .normal)
		if let selector {
			button.addTarget(hostController, action: Selector(selector), for: .touchUpInside)
		}
		button.isAccessibilityElement = true
		button.showsMenuAsPrimaryAction = showMenu
		
		stackView.addArrangedSubview(button)
		
		return button
	}
	
	func remove(_ button: Button) {
		stackView.removeArrangedSubview(button)
		button.removeFromSuperview()
		updateBarButtonItemWidth()
	}
	
	func insert(_ button: Button, at: Int) {
		stackView.insertArrangedSubview(button, at: at)
		updateBarButtonItemWidth()
	}
	
	func buildBarButtonItem() -> UIBarButtonItem {
		barButtonItem = UIBarButtonItem(customView: stackView)
		updateBarButtonItemWidth()
		return barButtonItem!
	}
	
	func showPopOverMenu(for button: Button) {
		guard let popoverButtonGroup = button.popoverButtonGroup else { return }
		
		dismissPopOverMenu()
		
		popoverController = UIViewController()
		popoverController!.modalPresentationStyle = .popover
		popoverController!.view = popoverButtonGroup.stackView
		popoverController!.preferredContentSize = popoverButtonGroup.size
		popoverController!.popoverPresentationController?.delegate = self
		popoverController!.popoverPresentationController?.sourceView = button
		hostController.present(popoverController!, animated: true, completion: nil)
	}
	
	func dismissPopOverMenu() {
		popoverController?.dismiss(animated: true)
		popoverController = nil
	}
	
}

// MARK: UIPopoverPresentationControllerDelegate

extension ButtonGroup: UIPopoverPresentationControllerDelegate {
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
	
}

// MARK: Helpers

private extension ButtonGroup {
	
	func updateBarButtonItemWidth() {
		barButtonItem?.width = width
	}
	
}
