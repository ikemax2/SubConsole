//
//  FourCharCode+string.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import Foundation

extension FourCharCode {
    
    var fourCharCodeString : String {
        let code = self
        
        var byteArray = [UInt8]()
        byteArray.append( UInt8((code >> 24) & 0xFF) )
        byteArray.append( UInt8((code >> 16) & 0xFF) )
        byteArray.append( UInt8((code >> 8) & 0xFF) )
        byteArray.append( UInt8((code >> 0) & 0xFF) )
                        
        let pattern = /[a-zA-Z0-9&-+=:;<>@]{4}/
        
        if let ret = String(bytes: byteArray, encoding: .ascii), let match = ret.wholeMatch(of: pattern) {
            return String(match.0)
        }else{
            // 16進数表示とする
            return String(format: "0x%02X%02X%02X%02X", byteArray[0], byteArray[1], byteArray[2], byteArray[3])
        }
    }
}
