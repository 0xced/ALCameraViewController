import AVFoundation

extension CVPixelBuffer {
  
	@discardableResult
    // Adapted from https://iyarweb.wordpress.com/2017/11/08/image-depth-maps-tutorial-for-ios-getting-started-2/
	public func normalize() -> (minValue: Float, maxValue: Float) {
		let width = CVPixelBufferGetWidth(self)
		let height = CVPixelBufferGetHeight(self)
		
		let flags = CVPixelBufferLockFlags(rawValue: 0)
		CVPixelBufferLockBaseAddress(self, flags)
		defer {
			CVPixelBufferUnlockBaseAddress(self, flags)
		}
		
		let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
		
		var minValue: Float = Float.greatestFiniteMagnitude
		var maxValue: Float = Float.leastNormalMagnitude
		
		for y in 0 ..< height {
			for x in 0 ..< width {
				let value = floatBuffer[y * width + x]
				minValue = min(value, minValue)
				maxValue = max(value, maxValue)
			}
		}
		
		let range = maxValue - minValue
		
		for y in 0 ..< height {
			for x in 0 ..< width {
				let pixel = floatBuffer[y * width + x]
				floatBuffer[y * width + x] = (pixel - minValue) / range
			}
		}
		
		return (minValue, maxValue)
	}
}
