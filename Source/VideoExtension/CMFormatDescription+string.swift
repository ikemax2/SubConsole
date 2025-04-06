//
//  CMFormatDescription+string.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import AVFoundation

extension CMFormatDescription {
    
    public var mediaTypeString : String {
        let code = mediaType.rawValue
        return code.fourCharCodeString
    }
    
    public var mediaSubTypeString : String {
        let code = mediaSubType.rawValue
        return code.fourCharCodeString
    }
    
    
    public var dimensionString : String {
        return String(dimensions.width) + "x" + String(dimensions.height)
    }
    
    static func dimensionComponents(_ string: String)  -> (width: Int, height: Int) {
        let f = string.components(separatedBy: "x")
        guard f.count == 2 else {
            return (1, 1)
        }
        
        if let ff = f.first, let fl = f.last, let w = Int(ff), let h = Int(fl) {
            return (width:w, height: h)
        }
        
        return (1, 1)
    }
    
}
