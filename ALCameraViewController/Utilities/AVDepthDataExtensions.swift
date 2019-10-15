import AVFoundation
import UIKit

extension AVDepthData {

    public func getImage(imageOrientation: UIImage.Orientation) -> (image: UIImage, minValue: Float, maxValue: Float) {
        let depthDataMap = self.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32).depthDataMap
        let result = depthDataMap.normalize()
        let ciImage = CIImage(cvPixelBuffer: depthDataMap)
        let image = UIImage(ciImage: ciImage, scale: 1, orientation: imageOrientation)
        return (image, result.minValue, result.maxValue)
    }

}
