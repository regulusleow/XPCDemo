//
//  HelperDemoService.swift
//  HelperDemo
//
//  Created by jiafeng wu on 2021/8/31.
//

import Foundation

@objc public class HelperDemoService: NSObject, HelperDemoProtocol {
    @objc public func upperCase(str: String, reply: @escaping (String) -> Void) {
        reply(str.uppercased())
    }
    
    @objc public func helperDemoStr(reply: @escaping (String) -> Void) {
        reply("这是 HelperDemo 的一个方法")
    }
    
    @objc public func checkHelperDemoConnection(reply: @escaping (String) -> Void) {
        reply("成功连接 HelperDemo")
    }
}
