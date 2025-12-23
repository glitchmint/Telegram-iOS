import Foundation
import Display
import UIKit
import AsyncDisplayKit

private let liquidGlassPressedScale: CGFloat = 0.92
private let liquidGlassBounceScale: CGFloat = 1.06
private let liquidGlassHighlightDuration: Double = 0.1
private let liquidGlassBounceDuration: Double = 0.4
private let liquidGlassSpringDamping: CGFloat = 0.6
private let liquidGlassSpringVelocity: CGFloat = 0.8

private final class LiquidGlassThumbView: UIView {
    private let blurView: UIVisualEffectView
    private let highlightLayer = CALayer()
    
    override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .light)
        self.blurView = UIVisualEffectView(effect: blurEffect)
        self.blurView.isUserInteractionEnabled = false
        
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.backgroundColor = .clear
        
        self.addSubview(blurView)
        
        for subview in blurView.subviews {
            if subview.description.contains("VisualEffectSubview") {
                subview.isHidden = true
            }
        }
        
        if let sublayer = blurView.layer.sublayers?.first, let filters = sublayer.filters {
            sublayer.backgroundColor = nil
            sublayer.isOpaque = false
            let allowedKeys: [String] = ["gaussianBlur", "colorSaturate"]
            sublayer.filters = filters.filter { filter in
                guard let filter = filter as? NSObject else { return true }
                let filterName = String(describing: filter)
                if !allowedKeys.contains(filterName) {
                    return false
                }
                if filterName == "gaussianBlur" {
                    filter.setValue(6.0 as NSNumber, forKey: "inputRadius")
                }
                return true
            }
        }
        
        highlightLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        highlightLayer.opacity = 0
        layer.addSublayer(highlightLayer)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cornerRadius = bounds.height / 2.0
        
        blurView.frame = bounds
        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true
        
        highlightLayer.frame = bounds
        highlightLayer.cornerRadius = cornerRadius
        
        layer.cornerRadius = cornerRadius
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
    
    func animateHighlight(_ highlighted: Bool) {
        if highlighted {
            CATransaction.begin()
            CATransaction.setAnimationDuration(liquidGlassHighlightDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
            highlightLayer.opacity = 1.0
            CATransaction.commit()
            
            UIView.animate(withDuration: liquidGlassHighlightDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                self.transform = CGAffineTransform(scaleX: liquidGlassPressedScale, y: liquidGlassPressedScale)
            }, completion: nil)
        } else {
            CATransaction.begin()
            CATransaction.setAnimationDuration(liquidGlassHighlightDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
            highlightLayer.opacity = 0.0
            CATransaction.commit()
            
            UIView.animate(withDuration: liquidGlassBounceDuration, delay: 0, usingSpringWithDamping: liquidGlassSpringDamping, initialSpringVelocity: liquidGlassSpringVelocity, options: [.allowUserInteraction], animations: {
                self.transform = .identity
            }, completion: nil)
        }
    }
}

public final class LiquidGlassSwitchNode: ASDisplayNode {
    public var valueUpdated: ((Bool) -> Void)?
    
    public var trackOffColor: UIColor = UIColor(rgb: 0xe0e0e0) {
        didSet {
            updateColors()
        }
    }
    
    public var trackOnColor: UIColor = UIColor(rgb: 0x42d451) {
        didSet {
            updateColors()
        }
    }
    
    private var _isOn: Bool = false
    public var isOn: Bool {
        get {
            return self._isOn
        }
        set(value) {
            if value != self._isOn {
                self._isOn = value
                updateThumbPosition(animated: false)
                updateColors()
            }
        }
    }
    
    private let trackView = UIView()
    private let thumbView = LiquidGlassThumbView(frame: .zero)
    private var isTracking = false
    
    private let switchWidth: CGFloat = 51.0
    private let switchHeight: CGFloat = 31.0
    private let thumbSize: CGFloat = 27.0
    private let thumbPadding: CGFloat = 2.0
    
    public override init() {
        super.init()
        
        self.setViewBlock { [weak self] in
            let view = UIView()
            self?.setupView(view)
            return view
        }
    }
    
    private func setupView(_ containerView: UIView) {
        trackView.layer.cornerRadius = switchHeight / 2.0
        trackView.backgroundColor = trackOffColor
        containerView.addSubview(trackView)
        
        thumbView.backgroundColor = .white
        containerView.addSubview(thumbView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        containerView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
        
        updateColors()
    }
    
    public override func didLoad() {
        super.didLoad()
        
        trackView.frame = CGRect(x: 0, y: 0, width: switchWidth, height: switchHeight)
        thumbView.frame = CGRect(x: thumbPadding, y: thumbPadding, width: thumbSize, height: thumbSize)
        
        updateThumbPosition(animated: false)
    }
    
    public func setOn(_ value: Bool, animated: Bool) {
        if value != self._isOn {
            self._isOn = value
            updateThumbPosition(animated: animated)
            updateColors()
        }
    }
    
    private func updateThumbPosition(animated: Bool) {
        let thumbX: CGFloat
        if _isOn {
            thumbX = switchWidth - thumbSize - thumbPadding
        } else {
            thumbX = thumbPadding
        }
        
        let newFrame = CGRect(x: thumbX, y: thumbPadding, width: thumbSize, height: thumbSize)
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction], animations: {
                self.thumbView.frame = newFrame
            }, completion: nil)
        } else {
            thumbView.frame = newFrame
        }
    }
    
    private func updateColors() {
        UIView.animate(withDuration: 0.2) {
            self.trackView.backgroundColor = self._isOn ? self.trackOnColor : self.trackOffColor
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        _isOn = !_isOn
        updateThumbPosition(animated: true)
        updateColors()
        
        thumbView.animateHighlight(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.thumbView.animateHighlight(false)
        }
        
        valueUpdated?(_isOn)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            isTracking = true
            thumbView.animateHighlight(true)
            
        case .changed:
            let translation = gesture.translation(in: self.view)
            let currentX = thumbView.frame.origin.x
            var newX = currentX + translation.x
            
            newX = max(thumbPadding, min(switchWidth - thumbSize - thumbPadding, newX))
            
            thumbView.frame.origin.x = newX
            gesture.setTranslation(.zero, in: self.view)
            
            let progress = (newX - thumbPadding) / (switchWidth - thumbSize - 2 * thumbPadding)
            trackView.backgroundColor = interpolateColor(from: trackOffColor, to: trackOnColor, progress: progress)
            
        case .ended, .cancelled:
            isTracking = false
            thumbView.animateHighlight(false)
            
            let thumbCenterX = thumbView.frame.midX
            let newIsOn = thumbCenterX > switchWidth / 2.0
            
            if newIsOn != _isOn {
                _isOn = newIsOn
                valueUpdated?(_isOn)
            }
            
            updateThumbPosition(animated: true)
            updateColors()
            
        default:
            break
        }
    }
    
    private func interpolateColor(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let clampedProgress = max(0, min(1, progress))
        
        return UIColor(
            red: fromR + (toR - fromR) * clampedProgress,
            green: fromG + (toG - fromG) * clampedProgress,
            blue: fromB + (toB - fromB) * clampedProgress,
            alpha: fromA + (toA - fromA) * clampedProgress
        )
    }
    
    public override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: switchWidth, height: switchHeight)
    }
}
