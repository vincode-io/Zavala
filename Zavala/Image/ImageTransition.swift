//
//  ImageAnimator.swift
//
//  Created by Maurice Parker on 10/15/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import UIKit

protocol ImageTransitionDelegate: AnyObject {
	func hideImage(_: ImageTransition, frame: CGRect);
	func unhideImage(_: ImageTransition);
}

class ImageTransition: NSObject, UIViewControllerAnimatedTransitioning {

	var presenting = true
	var originFrame: CGRect!
	var maskFrame: CGRect!
	var originImage: UIImage!

	init(delegate: ImageTransitionDelegate) {
		self.delegate = delegate
	}
	
	private weak var delegate: ImageTransitionDelegate?
	private let duration = 0.4
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return duration
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		if presenting {
			animateTransitionPresenting(using: transitionContext)
		} else {
			animateTransitionReturning(using: transitionContext)
		}
	}
	
	private func animateTransitionPresenting(using transitionContext: UIViewControllerContextTransitioning) {

		let imageView = UIImageView(image: originImage)
		imageView.frame = originFrame
		
		let fromView = transitionContext.view(forKey: .from)!
		fromView.removeFromSuperview()

		transitionContext.containerView.backgroundColor = AppAssets.fullScreenBackgroundColor
		transitionContext.containerView.addSubview(imageView)
		
		delegate?.hideImage(self, frame: originFrame)
		
		UIView.animate(
			withDuration: duration,
			delay:0.0,
			usingSpringWithDamping: 0.6,
			initialSpringVelocity: 0.2,
			animations: {
				let imageController = transitionContext.viewController(forKey: .to) as! ImageViewController
				imageView.frame = imageController.zoomedFrame
			}, completion: { _ in
				imageView.removeFromSuperview()
				let toView = transitionContext.view(forKey: .to)!
				transitionContext.containerView.addSubview(toView)
				transitionContext.completeTransition(true)
		})
	}
	
	private func animateTransitionReturning(using transitionContext: UIViewControllerContextTransitioning) {
		let imageController = transitionContext.viewController(forKey: .from) as! ImageViewController
		let imageView = UIImageView(image: originImage)
		imageView.frame = imageController.zoomedFrame
		
		let fromView = transitionContext.view(forKey: .from)!
		let windowFrame = fromView.window!.frame
		fromView.removeFromSuperview()
		
		let toView = transitionContext.view(forKey: .to)!
		transitionContext.containerView.addSubview(toView)
		
		let maskingView = UIView()
		
		let fullMaskFrame = CGRect(x: windowFrame.minX, y: maskFrame.minY, width: windowFrame.width, height: maskFrame.height)
        let path = UIBezierPath(rect: fullMaskFrame)
        let maskLayer = CAShapeLayer()
		maskLayer.path = path.cgPath
		maskingView.layer.mask = maskLayer
		
		maskingView.addSubview(imageView)
		transitionContext.containerView.addSubview(maskingView)

		UIView.animate(
			withDuration: duration,
			delay:0.0,
			usingSpringWithDamping: 0.6,
			initialSpringVelocity: 0.2,
			animations: {
				imageView.frame = self.originFrame
			}, completion: { _ in
				self.delegate?.unhideImage(self)
				imageView.removeFromSuperview()
				transitionContext.completeTransition(true)
		})
	}
	
}
