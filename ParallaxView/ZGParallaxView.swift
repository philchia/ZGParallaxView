//
//  ZGParallaxView.swift
//  ParallaxView
//
//  Created by Phil Chia on 15/11/4.
//  Copyright © 2015年 TouchDream. All rights reserved.
//

import UIKit
import Accelerate

public class ZGParallaxView: UIView {
	var scrollView: UIScrollView!
	var contentView: UIView!
	var blurredImageView: UIImageView!
	var blurImage: UIImage?
	var maxHeight: CGFloat?
	var minHeight: CGFloat?
	var stickToHeader: Bool = false
	
	var parallaxDeltaFactor: CGFloat = 0.5
	
	var maxBlurRadius: CGFloat = 20
		
	public class func parallaxView(subView: UIView, size: CGSize) -> ZGParallaxView {
		let parallaxView = ZGParallaxView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		parallaxView.setup(subView)
		return parallaxView
	}
	
	private func setup(view: UIView) {
		self.scrollView = UIScrollView(frame: self.bounds)
		self.scrollView.backgroundColor = UIColor.whiteColor()
		
		self.contentView = view
		self.scrollView.addSubview(self.contentView)
		self.contentView.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin, .FlexibleWidth, .FlexibleHeight]
		
		self.blurredImageView = UIImageView(frame: self.contentView.frame)
		self.blurredImageView.autoresizingMask = self.contentView.autoresizingMask
		self.blurredImageView.contentMode = .ScaleAspectFill
		self.blurredImageView.alpha = 0.0
		self.scrollView.addSubview(self.blurredImageView)
		self.addSubview(self.scrollView)
		self.refreshBlurImageView()
	}
	
	private func refreshBlurImageView() {
		self.blurImage = self.screenshot()
		let bluredImage = self.blurImage!.applyBlurWithRadius(self.maxBlurRadius, tintColor: UIColor(white: 0.6, alpha: 0.1), saturationDeltaFactor: 1.0, maskImage: nil)
		self.blurredImageView.image = bluredImage
	}
	
	public 	func scrollViewDidScroll(scrollView: UIScrollView) {
		let delta = scrollView.contentOffset.y
		var frame = self.frame

		if delta > 0 {
			frame.origin.y += delta
			self.scrollView.frame = frame
			self.blurredImageView.alpha = 1 / self.frame.size.height * delta * 2
			self.clipsToBounds = self.minHeight == nil
		} else if self.maxHeight != nil && (self.frame.size.height - delta) > self.maxHeight! {
			scrollView.contentOffset.y = -(self.maxHeight! - self.frame.size.height)
		} else {
			frame.origin.y += delta
			frame.size.height -= delta
			if self.minHeight != nil && frame.size.height < self.minHeight! {
				frame.size.height = self.minHeight!
			}
			self.scrollView.frame = frame
			self.clipsToBounds = false
		}
	}
}

extension UIImage {
	public func applyBlurWithRadius(blurRadius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat, maskImage: UIImage? = nil) -> UIImage? {
		// Check pre-conditions.
		if (size.width < 1 || size.height < 1) {
			print("*** error: invalid size: \(size.width) x \(size.height). Both dimensions must be >= 1: \(self)")
			return nil
		}
		if self.CGImage == nil {
			print("*** error: image must be backed by a CGImage: \(self)")
			return nil
		}
		if maskImage != nil && maskImage!.CGImage == nil {
			print("*** error: maskImage must be backed by a CGImage: \(maskImage)")
			return nil
		}
		
		let __FLT_EPSILON__ = CGFloat(FLT_EPSILON)
		let screenScale = UIScreen.mainScreen().scale
		let imageRect = CGRect(origin: CGPointZero, size: size)
		var effectImage = self
		
		let hasBlur = blurRadius > __FLT_EPSILON__
		let hasSaturationChange = fabs(saturationDeltaFactor - 1.0) > __FLT_EPSILON__
		
		if hasBlur || hasSaturationChange {
			func createEffectBuffer(context: CGContext) -> vImage_Buffer {
				let data = CGBitmapContextGetData(context)
				let width = vImagePixelCount(CGBitmapContextGetWidth(context))
				let height = vImagePixelCount(CGBitmapContextGetHeight(context))
				let rowBytes = CGBitmapContextGetBytesPerRow(context)
				
				return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
			}
			
			UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
			let effectInContext = UIGraphicsGetCurrentContext()
			
			CGContextScaleCTM(effectInContext, 1.0, -1.0)
			CGContextTranslateCTM(effectInContext, 0, -size.height)
			CGContextDrawImage(effectInContext, imageRect, self.CGImage)
			
			var effectInBuffer = createEffectBuffer(effectInContext!)
			
			
			UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
			let effectOutContext = UIGraphicsGetCurrentContext()
			
			var effectOutBuffer = createEffectBuffer(effectOutContext!)
			
			
			if hasBlur {
				// A description of how to compute the box kernel width from the Gaussian
				// radius (aka standard deviation) appears in the SVG spec:
				// http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
				//
				// For larger values of 's' (s >= 2.0), an approximation can be used: Three
				// successive box-blurs build a piece-wise quadratic convolution kernel, which
				// approximates the Gaussian kernel to within roughly 3%.
				//
				// let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
				//
				// ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
				//
				
				let inputRadius = blurRadius * screenScale
				var radius = UInt32(floor(inputRadius * 3.0 * CGFloat(sqrt(2 * M_PI)) / 4 + 0.5))
				if radius % 2 != 1 {
					radius += 1 // force radius to be odd so that the three box-blur methodology works.
				}
				
				let imageEdgeExtendFlags = vImage_Flags(kvImageEdgeExtend)
				
				vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
				vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
				vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
			}
			
			var effectImageBuffersAreSwapped = false
			
			if hasSaturationChange {
				let s: CGFloat = saturationDeltaFactor
				let floatingPointSaturationMatrix: [CGFloat] = [
					0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
					0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
					0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
					0,                    0,                    0,  1
				]
				
				let divisor: CGFloat = 256
				let matrixSize = floatingPointSaturationMatrix.count
				var saturationMatrix = [Int16](count: matrixSize, repeatedValue: 0)
				
				for var i: Int = 0; i < matrixSize; ++i {
					saturationMatrix[i] = Int16(round(floatingPointSaturationMatrix[i] * divisor))
				}
				
				if hasBlur {
					vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
					effectImageBuffersAreSwapped = true
				} else {
					vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
				}
			}
			
			if !effectImageBuffersAreSwapped {
				effectImage = UIGraphicsGetImageFromCurrentImageContext()
			}
			
			UIGraphicsEndImageContext()
			
			if effectImageBuffersAreSwapped {
				effectImage = UIGraphicsGetImageFromCurrentImageContext()
			}
			
			UIGraphicsEndImageContext()
		}
		
		// Set up output context.
		UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
		let outputContext = UIGraphicsGetCurrentContext()
		CGContextScaleCTM(outputContext, 1.0, -1.0)
		CGContextTranslateCTM(outputContext, 0, -size.height)
		
		// Draw base image.
		CGContextDrawImage(outputContext, imageRect, self.CGImage)
		
		// Draw effect image.
		if hasBlur {
			CGContextSaveGState(outputContext)
			if let image = maskImage {
				CGContextClipToMask(outputContext, imageRect, image.CGImage);
			}
			CGContextDrawImage(outputContext, imageRect, effectImage.CGImage)
			CGContextRestoreGState(outputContext)
		}
		
		// Add in color tint.
		if let color = tintColor {
			CGContextSaveGState(outputContext)
			CGContextSetFillColorWithColor(outputContext, color.CGColor)
			CGContextFillRect(outputContext, imageRect)
			CGContextRestoreGState(outputContext)
		}
		
		// Output image is ready.
		let outputImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return outputImage
	}
}

extension UIView {
	func screenshot() -> UIImage {
		print(self.frame.size)
		UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
		self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
		let image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return image
	}
}
