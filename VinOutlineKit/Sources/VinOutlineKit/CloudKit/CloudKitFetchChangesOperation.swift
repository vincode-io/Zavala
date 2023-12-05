//
//
//  Created by Maurice Parker on 12/4/23.
//

import Foundation
import OSLog
import CloudKit
import VinUtility

class CloudKitFetchChangesOperation: BaseMainThreadOperation {
    
    var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")
    
    var account: Account {
        return AccountManager.shared.cloudKitAccount!
    }
    
    var cloudKitManager: CloudKitManager {
        account.cloudKitManager!
    }
    
    let zoneID: CKRecordZone.ID
    
    init(zoneID: CKRecordZone.ID) {
        self.zoneID = zoneID
    }
    
    override func run() {
        let zone = cloudKitManager.findZone(zoneID: zoneID)
        zone.fetchChangesInZone(incremental: false) { [weak self] result in
            guard let self else { return }
            
            if case .failure(let error) = result {
                if let ckError = error as? CKError, ckError.code == .zoneNotFound {
                    AccountManager.shared.cloudKitAccount?.deleteAllDocuments(with: zoneID)
                } else {
                    self.error = error
                }
            }
            self.operationDelegate?.operationDidComplete(self)
        }
    }
    
}
