//
//  CMTime+fps.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import AVFoundation

extension CMTime {
    
    var frameRate : Float64 {
        return floor(Float64(timescale) / Float64(value)*100/100)
    }
    
    var frameRateString : String {
        return String(format:"%.2f", frameRate)
    }
    
}
