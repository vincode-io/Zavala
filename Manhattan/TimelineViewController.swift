//
//  TimelineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import Templeton

protocol TimelineDelegate: class  {
	func outlineSelectionDidChange(_: TimelineViewController, outline: Outline)
}

class TimelineViewController: UICollectionViewController {

	private struct TimelineItem: Hashable, Identifiable {
		let id: EntityID
		let title: String?
		let updateDate: String?

		private static let dateFormatter: DateFormatter = {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			formatter.timeStyle = .none
			return formatter
		}()

		private static let timeFormatter: DateFormatter = {
			let formatter = DateFormatter()
			formatter.dateStyle = .none
			formatter.timeStyle = .short
			return formatter
		}()
		
		private static func dateString(_ date: Date?) -> String {
			guard let date = date else {
				return NSLocalizedString("Not Available", comment: "Not Available")
			}
			
			if Calendar.dateIsToday(date) {
				return timeFormatter.string(from: date)
			}
			return dateFormatter.string(from: date)
		}

		static func timelineItem(_ outline: Outline) -> Self {
			let updateDate = Self.dateString(outline.updated)
			return TimelineItem(id: outline.id, title: outline.name, updateDate: updateDate)
		}
		
	}

	private var addBarButtonItem: UIBarButtonItem?
	
	private var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!

	private var currentOutline: Outline? {
		guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
			  let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
			  
		return AccountManager.shared.findOutline(item.id)
	}
	
	weak var delegate: TimelineDelegate?
	var outlineProvider: OutlineProvider? {
		didSet {
			guard isViewLoaded else { return }
			applySnapshot(animated: false)
			updateUI()
		}
	}
	
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			addBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(createOutline(_:)))
			navigationItem.setRightBarButton(addBarButtonItem, animated: false)
		}

		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot(animated: false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(outlinesDidChange(_:)), name: .OutlinesDidChange, object: nil)

		updateUI()
	}

	// MARK: Notifications
	
	@objc func outlinesDidChange(_ note: Notification) {
		guard let op = outlineProvider, !op.isSmartProvider else {
			applySnapshot(animated: true)
			return
		}
		
		guard let noteOP = note.object as? OutlineProvider, op.id == noteOP.id else { return }
		applySnapshot(animated: true)
	}
	
	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
		let addNavViewController = UIStoryboard.add.instantiateViewController(withIdentifier: "AddOutlineViewControllerNav") as! UINavigationController
		present(addNavViewController, animated: true)
	}

}

// MARK: Collection View

extension TimelineViewController {
		
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TimelineItem> { [weak self] (cell, indexPath, item) in
			guard let self = self else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.secondaryText = item.updateDate
			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
				contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
				contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
			}
			
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<Int, TimelineItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}
	
	private func snapshot() -> NSDiffableDataSourceSectionSnapshot<TimelineItem>? {
		var snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
		let outlines = outlineProvider?.sortedOutlines ?? [Outline]()
		let items = outlines.map { TimelineItem.timelineItem($0) }
		snapshot.append(items)
		return snapshot
	}
	
	private func applySnapshot(animated: Bool) {
		if let snapshot = snapshot() {
			dataSource.apply(snapshot, to: 0, animatingDifferences: animated)
		}
	}
	
}

// MARK: Helper Functions

extension TimelineViewController {
	
	private func updateUI() {
		navigationItem.title = outlineProvider?.name
		view.window?.windowScene?.title = outlineProvider?.name
	}
	
	private func deleteOutline(_ outline: Outline) {
		let deleteTitle = NSLocalizedString("Delete", comment: "Delete")
		let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { (action) in
			outline.folder?.removeOutline(outline) { result in
				if case .failure(let error) = result {
					self.presentError(error)
				}
			}
		}
		
		let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
		
		let localizedInformativeText = NSLocalizedString("Are you sure you want to delete the “%@” outline?", comment: "Outline delete text")
		let formattedInformativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, outline.name ?? "") as String
		let localizedMessageText = NSLocalizedString("This outline will be deleted and unrecoverable.", comment: "Outline delete Message")
		
		let alert = UIAlertController(title: formattedInformativeText, message: localizedMessageText, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		
		present(alert, animated: true, completion: nil)
	}
	
}
