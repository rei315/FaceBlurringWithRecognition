//
//  StickerView.swift
//
//  Created by minguk-kim on 2023/11/01.
//

import UIKit

public protocol StickerViewDelegate: NSObjectProtocol {
    func didTapApply(sticker: StickerView)
    func didTapRemove(sticker: StickerView)
}

public class StickerView: UIView, UIGestureRecognizerDelegate {
    public static let defaultStickerControlViewSize: CGFloat = 50
    
    public var stickerMinScale: CGFloat = 0.5
    public var stickerMaxScale: CGFloat = 2.0
    
    public var enabledControl: Bool = true {
        didSet {
            self.leftTopControl.isHidden = !self.enabledControl;
            self.rightBottomControl.isHidden = !self.enabledControl;
            self.rightTopControl.isHidden = !self.enabledControl;
        }
    }
    public var enabledBorder: Bool = true
    {
        didSet {
            if (self.enabledBorder) {
                self.contentView.layer.addSublayer(self.shapeLayer)
            } else {
                self.shapeLayer.removeFromSuperlayer()
            }
        }
    }

    private var contentImage: UIImage? {
        didSet {
            self.setContentImage(contentImage: self.contentImage)
        }
    }
    
    public weak var delegate: StickerViewDelegate?
    
    private var stickerControlViewSize: CGFloat = StickerView.defaultStickerControlViewSize
    private var stickerHalfControlViewSize: CGFloat {
        return stickerControlViewSize / 2
    }
    
    private lazy var contentView: UIImageView = {
        let imageView = UIImageView.init(frame: CGRect.init(x: stickerHalfControlViewSize, y: stickerHalfControlViewSize, width: frame.size.width, height: frame.size.height))
        return imageView
    }()

    private lazy var leftTopControl: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: contentView.center.x - contentView.bounds.size.width / 2 - stickerHalfControlViewSize,
            y: contentView.center.y - contentView.bounds.size.height / 2 - stickerHalfControlViewSize,
            width: stickerControlViewSize,
            height: stickerControlViewSize
        )
        let icon = UIImage(systemName: "x.circle.fill")?
            .withTintColor(.red, renderingMode: .alwaysOriginal)
        button.setImage(
            icon,
            for: .normal
        )
        return button
    }()

    private lazy var rightTopControl: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: contentView.center.x + contentView.bounds.size.width / 2 - stickerHalfControlViewSize,
            y: contentView.center.y - contentView.bounds.size.height / 2 - stickerHalfControlViewSize,
            width: stickerControlViewSize,
            height: stickerControlViewSize
        )
        
        let icon = UIImage(systemName: "checkmark.circle.fill")?
            .withTintColor(.green, renderingMode: .alwaysOriginal)
        button.setImage(
            icon,
            for: .normal
        )
        return button
    }()

    private lazy var rightBottomControl: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: contentView.center.x + contentView.bounds.size.width / 2 - stickerHalfControlViewSize,
            y: contentView.center.y + contentView.bounds.size.height / 2 - stickerHalfControlViewSize,
            width: stickerControlViewSize,
            height: stickerControlViewSize
        )
        let icon = UIImage(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")?
            .withTintColor(.blue, renderingMode: .alwaysOriginal)
        button.setImage(
            icon,
            for: .normal
        )
        return button
    }()

    private lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer.init()
        let shapeRect = self.contentView.frame
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint.init(x: self.contentView.frame.size.width / 2, y: self.contentView.frame.size.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.allowsEdgeAntialiasing = true
        shapeLayer.lineDashPattern = [NSNumber.init(value: 5), (3)]

        let path: CGMutablePath = CGMutablePath()
        path.addRect(shapeRect)
        shapeLayer.path = path
        return shapeLayer
    }()
    
    public init(
        frame: CGRect,
        contentImage: UIImage,
        stickerControlViewSize: CGFloat = StickerView.defaultStickerControlViewSize
    ) {
        self.stickerControlViewSize = stickerControlViewSize
        enabledControl = false
        
        enabledBorder = false
        let stickerHalfControlViewSize = stickerControlViewSize / 2

        super.init(
            frame: CGRect(
                x: frame.origin.x - stickerHalfControlViewSize,
                y: frame.origin.y - stickerHalfControlViewSize,
                width: frame.size.width + stickerControlViewSize,
                height: frame.size.height + stickerControlViewSize
            )
        )

        defer {
            self.contentImage = contentImage
        }
        
        addSubview(contentView)
        addSubview(rightBottomControl)
        addSubview(leftTopControl)
        addSubview(rightTopControl)
        
        setupConfig()
        attachGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StickerView {
    private func setupConfig() {
        isExclusiveTouch = true
        isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
        enabledControl = true
        enabledBorder = true
    }
    
    private func attachGestures() {
        let panGesture = UIPanGestureRecognizer(
            target: self, 
            action: #selector(handleMove)
        )
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = self
        contentView.addGestureRecognizer(panGesture)
        
        leftTopControl.addAction(
            .init(handler: { [weak self] _ in
                self?.handleDelete()
            }),
            for: .touchUpInside
        )
        
        rightTopControl.addAction(
            .init(handler: { [weak self] _ in
                self?.handleApply()
            }),
            for: .touchUpInside
        )
        
        let singleHandGesture = StickerGestureRecognizer(
            target: self,
            action: #selector(handleSingleHandAction(gesture:)),
            anchorView: contentView
        )
        rightBottomControl.addGestureRecognizer(singleHandGesture)
    }
}

extension StickerView {
    private func handleDelete() {
        delegate?.didTapRemove(sticker: self)
    }
    
    private func handleApply() {
        delegate?.didTapApply(sticker: self)
    }
    
    @objc 
    private func handleMove(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        var targetPoint = CGPoint.init(
            x: self.center.x + translation.x,
            y: self.center.y + translation.y
        )
        targetPoint.x = max(0, targetPoint.x)
        targetPoint.y = max(0, targetPoint.y)
        targetPoint.x = min(self.superview!.bounds.size.width, targetPoint.x)
        targetPoint.y = min(self.superview!.bounds.size.height, targetPoint.y)
        
        self.center = targetPoint
        gesture.setTranslation(CGPoint.zero, in: self.superview)
    }
    
    @objc 
    private func handleSingleHandAction(gesture: StickerGestureRecognizer) {
        var scale = gesture.scale
        guard let currentScale: CGFloat = contentView.layer.value(forKeyPath: "transform.scale") as? CGFloat else {
            return
        }
        if !(stickerMinScale == .zero && stickerMaxScale == .zero) {
            if (scale * currentScale <= stickerMinScale) {
                scale = stickerMinScale / currentScale;
            } else if (scale * currentScale >= stickerMaxScale) {
                scale = stickerMaxScale / currentScale;
            }
        }
        
        contentView.transform = contentView.transform.scaledBy(x: scale, y: scale)
        contentView.transform = contentView.transform.rotated(by: gesture.rotation)
        gesture.resetGesture()
        
        relocationControlView()
    }
    
    private func relocationControlView() {
        let originalCenter = contentView.center.applying(contentView.transform.inverted())
        rightBottomControl.center = CGPoint.init(
            x: originalCenter.x + contentView.bounds.size.width / 2.0,
            y: originalCenter.y + contentView.bounds.size.height / 2.0
        ).applying(contentView.transform)
        leftTopControl.center = CGPoint.init(
            x: originalCenter.x - contentView.bounds.size.width / 2.0,
            y: originalCenter.y - contentView.bounds.size.height / 2.0
        ).applying(contentView.transform)
        rightTopControl.center = CGPoint.init(
            x: originalCenter.x + contentView.bounds.size.width / 2.0,
            y: originalCenter.y - contentView.bounds.size.height / 2.0
        ).applying(contentView.transform)
    }
}

extension StickerView {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == rightBottomControl,
           gestureRecognizer.isKind(of: StickerGestureRecognizer.self) {
            return false
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) || otherGestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            return false
        } else {
            return true
        }
    }
}

extension StickerView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 {
            return nil
        }
        if enabledControl {
            if leftTopControl.point(inside: self.convert(point, to: leftTopControl), with: event) {
                return leftTopControl
            }
            if rightTopControl.point(inside: self.convert(point, to: rightTopControl), with: event) {
                return rightTopControl
            }
            if rightBottomControl.point(inside: self.convert(point, to: rightBottomControl), with: event) {
                return rightBottomControl
            }
        }
        if contentView.point(inside: self.convert(point, to: contentView), with: event) {
            return contentView
        }
        return nil
    }
}

extension StickerView {
    func setContentImage(contentImage: UIImage?) {
        contentView.image = contentImage;
    }
    
    func getContentView() -> UIView {
        return contentView
    }
}
