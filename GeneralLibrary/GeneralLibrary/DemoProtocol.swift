//
//  DemoProtocol.swift
//  XPCDemo
//
//  Created by jiafeng wu on 2021/9/13.
//

import Foundation

@objc public protocol DemoProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void)
    func demoStr(reply: @escaping (String) -> Void)
    func checkConnection(reply: @escaping (String) -> Void)
}
