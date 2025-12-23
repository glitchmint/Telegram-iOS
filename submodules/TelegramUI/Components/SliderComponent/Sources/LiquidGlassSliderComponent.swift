import Foundation
import UIKit
import Display
import ComponentFlow

private let liquidGlassPressedScale: CGFloat = 0.92
private let liquidGlassBounceScale: CGFloat = 1.06
private let liquidGlassHighlightDuration: Double = 0.1
private let liquidGlassBounceDuration: Double = 0.4
private let liquidGlassSpringDamping: CGFloat = 0.6
private let liquidGlassSpringVelocity: CGFloat = 0.8

private final class LiquidGlassKnobView: UIView {
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
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
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

public final class LiquidGlassSliderComponent: Component {
    public let value: CGFloat
    public let minValue: CGFloat
    public let maxValue: CGFloat
    public let trackBackgroundColor: UIColor
    public let trackForegroundColor: UIColor
    public let knobSize: CGFloat
    public let valueUpdated: (CGFloat) -> Void
    public let isTrackingUpdated: ((Bool) -> Void)?
    
    public init(
        value: CGFloat,
        minValue: CGFloat = 0.0,
        maxValue: CGFloat = 1.0,
        trackBackgroundColor: UIColor,
        trackForegroundColor: UIColor,
        knobSize: CGFloat = 28.0,
        valueUpdated: @escaping (CGFloat) -> Void,
        isTrackingUpdated: ((Bool) -> Void)? = nil
    ) {
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.trackBackgroundColor = trackBackgroundColor
        self.trackForegroundColor = trackForegroundColor
        self.knobSize = knobSize
        self.valueUpdated = valueUpdated
        self.isTrackingUpdated = isTrackingUpdated
    }
    
    public static func ==(lhs: LiquidGlassSliderComponent, rhs: LiquidGlassSliderComponent) -> Bool {
        if lhs.value != rhs.value {
            return false
        }
        if lhs.minValue != rhs.minValue {
            return false
        }
        if lhs.maxValue != rhs.maxValue {
            return false
        }
        if lhs.trackBackgroundColor != rhs.trackBackgroundColor {
            return false
        }
        if lhs.trackForegroundColor != rhs.trackForegroundColor {
            return false
        }
        if lhs.knobSize != rhs.knobSize {
            return false
        }
        return true
    }
    
    public final class View: UIView {
        private let trackBackgroundView = UIView()
        private let trackForegroundView = UIView()
        private let knobView = LiquidGlassKnobView(frame: .zero)
        
        private var component: LiquidGlassSliderComponent?
        private weak var state: EmptyComponentState?
        
        private var isTracking = false
        private var trackingStartValue: CGFloat = 0
        private var trackingStartLocation: CGPoint = .zero
        
        override public init(frame: CGRect) {
            super.init(frame: frame)
            
            trackBackgroundView.layer.cornerRadius = 2.0
            addSubview(trackBackgroundView)
            
            trackForegroundView.layer.cornerRadius = 2.0
            addSubview(trackForegroundView)
            
            knobView.backgroundColor = .white
            addSubview(knobView)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            knobView.addGestureRecognizer(panGesture)
            knobView.isUserInteractionEnabled = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            addGestureRecognizer(tapGesture)
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let component = self.component else { return }
            
            let location = gesture.location(in: self)
            let trackWidth = bounds.width - component.knobSize
            let normalizedX = (location.x - component.knobSize / 2.0) / trackWidth
            let clampedValue = max(0, min(1, normalizedX))
            let newValue = component.minValue + clampedValue * (component.maxValue - component.minValue)
            
            knobView.animateHighlight(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.knobView.animateHighlight(false)
            }
            
            component.valueUpdated(newValue)
        }
        
        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let component = self.component else { return }
            
            switch gesture.state {
            case .began:
                isTracking = true
                trackingStartValue = component.value
                trackingStartLocation = gesture.location(in: self)
                knobView.animateHighlight(true)
                component.isTrackingUpdated?(true)
                
            case .changed:
                let location = gesture.location(in: self)
                let trackWidth = bounds.width - component.knobSize
                let deltaX = location.x - trackingStartLocation.x
                let deltaValue = deltaX / trackWidth * (component.maxValue - component.minValue)
                let newValue = max(component.minValue, min(component.maxValue, trackingStartValue + deltaValue))
                
                component.valueUpdated(newValue)
                
            case .ended, .cancelled:
                isTracking = false
                knobView.animateHighlight(false)
                component.isTrackingUpdated?(false)
                
            default:
                break
            }
        }
        
        func update(component: LiquidGlassSliderComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            self.component = component
            self.state = state
            
            let height: CGFloat = 44.0
            let trackHeight: CGFloat = 4.0
            let size = CGSize(width: availableSize.width, height: height)
            
            trackBackgroundView.backgroundColor = component.trackBackgroundColor
            trackForegroundView.backgroundColor = component.trackForegroundColor
            
            let trackY = (height - trackHeight) / 2.0
            let trackWidth = size.width - component.knobSize
            
            trackBackgroundView.frame = CGRect(
                x: component.knobSize / 2.0,
                y: trackY,
                width: trackWidth,
                height: trackHeight
            )
            
            let normalizedValue = (component.value - component.minValue) / (component.maxValue - component.minValue)
            let foregroundWidth = trackWidth * normalizedValue
            
            trackForegroundView.frame = CGRect(
                x: component.knobSize / 2.0,
                y: trackY,
                width: foregroundWidth,
                height: trackHeight
            )
            
            let knobX = component.knobSize / 2.0 + foregroundWidth - component.knobSize / 2.0
            let knobY = (height - component.knobSize) / 2.0
            
            if !isTracking {
                knobView.frame = CGRect(
                    x: knobX,
                    y: knobY,
                    width: component.knobSize,
                    height: component.knobSize
                )
            }
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
