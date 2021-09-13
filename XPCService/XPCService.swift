//
//  XPCService.swift
//  XPCService
//
//  Created by jiafeng wu on 2021/8/26.
//

import Foundation

class XPCService: XPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void) {
        let upperStr = str.uppercased()
        reply(upperStr)
    }
}
