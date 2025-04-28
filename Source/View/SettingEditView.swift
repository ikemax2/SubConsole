//
//  SettingEditView.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI
import AVFoundation

struct SettingEditView: View {
    @Bindable var setting: ConsoleSetting
    @Environment(\.dismiss) var dismiss

    @State private var newSettingName: String
    
    @State private var selectedVideoDevice: AVCaptureDevice? = nil
    @State private var selectedVideoDeviceFormat: AVCaptureDevice.Format? = nil
    @State private var selectedVideoDeviceFrameDuration: CMTime? = nil
    
    @State private var selectedAudioDevice: AVCaptureDevice? = nil

    @State private var formVideoDevice: String?
    
    @State private var formMediaSubtypes: String?
    @State private var formDimensions: String?
    @State private var formFpss: String?
    
    @State private var formWindowFullSizeStating: Bool
    @State private var formPreventDisplaySleep: Bool

    @State private var formAudioDevice: String?
    
    @State private var formManipulatingDeviceType : ManipulatingDeviceType?
    let availableManipulatingDeviceType : [ManipulatingDeviceType] = [.CH9329]
    
    @State private var formManipulatingDeviceSetting : String?
    
    @State private var formManipulatingSerialPath: String?
    @State private var formManipulatingSerialBaudRate: Int32?
    @State private var formManipulatingSerialParity: UInt8? = nil
    @State private var formManipulatingSerialStopBit: UInt8? = nil
    
    @State private var displayStatus: DisplayStatus? = DisplayStatus()
    
    @State private var formMousePointingCommandType : PointingCommandType
    let availablePointingCommandType : [PointingCommandType] = [.absolute, .relative]
    
    @State private var formMousePointingFrameType : PointingFrameType = .topleft
    let availablePointingFrameType : [PointingFrameType] = [.topleft, .bottomleft]
    
    @State private var formMouseCursorType : CursorType? = nil
    let availableCursorType : [CursorType] = [.dot, .empty]
    
    @ObservedObject var deviceDiscovery : DeviceDiscovery
    
    init(setting: ConsoleSetting, deviceDiscovery: DeviceDiscovery) {
        print("SettingEditView initialized \(setting.id)")
        self.setting = setting
        self.deviceDiscovery = deviceDiscovery
        
        _newSettingName = State(initialValue: setting.name)
    
        _formVideoDevice =  State(initialValue: setting.videoDeviceID0)
        
        _formWindowFullSizeStating = State(initialValue: setting.windowFullScreenStarting)
        _formPreventDisplaySleep = State(initialValue: setting.preventDisplaySleep)
        
        _formMousePointingCommandType = State(initialValue: setting.mousePointingCommandType0)
        _formMousePointingFrameType = State(initialValue: setting.mousePointingFrameType0)
        _formMouseCursorType = State(initialValue: setting.mouseCursorType0)

                        
        let videoDevice = deviceDiscovery.availableCaptureDevices.first(where: {$0.uniqueID == setting.videoDeviceID0})
        _selectedVideoDevice = State(initialValue: videoDevice)
        
        var videoFrameDuration : CMTime? = nil
        
        var videoFormat = setting.videoDeviceFormat0(ofDevice: videoDevice)
        
        if videoFormat == nil {
            print("videoFormat cannot find.")
            videoFormat = videoDevice?.activeFormat
            videoFrameDuration = videoDevice?.activeVideoMinFrameDuration
            
        }else{
            videoFrameDuration = setting.videoDeviceFrameDuration0()
        }
        
        _selectedVideoDeviceFormat = State(initialValue: videoFormat)
        _selectedVideoDeviceFrameDuration = State(initialValue: videoFrameDuration)
        
        
        _formMediaSubtypes = State(initialValue: videoFormat?.formatDescription.mediaSubTypeString)
        _formDimensions = State(initialValue: videoFormat?.formatDescription.dimensionString)
        _formFpss = State(initialValue: videoFrameDuration?.frameRateString)
        
        
        
        _formAudioDevice = State(initialValue: setting.audioDeviceID0)
        
        let audioDevice = deviceDiscovery.availableAudioDevices.first(where: {$0.uniqueID == setting.audioDeviceID0})
        _selectedAudioDevice = State(initialValue: audioDevice)
        
        
        _formManipulatingSerialPath = State(initialValue: setting.manipulatingSerialPath0)
        _formManipulatingSerialBaudRate = State(initialValue: setting.manipulatingSerialBaudRate0)
        
        if let dtype = setting.manipulatingDeviceType0 {
            _formManipulatingDeviceType = State(initialValue:dtype)
        }else{
            _formManipulatingDeviceType = State(initialValue:ManipulatingDeviceType.CH9329)
        }
        
    }
        
    
    var body: some View {

        VStack{
            Text("Edit Setting")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment:.leading)
            
            Spacer()
            Form {
                TextField("Name", text: $newSettingName, prompt: Text("Required"))

            }
            
            
            Spacer()
            TabView{
                
                VStack(spacing: 10) {
                    Picker( selection: $formVideoDevice, content: {
                        Text("None").tag( nil as String? )
                        ForEach(deviceDiscovery.availableCaptureDevices.indices, id:\.self) { index in
                            // formVideoDevice が String? 型のため、tag内もオプショナル型に揃える。
                            Text("\(deviceDiscovery.availableCaptureDevices[index].localizedName)  [\(deviceDiscovery.availableCaptureDevices[index].uniqueID)]" ).tag( Optional(deviceDiscovery.availableCaptureDevices[index].uniqueID) )
                        }
                    }, label: {
                        Text("Video Device")
                            .frame(maxWidth: 100, alignment:.leading)
                    })
                    
                    .onChange(of: formVideoDevice) {
                        selectedVideoDeviceFormat = nil
                        selectedVideoDeviceFrameDuration = nil
                        formMediaSubtypes = nil
                        formDimensions = nil
                        formFpss = nil
                        selectedVideoDevice = deviceDiscovery.availableCaptureDevices.first(where: {$0.uniqueID == formVideoDevice})
                        
                    }
                    .onChange(of: deviceDiscovery.availableCaptureDevices) {
                        if deviceDiscovery.availableCaptureDevices.first(where: {$0.uniqueID == formVideoDevice}) == nil {
                            formVideoDevice = nil as String?
                        }
                    }
                    
                    HStack(alignment: .top) {
                        Text("Video Format")
                            .frame(maxWidth: 100, alignment:.leading)
                        
                        Group{
                            VideoFormatSelectionView(videoDevice:selectedVideoDevice,
                                                     selectedMediaSubtypes: $formMediaSubtypes,
                                                     selectedDimensions: $formDimensions,
                                                     selectedFpss: $formFpss )
                            .onChange(of: [formMediaSubtypes, formDimensions, formFpss]) {
                                // print("selectedmediaSubtypes changed")
                                updateVideoFormat()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment:.center)
                    }

                    HStack(alignment: .top) {
                        Text("Preview")
                            .frame(maxWidth: 100, alignment:.leading)
                        Group {
                            
                            DisplayUIView(captureDevice: $selectedVideoDevice,
                                          captureFormat: $selectedVideoDeviceFormat,
                                          captureFrameDuration: $selectedVideoDeviceFrameDuration,
                                          audioDevice: $selectedAudioDevice,
                                          displayStatus: $displayStatus)
                            .frame(width:200 * (selectedVideoDeviceFormat?.aspectRatio ?? 1.5) ,
                                   height:200,
                                   alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment:.center)
                        
                    }
                    
                    DisplayStatusText(displayStatus: $displayStatus)
                        .frame(maxWidth: .infinity, alignment:.trailing)
                    
                    HStack(alignment: .top) {
                        Text("Window")
                            .frame(maxWidth: 100, alignment:.leading)
                        
                        Toggle("Open Window in full Screen", isOn: $formWindowFullSizeStating)
                            .toggleStyle(.checkbox)
                            .frame(maxWidth: .infinity, alignment:.leading)
                        Toggle("Prevent Display Sleep", isOn: $formPreventDisplaySleep)
                            .toggleStyle(.checkbox)
                            .frame(maxWidth: .infinity, alignment:.leading)
                    }

                    
                }.padding()
                .tabItem {
                    Text("Video")
                }
                
                VStack(spacing: 10) {

                    Picker(selection: $formAudioDevice, content:{
                        Text("None").tag( nil as String? )
                        ForEach(deviceDiscovery.availableAudioDevices.indices, id:\.self) { index in
                            // formAudioDevice が String? 型のため、tag内もオプショナル型に揃える。
                            Text("\(deviceDiscovery.availableAudioDevices[index].localizedName)  [\(deviceDiscovery.availableAudioDevices[index].uniqueID)]").tag( Optional(deviceDiscovery.availableAudioDevices[index].uniqueID) )
                        }
                    }, label: {
                        Text("Audio Device")
                            .frame(maxWidth: 100, alignment:.leading)
                    })
                    .onChange(of: formAudioDevice) {
                        selectedAudioDevice = deviceDiscovery.availableAudioDevices.first(where: {$0.uniqueID == formAudioDevice})
                        // print("selectedAudioDevice: \(selectedAudioDevice)")
                    }
                    Spacer()
                    
                }.padding()
                .tabItem {
                    Text("Audio")
                }
                
                VStack(spacing: 10) {
                    
                    Form {
                        Picker("Device Type", selection: $formManipulatingDeviceType){
                            // Text(verbatim: "None").tag(String?(nil))
                            ForEach(availableManipulatingDeviceType, id:\.self) { manipulatingDevType in
                                // formManipulatignDeviceType が Optional 型のため、tag内もオプショナル型に揃える。
                                Text(manipulatingDevType.rawValue).tag( Optional(manipulatingDevType) )
                            }
                        }.onChange(of: formManipulatingDeviceType) {
                            print("manipDevType changed.")
                        }
                    }
                    
                    Divider()

                    VStack(spacing: 5) {
                        if setting.manipulatingDeviceType0 == .CH9329 {
                            ManipulateSettingView_CH9329(portName: $formManipulatingSerialPath,
                                                         baudRate: $formManipulatingSerialBaudRate,
                                                         deviceDiscovery: deviceDiscovery)
                           
                        }else{
                            Text(verbatim: " x ")
                        }
                    }.padding()
                    Spacer()
                                        
                }.padding()
                .tabItem {
                    Text("Manipulating")
                }
                
                VStack(spacing: 10) {
                    
                }.padding()
                .tabItem {
                    Text("Keyboard")
                }
                
                VStack(spacing: 10) {
                    Form {
                        /*
                        Toggle("Absolute MouseCursor", isOn: $formMouseCursorAbsolute)
                            .toggleStyle(.checkbox)
                            .padding()
                         */
                        
                        Picker("Command Type", selection: $formMousePointingCommandType) {
                            ForEach(availablePointingCommandType, id:\.self) { pointingCommandType in
                                Text( pointingCommandType.description).tag( pointingCommandType )
                            }
                        }
                        
                        Picker("Frame Type", selection: $formMousePointingFrameType) {
                            ForEach(availablePointingFrameType, id:\.self) { pointingFrameType in
                                Text( pointingFrameType.description).tag( pointingFrameType )
                            }
                        }
                        
                        Divider()
                        
                        Picker("Cursor Type", selection: $formMouseCursorType){
                            Text("System Default").tag( nil as CursorType? )
                            ForEach(availableCursorType, id:\.self) { cursorType in
                                Text(cursorType.description).tag( Optional(cursorType) )
                            }
                        }
                        
                    }
                    Spacer()
                    
                }.padding()
                .tabItem {
                    Text("Mouse")
                }
                
            }
            
            Spacer()
            
            HStack{
                Button (action: {
                    dismiss()
                }){
                    Text("Cancel")
                }
                Button (action: {
                    
                    setting.name = newSettingName
                    
                    setting.videoDeviceID0 = formVideoDevice
                    setting.videoDeviceName0 = selectedVideoDevice?.localizedName
                    setting.setVideoDeviceFormat0(format: selectedVideoDeviceFormat)
                    setting.setVideoDeviceFrameDuration0(frameDuration: selectedVideoDeviceFrameDuration)
                    setting.windowFullScreenStarting = formWindowFullSizeStating
                    setting.preventDisplaySleep = formPreventDisplaySleep
                    
                    setting.manipulatingDeviceType0 = formManipulatingDeviceType
                    
                    if setting.manipulatingDeviceType0 == .CH9329 {
                        setting.manipulatingSerialPath0 = formManipulatingSerialPath
                        setting.manipulatingSerialBaudRate0 = formManipulatingSerialBaudRate
                    }else{
                        setting.manipulatingSerialPath0 = nil
                        setting.manipulatingSerialBaudRate0 = nil
                    }
                    
                    setting.audioDeviceID0 = formAudioDevice
                    setting.audioDeviceName0 = selectedAudioDevice?.localizedName
                    
                    setting.mousePointingCommandType0 = formMousePointingCommandType
                    setting.mousePointingFrameType0 = formMousePointingFrameType
                    setting.mouseCursorType0 = formMouseCursorType
                    
                    dismiss()
                }){
                    Text("OK")
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
        }
        .padding()
        .frame(width: 600, height : 600)
    }
    
    func updateVideoFormat() {
        
        if let subtype = formMediaSubtypes, let dimension = formDimensions, let fpsString = formFpss {
            
            if let availableFormats : [AVCaptureDevice.Format] = selectedVideoDevice?.formats {
                for format : AVCaptureDevice.Format in availableFormats {
                    
                    if subtype != format.formatDescription.mediaSubTypeString {
                        continue
                    }
                        
                    if dimension != format.formatDescription.dimensionString {
                        continue
                    }
                    
                    let nextFrameDuration = format.isContainFrameRate(FPSString: fpsString)
                                                                    
                    if nextFrameDuration != nil {
                        print("update VideoFormat \(format.description) \(String(describing: nextFrameDuration))")
                        selectedVideoDeviceFormat = format
                        selectedVideoDeviceFrameDuration = nextFrameDuration
                        break
                    }
                }
            }
        }
    }
}
