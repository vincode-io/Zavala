//
//  EditorDisclosureButton.swift
//  Zavala
//
//  Created by Maurice Parker on 1/8/21.
//

import UIKit

class EditorDisclosureButton: UIButton {
	
	enum State {
		case expanded
		case collapsed
		case partial
	}
	
	private var currentState = State.expanded
	private let pointerInteractionDelegate = EditorDisclosureButtonInteractionDelegate()
	
	override init(frame: CGRect) {
		super.init(frame: frame)

		self.setImage(AppAssets.disclosure, for: .normal)
		self.adjustsImageWhenHighlighted = false
		self.tintColor = AppAssets.accessory
		self.imageView?.contentMode = .center
		self.imageView?.clipsToBounds = false
		self.translatesAutoresizingMaskIntoConstraints = false
		self.addInteraction(UIPointerInteraction(delegate: pointerInteractionDelegate))
		
		let dimension: CGFloat = traitCollection.userInterfaceIdiom == .mac ? 19 : 44
		NSLayoutConstraint.activate([
			self.widthAnchor.constraint(equalToConstant: dimension),
			self.heightAnchor.constraint(equalToConstant: dimension)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		// This is a really questionable hack to allow right clicks to go through the button
		let view = super.hitTest(point, with: event)
		if view == self && event == nil {
			return nil
		}
		return view
	}
	
	func toggleDisclosure() {
		switch currentState {
		case .expanded:
			setDisclosure(state: .collapsed, animated: true)
		case .collapsed:
			setDisclosure(state: .expanded, animated: true)
		case .partial:
			setDisclosure(state: .expanded, animated: true)
		}
		
	}
	
	func setDisclosure(state: State, animated: Bool) {
		guard currentState != state else { return }
		currentState = state

		switch currentState {
		case .expanded:
			accessibilityLabel = L10n.collapse
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.transform = CGAffineTransform(rotationAngle: 0)
				}
			} else {
				transform = CGAffineTransform(rotationAngle: 0)
			}
		case .collapsed:
			accessibilityLabel = L10n.expand
			let rotationAngle: CGFloat = traitCollection.horizontalSizeClass == .compact ? 1.570796 : -1.570796
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.transform = CGAffineTransform(rotationAngle: rotationAngle)
				}
			} else {
				transform = CGAffineTransform(rotationAngle: rotationAngle)
			}
		case .partial:
			accessibilityLabel = L10n.expand
			let rotationAngle: CGFloat = traitCollection.horizontalSizeClass == .compact ? 0.785398 : -0.785398
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.transform = CGAffineTransform(rotationAngle: rotationAngle)
				}
			} else {
				transform = CGAffineTransform(rotationAngle: rotationAngle)
			}
		}
	}
}

// MARK: UIPointerInteractionDelegate

class EditorDisclosureButtonInteractionDelegate: NSObject, UIPointerInteractionDelegate {
	
	func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
		var pointerStyle: UIPointerStyle? = nil

		if let interactionView = interaction.view {
			
			let parameters = UIPreviewParameters()
			let newBounds = CGRect(x: 8, y: 8, width: 28, height: 28)
			let visiblePath = UIBezierPath(roundedRect: newBounds, cornerRadius: 10)
			parameters.visiblePath = visiblePath
			
			let targetedPreview = UITargetedPreview(view: interactionView, parameters: parameters)
			pointerStyle = UIPointerStyle(effect: UIPointerEffect.automatic(targetedPreview))
		}
		return pointerStyle
	}
	
}
