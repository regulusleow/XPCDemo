//
//  XPCServiceProtocol.swift
//  XPCService
//
//  Created by jiafeng wu on 2021/8/26.
//

import Foundation

@objc public protocol XPCServiceProtocol {
    func installHelperTool(reply: @escaping (Bool) -> Void)
    func getHelperAppEndpoint(reply: @escaping (NSXPCListenerEndpoint?) -> Void)
    func setEndpoint(endpoint: NSXPCListenerEndpoint)
}
