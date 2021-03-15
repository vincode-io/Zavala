//
//  LinkViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/14/21.
//

import UIKit
import Templeton

protocol LinkViewControllerDelegate: AnyObject {
	func updateLink(cursorCoordinates: CursorCoordinates, text: String, link: String?, range: NSRange)
}

class LinkViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }


}
