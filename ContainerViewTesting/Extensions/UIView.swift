import UIKit



extension UIView {

    internal func setSubviewForAutoLayout(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        self.bringSubview(toFront: subview)
    }

    internal func insertSubviewForAutoLayout(_ subview: UIView, belowSubview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(subview, belowSubview: belowSubview)
    }

    internal func setSubviewsForAutoLayout(_ subviews: [UIView]) {
        _ = subviews.map { self.setSubviewForAutoLayout($0) }
    }

    internal func set(cornerRadius: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadius
    }

    func copyView<T: UIView>() -> T {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
    }

}
