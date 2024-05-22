//
//  EditorCollectionViewCompositionalLayout.swift
//  Zavala
//
//  Created by Maurice Parker on 11/19/21.
//

import UIKit
import VinOutlineKit

class EditorCollectionViewCompositionalLayout : UICollectionViewCompositionalLayout {
	
	var editorMaxWidth: CGFloat? = AppDefaults.shared.editorMaxWidth.pixels
	
	override var collectionViewContentSize: CGSize {
		guard let visibleSize = super.collectionView?.visibleSize else {
			return super.collectionViewContentSize
		}
		
		// Allow the editor overscroll by 50%
		var contentSize = super.collectionViewContentSize
		contentSize.height = contentSize.height + (visibleSize.height / 2)
		return contentSize
	}
	
	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		guard let superAttributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
		
		// Copy each item to prevent "UICollectionViewFlowLayout has cached frame mismatch" warning
		guard let attributes = superAttributes.copy() as? UICollectionViewLayoutAttributes else { return nil }

		if let editorMaxWidth {
			if attributes.size.width > editorMaxWidth {
				attributes.size.width = editorMaxWidth
			}
		}
		
		return attributes
	}
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
		
		// Copy each item to prevent "UICollectionViewFlowLayout has cached frame mismatch" warning
		guard let attributes = NSArray(array: superAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes] else { return nil }
		
		// Split the ones out by section because we only want to center the Tags
		var tagAttributes = [UICollectionViewLayoutAttributes]()
		var otherAttributes = [UICollectionViewLayoutAttributes]()
		for attr in attributes {
			if let editorMaxWidth {
				if attr.size.width > editorMaxWidth {
					attr.size.width = editorMaxWidth
				}
			}

			switch attr.indexPath.section {
			case Outline.Section.tags.rawValue:
				tagAttributes.append(attr)
			default:
				otherAttributes.append(attr)
			}
		}
		
		center(tagAttributes)
		otherAttributes.append(contentsOf: tagAttributes)
		
		return otherAttributes
	}
	
}

// MARK: Helpers

private extension EditorCollectionViewCompositionalLayout {
	
	// https://stackoverflow.com/a/38254368
	func center(_ attributes: [UICollectionViewLayoutAttributes]) {
		
		// Constants
		let leftPadding: CGFloat = 8
		let interItemSpacing: CGFloat = -8
		
		// Tracking values
		var leftMargin: CGFloat = leftPadding // Modified to determine origin.x for each item
		var maxY: CGFloat = -1.0 // Modified to determine origin.y for each item
		var rowSizes: [[CGFloat]] = [] // Tracks the starting and ending x-values for the first and last item in the row
		var currentRow: Int = 0 // Tracks the current row
		attributes.forEach { layoutAttribute in
			
			// Each layoutAttribute represents its own item
			if layoutAttribute.frame.origin.y >= maxY {
				
				// This layoutAttribute represents the left-most item in the row
				leftMargin = leftPadding
				
				// Register its origin.x in rowSizes for use later
				if rowSizes.count == 0 {
					// Add to first row
					rowSizes = [[leftMargin, 0]]
				} else {
					// Append a new row
					rowSizes.append([leftMargin, 0])
					currentRow += 1
				}
			}
			
			layoutAttribute.frame.origin.x = leftMargin
			
			leftMargin += layoutAttribute.frame.width + interItemSpacing
			maxY = max(layoutAttribute.frame.maxY, maxY)
			
			// Add right-most x value for last item in the row
			rowSizes[currentRow][1] = leftMargin - interItemSpacing
		}
		
		// At this point, all cells are left aligned
		// Reset tracking values and add extra left padding to center align entire row
		leftMargin = leftPadding
		maxY = -1.0
		currentRow = 0
		attributes.forEach { layoutAttribute in
			
			// Each layoutAttribute is its own item
			if layoutAttribute.frame.origin.y >= maxY {
				
				// This layoutAttribute represents the left-most item in the row
				leftMargin = leftPadding
				
				// Need to bump it up by an appended margin
				let rowWidth = rowSizes[currentRow][1] - rowSizes[currentRow][0] // last.x - first.x
				let appendedMargin = (collectionView!.frame.width - leftPadding  - rowWidth - leftPadding) / 2
				leftMargin += appendedMargin
				
				currentRow += 1
			}
			
			layoutAttribute.frame.origin.x = leftMargin
			
			leftMargin += layoutAttribute.frame.width + interItemSpacing
			maxY = max(layoutAttribute.frame.maxY, maxY)
		}
		
	}
	
}
