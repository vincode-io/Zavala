//
//  PrintListVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

@MainActor
final class PrintListVisitor {
	
	let numberingStyle: Outline.NumberingStyle
	let isCompletedFilterOn: Bool
	let isNotesFilterOn: Bool
	let respectCollapsed: Bool

	var indentLevel = 0
	var print = NSMutableAttributedString()

	init(numberingStyle: Outline.NumberingStyle,
		 isCompletedFilterOn: Bool = false,
		 isNotesFilterOn: Bool = false,
		 respectCollapsed: Bool = false) {
		self.numberingStyle = numberingStyle
		self.isCompletedFilterOn = isCompletedFilterOn
		self.isNotesFilterOn = isNotesFilterOn
		self.respectCollapsed = respectCollapsed
	}

	func visitor(_ visited: Row) {
		// Skip completed rows (and their descendants) when the completed filter is on, just like the on-screen view.
		if isCompletedFilterOn && (visited.isComplete ?? false) {
			return
		}

		#if canImport(UIKit)
		if let topic = visited.topic {
			print.append(NSAttributedString(string: "\n"))
			var attrs = [NSAttributedString.Key : Any]()
			if visited.isComplete ?? false || visited.isAnyParentComplete {
				attrs[.foregroundColor] = UIColor.darkGray
			} else {
				attrs[.foregroundColor] = UIColor.black
			}
			
			if visited.isComplete ?? false {
				attrs[.strikethroughStyle] = 1
				attrs[.strikethroughColor] = UIColor.darkGray
			} else {
				attrs[.strikethroughStyle] = 0
			}

			let topicFont = if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif) {
				UIFont(descriptor: descriptor, size: 11)
			} else {
				UIFont.systemFont(ofSize: 11)
			}

			let topicParagraphStyle = NSMutableParagraphStyle()
			topicParagraphStyle.paragraphSpacing = 0.33 * topicFont.lineHeight
			
			topicParagraphStyle.firstLineHeadIndent = CGFloat(indentLevel * 20)
			let textIndent = CGFloat(indentLevel * 20) + 10
			topicParagraphStyle.headIndent = textIndent
			topicParagraphStyle.defaultTabInterval = textIndent
			topicParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: textIndent, options: [:])]
			attrs[.paragraphStyle] = topicParagraphStyle
			
			let printTopic = switch numberingStyle {
			case .none:
				NSMutableAttributedString(string: "\u{2022}\t")
			case .simple:
				NSMutableAttributedString(string: "\(visited.simpleNumbering)  ")
			case .decimal:
				NSMutableAttributedString(string: "\(visited.decimalNumbering)  ")
			case .legal:
				NSMutableAttributedString(string: "\(visited.legalNumbering)  ")
			}
			
			printTopic.append(topic)
			printTopic.addAttributes(attrs)
			printTopic.replaceFont(with: topicFont)

			print.append(printTopic)
		}
		
		if let note = visited.note, !isNotesFilterOn {
			var attrs = [NSAttributedString.Key : Any]()
			attrs[.foregroundColor] = UIColor.darkGray

			let noteFont: UIFont
			if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif) {
				noteFont = UIFont(descriptor: descriptor, size: 10)
			} else {
				noteFont = UIFont.systemFont(ofSize: 10)
			}

			let noteParagraphStyle = NSMutableParagraphStyle()
			noteParagraphStyle.paragraphSpacing = 0.33 * noteFont.lineHeight
			noteParagraphStyle.firstLineHeadIndent = CGFloat(indentLevel * 20) + 10
			noteParagraphStyle.headIndent = CGFloat(indentLevel * 20) + 10
			attrs[.paragraphStyle] = noteParagraphStyle

			let noteTopic = NSMutableAttributedString(string: "\n")
			noteTopic.append(note)
			noteTopic.addAttributes(attrs)
			noteTopic.replaceFont(with: noteFont)

			print.append(noteTopic)
		}
		#endif

		// Don't show the contents of collapsed rows when mirroring the on-screen view.
		if respectCollapsed && !visited.isExpanded {
			return
		}

		indentLevel = indentLevel + 1
		visited.rows.forEach {
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
}
