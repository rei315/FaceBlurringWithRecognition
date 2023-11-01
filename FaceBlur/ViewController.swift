//
//  ViewController.swift
//  FaceBlur
//
//  Created by minguk-kim on 2023/10/24.
//

import UIKit
import Vision
import CoreImage

final class ViewController: UIViewController {
    private let imagePicker = UIImagePickerController()
    private let imageView: UIImageView = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        imagePicker.delegate = self
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary))
        imageView.addGestureRecognizer(tapGesture)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc
    private func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            Task {
                do {
                    let observations = try await FaceRecognition.recognize(in: selectedImage)
                    let result = try ImageFilterProcessor.performFaceBlurring(
                        originalImage: selectedImage,
                        observations: observations
                    )
                    await MainActor.run {
                        let test = UIView(frame: .init(x: 170, y: 400, width: 50, height: 50))
                        test.layer.borderColor = UIColor.red.cgColor
                        test.layer.borderWidth = 1
                        view.addSubview(test)

                        guard let targetRect = ImageFilterProcessor.getTargetRect(
                            image: selectedImage,
                            imageView: imageView,
                            targetView: test
                        ) else {
                            return
                        }

                        let testResult = try? ImageFilterProcessor.performTest(
                            originalImage: selectedImage,
                            rect: targetRect
                        )
                        imageView.image = testResult
                    }
                } catch {
                    await MainActor.run {
                        imageView.image = selectedImage
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


extension UIImage {
    func aspectFillSize(imageView: UIImageView) -> CGSize {
        let viewBounds = imageView.bounds
        let imageOriginalSize = self.size
        let widthRatio = viewBounds.width / imageOriginalSize.width
        let heightRatio = viewBounds.height / imageOriginalSize.height
        let ratio = max(heightRatio, widthRatio)
        let resizedWidth = imageOriginalSize.width * ratio
        let resizedHeight = imageOriginalSize.height * ratio
        let result = CGSize(width: resizedWidth, height: resizedHeight)
        return result
    }
}
