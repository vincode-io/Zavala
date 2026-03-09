//
//  OutlineEncryptionService.swift
//
//
//  Created by Maurice Parker on 3/8/26.
//

import Foundation
import CryptoKit

public final class OutlineEncryptionService: Sendable {

	private let symmetricKey: SymmetricKey

	public init(key: SymmetricKey) {
		self.symmetricKey = key
	}

	public func encrypt(_ data: Data?) throws -> Data? {
		guard let data else { return nil }
		let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
		return sealedBox.combined
	}

	public func decrypt(_ data: Data?) throws -> Data? {
		guard let data else { return nil }
		let sealedBox = try AES.GCM.SealedBox(combined: data)
		return try AES.GCM.open(sealedBox, using: symmetricKey)
	}

}
