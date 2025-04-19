//
//  ConsoleSetting.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import Foundation
import SwiftData
import AVFoundation

enum ManipulatingDeviceType : String, CaseIterable, Identifiable, Codable {
    case CH9329 = "CH9329"
    
    var id: String { self.rawValue }
}

enum PointingCommandType : Int8, CaseIterable, Identifiable, Codable {
    case absolute = 0
    case relative = 1
    
    var id: Int8 { self.rawValue }
    
    var description : String {
        switch self {
        case .absolute :
            return "Absolute"
        case .relative :
            return "Relative"
        }
    }
}

enum PointingFrameType : Int8, CaseIterable, Identifiable, Codable {
    case topleft = 0 // "Top-Left"
    case bottomleft = 1 // "Bottom-Left"
    
    var id: Int8 { self.rawValue }
    
    var description : String {
        switch self {
        case .topleft :
            return "Top-Left"
        case .bottomleft :
            return "Bottom-Left"
        }
    }
}

enum CursorType : Int8, CaseIterable, Identifiable, Codable {
    case dot = 1 // "dot"
    case empty = 2 // "empty"
    
    var id: Int8 { self.rawValue }
    
    var description : String {
        switch self {
        case .dot :
            return "Dot"
        case .empty :
            return "Empty"
        }
    }
}

@Model
final class ConsoleSetting: Identifiable, Codable {
    // codable 対応は、App の WindowGroupの引数対応のため
    typealias ID = UUID
    
    var id: UUID = UUID()
    var name : String
    var videoDeviceID0 : String?
    var videoDeviceName0 : String?
    var videoDeviceFormatString0 : String?
    var videoDeviceFrameDurationString0 : String?
    var audioDeviceID0 : String?
    var audioDeviceName0 : String?
    var manipulatingDeviceType0 : ManipulatingDeviceType? = ManipulatingDeviceType.CH9329
    var manipulatingSerialPath0 : String?
    var manipulatingSerialBaudRate0 : Int32? = 9600
    //var mouseCursorAbsolute0 : Bool = true
    var mousePointingCommandType0 : PointingCommandType = PointingCommandType.absolute
    var mousePointingFrameType0 : PointingFrameType = PointingFrameType.topleft
    var windowFullScreenStarting : Bool = false
    var preventDisplaySleep : Bool = false
    
    public enum CodingKeys: CodingKey {
        case id
        case name
        case videoDeviceID0
        case videoDeviceName0
        case videoDeviceFormatString0
        case videoDeviceFrameDurationString0
        case audioDeviceID0
        case audioDeviceName0
        case manipulatingDeviceType0
        case manipulatingSerialPath0
        case manipulatingSerialBaudRate0
        //case mouseCursorAbsolute0
        case mousePointingCommandType0
        case mousePointingFrameType0
        case windowFullScreenStarting
        case preventDisplaySleep
    }
    
    init(name: String = "" ) {
        self.name = name
    }
    
    // MARK: -
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.videoDeviceID0 = try container.decode(String.self, forKey: .videoDeviceID0)
        self.videoDeviceName0 = try container.decode(String.self, forKey: .videoDeviceName0)
        self.videoDeviceFormatString0 = try container.decode(String.self, forKey: .videoDeviceFormatString0)
        self.videoDeviceFrameDurationString0 = try container.decode(String.self, forKey: .videoDeviceFrameDurationString0)
        
        self.audioDeviceID0 = try container.decode(String.self, forKey: .audioDeviceID0)
        self.audioDeviceName0 = try container.decode(String.self, forKey: .audioDeviceName0)
        
        self.manipulatingDeviceType0 = try container.decode(ManipulatingDeviceType.self, forKey: .manipulatingDeviceType0)
        self.manipulatingSerialPath0 = try container.decode(String.self, forKey: .manipulatingSerialPath0)
        self.manipulatingSerialBaudRate0 = try container.decode(Int32.self, forKey: .manipulatingSerialBaudRate0)
                
        //self.mouseCursorAbsolute0 = try container.decode(Bool.self, forKey: .mouseCursorAbsolute0)
        self.mousePointingCommandType0 = try container.decode(PointingCommandType.self, forKey: .mousePointingCommandType0)
        self.mousePointingFrameType0 = try container.decode(PointingFrameType.self, forKey: .mousePointingFrameType0)
        
        self.preventDisplaySleep = try container.decode(Bool.self, forKey: .preventDisplaySleep)

    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(videoDeviceID0, forKey: .videoDeviceID0)
        try container.encode(videoDeviceName0, forKey: .videoDeviceName0)
        try container.encode(videoDeviceFormatString0, forKey: .videoDeviceFormatString0)
        try container.encode(videoDeviceFrameDurationString0, forKey: .videoDeviceFrameDurationString0)
        
        try container.encode(audioDeviceID0, forKey: .audioDeviceID0)
        try container.encode(audioDeviceName0, forKey: .audioDeviceName0)
        
        try container.encode(manipulatingDeviceType0, forKey: .manipulatingDeviceType0)
        try container.encode(manipulatingSerialPath0, forKey: .manipulatingSerialPath0)
        try container.encode(manipulatingSerialBaudRate0, forKey: .manipulatingSerialBaudRate0)
        
        //try container.encode(mouseCursorAbsolute0, forKey: .mouseCursorAbsolute0)
        try container.encode(mousePointingCommandType0, forKey: .mousePointingCommandType0)
        try container.encode(mousePointingFrameType0, forKey: .mousePointingFrameType0)
        
        try container.encode(preventDisplaySleep, forKey: .preventDisplaySleep)

    }
    
    // MARK: -
    func setVideoDeviceFormat0(format: AVCaptureDevice.Format?) {
        if let f = format {
            self.videoDeviceFormatString0 = encodeVideoDeviceFormat(format: f)
        }
    }
    
    // convert deviceFormat to string for DB storage
    func encodeVideoDeviceFormat(format: AVCaptureDevice.Format) -> String {
        let fdesc = format.formatDescription
        var str = fdesc.mediaTypeString + ","
        str += fdesc.mediaSubTypeString + ","
        str += fdesc.dimensionString
        return str
    }
    
    // return deviceFormat that matches the "videoDeviceFormat0" record in this setting.
    func videoDeviceFormat0(ofDevice device: AVCaptureDevice?) -> AVCaptureDevice.Format? {

        if self.videoDeviceFormatString0 == nil {
            return nil
        }
        
        guard let dev = device else{
            return nil
        }
        
        let availableFormats : [AVCaptureDevice.Format] = dev.formats
        for format : AVCaptureDevice.Format in availableFormats {
            let digestString = encodeVideoDeviceFormat(format: format)

            if self.videoDeviceFormatString0 == digestString {
                return format
            }
        }
        return nil
    }
    
    var videoSize0 : CGSize {
        var size = CGSize(width: 640, height: 480)
        if let str = self.videoDeviceFormatString0?.components(separatedBy: ",").last {
            let dimension = CMFormatDescription.dimensionComponents(str)
            size = CGSize(width: dimension.width, height: dimension.height)
        }
        return size
    }

    // MARK: -
    // store CMTime to "videoDeviceFrameDuration0" record of this setting
    func setVideoDeviceFrameDuration0(frameDuration: CMTime?) {
        if let fd = frameDuration {
            self.videoDeviceFrameDurationString0 = encodeVideoDeviceFrameDuration(frameDuration: fd)
        }
    }
    
    // convert CMTime to string for DB storage
    func encodeVideoDeviceFrameDuration(frameDuration: CMTime) -> String {
        let value = Int64(frameDuration.value)
        let timescale = Int32(frameDuration.timescale)
        let flags = frameDuration.flags.rawValue
        let epoch = Int64(frameDuration.epoch)
        
        let str = "\(value),\(timescale),\(flags),\(epoch)"
        return str
    }
    
    func videoDeviceFrameDuration0() -> CMTime? {
        if let str = self.videoDeviceFrameDurationString0 {
            return decodeVideoDeviceFrameDuration(str: str)
        }else{
            return nil
        }
    }
    
    func decodeVideoDeviceFrameDuration(str: String) -> CMTime? {
        let fields: [String] = str.components(separatedBy: ",")

        if fields.count != 4 {
            return nil
        }

        if let v = Int64(fields[0]), let t = Int32(fields[1]), let f = UInt32(fields[2]), let e = Int64(fields[3]) {
            let value = CMTimeValue(v)
            let timescale = CMTimeScale(t)
            let flags = CMTimeFlags(rawValue: f)
            let epoch = CMTimeEpoch(e)
            
            return CMTime(value:value, timescale:timescale, flags:flags, epoch:epoch)
        }
        
        return nil
    }
    
    
    // MARK: -
    func printVideoDevice() {
        if let e = self.videoDeviceID0 {
            print("videoDevice: \(e) ")
        }else {
            print("videoDevice: nil.");
        }
        
        if let f = self.videoDeviceFormatString0, let d = videoDeviceFrameDurationString0 {
            print("videoFormat: \(f) ")
            print("videoFrameDuration: \(d) ")
        }
    }
    
    static func predicate(searchID: ID) -> Predicate<ConsoleSetting> {
        return #Predicate<ConsoleSetting> { setting in
            searchID == setting.id            
        }
    }
    
    
    
}
