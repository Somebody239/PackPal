import UIKit

/// A UIView that allows touches to pass through to underlying views
/// Useful for creating overlay views that don't block user interaction
final class PassthroughView: UIView {
    // MARK: - Properties
    
    /// The primary view that touches should pass through to
    weak var passthroughView: UIView?
    /// Additional views that should receive touch events
    var additionalInteractiveViews: [UIView] = []

    // MARK: - Touch Handling
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Allow touches to pass through unless they hit designated interactive subviews
        if let target = passthroughView {
            let pt = convert(point, to: target)
            if target.point(inside: pt, with: event) { return true }
        }
        for view in additionalInteractiveViews where !view.isHidden {
            let pt = convert(point, to: view)
            if view.point(inside: pt, with: event) { return true }
        }
        return false
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit == self ? nil : hit
    }
}


