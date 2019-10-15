import AVFoundation
import UIKit

extension AVCapturePhoto {

    public func getImage(videoOrientation: AVCaptureVideoOrientation) -> (image: UIImage, depthData: AVDepthData?) {
        // Adapted from https://stackoverflow.com/questions/46852521/how-to-generate-an-uiimage-from-avcapturephoto-with-correct-orientation/46896096#46896096
        // It would be nice to use the orientation from `CGImagePropertyOrientation(rawValue: (photo.metadata[String(kCGImagePropertyOrientation)] as! NSNumber).uint32Value)!`
        // but it turns out the value is always 6 (CGImagePropertyOrientation.right)
        let orientation = convertOrientation(videoOrientation)
        let cgImage = self.cgImageRepresentation()!.takeUnretainedValue()
        let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
        return (image, self.depthData)
    }

}

private func convertOrientation(_ videoOrientation: AVCaptureVideoOrientation) -> UIImage.Orientation
{
    switch videoOrientation {
    case .portrait: return .right
    case .portraitUpsideDown: return .left
    case .landscapeRight: return .up
    case .landscapeLeft: return .down
    @unknown default:
        fatalError("Unknown AVCaptureVideoOrientation: \(String(describing: videoOrientation))")
    }
}
