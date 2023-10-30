//
//  DocumentProvider.swift
//  
//
//  Created by Maurice Parker on 11/7/21.
//

import Foundation

public protocol DocumentProvider {
    func documents(completion: @escaping (Result<[Document], Error>) -> Void)
}
