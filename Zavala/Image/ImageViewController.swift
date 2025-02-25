//
//  ImageViewController.swift
//
//  Created by Maurice Parker on 10/12/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

	@IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var shareButtonTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageScrollView: ImageScrollView!
	
	var image: UIImage!
	var zoomedFrame: CGRect {
		return imageScrollView.zoomedFrame
	}

	override func viewDidLoad() {
        super.viewDidLoad()
		
		closeButton.accessibilityLabel = NSLocalizedString("label.text.close", comment: "Close")
		shareButton.accessibilityLabel = NSLocalizedString("label.text.share", comment: "Share")

		closeButton.tintColor = .accentColor
		shareButton.tintColor = .accentColor

		if traitCollection.userInterfaceIdiom == .mac {
			closeButton.isHidden = true
			shareButtonTopConstraint.constant = -20
		}
		
        imageScrollView.setup()
        imageScrollView.imageScrollViewDelegate = self
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.initialOffset = .center
		
		if let image {
			imageScrollView.display(image: image)
		}
    }

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { [weak self] context in
			self?.imageScrollView.resize()
		})
	}
	
	@IBAction func share(_ sender: Any) {
		guard let image else { return }
		let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
		activityViewController.popoverPresentationController?.sourceView = shareButton
		activityViewController.popoverPresentationController?.sourceRect = shareButton.bounds
		present(activityViewController, animated: true)
	}
	
	@IBAction func done(_ sender: Any) {
		dismiss(animated: true)
	}
	
}

// MARK: ImageScrollViewDelegate

extension ImageViewController: ImageScrollViewDelegate {

	func imageScrollViewDidGestureSwipeUp(imageScrollView: ImageScrollView) {
		dismiss(animated: true)
	}
	
	func imageScrollViewDidGestureSwipeDown(imageScrollView: ImageScrollView) {
		dismiss(animated: true)
	}
		
}
