//
//  FaceRecognition.swift
//  FaceBlur
//
//  Created by minguk-kim on 2023/10/24.
//

import Vision
import UIKit

enum FaceRecognitionErrorType: Error {
    case invalidImage
    case invalidObservation
}

public final class FaceRecognition {
    public static func recognize(in image: UIImage) async throws -> [VNFaceObservation] {
        guard let cgImage = image.cgImage else {
            throw FaceRecognitionErrorType.invalidImage
        }
        let request = VNDetectFaceRectanglesRequest()
        request.preferBackgroundProcessing = true
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: .up
        )
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try handler.perform([request])
                    continuation.resume(returning: request.results ?? [])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            request.cancel()
        }
    }
}
