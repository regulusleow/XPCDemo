//
//  HelperXPCServiceProtocol.swift
//  HelperXPCService
//
//  Created by jiafeng wu on 2021/10/18.
//

import Foundation

@objc public protocol HelperXPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void)
    func getMainAppEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void)
    func getEndpointCollection(reply: @escaping (String) -> Void)
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32)
}
