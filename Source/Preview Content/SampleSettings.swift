//
//  SampleSettings.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import Foundation
import AVFoundation

struct SampleSettings {
    static var contents = [ConsoleSetting]()
    
    init(){
                
        let setting1 = ConsoleSetting(name: "setting 1")
        setting1.videoDeviceID0 = "/dev/xxx"
        setting1.videoDeviceFormatString0 = "x"
        
        setting1.manipulatingSerialPath0 = "/dev/xxx"
        setting1.manipulatingSerialBaudRate0 = 9600
        
        setting1.manipulatingDeviceType0 = .CH9329
        // setting1.manipulatingDeviceSetting0 = ""
        
        // setting1.sessionPresetString0 = AVCaptureSession.Preset.hd4K3840x2160.rawValue
                
        SampleSettings.contents.append(setting1)
        
        let setting2 = ConsoleSetting(name: "setting 1")
        setting2.videoDeviceID0 = "/dev/xxx"
        setting2.videoDeviceFormatString0 = "x"
        
        setting2.manipulatingSerialPath0 = "/dev/yyy"
        setting2.manipulatingSerialBaudRate0 = 9600
        
        setting2.manipulatingDeviceType0 = .CH9329
        //setting2.manipulatingDeviceSetting0 = "/dev/yyy,9600"
        
        // setting2.sessionPresetString0 = AVCaptureSession.Preset.hd1920x1080.rawValue
        
        SampleSettings.contents.append(setting2)
        
    }
}

struct SampleSetting {
    static var content : ConsoleSetting  {
        
        let setting99 = ConsoleSetting(name: "setting 99")
        setting99.videoDeviceID0 = "/dev/yys"
        setting99.videoDeviceFormatString0 = "x"
        
        setting99.manipulatingSerialPath0 = "/dev/zzz"
        setting99.manipulatingSerialBaudRate0 = 9600
                
        setting99.manipulatingDeviceType0 = .CH9329
       // setting99.manipulatingDeviceSetting0 = "/dev/xxk,9600"
        
        // setting99.sessionPresetString0 = AVCaptureSession.Preset.hd1920x1080.rawValue
        
        return setting99
    }
    
}

var sampleConsoleStatus : Dictionary<UUID, Bool> = [UUID(): true, UUID(): false]
    

