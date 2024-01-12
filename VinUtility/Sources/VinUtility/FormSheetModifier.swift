//
//  FormSheetModifier.swift
//
//
//  Created by Maurice Parker on 12/27/23.
//
//  From: https://stackoverflow.com/a/64839306

#if canImport(UIKit)

import UIKit
import SwiftUI

class FormSheetWrapper<Content: View>: UIViewController, UIPopoverPresentationControllerDelegate {

	var width: CGFloat
	var height: CGFloat
	var content: () -> Content
	var onDismiss: (() -> Void)?

	private var hostVC: UIHostingController<Content>?

	required init?(coder: NSCoder) { fatalError("") }

	init(width: CGFloat, height: CGFloat, content: @escaping () -> Content) {
		self.width = width
		self.height = height
		self.content = content
		super.init(nibName: nil, bundle: nil)
	}

	func show() {
		guard hostVC == nil else { return }
		let vc = UIHostingController(rootView: content())

		let contentWidth = UIFontMetrics(forTextStyle: .body).scaledValue(for: width)
		let contentHeight = UIFontMetrics(forTextStyle: .body).scaledValue(for: height)
		
		vc.preferredContentSize = .init(width: contentWidth, height: contentHeight)

		vc.modalPresentationStyle = .formSheet
		vc.presentationController?.delegate = self
		hostVC = vc
		self.present(vc, animated: true, completion: nil)
	}

	func hide() {
		guard let vc = self.hostVC, !vc.isBeingDismissed else { return }
		dismiss(animated: true, completion: nil)
		hostVC = nil
	}

	func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		hostVC = nil
		self.onDismiss?()
	}
}

struct FormSheet<Content: View> : UIViewControllerRepresentable {

	@Binding var show: Bool
	var width: CGFloat
	var height: CGFloat
	
	let content: () -> Content

	func makeUIViewController(context: UIViewControllerRepresentableContext<FormSheet<Content>>) -> FormSheetWrapper<Content> {
		let vc = FormSheetWrapper(width: width, height: height, content: content)
		vc.onDismiss = { self.show = false }
		return vc
	}

	func updateUIViewController(_ uiViewController: FormSheetWrapper<Content>,
								context: UIViewControllerRepresentableContext<FormSheet<Content>>) {
		if show {
			uiViewController.show()
		} else {
			uiViewController.hide()
		}
	}
}

extension View {
	public func formSheet<Content: View>(isPresented: Binding<Bool>,
										 width: CGFloat,
										 height: CGFloat,
										 @ViewBuilder content: @escaping () -> Content) -> some View {
		self.background(FormSheet(show: isPresented, width: width, height: height, content: content))
	}
}


#endif
