//
//  Data+Utility.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import Foundation

extension Data {
    // Data型をUInt8の配列に変換
    var encodedHexadecimals: [UInt8]? {
        let responseValues = self.withUnsafeBytes({ (pointer: UnsafeRawBufferPointer) -> [UInt8] in
            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            return [UInt8](UnsafeBufferPointer(start: unsafePointer, count: self.count))
        })
        return responseValues
    }
}
