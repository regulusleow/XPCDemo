//
//  XPCServiceProtocol.swift
//  XPCService
//
//  Created by jiafeng wu on 2021/8/26.
//

import Foundation

@objc public protocol XPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void);
}
