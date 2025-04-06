//
//  Info_CH9329.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
struct Info_CH9329 : Equatable  {
    var version: UInt8
    var connected: UInt8
    var indicator: UInt8
    
    init(buffer: [UInt8]) {
        self.version = buffer[0]
        self.connected = buffer[1]
        self.indicator = buffer[2]
        
    }
    
    var versionString: String {
        return "0x\(String(version, radix:16))"
    }
    
    var connectedString: String {
        if connected == 1 {
            return "Yes"
        }else {
            return "No"
        }
    }
    
    var indicatorString: String {
        var str = String()
        str += ( 0x01 & indicator == 0x00) ? "NumLock:OFF" : "NumLock:ON"
        str += ","
        str += ( 0x02 & indicator == 0x00) ? "CapsLock:OFF" : "CapsLock:ON"
        str += ","
        str += ( 0x04 & indicator == 0x00) ? "ScrollLock:OFF" : "ScrollLock:ON"
        
        return str
    }
}
