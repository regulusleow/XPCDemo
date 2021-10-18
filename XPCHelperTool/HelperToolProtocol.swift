//
//  HelperToolProtocol.swift
//  XPCHelperTool
//
//  Created by jiafeng wu on 2021/8/27.
//

import Foundation

@objc public protocol HelperToolProtocol {
    func checkDaemonPluse(_ reply: @escaping () -> Void)
    func setMainAppEndpoint(_ endpoint: NSXPCListenerEndpoint?)
    func getMainAppEndpoint(_ reply: @escaping (NSXPCListenerEndpoint?) -> Void)
    func setHelperAppEndpoint(_ endpoint: NSXPCListenerEndpoint?)
    func getHelperAppEndpoint(_ reply: @escaping (NSXPCListenerEndpoint?) -> Void)
}
