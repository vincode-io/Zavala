//
//  SidebarViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import UniformTypeIdentifiers
import RSCore
import Combine
import Templeton

protocol SidebarDelegate: class {
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)?)
}

class SidebarViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .sidebar }
	
	weak var delegate: SidebarDelegate?
	
	var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
	private let dataSourceQueue = MainThreadOperationQueue()

	override func viewDidLoad() {
		super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidInitialize(_:)), name: .AccountDidInitialize, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
	}
	
	// MARK: API
	
	func startUp() {
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
	}
	
	func selectDocumentContainer(_ documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)? = nil) {
		if let search = documentContainer as? Search {
			DispatchQueue.main.async {
				if let searchCellIndexPath = self.dataSource.indexPath(for: SidebarItem.searchSidebarItem()) {
					if let searchCell = self.collectionView.cellForItem(at: searchCellIndexPath) as? SidebarSearchCell {
						searchCell.setSearchField(searchText: search.searchText)
					}
				}
			}
		}

		var sidebarItem: SidebarItem? = nil
		if let documentContainer = documentContainer {
			sidebarItem = SidebarItem.sidebarItem(documentContainer)
		}
		updateSelection(item: sidebarItem, animated: animated)
		
		delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer, animated: animated, completion: completion)
	}
	
	func restoreArchive() {
		let zalarcType = UTType(exportedAs: "io.vincode.Zavala.archive")
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [zalarcType])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = false
		self.present(docPicker, animated: true)
	}
	
	func restoreArchive(url: URL) {
		let unpackResult : (AccountType, URL)
		do {
			unpackResult = try AccountManager.shared.unpackArchive(url)
		} catch {
			presentError(error)
			return
		}
		
		let restoreAction = UIAlertAction(title: L10n.restore, style: .default) { [weak self] _ in
			guard let self = self else { return }
			self.collectionView.selectItem(at: nil, animated: true, scrollPosition: .top)
			self.delegate?.documentContainerSelectionDidChange(self, documentContainer: nil, animated: true, completion: nil)
			AccountManager.shared.restoreArchive(accountType: unpackResult.0, unpackURL: unpackResult.1)
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			AccountManager.shared.cleanUpArchive(unpackURL: unpackResult.1)
		}
		
		let title = L10n.restoreAccountPrompt(unpackResult.0.name)
		let alert = UIAlertController(title: title, message: L10n.restoreAccountMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(restoreAction)
		alert.preferredAction = restoreAction
		
		present(alert, animated: true, completion: nil)
	}
	
	func archiveAccount(type: AccountType) {
		guard let archiveFile = AccountManager.shared.archiveAccount(type: type) else { return }
		
		let docPicker = UIDocumentPickerViewController(forExporting: [archiveFile])
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	// MARK: Notifications
	
	@objc func accountDidInitialize(_ note: Notification) {
		applyChangeSnapshot()
	}
	
	@objc func accountMetadataDidChange(_ note: Notification) {
		applyChangeSnapshot()
	}
	
}

// MARK: Collection View

extension SidebarViewController {
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let searchCellIndexPath = dataSource.indexPath(for: SidebarItem.searchSidebarItem()) {
			if let searchCell = collectionView.cellForItem(at: searchCellIndexPath) as? SidebarSearchCell {
				searchCell.clearSearchField()
			}
		}
		
		guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
		
		if case .documentContainer(let entityID) = sidebarItem.id {
			let documentContainer = AccountManager.shared.findDocumentContainer(entityID)
			delegate?.documentContainerSelectionDidChange(self, documentContainer: documentContainer, animated: true, completion: nil)
		}
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			configuration.showsSeparators = false
			configuration.headerMode = .firstItemInSection
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let searchRegistration = UICollectionView.CellRegistration<SidebarSearchCell, SidebarItem> { (cell, indexPath, item) in
			var contentConfiguration = SidebarSearchContentConfiguration(searchText: nil)
			contentConfiguration.delegate = self
			cell.contentConfiguration = contentConfiguration
		}

		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {	(cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarHeader()
			contentConfiguration.text = item.title
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			contentConfiguration.text = item.title
			contentConfiguration.image = item.image
			
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			switch item.id {
			case .search:
				return collectionView.dequeueConfiguredReusableCell(using: searchRegistration, for: indexPath, item: item)
			case .header:
				return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
			default:
				return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
			}
		}
	}
	
	private func searchSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		snapshot.append([SidebarItem.searchSidebarItem()])
		return snapshot
	}
	
	private func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem>? {
		guard let localAccount = AccountManager.shared.localAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
		let header = SidebarItem.sidebarItem(title: AccountType.local.name, id: .header(.localAccount))
		
		let items = localAccount.documentContainers.map { SidebarItem.sidebarItem($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func applyInitialSnapshot() {
		if traitCollection.userInterfaceIdiom == .mac {
			applySnapshot(searchSnapshot(), section: .search, animated: false)
		}
		if let snapshot = self.localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: false)
		}
	}
	
	private func applyChangeSnapshot() {
		if let snapshot = localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: true)
		}
	}
	
	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<SidebarItem>, section: SidebarSection, animated: Bool) {
		dataSourceQueue.add(ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated))
	}
	
	func updateSelection(item: SidebarItem?, animated: Bool) {
		dataSourceQueue.add(UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, item: item, animated: animated))
	}
}

// MARK: UIDocumentPickerDelegate

extension SidebarViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		restoreArchive(url: urls[0])
	}
	
}

// MARK: SidebarSearchCellDelegate

extension SidebarViewController: SidebarSearchCellDelegate {

	func sidebarSearchDidBecomeActive() {
		selectDocumentContainer(Search(searchText: ""), animated: false)
	}

	func sidebarSearchDidUpdate(searchText: String?) {
		if let searchText = searchText {
			selectDocumentContainer(Search(searchText: searchText), animated: true)
		} else {
			selectDocumentContainer(Search(searchText: ""), animated: false)
		}
	}
	
}

// MARK: Helper Functions

extension SidebarViewController {
	
}
