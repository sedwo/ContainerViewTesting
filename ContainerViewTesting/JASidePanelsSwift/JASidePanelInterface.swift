import UIKit
import CocoaLumberjack
import DeviceKit



internal enum PanelMode: Int {
    case singleActive = 0
    case multipleActive
}

internal enum PanelState: Int {
    case unknown = 0
    case centerVisible
    case leftVisible
    case rightVisible
}

// Helps with UI view container tracking.
private struct ContainerTags {
    static let ROOT_VIEW    = -2
    static let LEFT_VIEW    = 80
    static let CENTER_VIEW  = 90
    static let RIGHT_VIEW   = 100
    static let TAP_VIEW     = 200
}



open class JASidePanelController: UIViewController, UIGestureRecognizerDelegate {

    // size the left panel based on % of total screen width
    var leftGapPercentage: CGFloat = 0.50

    // size the left panel based on this fixed size. overrides leftGapPercentage
    var leftFixedWidth: CGFloat = 0.0

    // the visible width of the left panel
    private var _leftVisibleWidth: CGFloat = 0.0
    var leftVisibleWidth: CGFloat {
        set {
            _leftVisibleWidth = newValue
        }

        get {
            if centerPanelHidden && shouldResizeLeftPanel {
                return view.bounds.size.width
            } else {
                return leftFixedWidth != 0 ? leftFixedWidth : floor(view.bounds.size.width * leftGapPercentage)
            }
        }
    }


    // size the right panel based on % of total screen width
    var rightGapPercentage: CGFloat = 0.50

    // size the right panel based on this fixed size. overrides rightGapPercentage
    var rightFixedWidth: CGFloat = 0.0

    // the visible width of the right panel
    private var _rightVisibleWidth: CGFloat = 0.0
    var rightVisibleWidth: CGFloat {
        set {
            _rightVisibleWidth = newValue
        }

        get {
            if centerPanelHidden && shouldResizeRightPanel {
                return view.bounds.size.width
            } else {
                return rightFixedWidth != 0 ? rightFixedWidth : floor(view.bounds.size.width * rightGapPercentage)
            }
        }
    }



    // MARK: - Animation

    // should the center panel bounce when you are panning open a left/right panel.
    var bounceOnSidePanelOpen: Bool = true

    // should the center panel bounce when you are panning closed a left/right panel.
    var bounceOnSidePanelClose: Bool = false

    // while changing the center panel, should we bounce it offscreen?
    var bounceOnCenterPanelChange: Bool = true

    // the minimum % of total screen width the view must move for panGesture to succeed
    var minimumMovePercentage: CGFloat = 0.15

    // the maximum time panel opening/closing should take. Actual time may be less if panGesture has already moved the view.
    var maximumAnimationDuration: CGFloat = 0.2

    // how long the bounce animation should take
    var bounceDuration: CGFloat = 0.12

    // how far the view should bounce
    var bouncePercentage: CGFloat = 0.1



    // MARK: - Gesture Behavior

    // Determines whether the pan gesture is limited to the top ViewController in a UINavigationController/UITabBarController
    var panningLimitedToTopViewController: Bool = false // default is YES

    // Determines whether showing panels can be controlled through pan gestures, or only through buttons
    var recognizesPanGesture: Bool = true // default is YES



    // MARK: - Nuts & Bolts

    // Current state of panels. Use KVO to monitor state changes
    // MARK: - State
    private var _state: PanelState = .centerVisible
    var state: PanelState {
        set {
            if _state != newValue {
                _state = newValue

                switch _state {
                case .centerVisible:
                    visiblePanel = centerPanel
                    leftPanelContainer.isUserInteractionEnabled = false
                    rightPanelContainer.isUserInteractionEnabled = false

                case .leftVisible:
                    visiblePanel = leftPanel
                    leftPanelContainer.isUserInteractionEnabled = true

                case .rightVisible:
                    visiblePanel = rightPanel
                    rightPanelContainer.isUserInteractionEnabled = true

                case .unknown:
                    break
                }
            }
        }

        get {
            return _state
        }
    }


    // Whether or not the center panel is completely hidden
    private var _centerPanelHidden: Bool = false
    var centerPanelHidden: Bool {
        set {
            setCenterPanelHidden(isHidden: _centerPanelHidden, animated: false, duration: 0.0)
        }

        get {
            return _centerPanelHidden
        }
    }


    private var _tapView: UIView?
    var tapView: UIView? {
        set {
            if newValue != _tapView {
                if _tapView != nil {
                    _tapView!.removeFromSuperview()
                }

                if newValue != nil {
                    _tapView = newValue!
                    _tapView!.frame = centerPanelContainer.bounds
                    _tapView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                    let tapGesture = addTapGestureToView(view: _tapView!)

                    if recognizesPanGesture {
                        let panGesture = addPanGestureToView(view: _tapView!)
                        tapGesture.require(toFail: panGesture)
                    }

                    _tapView?.tag = ContainerTags.TAP_VIEW
                    centerPanelContainer.addSubview(_tapView!)
                }
            }

        }
        get {
            return _tapView
        }
    }


    // MARK: - set the panels

    private var _leftPanel: UIViewController!
    var leftPanel: UIViewController! {
        set {
            if newValue != _leftPanel {
                if _leftPanel != nil {
                    _leftPanel.willMove(toParentViewController: nil)
                    _leftPanel.view.removeFromSuperview()
                    _leftPanel.removeFromParentViewController()
                }

                _leftPanel = newValue
                _leftPanel.view.tag = ContainerTags.LEFT_VIEW+1

                if _leftPanel != nil {
                    addChildViewController(_leftPanel)
                    _leftPanel.didMove(toParentViewController: self)
                    placeButtonForLeftPanel()
                }

                if state == .leftVisible {
                    visiblePanel = _leftPanel
                }
            }

        }

        get {
            return _leftPanel
        }
    }


    private var _centerPanel: UIViewController!
    var centerPanel: UIViewController! {
        set {
            let previous = _centerPanel

            if newValue != _centerPanel {
                if _centerPanel != nil {
                    _centerPanel.removeObserver(self, forKeyPath: "view")
                    _centerPanel.removeObserver(self, forKeyPath: "viewControllers")
                }

                _centerPanel = newValue
                _centerPanel.view.tag = ContainerTags.CENTER_VIEW+1

                _centerPanel.addObserver(self, forKeyPath: "viewControllers", options: [], context: ja_kvoContext)
                _centerPanel.addObserver(self, forKeyPath: "view", options: .initial, context: ja_kvoContext)

                if state == .centerVisible {
                    visiblePanel = _centerPanel
                }
            }

            if isViewLoaded && state == .centerVisible {
                swapCenter(previous: previous!, previousState: .unknown, with: _centerPanel)
            } else if isViewLoaded {
                // update the state immediately to prevent user interaction on the side panels while animating
                let previousState = state
                state = .centerVisible

                UIView.animate(withDuration: 0.2, animations: { [unowned self] () -> Void in
                    if self.bounceOnCenterPanelChange {
                        // first move the centerPanel offscreen
                        let x: CGFloat = (previousState == .leftVisible) ? self.view.bounds.size.width : -self.view.bounds.size.width
                        self.centerPanelRestingFrame.origin.x = x
                    }

                    self.centerPanelContainer.frame = self.centerPanelRestingFrame

                    }, completion: { [unowned self] (finished) -> Void in
                        self.swapCenter(previous: previous!, previousState: previousState, with: self._centerPanel)
                        self.showCenterPanel(animated: true, bounce: false)
                })
            }
        }

        get {
            return _centerPanel
        }
    }


    private var _rightPanel: UIViewController!
    var rightPanel: UIViewController! {
        set {
            if newValue != _rightPanel {
                if _rightPanel != nil {
                    _rightPanel.willMove(toParentViewController: nil)
                    _rightPanel.view.removeFromSuperview()
                    _rightPanel.removeFromParentViewController()
                }

                _rightPanel = newValue
                _rightPanel.view.tag = ContainerTags.RIGHT_VIEW+1

                if _rightPanel != nil {
                    addChildViewController(_rightPanel)
                    _rightPanel.didMove(toParentViewController: self)
                }

                if state == .rightVisible {
                    visiblePanel = _rightPanel
                }
            }
        }

        get {
            return _rightPanel
        }
    }


    // MARK: - style

    private var _mode: PanelMode = .singleActive // default is .singleActive
    var mode: PanelMode {
        set {
            if newValue != _mode {
                _mode = newValue
                if isViewLoaded {
                    configureContainers()
                    layoutSideContainers(animate: false, duration: 0.0)
                }
            }
        }

        get {
            return _mode
        }
    }


    // If set to yes, "shouldAutorotateToInterfaceOrientation:" will be passed to visiblePanel instead of handled directly
    var shouldDelegateAutorotateToVisiblePanel: Bool = false

    // 'Push' vs 'Reveal' side panels into view
    // 'Push' = side panels are inline with the center panel, and pan with the center panel to make room for side panel
    // 'Reveal' = side panels are in the background, overlapped by the center panel, and you 'reveal' them by sliding center panel out of the way
    var pushesSidePanels: Bool = true

    // Style the side panels with a shadow edge effect to indicate floating
    var styleContainerWithShadow: Bool = false

    // Determines whether or not the panel's views are removed when not visble. If YES, rightPanel & leftPanel's views are eligible for release
    // of their references to the view controller’s view if they are not being used.
    var canUnloadRightPanel: Bool = false
    var canUnloadLeftPanel: Bool = false

    // Determines whether or not the panel's views should be resized when they are displayed. If yes, the views will be resized to their visible width
    var shouldResizeRightPanel: Bool = true
    var shouldResizeLeftPanel: Bool = true

    // Determines whether or not the center panel can be panned beyound the the visible area of the side panels
    var allowRightOverpan: Bool = false
    var allowLeftOverpan: Bool = false

    // Determines whether or not the left or right panel can be swiped into view. Use if only way to view a panel is with a button
    var allowLeftSwipe: Bool = true
    var allowRightSwipe: Bool = true

    // Containers for the panels.
    var leftPanelContainer: UIView!
    var rightPanelContainer: UIView!
    var centerPanelContainer: UIView!

    var centerPanelRestingFrame = CGRect.zero
    var locationBeforePan = CGPoint.zero

    let ja_kvoContext: UnsafeMutableRawPointer? = nil

    // The currently visible panel
    var visiblePanel: UIViewController!


    // MARK: - Icon

    static let defaultImage: UIImage = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 13))
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 20, height: 1))
            ctx.cgContext.fill(CGRect(x: 0, y: 5, width: 20, height: 1))
            ctx.cgContext.fill(CGRect(x: 0, y: 10, width: 20, height: 1))

            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 1, width: 20, height: 2))
            ctx.cgContext.fill(CGRect(x: 0, y: 6, width: 20, height: 2))
            ctx.cgContext.fill(CGRect(x: 0, y: 11, width: 20, height: 2))
        }
    }()


    let device: Device = {
        return Device()
    }()



    // MARK: - Initializers(...)

    public init() {
        super.init(nibName: nil, bundle: nil)
        DDLogInfo("")

        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        DDLogInfo("")
        fatalError("")
    }

    private func commonInit() {
        DDLogInfo("")
        mode = .singleActive
        bounceOnSidePanelOpen = !pushesSidePanels
    }



    // MARK: - Lifecycle Methods

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = #colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1)
        view.tag = ContainerTags.ROOT_VIEW

        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        centerPanelContainer = UIView(frame: view.bounds)
        centerPanelContainer.tag = ContainerTags.CENTER_VIEW
        centerPanelRestingFrame = centerPanelContainer.frame
        centerPanelHidden = false

        leftPanelContainer = UIView(frame: view.bounds)
        leftPanelContainer.isHidden = true
        leftPanelContainer.tag = ContainerTags.LEFT_VIEW

        rightPanelContainer = UIView(frame: view.bounds)
        rightPanelContainer.isHidden = true
        rightPanelContainer.tag = ContainerTags.RIGHT_VIEW

        configureContainers()

        view.addSubview(centerPanelContainer)
        view.addSubview(leftPanelContainer)
        view.addSubview(rightPanelContainer)

        state = .centerVisible
        swapCenter(previous: UIViewController(), previousState: .centerVisible, with: centerPanel)
        view.bringSubview(toFront: centerPanelContainer)
    }


    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // ensure correct view dimensions
        layoutSideContainers(animate: false, duration: 0.0)
        layoutSidePanels()
        centerPanelContainer.frame = adjustCenterFrame()
        styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)
    }


    // Account for possible rotation while view appearing
    override open func viewDidAppear(_ animated: Bool) {
        _ = adjustCenterFrame()
        super.viewDidAppear(animated)
    }


    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        centerPanelContainer.frame = adjustCenterFrame()
        layoutSideContainers(animate: true, duration: 0.0)
        layoutSidePanels()
        styleContainer(container: centerPanelContainer, animate: true, duration: 0.0)
        if centerPanelHidden {
            var frame: CGRect = centerPanelContainer.frame
            frame.origin.x = state == .leftVisible ? centerPanelContainer.frame.size.width : -centerPanelContainer.frame.size.width
            centerPanelContainer.frame = frame
        }
    }


    override open func updateViewConstraints() {
        super.updateViewConstraints()
//        DDLogInfo("")
    }


    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
//        DDLogInfo("")
        view.setNeedsUpdateConstraints()
    }


    override open var shouldAutorotate: Bool {
        if let panel = visiblePanel {
            if shouldDelegateAutorotateToVisiblePanel && panel.responds(to: #selector(getter: self.shouldAutorotate)) {
                return panel.shouldAutorotate
            }
        }

        return true
    }


    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let panel = visiblePanel {
            if shouldDelegateAutorotateToVisiblePanel && panel.responds(to: #selector(getter: self.supportedInterfaceOrientations)) {
                return panel.supportedInterfaceOrientations
            }
        }

        return UIInterfaceOrientationMask.all
    }

/*
    override public func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        centerPanelContainer.frame = _adjustCenterFrame()
        _layoutSideContainers(animate: true, duration: duration)
        _layoutSidePanels()
        styleContainer(container: centerPanelContainer, animate: true, duration: duration)
        if centerPanelHidden {
            var frame = centerPanelContainer.frame
            frame.origin.x = state == .JASidePanelLeftVisible ? centerPanelContainer.frame.size.width : -centerPanelContainer.frame.size.width
            centerPanelContainer.frame = frame
        }
    }
*/

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DDLogInfo("")
        view.setNeedsUpdateConstraints()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        DDLogError("")
    }


    deinit {
        DDLogWarn("")
        centerPanel?.removeObserver(self, forKeyPath: "view")
        centerPanel?.removeObserver(self, forKeyPath: "viewControllers")
    }


}
