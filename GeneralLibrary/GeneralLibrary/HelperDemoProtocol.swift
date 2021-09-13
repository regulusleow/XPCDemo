//
//  HelperDemoProtocol.swift
//  HelperDemo
//
//  Created by jiafeng wu on 2021/8/31.
//

import Foundation

@objc public protocol HelperDemoProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void)
    func helperDemoStr(reply: @escaping (String) -> Void)
    func checkHelperDemoConnection(reply: @escaping (String) -> Void)
}
