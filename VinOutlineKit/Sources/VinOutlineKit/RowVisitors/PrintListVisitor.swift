//
//  PrintListVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import UIKit

class PrintListVisitor {
	
	var indentLevel = 0
	var print = NSMutableAttributedString()

	func visitor(_ visited: Row) {
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

			let topicFont = UIFont.systemFont(ofSize: 11)
			let topicParagraphStyle = NSMutableParagraphStyle()
			topicParagraphStyle.paragraphSpacing = 0.33 * topicFont.lineHeight
			
			topicParagraphStyle.firstLineHeadIndent = CGFloat(indentLevel * 20)
			let textIndent = CGFloat(indentLevel * 20) + 10
			topicParagraphStyle.headIndent = textIndent
			topicParagraphStyle.defaultTabInterval = textIndent
			topicParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: textIndent, options: [:])]
			attrs[.paragraphStyle] = topicParagraphStyle
			
			let printTopic = NSMutableAttributedString(string: "\u{2022}\t")
			printTopic.append(topic)
			printTopic.addAttributes(attrs)
			printTopic.replaceFont(with: topicFont)

			print.append(printTopic)
		}
		
		if let note = visited.note {
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
			noteParagraphStyle.firstLineHeadIndent = CGFloat(indentLevel * 20) + 10
			noteParagraphStyle.headIndent = CGFloat(indentLevel * 20) + 10
			attrs[.paragraphStyle] = noteParagraphStyle

			let noteTopic = NSMutableAttributedString(string: "\n")
			noteTopic.append(note)
			noteTopic.addAttributes(attrs)
			noteTopic.replaceFont(with: noteFont)

			print.append(noteTopic)
		}
		
		indentLevel = indentLevel + 1
		visited.rows.forEach {
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
}
