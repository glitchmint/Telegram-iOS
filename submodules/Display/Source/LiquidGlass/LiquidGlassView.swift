import UIKit
import UIKitRuntimeUtils

private let sharedIsReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled

public struct LiquidGlassAnimationConfig {
    public let highlightScale: CGFloat
    public let pressedScale: CGFloat
    public let bounceScale: CGFloat
    public let stretchFactor: CGFloat
    public let highlightDuration: Double
    public let bounceDuration: Double
    public let springDamping: CGFloat
    public let springInitialVelocity: CGFloat
    
    public static let `default` = LiquidGlassAnimationConfig(
        highlightScale: 0.96,
        pressedScale: 0.92,
        bounceScale: 1.04,
        stretchFactor: 0.03,
        highlightDuration: 0.1,
        bounceDuration: 0.4,
        springDamping: 0.6,
        springInitialVelocity: 0.8
    )
    
    public static let subtle = LiquidGlassAnimationConfig(
        highlightScale: 0.98,
        pressedScale: 0.95,
        bounceScale: 1.02,
        stretchFactor: 0.02,
        highlightDuration: 0.08,
        bounceDuration: 0.35,
        springDamping: 0.7,
        springInitialVelocity: 0.6
    )
    
    public static let prominent = LiquidGlassAnimationConfig(
        highlightScale: 0.94,
        pressedScale: 0.88,
        bounceScale: 1.06,
        stretchFactor: 0.04,
        highlightDuration: 0.12,
        bounceDuration: 0.5,
        springDamping: 0.5,
        springInitialVelocity: 1.0
    )
    
    public init(
        highlightScale: CGFloat,
        pressedScale: CGFloat,
        bounceScale: CGFloat,
        stretchFactor: CGFloat,
        highlightDuration: Double,
        bounceDuration: Double,
        springDamping: CGFloat,
        springInitialVelocity: CGFloat
    ) {
        self.highlightScale = highlightScale
        self.pressedScale = pressedScale
        self.bounceScale = bounceScale
        self.stretchFactor = stretchFactor
        self.highlightDuration = highlightDuration
        self.bounceDuration = bounceDuration
        self.springDamping = springDamping
        self.springInitialVelocity = springInitialVelocity
    }
}

public enum LiquidGlassShape {
    case circle
    case roundedRect(cornerRadius: CGFloat)
    case capsule
    
    func cornerRadius(for size: CGSize) -> CGFloat {
        switch self {
        case .circle:
            return min(size.width, size.height) / 2.0
        case .roundedRect(let cornerRadius):
            return cornerRadius
        case .capsule:
            return min(size.width, size.height) / 2.0
        }
    }
}

open class LiquidGlassView: UIView {
    public var shape: LiquidGlassShape = .circle {
        didSet {
            updateShape()
        }
    }
    
    public var animationConfig: LiquidGlassAnimationConfig = .default
    
    public var blurRadius: CGFloat = 10.0 {
        didSet {
            updateBlurEffect()
        }
    }
    
    public var tintColor_: UIColor = UIColor(white: 1.0, alpha: 0.3) {
        didSet {
            updateTintColor()
        }
    }
    
    public var enableBlur: Bool = true {
        didSet {
            updateBlurEffect()
        }
    }
    
    public var enableShadow: Bool = true {
        didSet {
            updateShadow()
        }
    }
    
    public var highlightColor: UIColor = UIColor(white: 1.0, alpha: 0.2) {
        didSet {
            highlightLayer.backgroundColor = highlightColor.cgColor
        }
    }
    
    private var effectView: UIVisualEffectView?
    private let backgroundLayer = CALayer()
    private let highlightLayer = CALayer()
    private let borderLayer = CAShapeLayer()
    private let contentContainerView = UIView()
    
    private var isHighlighted: Bool = false
    private var touchStartPoint: CGPoint?
    
    public var contentView: UIView {
        return contentContainerView
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        clipsToBounds = false
        
        backgroundLayer.backgroundColor = tintColor_.cgColor
        layer.addSublayer(backgroundLayer)
        
        highlightLayer.backgroundColor = highlightColor.cgColor
        highlightLayer.opacity = 0
        layer.addSublayer(highlightLayer)
        
        borderLayer.fillColor = nil
        borderLayer.strokeColor = UIColor(white: 1.0, alpha: 0.3).cgColor
        borderLayer.lineWidth = 0.5
        layer.addSublayer(borderLayer)
        
        contentContainerView.backgroundColor = .clear
        addSubview(contentContainerView)
        
        updateBlurEffect()
        updateShadow()
    }
    
    private func updateBlurEffect() {
        if enableBlur && !sharedIsReduceTransparencyEnabled {
            if effectView == nil {
                let blurEffect = UIBlurEffect(style: .light)
                let effectView = UIVisualEffectView(effect: blurEffect)
                effectView.isUserInteractionEnabled = false
                
                for subview in effectView.subviews {
                    if subview.description.contains("VisualEffectSubview") {
                        subview.isHidden = true
                    }
                }
                
                if let sublayer = effectView.layer.sublayers?.first, let filters = sublayer.filters {
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
                            filter.setValue(blurRadius as NSNumber, forKey: "inputRadius")
                        }
                        return true
                    }
                }
                
                insertSubview(effectView, at: 0)
                self.effectView = effectView
            }
        } else {
            effectView?.removeFromSuperview()
            effectView = nil
        }
        
        setNeedsLayout()
    }
    
    private func updateTintColor() {
        backgroundLayer.backgroundColor = tintColor_.cgColor
    }
    
    private func updateShadow() {
        if enableShadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 8
            layer.shadowOpacity = 0.15
        } else {
            layer.shadowOpacity = 0
        }
    }
    
    private func updateShape() {
        setNeedsLayout()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let cornerRadius = shape.cornerRadius(for: bounds.size)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        backgroundLayer.frame = bounds
        backgroundLayer.cornerRadius = cornerRadius
        
        highlightLayer.frame = bounds
        highlightLayer.cornerRadius = cornerRadius
        
        let borderPath = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.25, dy: 0.25), cornerRadius: cornerRadius)
        borderLayer.path = borderPath.cgPath
        borderLayer.frame = bounds
        
        effectView?.frame = bounds
        effectView?.layer.cornerRadius = cornerRadius
        effectView?.clipsToBounds = true
        
        contentContainerView.frame = bounds
        
        layer.cornerRadius = cornerRadius
        
        if enableShadow {
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        }
        
        CATransaction.commit()
    }
    
    public func animateHighlight(_ highlighted: Bool, at point: CGPoint? = nil) {
        guard isHighlighted != highlighted else { return }
        isHighlighted = highlighted
        
        if highlighted {
            touchStartPoint = point
            animatePress(at: point)
        } else {
            animateRelease(from: touchStartPoint)
            touchStartPoint = nil
        }
    }
    
    private func animatePress(at point: CGPoint?) {
        let config = animationConfig
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(config.highlightDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        
        highlightLayer.opacity = 1.0
        
        CATransaction.commit()
        
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, config.pressedScale, config.pressedScale, 1.0)
        
        if let point = point {
            let stretchX = (point.x - bounds.midX) / bounds.width * config.stretchFactor
            let stretchY = (point.y - bounds.midY) / bounds.height * config.stretchFactor
            transform = CATransform3DTranslate(transform, stretchX * bounds.width, stretchY * bounds.height, 0)
        }
        
        UIView.animate(
            withDuration: config.highlightDuration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.layer.transform = transform
            },
            completion: nil
        )
    }
    
    private func animateRelease(from point: CGPoint?) {
        let config = animationConfig
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(config.highlightDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
        
        highlightLayer.opacity = 0.0
        
        CATransaction.commit()
        
        UIView.animate(
            withDuration: config.bounceDuration,
            delay: 0,
            usingSpringWithDamping: config.springDamping,
            initialSpringVelocity: config.springInitialVelocity,
            options: [.allowUserInteraction],
            animations: {
                self.layer.transform = CATransform3DIdentity
            },
            completion: nil
        )
    }
    
    public func animateBounce(completion: (() -> Void)? = nil) {
        let config = animationConfig
        
        let bounceTransform = CATransform3DScale(CATransform3DIdentity, config.bounceScale, config.bounceScale, 1.0)
        
        UIView.animate(
            withDuration: config.highlightDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.layer.transform = bounceTransform
            },
            completion: { _ in
                UIView.animate(
                    withDuration: config.bounceDuration,
                    delay: 0,
                    usingSpringWithDamping: config.springDamping,
                    initialSpringVelocity: config.springInitialVelocity,
                    options: [],
                    animations: {
                        self.layer.transform = CATransform3DIdentity
                    },
                    completion: { _ in
                        completion?()
                    }
                )
            }
        )
    }
    
    public func animateStretch(direction: CGPoint, completion: (() -> Void)? = nil) {
        let config = animationConfig
        
        let stretchX = 1.0 + direction.x * config.stretchFactor
        let stretchY = 1.0 + direction.y * config.stretchFactor
        
        var stretchTransform = CATransform3DIdentity
        stretchTransform = CATransform3DScale(stretchTransform, stretchX, stretchY, 1.0)
        
        UIView.animate(
            withDuration: config.highlightDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.layer.transform = stretchTransform
            },
            completion: { _ in
                UIView.animate(
                    withDuration: config.bounceDuration,
                    delay: 0,
                    usingSpringWithDamping: config.springDamping,
                    initialSpringVelocity: config.springInitialVelocity,
                    options: [],
                    animations: {
                        self.layer.transform = CATransform3DIdentity
                    },
                    completion: { _ in
                        completion?()
                    }
                )
            }
        )
    }
    
    public func animateSelection(selected: Bool) {
        let config = animationConfig
        
        if selected {
            let scaleTransform = CATransform3DScale(CATransform3DIdentity, config.highlightScale, config.highlightScale, 1.0)
            
            UIView.animate(
                withDuration: config.highlightDuration,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    self.layer.transform = scaleTransform
                },
                completion: { _ in
                    UIView.animate(
                        withDuration: config.bounceDuration,
                        delay: 0,
                        usingSpringWithDamping: config.springDamping,
                        initialSpringVelocity: config.springInitialVelocity,
                        options: [],
                        animations: {
                            self.layer.transform = CATransform3DIdentity
                        },
                        completion: nil
                    )
                }
            )
        }
    }
}

open class LiquidGlassButton: UIControl {
    public let glassView: LiquidGlassView
    
    public var animationConfig: LiquidGlassAnimationConfig {
        get { glassView.animationConfig }
        set { glassView.animationConfig = newValue }
    }
    
    public var shape: LiquidGlassShape {
        get { glassView.shape }
        set { glassView.shape = newValue }
    }
    
    public var contentView: UIView {
        return glassView.contentView
    }
    
    public override init(frame: CGRect) {
        glassView = LiquidGlassView(frame: CGRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        setupButton()
    }
    
    required public init?(coder: NSCoder) {
        glassView = LiquidGlassView(frame: .zero)
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        addSubview(glassView)
        glassView.isUserInteractionEnabled = false
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
    }
    
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        glassView.animateHighlight(true, at: point)
        return super.beginTracking(touch, with: event)
    }
    
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return super.continueTracking(touch, with: event)
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        glassView.animateHighlight(false)
        super.endTracking(touch, with: event)
    }
    
    open override func cancelTracking(with event: UIEvent?) {
        glassView.animateHighlight(false)
        super.cancelTracking(with: event)
    }
}
