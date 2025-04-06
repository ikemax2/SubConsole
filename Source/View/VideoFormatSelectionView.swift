//
//  VideoFormatSelectionView.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI
import AVFoundation
    
struct VideoFormatSelectionView: View {
        var videoDevice: AVCaptureDevice?
        
        var selectedMediaSubtypes: Binding<String?>
        var selectedDimensions: Binding<String?>
        var selectedFpss: Binding<String?>
        
        var labels : (mediaSubtypes: Dictionary<String, Bool>, dimensions: Dictionary<String, Bool>, fpss: Dictionary<String, Bool>) {

            var candidates = [(subtype: String, dimension: String, fps: String, selectionDisable: Bool)]()
            
            if let availableFormats : [AVCaptureDevice.Format] = videoDevice?.formats {
                for format : AVCaptureDevice.Format in availableFormats {
                    
                    let subtypeString = format.formatDescription.mediaSubTypeString
                    
                    let dimString = format.formatDescription.dimensionString
                    
                    for fpsString in format.supportedFrameRateStrings {
                        candidates.append( (subtypeString, dimString, fpsString, false) )
                    }
                }
            }
            
            for index in 0..<candidates.count {
                
                if selectedMediaSubtypes.wrappedValue != nil && selectedMediaSubtypes.wrappedValue != candidates[index].subtype {
                    candidates[index].selectionDisable = true
                }
                
                
                if selectedDimensions.wrappedValue != nil && selectedDimensions.wrappedValue != candidates[index].dimension {
                    candidates[index].selectionDisable = true
                }
                
                if selectedFpss.wrappedValue != nil && selectedFpss.wrappedValue != candidates[index].fps {
                    candidates[index].selectionDisable = true
                }
            }
            
            
            var mediaSubTypesLabels = Dictionary<String, Bool>()
            var dimensionsLabels = Dictionary<String, Bool>()
            var fpssLabels = Dictionary<String, Bool>()
            
            candidates.forEach { combination in
                // print("combination: \(combination.subtype), \(combination.dimension), \(combination.fps) -> \(combination.selectionDisable)")
                // combination.selectionDisableがひとつでもfalseであれば、**Labels[*]には、falseを設定
                // combination.selectionDisableが全部trueであるときだけ、**Labels[*]には、trueを設定
                
                if combination.selectionDisable == true {
                    
                    if mediaSubTypesLabels.keys.contains( combination.subtype ) == false {
                        mediaSubTypesLabels[combination.subtype] = true
                    }
                    
                    if dimensionsLabels.keys.contains( combination.dimension ) == false {
                        dimensionsLabels[combination.dimension] = true
                    }
                    
                    if fpssLabels.keys.contains( combination.fps ) == false {
                        fpssLabels[combination.fps] = true
                    }
                    
                }else{
                    mediaSubTypesLabels[combination.subtype] = false
                    dimensionsLabels[combination.dimension] = false
                    fpssLabels[combination.fps] = false
                }
            }
            
            // サポートされていない mediaSubtype は常に true, 選択できないようにする
            let supportedSubTypes = VideoAudioCapturer.supportedPixelFormat.map{ element in element.fourCharCodeString }
            
            for label in mediaSubTypesLabels{
                if supportedSubTypes.contains(label.key) == false {
                    // print("label: \(label.key) \(label.value)")
                    mediaSubTypesLabels[label.key] = true
                }
            }
            
            return (mediaSubTypesLabels, dimensionsLabels, fpssLabels)
        }
        
        var body: some View {
            
            HStack {
                VStack {
                    Text("PixelFormat")
                        .frame(maxWidth: .infinity, alignment:.center)
                    ScrollView{
                        Picker("", selection: selectedMediaSubtypes){
                            ForEach(labels.mediaSubtypes.keys.sorted(), id:\.self) { label in
                                // selectedVideoDeviceID が String? 型のため、tag内もオプショナル型に揃える。
                                
                                Text(label).tag(Optional(label)).selectionDisabled( labels.mediaSubtypes[label]! )
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                    Label("deselct", systemImage: "xmark")
                        .onTapGesture {
                            selectedMediaSubtypes.wrappedValue = nil
                        }
                }
                .padding(3)
                
                VStack {
                    Text("Dimension")
                        .frame(maxWidth: .infinity, alignment:.center)
                    ScrollView {
                        Picker("", selection: selectedDimensions) {
                            ForEach(labels.dimensions.keys.sorted(), id:\.self) { label in
                                // selectedVideoDeviceID が String? 型のため、tag内もオプショナル型に揃える。
                                Text(label).tag(Optional(label)).selectionDisabled( labels.dimensions[label]! )
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                    Label("deselct", systemImage: "xmark")
                        .onTapGesture {
                            selectedDimensions.wrappedValue = nil
                        }
                }
                .padding(3)
                
                VStack {
                    Text("FrameRate")
                        .frame(maxWidth: .infinity, alignment:.center)
                    ScrollView {
                        Picker("", selection: selectedFpss) {
                            ForEach(labels.fpss.keys.sorted(), id:\.self) { label in
                                // selectedVideoDeviceID が String? 型のため、tag内もオプショナル型に揃える。
                                Text(label).tag(Optional(label)).selectionDisabled( labels.fpss[label]! )
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                    Label("deselct", systemImage: "xmark")
                        .onTapGesture {
                            selectedFpss.wrappedValue = nil
                        }
                }
                .padding(3)
            }
        }
    
}

