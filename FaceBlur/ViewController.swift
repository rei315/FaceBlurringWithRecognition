//
//  ViewController.swift
//  FaceBlur
//
//  Created by minguk-kim on 2023/10/24.
//

import UIKit
import Vision
import CoreImage

class ViewController: UIViewController {
    let imagePicker = UIImagePickerController()
    let button = UIButton(type: .system)
    let imageView: UIImageView = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        imagePicker.delegate = self
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("選択する", for: .normal)
        button.addAction(
            .init(
                handler: { [weak self] _ in
                    self?.openPhotoLibrary()
                }
            ),
            for: .touchUpInside
        )
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
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

