//
//  File.swift
//  
//
//  Created by Maurice Parker on 9/24/21.
//

import UIKit

class PrintDocVisitor {
	
	var indentLevel = 0
	var print = NSMutableAttributedString()
	
	var previousRowWasParagraph = false

	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }
		
		func visitChildren() {
			indentLevel = indentLevel + 1
			textRow.rows.forEach {
				$0.visit(visitor: self.visitor)
			}
			indentLevel = indentLevel - 1
		}
		
		if let topic = textRow.topic {
			if let note = textRow.note {
				printTopic(topic, textRow: textRow)
				printNote(note)
				
				previousRowWasParagraph = true
				visitChildren()
			} else {
				if previousRowWasParagraph {
					print.append(NSAttributedString(string: "\n"))
				}
				
				let listVisitor = PrintListVisitor()
				listVisitor.indentLevel = 1
				visited.visit(visitor: listVisitor.visitor)
				print.append(listVisitor.print)
				
				previousRowWasParagraph = false
			}
		} else {
			if let note = textRow.note {
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

extension PrintDocVisitor {
	
	private func printTopic(_ topic: NSAttributedString, textRow: TextRow) {
		print.append(NSAttributedString(string: "\n\n"))
		var attrs = [NSAttributedString.Key : Any]()
		if textRow.isComplete || textRow.isAncestorComplete {
			attrs[.foregroundColor] = UIColor.darkGray
		} else {
			attrs[.foregroundColor] = UIColor.black
		}
		
		if textRow.isComplete {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.darkGray
		} else {
			attrs[.strikethroughStyle] = 0
		}
		
		let fontSize = indentLevel < 3 ? 18 - ((indentLevel + 1) * 2) : 12

		let topicFont = UIFont.systemFont(ofSize: CGFloat(fontSize))
		let topicParagraphStyle = NSMutableParagraphStyle()
		topicParagraphStyle.paragraphSpacing = 0.33 * topicFont.lineHeight
		attrs[.paragraphStyle] = topicParagraphStyle
		
		let printTopic = NSMutableAttributedString(attributedString: topic)
		let range = NSRange(location: 0, length: printTopic.length)
		printTopic.addAttributes(attrs, range: range)
		printTopic.replaceFont(with: topicFont)

		print.append(printTopic)
	}
	
	private func printNote(_ note: NSAttributedString) {
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.darkGray

		let noteFont: UIFont
		if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif) {
			noteFont = UIFont(descriptor: descriptor, size: 11)
		} else {
			noteFont = UIFont.systemFont(ofSize: 11)
		}

		let noteParagraphStyle = NSMutableParagraphStyle()
		noteParagraphStyle.paragraphSpacing = 0.33 * noteFont.lineHeight
		attrs[.paragraphStyle] = noteParagraphStyle

		let noteTopic = NSMutableAttributedString(string: "\n")
		noteTopic.append(note)
		let range = NSRange(location: 0, length: noteTopic.length)
		noteTopic.addAttributes(attrs, range: range)
		noteTopic.replaceFont(with: noteFont)

		print.append(noteTopic)
	}
	
}
