//
//  MacOpenQuicklyTimelineViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/20/21.
//

import UIKit
import RSCore
import Templeton

protocol MacOpenQuicklyTimelineDelegate: AnyObject {
	func documentSelectionDidChange(_: MacOpenQuicklyTimelineViewController, documentID: EntityID?)
	func openDocument(_: MacOpenQuicklyTimelineViewController, documentID: EntityID)
}

class MacOpenQuicklyTimelineViewController: UICollectionViewController {

	weak var delegate: MacOpenQuicklyTimelineDelegate?
	private var documentContainer: DocumentContainer?

	private var dataSource: UICollectionViewDiffableDataSource<Int, TimelineItem>!
	private let dataSourceQueue = MainThreadOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.layer.borderWidth = 1
		collectionView.layer.borderColor = UIColor.systemGray2.cgColor
		collectionView.layer.cornerRadius = 3
		
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
	}

	func setDocumentContainer(_ documentContainer: DocumentContainer?, completion: (() -> Void)? = nil) {
		self.documentContainer = documentContainer
		collectionView.deselectAll()
		applySnapshot()
	}
	
	// MARK: UICollectionView
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			configuration.showsSeparators = false
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, TimelineItem> { [weak self] (cell, indexPath, item) in
			guard let self = self, let document = AccountManager.shared.findDocument(item.id) else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			cell.insetBackground = true
			contentConfiguration.text = document.title ?? L10n.noTitle
//			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
//			contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
			
			cell.contentConfiguration = contentConfiguration
			
			let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.selectDocument(gesture:)))
			cell.addGestureRecognizer(singleTap)
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.openDocumentInNewWindow(gesture:)))
				doubleTap.numberOfTapsRequired = 2
				cell.addGestureRecognizer(doubleTap)
			}
		}
		
		dataSource = UICollectionViewDiffableDataSource<Int, TimelineItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}

	@objc private func selectDocument(gesture: UITapGestureRecognizer) {
		guard let cell = gesture.view as? UICollectionViewCell,
			  let indexPath = collectionView.indexPath(for: cell),
			  let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return }

		collectionView.deselectAll()
		collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
		delegate?.documentSelectionDidChange(self, documentID: timelineItem.id)
	}
	
	@objc func openDocumentInNewWindow(gesture: UITapGestureRecognizer) {
		guard let cell = gesture.view as? UICollectionViewCell,
			  let indexPath = collectionView.indexPath(for: cell),
			  let timelineItem = dataSource.itemIdentifier(for: indexPath) else { return }

		delegate?.openDocument(self, documentID: timelineItem.id)
	}
	
	func applySnapshot() {
		guard let documentContainer = documentContainer else {
			let snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
			self.dataSourceQueue.add(ApplySnapshotOperation(dataSource: self.dataSource, section: 0, snapshot: snapshot, animated: false))
			return
		}
		
		documentContainer.sortedDocuments { [weak self] result in
			guard let self = self, let documents = try? result.get() else { return }

			let items = documents.map { TimelineItem.timelineItem($0) }
			var snapshot = NSDiffableDataSourceSectionSnapshot<TimelineItem>()
			snapshot.append(items)

			let snapshotOp = ApplySnapshotOperation(dataSource: self.dataSource, section: 0, snapshot: snapshot, animated: false)
			self.dataSourceQueue.add(snapshotOp)
		}
	}
}
