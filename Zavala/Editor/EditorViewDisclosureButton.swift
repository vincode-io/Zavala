//
//  EditorViewDisclosureButton.swift
//  Zavala
//
//  Created by Maurice Parker on 1/8/21.
//

import UIKit

class EditorViewDisclosureButton: UIButton {
	
	private var isDisclosed = true
	private let pointerInteractionDelegate = EditorViewDisclosureButtonInteractionDelegate()
	
	override init(frame: CGRect) {
		super.init(frame: frame)

		self.setImage(AppAssets.disclosure, for: .normal)
		self.adjustsImageWhenHighlighted = false
		self.tintColor = AppAssets.accessory
		self.imageView?.contentMode = .center
		self.imageView?.clipsToBounds = false
		self.translatesAutoresizingMaskIntoConstraints = false
		self.addInteraction(UIPointerInteraction(delegate: pointerInteractionDelegate))
		
		let dimension: CGFloat = traitCollection.userInterfaceIdiom == .mac ? 25 : 44
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
		if event == nil, let view = superview?.hitTest(point, with: event) {
			return view
		}
		return super.hitTest(point, with: event)
	}
	
	func toggleDisclosure() {
		setDisclosure(isExpanded: !isDisclosed, animated: true)
	}
	
	func setDisclosure(isExpanded: Bool, animated: Bool) {
		guard isDisclosed != isExpanded else { return }
		isDisclosed = isExpanded

		if isDisclosed {
			accessibilityLabel = L10n.collapse
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.transform = CGAffineTransform(rotationAngle: 0)
				}
			} else {
				transform = CGAffineTransform(rotationAngle: 0)
			}
		} else {
			accessibilityLabel = L10n.expand
			let rotationAngle: CGFloat = traitCollection.horizontalSizeClass == .compact ? 1.570796 : -1.570796
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

class EditorViewDisclosureButtonInteractionDelegate: NSObject, UIPointerInteractionDelegate {
	
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
