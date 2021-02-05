// Douglas Hill, December 2018
// Made for https://douglashill.co/reading-app/
// Find the latest version of this file at https://github.com/douglashill/KeyboardKit

import UIKit

/// A table view that allows navigation and selection using a hardware keyboard.
/// Only supports a single section.
class KeyboardTableView: UITableView {

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc var isSelecting: Bool {
		return indexPathForSelectedRow != nil
	}
	
	@objc func selectAbove() {
		if let oldSelectedIndexPath = indexPathForSelectedRow {
			selectRowAtIndex(oldSelectedIndexPath.row - 1)
		} else {
			selectBottom()
		}
	}

	@objc func selectBelow() {
		if let oldSelectedIndexPath = indexPathForSelectedRow {
			selectRowAtIndex(oldSelectedIndexPath.row + 1)
		} else {
			selectTop()
		}
	}

	@objc func selectTop() {
		selectRowAtIndex(0)
	}

	@objc func selectBottom() {
		selectRowAtIndex(numberOfRows(inSection: 0) - 1)
	}

	/// Tries to select and scroll to the row at the given index in section 0.
	/// Does not require the index to be in bounds. Does nothing if out of bounds.
	private func selectRowAtIndex(_ rowIndex: Int) {
		guard rowIndex >= 0 && rowIndex < numberOfRows(inSection: 0) else {
			return
		}

		let indexPath = IndexPath(row: rowIndex, section: 0)

		switch cellVisibility(atIndexPath: indexPath) {
		case .fullyVisible:
			selectRow(at: indexPath, animated: false, scrollPosition: .none)
		case .notFullyVisible(let scrollPosition):
			// Looks better and feel more responsive if the selection updates without animation.
			selectRow(at: indexPath, animated: false, scrollPosition: .none)
			scrollToRow(at: indexPath, at: scrollPosition, animated: true)
			flashScrollIndicators()
		}
	}

	/// Whether a row is fully visible, or if not if it’s above or below the viewport.
	enum CellVisibility { case fullyVisible; case notFullyVisible(ScrollPosition); }

	/// Whether the given row is fully visible, or if not if it’s above or below the viewport.
	private func cellVisibility(atIndexPath indexPath: IndexPath) -> CellVisibility {
		let rowRect = rectForRow(at: indexPath)
		if bounds.inset(by: adjustedContentInset).contains(rowRect) {
			return .fullyVisible
		}

		let position: ScrollPosition = rowRect.midY < bounds.midY ? .top : .bottom
		return .notFullyVisible(position)
	}

	@objc func clearSelection() {
		selectRow(at: nil, animated: false, scrollPosition: .none)
	}

	@objc func activateSelection() {
		guard let indexPathForSelectedRow = indexPathForSelectedRow else {
			return
		}
		delegate?.tableView?(self, didSelectRowAt: indexPathForSelectedRow)
	}
}
