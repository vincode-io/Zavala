//
//  ValueStepper.swift
//  http://github.com/BalestraPatrick/ValueStepper
//
//  Created by Patrick Balestra on 2/16/16.
//  Copyright © 2016 Patrick Balestra. All rights reserved.
//

import UIKit
import VinOutlineKit

/// Button tags
///
/// - decrease: decrease button has tag 0.
/// - increase: increase button has tag 1.
private enum Button: Int {
	case decrease
	case increase
}

@IBDesignable open class ValueStepper: UIControl {

	// MARK - Public variables

	/// Current value and sends UIControlEventValueChanged when modified.
	@IBInspectable public var value: Double = 0.0 {
		didSet {
			if value > maximumValue || value < minimumValue {
				// Value is possibly out of range, it means we're setting up the values so discard any update to the UI.
			} else if oldValue != value {
				sendActions(for: .valueChanged)
				setFormattedValue(value)
				setState()
			}
		}
	}

	/// Minimum value that must be less than the maximum value.
	@IBInspectable public var minimumValue: Double = 0.0 {
		didSet {
			setState()
		}
	}

	/// Maximum value that must be greater than the minimum value.
	@IBInspectable public var maximumValue: Double = 1.0 {
		didSet {
			setState()
		}
	}

	/// When set to true, the user can tap the label and manually enter a value.
	@IBInspectable public var enableManualEditing: Bool = false {
		didSet {
			valueLabel.isUserInteractionEnabled = enableManualEditing
		}
	}

	/// The value added/subtracted when one of the two buttons is pressed.
	@IBInspectable public var stepValue: Double = 0.1

	/// When set to true, keeping a button pressed will continuously increase/decrease the value every 0.1s.
	@IBInspectable public var autorepeat: Bool = true

	/// The background color of the stepper buttons while pressed.
	@IBInspectable public var highlightedBackgroundColor: UIColor = UIColor(white: 1.0, alpha: 0.1)

	/// The color of the +/- icons when in normal state.
	@IBInspectable public var iconButtonColor: UIColor = .white

	/// The color of the +/- icons when in disabled state.
	@IBInspectable public var disabledIconButtonColor: UIColor = .gray

	/// The color of the +/- buttons background when in disabled state.
	@IBInspectable public var disabledBackgroundButtonColor: UIColor = .clear

	/// The background color of the plus and minus buttons.
	@IBInspectable public var backgroundButtonColor: UIColor = .clear {
		didSet {
			decreaseButton.backgroundColor = backgroundButtonColor
			increaseButton.backgroundColor = backgroundButtonColor
		}
	}

	/// The background color of the center view that contains the value label.
	@IBInspectable public var backgroundLabelColor: UIColor = .clear {
		didSet {
			valueLabel.backgroundColor = backgroundLabelColor
		}
	}

	/// The text color of the value label in positioned in the center.
	@IBInspectable public var labelTextColor: UIColor = .white {
		didSet {
			valueLabel.textColor = labelTextColor
		}
	}

	/// Describes the format of the value.
	public var numberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.maximumFractionDigits = 2
		return formatter
		}() {
		didSet {
			setFormattedValue(value)
		}
	}

	// Default width of the stepper. Taken from the official UIStepper object.
	public let defaultWidth = 141.0

	// Default height of the stepper. Taken from the official UIStepper object.
	public let defaultHeight = 29.0

	/// Value label that displays the current value displayed at the center of the stepper.
	public let valueLabel: UILabel = {
		let label = UILabel()
		label.textAlignment = .center
		label.minimumScaleFactor = 0.5
		label.adjustsFontSizeToFitWidth = true
		return label
	}()

	// MARK - Private variables

	/// Decrease button positioned on the left of the stepper.
	internal lazy var decreaseButton: UIButton = {
		let button = UIButton(type: .custom)
		button.tag = Button.decrease.rawValue
		button.backgroundColor = backgroundButtonColor
		return button
	}()

	/// Increase button positioned on the right of the stepper.
	internal lazy var increaseButton: UIButton = {
		let button = UIButton(type: .custom)
		button.backgroundColor = .clear
		button.tag = Button.increase.rawValue
		return button
	}()

	// Decrease (-) button layer. Declared here because we can change its color when not enabled.
	private var decreaseLayer = CAShapeLayer()

	// Increase (+) button layer. Declared here because we can change its color when not enabled.
	private var increaseLayer = CAShapeLayer()

	// Left separator.
	private var leftSeparator = CAShapeLayer()

	// Right separator.
	private var rightSeparator = CAShapeLayer()

	// Timer used in case that autorepeat is true to change the value continuously.
	private var continuousTimer: Timer? {
		didSet {
			if let timer = oldValue {
				timer.invalidate()
			}
		}
	}

	// MARK: Initializers

	override init(frame: CGRect) {
		// Override frame with default width and height
		let frameWithDefaultSize = CGRect(x: Double(frame.origin.x), y: Double(frame.origin.y), width: defaultWidth, height: defaultHeight)
		super.init(frame: frameWithDefaultSize)
		setUp()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUp()
	}

	private func setUp() {
		addSubview(decreaseButton)
		addSubview(valueLabel)
		addSubview(increaseButton)

		// Control events
		decreaseButton.addTarget(self, action: #selector(decrease(_:)), for: [.touchUpInside, .touchCancel])
		increaseButton.addTarget(self, action: #selector(increase(_:)), for: [.touchUpInside, .touchCancel])
		increaseButton.addTarget(self, action: #selector(stopContinuous(_:)), for: .touchUpOutside)
		decreaseButton.addTarget(self, action: #selector(stopContinuous(_:)), for: .touchUpOutside)
		decreaseButton.addTarget(self, action: #selector(selected(_:)), for: .touchDown)
		increaseButton.addTarget(self, action: #selector(selected(_:)), for: .touchDown)

		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelPressed(_:)))
		valueLabel.addGestureRecognizer(tapGesture)
	}

	// MARK: Storyboard preview setup

	override open func prepareForInterfaceBuilder() {
		setUp()
	}

	open override var intrinsicContentSize: CGSize {
		return CGSize(width: defaultWidth, height: defaultHeight)
	}

	override public static var requiresConstraintBasedLayout: Bool {
		return true
	}

	// MARK: Lifecycle

	open override func layoutSubviews() {
		// Size constants
		let sliceWidth = bounds.width / 3
		let sliceHeight = bounds.height

		// Set frames
		decreaseButton.frame = CGRect(x: 0, y: 0, width: sliceWidth, height: sliceHeight)
		valueLabel.frame = CGRect(x: sliceWidth, y: 0, width: sliceWidth, height: sliceHeight)
		increaseButton.frame = CGRect(x: sliceWidth * 2, y: 0, width: sliceWidth, height: sliceHeight)

		// Set initial formatted value
		setFormattedValue(value)
	}

	open override func draw(_ rect: CGRect) {
		// Size constants
		let sliceWidth = bounds.width / 3
		let sliceHeight = bounds.height
		let thickness = 1.0 as CGFloat
		let iconSize: CGFloat = sliceHeight * 0.6

		valueLabel.backgroundColor = backgroundLabelColor
		valueLabel.textColor = labelTextColor

		// Layer customizations
		layer.borderColor = tintColor.cgColor
		layer.borderWidth = 1.0
		layer.cornerRadius = 4.0
		backgroundColor = .clear
		clipsToBounds = true

		let leftPath = UIBezierPath()
		// Left separator line
		leftPath.move(to: CGPoint(x: sliceWidth, y: 0.0))
		leftPath.addLine(to: CGPoint(x: sliceWidth, y: sliceHeight))
		tintColor.setStroke()
		leftPath.stroke()

		// Set left separator layer
		leftSeparator.path = leftPath.cgPath
		leftSeparator.strokeColor = tintColor.cgColor
		layer.addSublayer(leftSeparator)

		// Right separator line
		let rightPath = UIBezierPath()
		rightPath.move(to: CGPoint(x: sliceWidth * 2, y: 0.0))
		rightPath.addLine(to: CGPoint(x: sliceWidth * 2, y: sliceHeight))
		tintColor.setStroke()
		rightPath.stroke()

		// Set right separator layer
		rightSeparator.path = rightPath.cgPath
		rightSeparator.strokeColor = tintColor.cgColor
		layer.addSublayer(rightSeparator)

		// - path
		let decreasePath = UIBezierPath()
		decreasePath.lineWidth = thickness
		// Horizontal + line
		decreasePath.move(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5, y: sliceHeight / 2 + 0.5))
		decreasePath.addLine(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5 + iconSize, y: sliceHeight / 2 + 0.5))
		tintColor.setStroke()
		decreasePath.stroke()

		// Create layer so that we can dynamically change its color when not enabled
		decreaseLayer.path = decreasePath.cgPath
		decreaseLayer.strokeColor = iconButtonColor.cgColor
		layer.addSublayer(decreaseLayer)

		// + path
		let increasePath = UIBezierPath()
		increasePath.lineWidth = thickness
		// Horizontal + line
		increasePath.move(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5 + sliceWidth * 2, y: sliceHeight / 2 + 0.5))
		increasePath.addLine(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5 + iconSize + sliceWidth * 2, y: sliceHeight / 2 + 0.5))
		// Vertical + line
		increasePath.move(to: CGPoint(x: sliceWidth / 2 + 0.5 + sliceWidth * 2, y: (sliceHeight / 2) - (iconSize / 2) + 0.5))
		increasePath.addLine(to: CGPoint(x: sliceWidth / 2 + 0.5 + sliceWidth * 2, y: (sliceHeight / 2) + (iconSize / 2) + 0.5))
		tintColor.setStroke()
		increasePath.stroke()

		// Create layer so that we can dynamically change its color when not enabled
		increaseLayer.path = increasePath.cgPath
		increaseLayer.strokeColor = iconButtonColor.cgColor
		layer.addSublayer(increaseLayer)

		// Set initial buttons state
		setState()
	}

	// MARK: Control Events

	@objc func decrease(_ sender: UIButton) {
		continuousTimer = nil
		decreaseValue()
	}

	@objc func increase(_ sender: UIButton) {
		continuousTimer = nil
		increaseValue()
	}

	@objc func continuousIncrement(_ timer: Timer) {
		// Check which one of the two buttons was continuously pressed
		let userInfo = timer.userInfo as! Dictionary<String, AnyObject>
		guard let sender = userInfo["sender"] as? UIButton else { return }

		if sender.tag == Button.decrease.rawValue {
			decreaseValue()
		} else {
			increaseValue()
		}
	}

	@objc func selected(_ sender: UIButton) {
		// Start a timer to handle the continuous pressed case
		if autorepeat {
			continuousTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(continuousIncrement), userInfo: ["sender" : sender], repeats: true)
		}
		sender.backgroundColor = highlightedBackgroundColor
	}

	@objc func stopContinuous(_ sender: UIButton) {
		// When dragged outside, stop the timer.
		continuousTimer = nil
	}

	func increaseValue() {
		let roundedValue = value.rounded(digits: numberFormatter.maximumFractionDigits)
		if roundedValue + stepValue <= maximumValue && roundedValue + stepValue >= minimumValue {
			value = roundedValue + stepValue
		}
	}

	func decreaseValue() {
		let roundedValue = value.rounded(digits: numberFormatter.maximumFractionDigits)
		if roundedValue - stepValue <= maximumValue && roundedValue - stepValue >= minimumValue {
			value = roundedValue - stepValue
		}
	}

	@objc func labelPressed(_ sender: UITapGestureRecognizer) {
		let alertController = UIAlertController(title: "Enter Value", message: nil, preferredStyle: .alert)
		alertController.addTextField { textField in
			textField.placeholder = "Value"
			textField.keyboardType = .decimalPad
		}
		alertController.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
			if let newString = alertController.textFields?.first?.text, let newValue = Double(newString) {
				if newValue >= self.minimumValue || newValue <= self.maximumValue {
					self.value = newValue
				}
			}
		})
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		getTopMostViewController()?.present(alertController, animated: true, completion: nil)
	}

	// MARK: Actions

	// Set correct state of the buttons (in case we reached the minimum or maximum value).
	private func setState() {
		if value >= maximumValue {
			increaseButton.isEnabled = false
			increaseButton.backgroundColor = disabledBackgroundButtonColor
			increaseLayer.strokeColor = disabledIconButtonColor.cgColor
			decreaseButton.isEnabled = true
			if continuousTimer == nil {
				decreaseButton.backgroundColor = backgroundButtonColor
			}
			continuousTimer = nil
		} else if value <= minimumValue {
			increaseButton.isEnabled = true
			if continuousTimer == nil {
				increaseButton.backgroundColor = backgroundButtonColor
			}
			decreaseButton.isEnabled = false
			decreaseButton.backgroundColor = disabledBackgroundButtonColor
			decreaseLayer.strokeColor = disabledIconButtonColor.cgColor
			continuousTimer = nil
		} else {
			increaseButton.isEnabled = true
			increaseButton.backgroundColor = backgroundButtonColor
			increaseLayer.strokeColor = tintColor.cgColor
			decreaseButton.isEnabled = true
			decreaseButton.backgroundColor = backgroundButtonColor
			decreaseLayer.strokeColor = tintColor.cgColor
		}
	}

	// Display the value with the correctly formatted value.
	private func setFormattedValue(_ value: Double) {
		valueLabel.text = numberFormatter.string(from: NSNumber(value: value))
	}

	// Update all the subviews tintColor properties.
	open override func tintColorDidChange() {
		layer.borderColor = tintColor.cgColor
		iconButtonColor = tintColor
		valueLabel.textColor = labelTextColor
		leftSeparator.strokeColor = tintColor.cgColor
		rightSeparator.strokeColor = tintColor.cgColor
		increaseLayer.strokeColor = tintColor.cgColor
		decreaseLayer.strokeColor = tintColor.cgColor
	}

	// MARK: Helpers

	func getTopMostViewController() -> UIViewController? {
		if var topController = UIApplication.shared.foregroundActiveScene?.keyWindow?.rootViewController {
			while let presentedViewController = topController.presentedViewController {
				topController = presentedViewController
			}
			return topController
		}
		return nil
	}
}

extension Double {

	/// Rounds a double to `digits` decimal places.
	func rounded(digits: Int) -> Double {
		let behavior = NSDecimalNumberHandler(roundingMode: .bankers, scale: Int16(digits), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: true)
		return NSDecimalNumber(value: self).rounding(accordingToBehavior: behavior).doubleValue
	}
}

