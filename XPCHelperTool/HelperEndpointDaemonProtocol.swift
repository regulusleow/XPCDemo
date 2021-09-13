//
//  HelperEndpointDaemonProtocol.swift
//  XPCHelperTool
//
//  Created by jiafeng wu on 2021/8/27.
//

import Foundation

@objc public protocol HelperEndpointDaemonProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void)
    func checkDaemonPluse(_ reply: @escaping () -> Void)
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32)
    func getEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void)
}
