import UIKit
import AsyncDisplayKit

public final class LiquidGlassNode: ASDisplayNode {
    private var glassView: LiquidGlassView?
    
    public var shape: LiquidGlassShape = .circle {
        didSet {
            glassView?.shape = shape
        }
    }
    
    public var animationConfig: LiquidGlassAnimationConfig = .default {
        didSet {
            glassView?.animationConfig = animationConfig
        }
    }
    
    public var blurRadius: CGFloat = 10.0 {
        didSet {
            glassView?.blurRadius = blurRadius
        }
    }
    
    public var glassTintColor: UIColor = UIColor(white: 1.0, alpha: 0.3) {
        didSet {
            glassView?.tintColor_ = glassTintColor
        }
    }
    
    public var enableBlur: Bool = true {
        didSet {
            glassView?.enableBlur = enableBlur
        }
    }
    
    public var enableShadow: Bool = true {
        didSet {
            glassView?.enableShadow = enableShadow
        }
    }
    
    public var highlightColor: UIColor = UIColor(white: 1.0, alpha: 0.2) {
        didSet {
            glassView?.highlightColor = highlightColor
        }
    }
    
    public var contentView: UIView? {
        return glassView?.contentView
    }
    
    public override init() {
        super.init()
        
        setViewBlock { [weak self] in
            let view = LiquidGlassView(frame: .zero)
            self?.glassView = view
            return view
        }
    }
    
    public override func didLoad() {
        super.didLoad()
        
        glassView?.shape = shape
        glassView?.animationConfig = animationConfig
        glassView?.blurRadius = blurRadius
        glassView?.tintColor_ = glassTintColor
        glassView?.enableBlur = enableBlur
        glassView?.enableShadow = enableShadow
        glassView?.highlightColor = highlightColor
    }
    
    public func animateHighlight(_ highlighted: Bool, at point: CGPoint? = nil) {
        glassView?.animateHighlight(highlighted, at: point)
    }
    
    public func animateBounce(completion: (() -> Void)? = nil) {
        glassView?.animateBounce(completion: completion)
    }
    
    public func animateStretch(direction: CGPoint, completion: (() -> Void)? = nil) {
        glassView?.animateStretch(direction: direction, completion: completion)
    }
    
    public func animateSelection(selected: Bool) {
        glassView?.animateSelection(selected: selected)
    }
}

public final class LiquidGlassButtonNode: ASDisplayNode {
    private var buttonView: LiquidGlassButton?
    
    public var shape: LiquidGlassShape = .circle {
        didSet {
            buttonView?.shape = shape
        }
    }
    
    public var animationConfig: LiquidGlassAnimationConfig = .default {
        didSet {
            buttonView?.animationConfig = animationConfig
        }
    }
    
    public var contentView: UIView? {
        return buttonView?.contentView
    }
    
    public var pressed: (() -> Void)?
    
    public override init() {
        super.init()
        
        setViewBlock { [weak self] in
            let view = LiquidGlassButton(frame: .zero)
            view.addTarget(self, action: #selector(self?.buttonPressed), for: .touchUpInside)
            self?.buttonView = view
            return view
        }
    }
    
    public override func didLoad() {
        super.didLoad()
        
        buttonView?.shape = shape
        buttonView?.animationConfig = animationConfig
    }
    
    @objc private func buttonPressed() {
        pressed?()
    }
    
    public func animateBounce(completion: (() -> Void)? = nil) {
        buttonView?.glassView.animateBounce(completion: completion)
    }
}
