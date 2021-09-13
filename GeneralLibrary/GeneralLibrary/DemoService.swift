//
//  DemoService.swift
//  XPCDemo
//
//  Created by jiafeng wu on 2021/9/13.
//

import Foundation

@objc public class DemoService: NSObject, DemoProtocol {
    @objc public func upperCase(str: String, reply: (String) -> Void) {
        let result = str.uppercased()
        reply(result)
    }
    
    @objc public func demoStr(reply: @escaping (String) -> Void) {
        reply("这是 XPCDemo 的一个方法")
    }
    
    @objc public func checkConnection(reply: @escaping (String) -> Void) {
        reply("成功连接 XPCDemo")
    }
}
