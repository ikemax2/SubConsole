//
//  ManipulatingArea.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import Foundation
import AVFoundation

// 画面表示エリアとマウス座標出力を一致させるためのクラス.
//   DisplayViewにも渡し、displayDimensions, inputDimensionsを更新する。
class ManipulatingArea : NSObject {
    
    var inputDimensions: CGSize = CGSizeZero {
        didSet {
            print("set inputDimension \(self)")
        }
    }
    
    var displayDimensions: CGSize = CGSizeZero {
        didSet {
            print("set displayDimension \(self)")
            if displayDimensions.width == 0 || displayDimensions.height == 0 {
                print("displayDimensions width or height is zero.")
            }
        }
    }
    
    // previewLayer.videoGravity = .resizeAspect の場合。
    var videoFrame: CGRect {
        guard displayDimensions.width != 0 && displayDimensions.height != 0 else{
            return CGRectZero
        }
        
        let displayAspectRatio: Double = displayDimensions.height / displayDimensions.width
        let inputAspectRatio: Double  = inputDimensions.height / inputDimensions.width
        
        if inputAspectRatio < displayAspectRatio {
            return CGRect(x:0.0,
                          y:(displayDimensions.height - displayDimensions.width * inputAspectRatio)/2.0,
                          width:displayDimensions.width,
                          height:displayDimensions.width * inputAspectRatio)
        }else{
            return CGRect(x:(displayDimensions.width - displayDimensions.height / inputAspectRatio)/2.0,
                          y: 0.0,
                          width: displayDimensions.height / inputAspectRatio,
                          height: displayDimensions.height)
        }
    }
    
    var displayZoomScale: CGFloat {
        if inputDimensions.width != 0 {
            return videoFrame.width / inputDimensions.width
        }
        return 1.0
    }
    
    func videoLocation(fromViewLocation: CGPoint) -> CGPoint? {
        // print("videoFrame \(videoFrame)")
        let x = (fromViewLocation.x - videoFrame.origin.x) / videoFrame.width * inputDimensions.width;
        let y = (fromViewLocation.y - videoFrame.origin.y) / videoFrame.height * inputDimensions.height;
        if x >= 0 && x <= inputDimensions.width && y >= 0 && y <= inputDimensions.height {
            return CGPoint(x:x,  y:y)
        }
        
        return nil
    }

}
