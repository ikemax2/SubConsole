//
//  Parameter_CH9329.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
struct Parameter_CH9329  : Equatable {
    
    var actionMode : UInt8    // 0
    var serialComMode : UInt8 // 1
    var serialAddress : UInt8 // 2
    var serialBaudRate : UInt32 // 3-6
    // 7-8
    var serialPacketInterval : UInt16  // 9-10
    var usbVid : [UInt8] // 11,12
    var usbPid : [UInt8]  // 13,14
    var usbUploadInterval : UInt16 // 15,16
    var usbReleaseDelay : UInt16 // 17,18
    var usbAutoLineFeedFlag : UInt8 // 19
    var usbCarriageReturnCharactor0 : [UInt8] // 20-23
    var usbCarriageReturnCharactor1 : [UInt8]  // 24-27
    var usbFilteringCharactorStart : [UInt8]  // 28-31
    var usbFilteringCharactorEnd : [UInt8]  // 32-35
    var usbStringValidFlag : UInt8  // 36
    var usbHighSpeedUploadFlag : UInt8  // 37
    // 38-49
    
    
    init(buffer: [UInt8]) {
        
        self.actionMode = buffer[0]
        self.serialComMode = buffer[1]
        self.serialAddress = buffer[2]

        self.serialBaudRate = UInt32(bytes:[buffer[6], buffer[5], buffer[4], buffer[3]]) ?? 0
        
        self.serialPacketInterval = UInt16(bytes:[buffer[10], buffer[9]]) ?? 0
        self.usbVid = [buffer[11], buffer[12]]
        self.usbPid = [buffer[13], buffer[14]]
        self.usbUploadInterval = UInt16(bytes:[buffer[16], buffer[15]]) ?? 0
        self.usbReleaseDelay = UInt16(bytes:[buffer[18], buffer[17]]) ?? 0
        self.usbAutoLineFeedFlag = buffer[19]
        self.usbCarriageReturnCharactor0 = [buffer[20], buffer[21], buffer[22], buffer[23]]
        self.usbCarriageReturnCharactor1 = [buffer[24], buffer[25], buffer[26], buffer[27]]
        self.usbFilteringCharactorStart = [buffer[28], buffer[29], buffer[30], buffer[31]]
        self.usbFilteringCharactorEnd = [buffer[32], buffer[33], buffer[34], buffer[35]]
        self.usbStringValidFlag = buffer[36]
        self.usbHighSpeedUploadFlag = buffer[37]
        
    }
    
    func encodedBytes() -> [UInt8] {
        var bytes = [UInt8]()
        
        bytes.append(self.actionMode) // 0
        bytes.append(self.serialComMode) // 1
        bytes.append(self.serialAddress) // 2
        bytes.append(contentsOf: self.serialBaudRate.uint8Array) // 3-6
        bytes.append(contentsOf: [0, 0]) // 7,8
        bytes.append(contentsOf: self.serialPacketInterval.uint8Array) // 9,10
        bytes.append(contentsOf: self.usbVid) // 11,12
        bytes.append(contentsOf: self.usbPid) // 13,14
        bytes.append(contentsOf: self.usbUploadInterval.uint8Array) // 15,16
        bytes.append(contentsOf: self.usbReleaseDelay.uint8Array) // 17,18
        bytes.append(self.usbAutoLineFeedFlag) // 19
        bytes.append(contentsOf: self.usbCarriageReturnCharactor0) // 20-23
        bytes.append(contentsOf: self.usbCarriageReturnCharactor1) // 24-27
        bytes.append(contentsOf: self.usbFilteringCharactorStart) // 28-31
        bytes.append(contentsOf: self.usbFilteringCharactorEnd) // 32-35
        bytes.append(self.usbStringValidFlag) // 36
        bytes.append(self.usbHighSpeedUploadFlag) // 37
        bytes.append(contentsOf: [0, 0, 0, 0]) // 38-41
        bytes.append(contentsOf: [0, 0, 0, 0]) // 42-45
        bytes.append(contentsOf: [0, 0, 0, 0]) // 46-49
        
        
        let cb = self.serialPacketInterval.uint8Array
        let interval = UInt16(bytes: [cb[1], cb[0]]) ?? 0
        print("encodedBytes confirmation packetInterval: \(interval)")

        print("encodedBytes count: \(bytes.count)")
        return bytes
        
    }
    
    
    var actionModeString: String {
        var str : String
        switch(actionMode){
            case 0x00:
                str = "Keyboard(Normal, Multimedia) + Mouse(absolute, relative), software"
            case 0x01:
                str = "Keyboard(Normal), software"
            case 0x02:
                str = "Mouse(absolute, relative), software"
            case 0x03:
                str = "Custom HID Device, software"
            case 0x80:
                str = "Keyboard(Normal, Multimedia) + Mouse(absolute, relative), hardware"
            case 0x81:
                str = "Keyboard(Normal), hardware"
            case 0x82:
                str = "Mouse(absolute, relative), hardware"
            case 0x83:
                str = "Custom HID Device, hardware"
            default:
                print("chipInfoActionModeString  invalid mode detect!!")
                str = "--"
        }
        return str
    }
    
    var serialComModeString: String {
        var str : String
        switch(serialComMode) {
            case 0x00:
                str = "Protocol Communicatin Mode, software"
            case 0x01:
                str = "ASCII Mode, software"
            case 0x02:
                str = "Pass through Mode, software"
            case 0x80:
                str = "Protocol Communicatin Mode, hardware"
            case 0x81:
                str = "ASCII Mode, hardware"
            case 0x82:
                str = "Pass through Mode, hardware"
            default:
                print("chipInfoSerialComModeString  invalid mode detect!!")
                str = "--"
        }
        return str
    }
    
    var serialAddressString: String {
        return "0x\(String(serialAddress, radix:16))"
    }
    
    var serialBaudRateString: String {
        return "\(String(serialBaudRate, radix:10))bps"
    }
    
    var serialPacketIntervalString: String {
        return "\(String(serialPacketInterval, radix:10))msec"
    }
        
    var usbVidString: String {
        return byteArrayToString(array: usbVid)
    }
    
    var usbPidString: String {
        return byteArrayToString(array: usbPid)
    }
    
    var usbUploadIntervalString: String {
        return "\(String(usbUploadInterval, radix:10))msec"
    }
    
    var usbReleaseDelayString: String {
        return "\(String(usbReleaseDelay, radix:10))msec"
    }
    
    var usbAutoLineFeedString: String {
        var str : String

        if usbAutoLineFeedFlag == 0x01 {
            str = "ON"
        }else if usbAutoLineFeedFlag == 0x00 {
            str = "OFF"
        }else{
            print("")
            str = "--"
        }
        
        return str
    }
    
    var usbCarriageReturnCharactorString: String {
        return byteArrayToString(array: usbCarriageReturnCharactor0) + " / " + byteArrayToString(array: usbCarriageReturnCharactor1)
    }
        
    var filteringCharactorString: String {
        return byteArrayToString(array: usbFilteringCharactorStart) + " - " + byteArrayToString(array: usbFilteringCharactorEnd)
    }
    
    
    func byteArrayToString(array: [UInt8]?) -> String {
        var str = String()
        if let byteArray = array {
            str = "0x"
            for byte in byteArray {
                str += "\(String(byte, radix:16))"
            }
        }else{
            str = "--"
        }
        return str
    }
    
    
    var usbStringValidFlagString: String {

        let flag = usbStringValidFlag
        
        var str = String()
        str += ( 0x01 & flag == 0x00) ? "SN:OFF" : "SN:ON"
        str += ","
        str += ( 0x02 & flag == 0x00) ? "Product:OFF" : "Product:ON"
        str += ","
        str += ( 0x04 & flag == 0x00) ? "Vendor:OFF" : "Vendor:ON"
        str += ","
        str += ( 0x80 & flag == 0x00) ? "String:OFF" : "String:ON"
        
        return str
    
    }
    
    var usbHighSpeedUploadFlagString: String {
        var str : String
        let mode = usbHighSpeedUploadFlag
        
        if mode == 0x01 {
            str = "ON"
        }else if mode == 0x00 {
            str = "OFF"
        }else{
            print("")
            str = "--"
        }
        
        return str
    }
    
}

