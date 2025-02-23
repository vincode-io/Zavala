//
//  File.swift
//  
//
//  Created by Maurice Parker on 9/24/21.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

@MainActor
final class PrintDocVisitor {
	
	var indentLevel = 0
	var print = NSMutableAttributedString()
	
	var previousRowWasParagraph = false

	func visitor(_ visited: Row) {
		
		func visitChildren() {
			indentLevel = indentLevel + 1
			visited.rows.forEach {
				$0.visit(visitor: self.visitor)
			}
			indentLevel = indentLevel - 1
		}
		
		if let topic = visited.topic {
			if let note = visited.note {
				printTopic(topic, row: visited)
				printNote(note)
				
				previousRowWasParagraph = true
				visitChildren()
			} else {
				if previousRowWasParagraph {
					print.append(NSAttributedString(string: "\n"))
				}
				
				let listVisitor = PrintListVisitor(numberingStyle: .none)
				listVisitor.indentLevel = 1
				visited.visit(visitor: listVisitor.visitor)
				print.append(listVisitor.print)
				
				previousRowWasParagraph = false
			}
		} else {
			if let note = visited.note {
				printNote(note)
				previousRowWasParagraph = true
			} else {
				previousRowWasParagraph = false
			}
			
			visitChildren()
		}
		
	}
}

// MARK: Helpers

private extension PrintDocVisitor {
	
	func printTopic(_ topic: NSAttributedString, row: Row) {
		#if canImport(UIKit)
		print.append(NSAttributedString(string: "\n\n"))
		var attrs = [NSAttributedString.Key : Any]()
		if row.isComplete ?? false || row.isAnyParentComplete {
			attrs[.foregroundColor] = UIColor.darkGray
		} else {
			attrs[.foregroundColor] = UIColor.black
		}
		
		if row.isComplete ?? false {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.darkGray
		} else {
			attrs[.strikethroughStyle] = 0
		}
		
		let fontSize = CGFloat(indentLevel < 3 ? 18 - ((indentLevel + 1) * 2) : 12)

		let topicFont = if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif) {
			UIFont(descriptor: descriptor, size: fontSize)
		} else {
			UIFont.systemFont(ofSize: fontSize)
		}

		let topicParagraphStyle = NSMutableParagraphStyle()
		topicParagraphStyle.paragraphSpacing = 0.33 * topicFont.lineHeight
		attrs[.paragraphStyle] = topicParagraphStyle
		
		let printTopic = NSMutableAttributedString(attributedString: topic)
		printTopic.addAttributes(attrs)
		printTopic.replaceFont(with: topicFont)

		print.append(printTopic)
		#endif
	}
	
	func printNote(_ note: NSAttributedString) {
		#if canImport(UIKit)
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.darkGray

		let noteFont = if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif) {
			UIFont(descriptor: descriptor, size: 11)
		} else {
			UIFont.systemFont(ofSize: 11)
		}

		let noteParagraphStyle = NSMutableParagraphStyle()
		noteParagraphStyle.paragraphSpacing = 0.33 * noteFont.lineHeight
		attrs[.paragraphStyle] = noteParagraphStyle

		let noteTopic = NSMutableAttributedString(string: "\n")
		noteTopic.append(note)
		noteTopic.addAttributes(attrs)
		noteTopic.replaceFont(with: noteFont)

		print.append(noteTopic)
		#endif
	}
	
}
