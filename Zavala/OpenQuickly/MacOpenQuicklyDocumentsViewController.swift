//
//  MacOpenQuicklyDocumentsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/20/21.
//

import UIKit
import VinOutlineKit
import VinUtility

protocol MacOpenQuicklyDocumentsDelegate: AnyObject {
	func documentSelectionDidChange(_: MacOpenQuicklyDocumentsViewController, documentID: EntityID?)
	func openDocument(_: MacOpenQuicklyDocumentsViewController, documentID: EntityID)
}

final class DocumentsItem: NSObject, NSCopying, Identifiable {

		let id: EntityID

		init(id: EntityID) {
				self.id = id
		}

		static func item(_ document: Document) -> DocumentsItem {
				return DocumentsItem(id: document.id)
		}

		override func isEqual(_ object: Any?) -> Bool {
				guard let other = object as? DocumentsItem else { return false }
				if self === other { return true }
				return id == other.id
		}

		override var hash: Int {
				var hasher = Hasher()
				hasher.combine(id)
				return hasher.finalize()
		}

		func copy(with zone: NSZone? = nil) -> Any {
				return self
		}

}

class MacOpenQuicklyDocumentsViewController: UICollectionViewController {

	weak var delegate: MacOpenQuicklyDocumentsDelegate?
	private var documentContainers: [DocumentContainer]?

	private var dataSource: UICollectionViewDiffableDataSource<Int, DocumentsItem>!

    override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.layer.borderWidth = 1
		collectionView.layer.borderColor = UIColor.systemGray2.cgColor
		collectionView.layer.cornerRadius = 3
		
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot()
	}

	func setDocumentContainers(_ documentContainers: [DocumentContainer], completion: (() -> Void)? = nil) {
		self.documentContainers = documentContainers
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
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, DocumentsItem> { [weak self] (cell, indexPath, item) in
			guard let self, let document = AccountManager.shared.findDocument(item.id) else { return }
			
			var contentConfiguration = UIListContentConfiguration.subtitleCell()
			cell.insetBackground = true

			let title = (document.title?.isEmpty ?? true) ? .noTitleLabel : document.title!

			if document.isCollaborating {
				let attrText = NSMutableAttributedString(string: "\(title) ")
				let shareAttachement = NSTextAttachment(image: .collaborating)
				attrText.append(NSAttributedString(attachment: shareAttachement))
				contentConfiguration.attributedText = attrText
			} else {
				contentConfiguration.text = title
			}
			
			cell.contentConfiguration = contentConfiguration
			
			let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.selectDocument(gesture:)))
			cell.addGestureRecognizer(singleTap)
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.openDocumentInNewWindow(gesture:)))
				doubleTap.numberOfTapsRequired = 2
				cell.addGestureRecognizer(doubleTap)
			}
		}
		
		dataSource = UICollectionViewDiffableDataSource<Int, DocumentsItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
		}
	}

	@objc private func selectDocument(gesture: UITapGestureRecognizer) {
		guard let cell = gesture.view as? UICollectionViewCell,
			  let indexPath = collectionView.indexPath(for: cell),
			  let item = dataSource.itemIdentifier(for: indexPath) else { return }

		collectionView.deselectAll()
		collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
		delegate?.documentSelectionDidChange(self, documentID: item.id)
	}
	
	@objc func openDocumentInNewWindow(gesture: UITapGestureRecognizer) {
		guard let cell = gesture.view as? UICollectionViewCell,
			  let indexPath = collectionView.indexPath(for: cell),
			  let item = dataSource.itemIdentifier(for: indexPath) else { return }

		delegate?.openDocument(self, documentID: item.id)
	}
	
	func applySnapshot() {
		guard let documentContainers else {
			let snapshot = NSDiffableDataSourceSectionSnapshot<DocumentsItem>()
			self.dataSource.apply(snapshot, to: 0, animatingDifferences: false)
			return
		}
		
		let tags = documentContainers.tags
		let selectionContainers: [DocumentProvider]
		if !tags.isEmpty {
			selectionContainers = [TagsDocuments(tags: tags)]
		} else {
			selectionContainers = documentContainers
		}
	
		Task {
			let documents = await withTaskGroup(of: DocumentProvider.self, returning: Set<Document>.self) { taskGroup in
				var documents = Set<Document>()
				for container in selectionContainers {
					if let containerDocuments = try? await container.documents {
						documents.formUnion(containerDocuments)
					}
				}
				return documents
			}
			
			let sortedDocuments = documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
			let items = sortedDocuments.map { DocumentsItem.item($0) }
			var snapshot = NSDiffableDataSourceSectionSnapshot<DocumentsItem>()
			snapshot.append(items)

			Task { @MainActor in
				dataSource.apply(snapshot, to: 0, animatingDifferences: false)
			}
		}
	}
}
