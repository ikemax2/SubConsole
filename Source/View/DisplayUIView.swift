//
//  DisplayUIView.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI
import AVFoundation


struct DisplayUIView: NSViewRepresentable, Equatable {

    // Equatable に適合することで、ビューの再生成を最小限にできる。
    static func == (lhs: DisplayUIView, rhs: DisplayUIView) -> Bool {
        lhs.captureDevice?.uniqueID == rhs.captureDevice?.uniqueID &&
        lhs.audioDevice?.uniqueID == rhs.audioDevice?.uniqueID
    }
    
    typealias NSViewType = DisplayView

    var drawHandler: VideoRenderer.DrawHandler?
    weak var manipulator: Manipulator?
    
    @Binding var captureDevice: AVCaptureDevice?
    @Binding var captureFormat: AVCaptureDevice.Format?
    @Binding var captureFrameDuration: CMTime?
    @Binding var audioDevice : AVCaptureDevice?
    @Binding var displayStatus : DisplayStatus?
    
    var cursorType : CursorType?
    
    init(captureDevice: Binding<AVCaptureDevice?>,
         captureFormat: Binding<AVCaptureDevice.Format?>,
         captureFrameDuration: Binding<CMTime?>,
         audioDevice: Binding<AVCaptureDevice?>,
         displayStatus: Binding<DisplayStatus?>,
         manipulator: Manipulator? = nil,
         drawHandler: VideoRenderer.DrawHandler? = nil,
         cursorType: CursorType? = nil) {


        self._captureDevice = captureDevice
        self._captureFormat = captureFormat
        self._captureFrameDuration = captureFrameDuration
        self._audioDevice = audioDevice
        
        self._displayStatus = displayStatus
        
        self.manipulator = manipulator
        self.drawHandler = drawHandler
        
        self.cursorType = cursorType
                
        NotificationCenter.default.addObserver(forName: Notification.Name.AVSampleBufferDisplayLayerFailedToDecode,
                                               object: nil, queue: nil) { notification in
                        
            guard let errorString = notification.object as? String else {
                return
            }
            print("AVSampleBufferDisplayLayer decode Error occured. string: \(errorString)")
        }
        
    }
    
    func makeNSView(context: Context) -> DisplayView {
        // SwiftUIのViewとは異なり、 NSViewは、頻繁に破棄・生成されない。 makeNSViewは1回だけ呼び出され、この中だけでNSView を生成する。
        
        let handler : VideoRenderer.StatusUpdateHandler = { [self] description, fps in
            
            let ds = DisplayStatus()
            ds.framerate = fps
            
            if let desc : CMFormatDescription = description {
                ds.mediaSubtype = desc.mediaSubTypeString
                ds.resolution = desc.dimensionString
            }
            
            self.displayStatus = ds
            
        }
        
        let nsView = DisplayView(statusUpdateHandler: handler,
                                 manipulator: self.manipulator,
                                 drawHandler: self.drawHandler,
                                 cursorType: self.cursorType)

        return nsView
    }
    
    func updateNSView(_ nsView: DisplayView, context: Context) {
        print("DisplayView updateNSView called")
        
        if let cDevice = captureDevice, let cFormat = captureFormat, let cFrameDuration = captureFrameDuration{
            nsView.refleshCapturer(captureDevice: cDevice,
                                   captureFormat: cFormat,
                                   captureFrameDuration: cFrameDuration,
                                   audioDevice: audioDevice)
        }else{
            nsView.inactive()
        }
    }
}
