//
//  ConsoleView.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI
import AVFoundation
import SwiftData

struct ConsoleView: View {
    @Bindable var setting: ConsoleSetting
    @EnvironmentObject var appDelegate : AppDelegate
    
    @State private var videoDevice: AVCaptureDevice? = nil
    @State private var videoDeviceFormat: AVCaptureDevice.Format? = nil
    @State private var videoDeviceFrameDuration: CMTime? = nil
    
    @State private var audioDevice: AVCaptureDevice? = nil
    
    // @State private var isHover = false
    @State private var hoverLocation: CGPoint = .zero
    
    @State private var displayStatus: DisplayStatus? = nil
    
    @State private var preventDisplaySleep : Bool = false
    
    @StateObject var manipulator: Manipulator
    weak var keyboardMonitor : KeyboardMonitor?
    
    static func identifier(ssid: UUID ) -> String {
        "Console_\(ssid)"
    }    
    
    init(setting: ConsoleSetting, keyboardMonitor: KeyboardMonitor, deviceDiscovery: DeviceDiscovery) {
        print("ConsoleView initialized \(setting)")
        
        self.setting = setting
        self.keyboardMonitor = keyboardMonitor
        //self.deviceDiscovery = deviceDiscovery
        self.preventDisplaySleep = setting.preventDisplaySleep
                
        switch setting.manipulatingDeviceType0 {
        case .CH9329:
            // StateObject(wrappedValue: )は、一行で記述することに意味がある。
            self._manipulator = StateObject(wrappedValue:
                                                Manipulator(manipulatingArea: ManipulatingArea(),
                                                            converter: ManipulateConverter_CH9329(setting: setting,
                                                                                                  deviceDiscovery: deviceDiscovery),
                                                            pointingFrameType: setting.mousePointingFrameType0)
                                                           )
            
        default:
            fatalError()
        }
        
        
        if let devID = setting.videoDeviceID0 {
            _videoDevice = State(initialValue: AVCaptureDevice(uniqueID: devID))
            
            if let sformat = setting.videoDeviceFormat0(ofDevice: videoDevice) {
                _videoDeviceFormat = State(initialValue: sformat)
                _videoDeviceFrameDuration = State(initialValue: setting.videoDeviceFrameDuration0())
                

            }else{
                print("ConsoleView appear videoFormat cannot find. use current active format.")
                _videoDeviceFormat = State(initialValue: videoDevice?.activeFormat)
                _videoDeviceFrameDuration = State(initialValue: videoDevice?.activeVideoMinFrameDuration)
                
            }
            
            // setting.printVideoDevice()
            
        }else{
            print("ConsoleView videoDevice is not set.")
            _videoDevice = State(initialValue: nil)
            _videoDeviceFormat = State(initialValue: nil)
            _videoDeviceFrameDuration = State(initialValue: nil)
        }
        
        
        if let devID = setting.audioDeviceID0 {
            _audioDevice = State(initialValue: AVCaptureDevice(uniqueID: devID))
        }else{
            _audioDevice = State(initialValue: nil)
        }
    }
    
    var body: some View {
        VStack{
            DisplayUIView(captureDevice: $videoDevice,
                          captureFormat: $videoDeviceFormat,
                          captureFrameDuration: $videoDeviceFrameDuration,
                          audioDevice: $audioDevice,
                          displayStatus: $displayStatus,
                          manipulator: manipulator,
                          drawHandler: manipulator.drawHandler)
        }
        .aspectRatio(videoDeviceFormat?.aspectRatio ?? 1, contentMode: .fit)
        .navigationTitle("\(setting.name)")
        /*
        .toolbar{
            ConsoleToolbar(muted: $manipulator.converter.mute)
        }*/
        .onHover { hover in
            
            if hover == true {
                NSCursor.hide()
            }else {
                NSCursor.unhide()
            }
            
        }
        .onAppear(){
            // manipulator reset
            self.manipulator.reset()
            keyboardMonitor?.setManipulator(self.manipulator)
            
            appDelegate.isPreventingSleep = self.preventDisplaySleep
            
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)){notification in
            
            guard let window = notification.object as? NSWindow else {
                return
            }
            
            if let sw = appDelegate.windows[ConsoleView.identifier(ssid: setting.id)]?.object, window == sw {
            // if window.identifier == NSUserInterfaceItemIdentifier(ConsoleView.identifier(ssid: setting.id)) {
                print("become keyWindow of consoleView \(setting.id)")
                keyboardMonitor?.setManipulator(self.manipulator)
                self.manipulator.reset()
            }
            // 起動直後に didBecomeKeyNotificationは呼ばれるが、そのときはidentifierはまだ設定されていない
        }
        
    }
        
}
