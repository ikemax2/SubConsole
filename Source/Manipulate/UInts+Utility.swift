//
//  UInts+Utility.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
extension UInt16 {
    
    init?(bytes: [UInt8]) {
        guard let value: UInt16 = convertBytesToValue(bytes: bytes) else {
            return nil
        }
        self = value
    }
    
    // UInt16型整数を [UInt8]に変換する
    var uint8Array: [UInt8] {
        var bigEndian: UInt16 = self.bigEndian
        let count = MemoryLayout<UInt16>.size
        let bytePtr = withUnsafePointer(to: &bigEndian){
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start:$0, count: count)
            }
        }
        return Array(bytePtr)
    }
    
    var lowestUInt8: UInt8 {
        var bigEndian: UInt16 = self.bigEndian
        let count = MemoryLayout<UInt16>.size
        let lowestByte = withUnsafePointer(to: &bigEndian){
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                let bytePtr = UnsafeBufferPointer(start:$0, count: count)
                return Array(bytePtr).last!
            }
        }
        return lowestByte
    }
    
}

extension UInt32 {
    
    init?(bytes: [UInt8]) {
        guard let value: UInt32 = convertBytesToValue(bytes: bytes) else {
            return nil
        }
        self = value
    }
    
    // UInt32型整数を [UInt8]に変換する
    var uint8Array: [UInt8] {
        var bigEndian: UInt32 = self.bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bigEndian){
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start:$0, count: count)
            }
        }
        return Array(bytePtr)
    }
}


fileprivate func convertBytesToValue<T>(bytes: [UInt8]) -> T? {
    if bytes.count < MemoryLayout<T>.size {
        return nil
    }
    let value = UnsafePointer(bytes).withMemoryRebound(to: T.self, capacity: 1) {
        $0.pointee
    }
    return value
}

