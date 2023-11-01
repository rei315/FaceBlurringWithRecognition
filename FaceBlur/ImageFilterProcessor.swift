//
//  ImageFilterProcessor.swift
//  FaceBlur
//
//  Created by minguk-kim on 2023/10/24.
//

import UIKit
import Vision

enum ImageFilterProcessorErrorType: Error {
    case invalidImage
    case invalidMasking
    case invalidCompositeResult
    case invalidCGImageResult
}

public final class ImageFilterProcessor {
    enum CIFilterType {
        case radialGradient
        case sourceOverCompositing
        case pixellate
        case blendWithMask
        
        var value: String {
            switch self {
            case .radialGradient:
                "CIRadialGradient"
            case .sourceOverCompositing:
                "CISourceOverCompositing"
            case .pixellate:
                "CIPixellate"
            case .blendWithMask:
                "CIBlendWithMask"
            }
        }
    }
    
    public static func performTest(
        originalImage: UIImage,
        rect: CGRect
    ) throws -> UIImage {
        guard let ciImage = CIImage(image: originalImage) else {
            throw ImageFilterProcessorErrorType.invalidImage
        }
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = min(rect.size.width, rect.size.height) / 1.8
        let radialGradient = CIFilter(name: CIFilterType.radialGradient.value)
        radialGradient?.setValue(
            radius,
            forKey: "inputRadius0"
        )
        radialGradient?.setValue(
            radius + 1,
            forKey: "inputRadius1"
        )
        radialGradient?.setValue(
            CIColor(red: 0, green: 1, blue: 0, alpha: 1),
            forKey: "inputColor0"
        )
        radialGradient?.setValue(
            CIColor(red: 0, green: 0, blue: 0, alpha: 0),
            forKey: "inputColor1"
        )
        radialGradient?.setValue(
            CIVector(x: centerX, y: centerY),
            forKey: kCIInputCenterKey
        )
        let maskImage = radialGradient?.outputImage?.cropped(to: ciImage.extent)
        let pixelateFilter = CIFilter(name: CIFilterType.pixellate.value)
        pixelateFilter?.setValue(
            ciImage,
            forKey: kCIInputImageKey
        )
        pixelateFilter?.setValue(
            max(ciImage.extent.width, ciImage.extent.height) / 60.0,
            forKey: kCIInputScaleKey
        )
        let composite = CIFilter(name: CIFilterType.blendWithMask.value)
        composite?.setValue(pixelateFilter?.outputImage, forKey: kCIInputImageKey)
        composite?.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        composite?.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = composite?.outputImage else {
            throw ImageFilterProcessorErrorType.invalidCompositeResult
        }
        guard let resultCGImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageFilterProcessorErrorType.invalidCGImageResult
        }
        let resultImage = UIImage(cgImage: resultCGImage, scale: 1, orientation: originalImage.imageOrientation)
        return resultImage
    }
    
    
    public static func performFaceBlurring(
        originalImage: UIImage,
        observations: [VNFaceObservation]
    ) throws -> UIImage {
        guard let ciImage = CIImage(image: originalImage),
              let cgImage = originalImage.cgImage else {
            throw ImageFilterProcessorErrorType.invalidImage
        }
        var maskImage: CIImage?
        for observation in observations {
            let boundingBox = observation.boundingBox
            let normalizedRect = VNImageRectForNormalizedRect(
                boundingBox,
                Int(cgImage.width),
                Int(cgImage.height)
            )
            let centerX = normalizedRect.midX
            let centerY = normalizedRect.midY
            let radius = min(normalizedRect.size.width, normalizedRect.size.height) / 1.5
            let radialGradient = CIFilter(name: CIFilterType.radialGradient.value)
            radialGradient?.setValue(
                radius, 
                forKey: "inputRadius0"
            )
            radialGradient?.setValue(
                radius + 1, 
                forKey: "inputRadius1"
            )
            radialGradient?.setValue(
                CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                forKey: "inputColor0"
            )
            radialGradient?.setValue(
                CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                forKey: "inputColor1"
            )
            radialGradient?.setValue(
                CIVector(x: centerX, y: centerY),
                forKey: kCIInputCenterKey
            )
            let circleImage = radialGradient?.outputImage?.cropped(to: ciImage.extent)
            if (maskImage == nil) {
                maskImage = circleImage
            } else {
                let filter = CIFilter(name: CIFilterType.sourceOverCompositing.value)
                filter?.setValue(circleImage, forKey: kCIInputImageKey)
                filter?.setValue(maskImage, forKey: kCIInputBackgroundImageKey)
                maskImage = filter?.outputImage
            }
        }
        guard let maskImage else {
            throw ImageFilterProcessorErrorType.invalidMasking
        }
        let pixelateFilter = CIFilter(name: CIFilterType.pixellate.value)
        pixelateFilter?.setValue(
            ciImage,
            forKey: kCIInputImageKey
        )
        pixelateFilter?.setValue(
            max(ciImage.extent.width, ciImage.extent.height) / 60.0,
            forKey: kCIInputScaleKey
        )
        let composite = CIFilter(name: CIFilterType.blendWithMask.value)
        composite?.setValue(pixelateFilter?.outputImage, forKey: kCIInputImageKey)
        composite?.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        composite?.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = composite?.outputImage else {
            throw ImageFilterProcessorErrorType.invalidCompositeResult
        }
        guard let resultCGImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageFilterProcessorErrorType.invalidCGImageResult
        }
        let resultImage = UIImage(cgImage: resultCGImage, scale: 1, orientation: .up)
        return resultImage
    }
    
    public static func getTargetRect(
        image: UIImage,
        imageView: UIImageView,
        targetView: UIView
    ) -> CGRect? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        let convertedOrigin = imageView.convert(
            targetView.frame.origin,
            from: targetView.superview
        )
        let convertedEnd = imageView.convert(
            CGPoint(
                x: targetView.frame.maxX,
                y: targetView.frame.maxY
            ),
            from: targetView.superview
        )
        let imageWidthRatio = image.size.width / imageView.bounds.width
        let imageHeightRatio = image.size.height / imageView.bounds.height
        let xImageCoordinate = (convertedOrigin.x - imageView.frame.origin.x) * imageWidthRatio
        let yImageCoordinate = (convertedOrigin.y - imageView.frame.origin.y) * imageHeightRatio
        let width = (convertedEnd.x - convertedOrigin.x) * imageWidthRatio
        let height = (convertedEnd.y - convertedOrigin.y) * imageHeightRatio
        let targetRect: CGRect = CGRect(
            x: xImageCoordinate,
            y: yImageCoordinate,
            width: width,
            height: height
        )
        let ciTargetRect = CGRect(
            x: targetRect.origin.x,
            y: ciImage.extent.height - targetRect.origin.y - targetRect.size.height,
            width: targetRect.size.width,
            height: targetRect.size.height
        )
        return ciTargetRect
    }
}
