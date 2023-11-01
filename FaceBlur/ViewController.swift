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
//                        let sticker = StickerView(
//                            frame: .init(x: 100, y: 100, width: 100, height: 100),
//                            contentImage: UIImage()
//                        )
//                        sticker.delegate = self
//                        view.addSubview(sticker)
                        
                        imageView.image = result
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

extension ViewController: StickerViewDelegate {
    @MainActor
    func didTapApply(sticker: StickerView) {
        guard let selectedImage = imageView.image,
              let targetRect = ImageFilterProcessor.getTargetRect(
                  image: selectedImage,
                  imageView: imageView,
                  targetView: sticker.getContentView()
              ) else {
            return
        }

        let testResult = try? ImageFilterProcessor.performTest(
            originalImage: selectedImage,
            rect: targetRect
        )
        imageView.image = testResult
    }
    
    func didTapRemove(sticker: StickerView) {
        
    }
}
