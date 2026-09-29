//
//  ButtonGroup.swift
//  Zavala
//
//  Created by Maurice Parker on 2/13/22.
//

import UIKit

@MainActor
class ButtonGroup: NSObject {
	
	class Button: UIButton {
		var popoverButtonGroup: ButtonGroup?
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
			updateStackViewWidth()
		}
	}
	
	var size: CGSize {
		return CGSize(width: width, height: height)
	}

	private let stackView: UIStackView
	private let stackViewWidthConstraint: NSLayoutConstraint?
	private var barButtonItem: UIBarButtonItem?

	private let hostController: UIViewController
	private let containerType: ContainerType

	private var popoverController: UIViewController?

	private var width: CGFloat {
		if containerWidth >= 440 {
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

		stackViewWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: 0)
		stackViewWidthConstraint?.isActive = true
		
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
	
	func addButton(label: String, image: UIImage, target: Any? = nil, selector: Selector? = nil, showMenu: Bool = false) -> Button {
		let button = Button(type: .system)
		button.accessibilityLabel = label
		if let selector {
			button.addTarget(target, action: selector, for: .touchUpInside)
		}
		button.isAccessibilityElement = true
		button.showsMenuAsPrimaryAction = showMenu
		button.tintColor = .label
		button.setImage(image.applyingSymbolConfiguration(.init(weight: .semibold)), for: .normal)
		
		stackView.addArrangedSubview(button)
		updateStackViewWidth()

		return button
	}
	
	func remove(_ button: Button) {
		stackView.removeArrangedSubview(button)
		button.removeFromSuperview()
		updateStackViewWidth()
	}
	
	func insert(_ button: Button, at: Int) {
		stackView.insertArrangedSubview(button, at: at)
		updateStackViewWidth()
	}
	
	func buildBarButtonItem() -> UIBarButtonItem {
		barButtonItem = UIBarButtonItem(customView: stackView)
		updateStackViewWidth()
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
		popoverController?.view = nil
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
	
	func updateStackViewWidth() {
		stackViewWidthConstraint?.constant = width
	}
	
}
