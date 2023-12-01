//
//  Created by Maurice Parker on 4/20/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension UIView {
	
	/// Removes all constrains for this view as long as unowned ones only relate to the superview
	func removeConstraintsOwnedBySuperview() {
		let constraints = self.superview?.constraints.filter{
			$0.firstItem as? UIView == self || $0.secondItem as? UIView == self
		} ?? []

		self.superview?.removeConstraints(constraints)
	}
	
	func setFrameIfNotEqual(_ rect: CGRect) {
		if !self.frame.equalTo(rect) {
			self.frame = rect
		}
	}
	
	func addChildAndPin(_ view: UIView) {
		view.translatesAutoresizingMaskIntoConstraints = false
		addSubview(view)
		
		NSLayoutConstraint.activate([
			safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
			safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
		
	}
	
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
	
}
#endif
