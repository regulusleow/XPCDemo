//
//  XPCServiceProtocol.swift
//  XPCService
//
//  Created by jiafeng wu on 2021/8/26.
//

import Foundation

@objc public protocol XPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void)
    func installHelperTool(reply: @escaping (Bool) -> Void)
    func getHelperAppEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void)
    func getEndpointCollection(reply: @escaping (String) -> Void)
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32)
}
