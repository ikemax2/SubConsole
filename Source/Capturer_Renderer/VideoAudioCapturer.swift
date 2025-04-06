//
//  VideoAudioCapturer.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import AVFoundation

class VideoAudioCapturer  {
    
    static let supportedPixelFormat : [OSType] = [kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] // 420v
    
    var captureSession: AVCaptureSession
    
    var captureDevice: AVCaptureDevice?
    var captureFormat: AVCaptureDevice.Format?
    var captureFrameDuration: CMTime?
    
    var audioDevice : AVCaptureDevice?
    
    
    var captureVideoInput : AVCaptureDeviceInput?
    var captureVideoOutput : AVCaptureVideoDataOutput
    
    var captureAudioOutput : AVCaptureOutput?
    
    public weak var manipulatingArea: ManipulatingArea?
    
    init(captureDevice: AVCaptureDevice?,
         captureFormat: AVCaptureDevice.Format?, captureFrameDuration: CMTime?,
         audioDevice: AVCaptureDevice?,
         manipulatingArea: ManipulatingArea? = nil){
        
        self.captureDevice = captureDevice
        self.captureFormat = captureFormat
        self.captureFrameDuration = captureFrameDuration
        // self.sessionPreset = sessionPreset
        
        self.audioDevice = audioDevice
        
        self.captureSession = AVCaptureSession()
        
        self.captureVideoOutput = AVCaptureVideoDataOutput()

        self.manipulatingArea = manipulatingArea
    }
  
    func start(){
        captureSession.startRunning()
        print("captureStart called")
    }
    
    func stop(){
        if captureSession.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func setVideoRenderer(_ videoRenderer: VideoRenderer){
        // 以下によって キャプチャのたびに videoRenderer の captureOutput が呼ばれるようになる。
        self.captureVideoOutput.setSampleBufferDelegate(videoRenderer, queue: DispatchQueue(label:"capture", qos: .userInteractive))
        
    }
    

    func setAudioOutput(_ audioOutput: AVCaptureOutput){
        self.captureAudioOutput = audioOutput
    }
    
    func videoInputDimensions() -> CGSize{
        
        var outputSize : CGSize = .zero
        
        // update videoInformation.
        if let port = self.captureVideoInput?.ports.first(where: {$0.mediaType == .video}) {
            if let  dimensions = port.formatDescription?.dimensions {
                outputSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
            }
        }
        
        return outputSize
    }
    
    func configureSession() {
        // fourcharcode との対応は CVPixelBuffer.h または以下を参照。
        // https://developer.apple.com/documentation/technotes/tn3121-selecting-a-pixel-format-for-an-avcapturevideodataoutput
        // https://developer.apple.com/documentation/corevideo/cvpixelformatdescription/1563591-pixel_format_identifiers

        // print("configureSession outputSetting: \(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange.fourCharCodeString)")  // 420v
        // print("configureSession outputSetting: \(kCVPixelFormatType_422YpCbCr8_yuvs.fourCharCodeString)")  // yuvs
        // print("configureSession outputSetting: \(kCVPixelFormatType_422YpCbCr8.fourCharCodeString)")  // 2vuy
        // print("configureSession outputSetting: \(kCVPixelFormatType_32BGRA.fourCharCodeString)")  // BGRA
        // print("configureSession outputSetting: \(kCVPixelFormatType_32ARGB.fourCharCodeString)")  // 0x00000020
        
        captureSession.beginConfiguration()
            
        let inputs = captureSession.inputs
        inputs.forEach{ input in
            captureSession.removeInput(input)
        }
        
        if let cDevice = self.captureDevice {
            
            do {

                let videoInput = try AVCaptureDeviceInput(device: cDevice)
                self.captureVideoInput = videoInput
                
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                    
                    // update videoInformation.
                    if let port = videoInput.ports.first(where: {$0.mediaType == .video}) {
                        if let  dimensions = port.formatDescription?.dimensions {
                            self.manipulatingArea?.inputDimensions = CGSize(width: CGFloat(dimensions.width),
                                                                            height: CGFloat(dimensions.height))
                            // print("xx set InputDimension \(dimensions)")
                        }
                    }
                    
                    if captureSession.canAddOutput(self.captureVideoOutput){
                        captureSession.addOutput(self.captureVideoOutput)
                    }
                    
                }else{
                    print("selectDevice denied to add the device \(cDevice.uniqueID)")
                }
                
            }catch {
                fatalError("can't add video input device to session")
            }
            
            if let cFormat = self.captureFormat, let cFrameDuration = self.captureFrameDuration {
                print("DisplayView configureSession  Resolution: \(cFormat.formatDescription.dimensionString)")
                
                // format設定
                // frameDuration 設定
                do {
                    try cDevice.lockForConfiguration()  // 設定が自動的に変更されないようにする。
                    
                    cDevice.activeFormat = cFormat
                    
                    cDevice.activeVideoMinFrameDuration = cFrameDuration
                    cDevice.activeVideoMaxFrameDuration = cFrameDuration
                    
                    // unlockForConfiguration によって、自動的に解像度が変更されるようになる。ここで呼ばない。
                    
                }catch{
                    //TODO: 他アプリがlockForConfiguration していると落ちる問題
                    fatalError("DisplayView configureSession  can't set format to device.")
                }
                
                // output にも 同じ pixelFormatを指定する。 = AVCaptureOutput内でのBGRA変換などの機能は利用しない
                let videoOutputSettings = [kCVPixelBufferPixelFormatTypeKey as String : cFormat.formatDescription.mediaSubType]
                self.captureVideoOutput.videoSettings = videoOutputSettings
                
                var checkFlag = false
                for f in self.captureVideoOutput.availableVideoPixelFormatTypes {
                    if VideoAudioCapturer.supportedPixelFormat.contains(f) {
                        checkFlag = true
                        break
                    }
                //    print(" outputAvailableFormat: \(f.fourCharCodeString)")
                }
                if checkFlag == false {
                    print("!!WARNING!! can't find supported pixelFormat in availablePixelFormat of captureOutput.")
                }
                
            }
            
        }else{
            print("DisplayView configureSession  any videoInput is not added to session. ")
        }
        
        
        if let aDevice = self.audioDevice {
            
            do {
                let audioInput = try AVCaptureDeviceInput(device: aDevice)

                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                    
                    if let audioOutput = self.captureAudioOutput {
                        if captureSession.canAddOutput(audioOutput) {
                            captureSession.addOutput(audioOutput)
                        }
                    }
                    
                    
                }else{
                    print("DisplayView configureSession  selectDevice denied to add the device \(aDevice.uniqueID)")
                }
            }catch {
                print("DisplayView configureSession can't get or add audio input device to session")
                
            }
            
        }else{
            print("DisplayView configureSession  any audioInput is not added to session. ")
        }
        
        captureSession.commitConfiguration()
                
    }
    
    
}
