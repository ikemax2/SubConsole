//
//  SettingListView.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI
import SwiftData
import AVFoundation
import SerialGate

struct SettingListView: View {
    @Binding var consoleStatus: Dictionary<UUID, Bool>
    @EnvironmentObject var appDelegate : AppDelegate
    
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [ConsoleSetting]
    
    @State private var selectedSettingID: ConsoleSetting.ID? = nil // for single-select

    @State private var sortOrder = [KeyPathComparator(\ConsoleSetting.name)]
    
    @State private var isEditing = false
    
    @State private var isSettingDeleteAlertShow = false
    @State private var willDeleteSetting : ConsoleSetting? = nil
    
    @ObservedObject var deviceDiscovery : DeviceDiscovery
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    weak var keyboardMonitor : KeyboardMonitor?
    
    static func identifier() -> String {
        "SettingList"
    }
    
    init(consoleStatus: Binding<Dictionary<UUID, Bool>>, keyboardMonitor: KeyboardMonitor, deviceDiscovery: DeviceDiscovery) {
        self._consoleStatus = consoleStatus
        self.keyboardMonitor = keyboardMonitor
        self.deviceDiscovery = deviceDiscovery
    }
    
    var sortedSettings: [ConsoleSetting] {
        settings.sorted(using: sortOrder)
    }
    
    var newSettingName : String {
        var lastNum = 0
        settings.forEach {
            if $0.name.hasPrefix("Console ") == true {
                print("setting name: \($0.name)")
                let numString = $0.name.replacingOccurrences(of: "Console ", with: "")
                if let num = Int(numString), lastNum < num {
                    lastNum = num
                }
            }
        }

        lastNum += 1
        return "Console \(lastNum)"
    }
    
    var body: some View {
        
        Table(of: ConsoleSetting.self, selection: $selectedSettingID, sortOrder: $sortOrder){

            TableColumn("Name") { columndata in
                HStack{
                    ConsoleIndicator(consoleStatus: $consoleStatus, id: columndata.id)
                        .frame(width:12, height:12)
                    Text(columndata.name)
                }
            }
            
            TableColumn("Video") { columndata in
                AVDeviceText(deviceID: columndata.videoDeviceID0, deviceName: columndata.videoDeviceName0,
                             deviceList: $deviceDiscovery.availableCaptureDevices)
            }
            
            TableColumn("Audio") { columndata in
                AVDeviceText(deviceID: columndata.audioDeviceID0, deviceName: columndata.audioDeviceName0,
                             deviceList: $deviceDiscovery.availableAudioDevices)
                
            }

            TableColumn("Manipulating") { columndata in
                SerialDeviceText(deviceType: columndata.manipulatingDeviceType0, devicePath: columndata.manipulatingSerialPath0,
                                 deviceList: $deviceDiscovery.availableSerialPorts)

            }
                
        } rows: {
            ForEach(sortedSettings) { setting in
                TableRow(setting)
                    .contextMenu{
                        Button("Open"){
                            openWindow(id:"console", value: setting)
                            print("consoleStatus: \(consoleStatus)")
                            print(" setting id: \(setting.id)")
                        }
                        .disabled($consoleStatus.wrappedValue[setting.id] ?? false)
                        
                        Button("Dismiss"){
                            dismissWindow(id:"console", value: setting)
                        }
                        .disabled(!($consoleStatus.wrappedValue[setting.id] ?? false))
                        
                        Divider()
                        
                        Button("Edit"){
                            selectedSettingID = setting.id
                            isEditing = true
                        }
                        .disabled($consoleStatus.wrappedValue[setting.id] ?? false)
                        
                        Button("Delete"){
                            willDeleteSetting = setting
                            isSettingDeleteAlertShow = true
                        }
                        .disabled($consoleStatus.wrappedValue[setting.id] ?? false)
                    }
            }
       }

        .contextMenu(forSelectionType: ConsoleSetting.ID.self, menu: { settingIDs in

        }, primaryAction: { settingIDs in
            // print("primary action \(settingIDs.first)")
            if let setting = selectedSetting(sid: settingIDs.first){
                openWindow(id:"console", value: setting)
            }
        })

        .onChange(of: sortOrder){_, sortOrder in
            _ = sortedSettings.sorted(using: sortOrder)
        }
        .toolbar{
            SettingListToolbar(editing: $isEditing, selectedSettingID: $selectedSettingID, consoleStatus: $consoleStatus) {
                
                let newSetting = ConsoleSetting(name: self.newSettingName)
                
                modelContext.insert(newSetting)
                selectedSettingID = newSetting.id
                isEditing = true
            }
        }

        .sheet(isPresented: $isEditing, onDismiss: nil) {
           
            ForEach(settings) { sset in
                Group{
                    if sset.id == selectedSettingID {
                        SettingEditView(setting: sset, deviceDiscovery: self.deviceDiscovery)
                    }
                }
            }
             
        }

        .navigationTitle("SubConsole")

        .onAppear(){
            Task{
                await setUpCameraCaptureSession()
                await setUpMicrophoneCaptureSession()
            }

            keyboardMonitor?.setManipulator(nil)
           
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)){ notification in
            
            guard let window = notification.object as? NSWindow else {
                return
            }
            
            if let sw = appDelegate.windows[SettingListView.identifier()]?.object, window == sw {
            // if window.identifier == NSUserInterfaceItemIdentifier(SettingListView.identifier() ) {
                print("become keyWindow of settingListView")
                keyboardMonitor?.setManipulator(nil)
            }
            // 起動直後に didBecomeKeyNotificationは呼ばれるが、そのときはidentifierはまだ設定されていない
        }
        
        .confirmationDialog("The setting will be removed if continued.",
                            isPresented: $isSettingDeleteAlertShow){
                        
            Button("OK", role: .destructive){
                if let s = willDeleteSetting {
                    modelContext.delete(s)
                }
                
                willDeleteSetting = nil
                isSettingDeleteAlertShow = false
            }
        }
    }

    struct AVDeviceText : View{
        
        let deviceID : String?
        let deviceName : String?
        var deviceList : Binding<[AVCaptureDevice]>
        
        var body: some View {
            if let dID = deviceID {
                if let device = deviceList.wrappedValue.first(where: {$0.uniqueID == dID}){
                    if device.isInUseByAnotherApplication == true {
                        // デバイスは使用中である。(lockForConfigurationされている)
                        TextWithDetail(device.localizedName, "SN:\(shrinkDeviceUniqueID(device.uniqueID))").disabled(true)
                    }else{
                        TextWithDetail(device.localizedName, "SN:\(shrinkDeviceUniqueID(device.uniqueID))").disabled(false)
                    }
                    
                }else{
                    // deviceID が見つからない
                    TextWithDetail(deviceName ?? "", "SN:\(shrinkDeviceUniqueID(deviceID ?? ""))").disabled(true)
                }
                    
           }else{
               Text("None")
           }
        }
        
        func shrinkDeviceUniqueID(_ uniqueID: String) -> String {
            let f = uniqueID.components(separatedBy: ":")
            
            if f.count > 3 {
                return f[3..<f.count].joined(separator:":")
            }else{
                return uniqueID
            }
        }
    }
    
    
    struct SerialDeviceText : View{
        
        let deviceType : ManipulatingDeviceType?
        let devicePath : String?
        var deviceList : Binding<[SGPort]>
        
        var body: some View {
            
            if deviceType == .CH9329 {
                if let dPath = devicePath {
                    if let device = deviceList.wrappedValue.first(where: {$0.name == dPath}){
                        /*
                        if device.portState == .open {
                            // デバイスは使用中である。
                            TextWithDetail(deviceType!.rawValue, "Path:\(dPath)").disabled(true)
                        }else{
                            TextWithDetail(deviceType!.rawValue, "Path:\(dPath)").disabled(false)
                        }
                        */
                        TextWithDetail(deviceType!.rawValue, "Path:\(dPath)").disabled(false)
                        
                    }else{
                        // devicePath が見つからない
                        TextWithDetail(deviceType!.rawValue, "Path:\(dPath)").disabled(true)
                    }
                }else{
                    Text("None")
                }
                    
           }else{
               // deviceType is unknown
               Text("Unknown")
           }
        }
    }
    

    func selectedSetting(sid: ConsoleSetting.ID?) -> ConsoleSetting? {
         guard selectedSettingID != nil else {
             return nil
         }
         
        let filterdSetting: [ConsoleSetting] = settings.filter{ $0.id == selectedSettingID }
         
         guard filterdSetting.count > 0 else {
             return nil
         }
                 
         return filterdSetting.first
    }

                     
    var isCameraAuthorized: Bool {
        get async {
            // camera
            let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)

            var isCameraAuthorized = cameraStatus == .authorized
            
            if cameraStatus == .notDetermined {
                isCameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
                    
            return isCameraAuthorized
        }
        
    }
    
    var isMicrophoneAuthorized: Bool {
        get async {
            
            // microphone
            let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)

            var isAudioAuthorized = audioStatus == .authorized
            
            if audioStatus == .notDetermined {
                isAudioAuthorized = await AVCaptureDevice.requestAccess(for: .audio)
            }
                    
            return isAudioAuthorized
        }
        
    }
    
    func setUpCameraCaptureSession() async{
        guard await isCameraAuthorized else { return }
    }
    
    func setUpMicrophoneCaptureSession() async{
        guard await isMicrophoneAuthorized else { return }
    }
    
}

