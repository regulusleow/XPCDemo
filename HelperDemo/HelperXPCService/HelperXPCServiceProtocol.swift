//
//  HelperXPCServiceProtocol.swift
//  HelperXPCService
//
//  Created by jiafeng wu on 2021/10/18.
//

import Foundation

@objc public protocol HelperXPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void)
    func getMainAppEndpoint(reply: @escaping (NSXPCListenerEndpoint?) -> Void)
    func setEndpoint(endpoint: NSXPCListenerEndpoint)
}
