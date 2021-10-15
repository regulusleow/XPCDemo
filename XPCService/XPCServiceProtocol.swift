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
    func connectHelperApp(for PID: Int32)
    func getEndpointCollection(reply: @escaping (String) -> Void)
}
