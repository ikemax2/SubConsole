//
//  UsbStrings_CH9329.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import Foundation

struct UsbStrings_CH9329  : Equatable {
    
    enum StringType : UInt8 {
        case vendorDescription = 0x00
        case productDescription = 0x01
        case serialNumberDescription = 0x02
    }
        
    var descriptions = Dictionary<StringType, String>()
    
    mutating func append(buffer: [UInt8]) {
        let stringType = buffer[0]
        let stringLength = Int(buffer[1])
        let descArray = Array(buffer[2..<(2+stringLength)])
        let data = Data(bytes: descArray, count: descArray.count)
        
        if let description = String(data: data, encoding: .ascii) {
            if let stype = StringType(rawValue: stringType){
                self.descriptions[stype] = description
            }else{
                fatalError("UsbStrings_CH9329  unknown stringType \(stringType)")
            }
        }
    }
    
    var isReady: Bool {
        return descriptions[.vendorDescription] != nil && descriptions[.productDescription] != nil &&
        descriptions[.serialNumberDescription] != nil
    }
    
    var vendorDescription: String {
        return descriptions[.vendorDescription] ?? "--"
    }
    
    var productDescription: String {
        return descriptions[.productDescription] ?? "--"
    }
    
    var serialNumberDescription: String {
        return descriptions[.serialNumberDescription] ?? "--"
    }
}


