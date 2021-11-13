//
//  ImageViewController.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 10/12/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

	@IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var imageScrollView: ImageScrollView!
	
	var image: UIImage!
	var zoomedFrame: CGRect {
		return imageScrollView.zoomedFrame
	}

	override func viewDidLoad() {
        super.viewDidLoad()
		
		closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Close")
		shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Share")

		if traitCollection.userInterfaceIdiom == .mac {
			closeButton.isHidden = true
			shareButton.tintColor = .accentColor
		}
		
        imageScrollView.setup()
        imageScrollView.imageScrollViewDelegate = self
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.initialOffset = .center
		
		if let image = image {
			imageScrollView.display(image: image)
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		#if targetEnvironment(macCatalyst)
		if let image = image {
			appDelegate.appKitPlugin?.configureViewImage(view.window?.nsWindow, width: image.size.width, height: image.size.height)
		}
		#endif
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { [weak self] context in
			self?.imageScrollView.resize()
		})
	}
	
	@IBAction func share(_ sender: Any) {
		guard let image = image else { return }
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
