//
//  AVCaptureDeviceFormat+utility.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import AVFoundation

extension AVCaptureDevice.Format {
    
    public var supportedFrameRateStrings : [String] {
        
        var strs = [String]()
        for frameDuration in supportedFrameDurations {
            let fpsString = frameDuration.frameRateString
            strs.append(fpsString)
        }
        
        return strs
    }
    
    public var supportedFrameDurations : [CMTime] {
        
        var availableFrameDuration = [CMTime]()
        for range: AVFrameRateRange in videoSupportedFrameRateRanges {
            if range.maxFrameDuration == range.minFrameDuration {
                availableFrameDuration.append(range.minFrameDuration)
            }else{
                var f = range.minFrameRate
                let sTimescale = range.minFrameDuration.timescale
                repeat {
                    availableFrameDuration.append(CMTimeMake(value:Int64(Float64(sTimescale)/Float64(f)), timescale:sTimescale))
                    f += 1.0
                }while(f < range.maxFrameRate)
                
                availableFrameDuration.append(range.maxFrameDuration)
            }
        }
        
        return availableFrameDuration
    }

    
    public func isContainFrameRate(FPSString: String) -> CMTime? {
                
        var nextFrameDuration : CMTime? = nil
        for  frameDuration  in supportedFrameDurations {
            if frameDuration.frameRate == Float64(FPSString) {
                nextFrameDuration = frameDuration
            }
        }
        
        return nextFrameDuration
    }
    
    public var supportedFrameRateRangeDescription : String {
        
        let sortedArray = supportedFrameDurations.sorted(by: { $0.frameRate > $1.frameRate })

        var rangeArray = [String]()
        sortedArray.forEach { f in
            rangeArray.append(f.frameRateString)
        }
        
        return "[" + rangeArray.joined(separator: ",") + "]"
    }
    
    public var aspectRatio : CGFloat {
        return CGFloat(formatDescription.dimensions.width) / CGFloat(formatDescription.dimensions.height)
    }
}
