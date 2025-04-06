//
//  DeviceDiscovery.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import AppKit
import AVFoundation
import IOKit
import IOKit.serial
import IOKit.usb
import SerialGate

 class DeviceDiscovery : ObservableObject{
    
     private var captureDiscovery : AVCaptureDevice.DiscoverySession
     private var audioDiscovery : AVCaptureDevice.DiscoverySession
                
     private var observations = [NSKeyValueObservation]()

    @Published var availableCaptureDevices : [AVCaptureDevice]
    @Published var availableAudioDevices : [AVCaptureDevice]
    @Published var availableSerialPorts = [SGPort]()
    
    private var searchPortsTask: Task<Void, Never>?
     
     private let portManager = SGPortManager.shared
    
    init(){
        
        self.captureDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera, .microphone],
            mediaType: .video,
            position: .unspecified)
        
        self.audioDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera, .microphone],
            mediaType: .audio,
            position: .unspecified)

        
        self.availableCaptureDevices = self.captureDiscovery.devices
        self.availableAudioDevices = self.audioDiscovery.devices
        
        searchPortsTask = Task {
            for await portsList in portManager.availablePortsStream {
                
                // 配列内容に変更があった場合に、publishする(順序の変更は無視)
                print("deviceDiscovery serialPortChanged.")
                if Set(portsList).symmetricDifference(Set(availableSerialPorts)).isEmpty != true {
                    await MainActor.run {
                        self.availableSerialPorts = portsList
                    }
                }
            }
        }
        
        addKeyValueObserver()
        
    }
    
    deinit{
        removeKeyValueObserer()
        searchPortsTask?.cancel()
    }
    
     //MARK: - observation KVO
    func addKeyValueObserver() {
        let observationC = captureDiscovery.observe(\.devices, options:[.new]) { object, change in
            if let devices = change.newValue {
                self.availableCaptureDevices = devices
            }else{
                print("AVCaptureDevice.DiscoverySession KVO observing detect nil as New Value")
            }
            print("available CaptureDevice Changed:\(self.availableCaptureDevices)")
        }
        observations.append(observationC)
        
        
        let observationA = audioDiscovery.observe(\.devices, options:[.new]) { object, change in
            if let devices = change.newValue {
                self.availableAudioDevices = devices
            }else{
                print("AVCaptureDevice.DiscoverySession KVO observing detect nil as New Value")
            }
            print("available AudioDevice Changed:\(self.availableAudioDevices)")
        }
        observations.append(observationA)
        
    }
    
    func removeKeyValueObserer() {
        observations.forEach { $0.invalidate() }
        observations.removeAll()
        print("finish observation(KVO) for AVCaptureDevice.DiscoverySession")
    }
     
}
