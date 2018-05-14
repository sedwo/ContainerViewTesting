import UIKit
import CocoaLumberjack
import DeviceKit



extension JASidePanelController {

    // MARK: - Lifecycle Methods
    override open func viewDidLoad() {
        super.viewDidLoad()
        DDLogInfo("")

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
        DDLogInfo("")

        // ensure correct view dimensions
        resetViewFrames()
    }


    // Account for possible rotation while view appearing
    override open func viewDidAppear(_ animated: Bool) {
//        _ = adjustCenterFrame()
        super.viewDidAppear(animated)
        DDLogInfo("")
    }


    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DDLogInfo("")
        resetViewFrames()
    }


    func resetViewFrames() {
        DDLogInfo("")
        centerPanelContainer.frame = adjustCenterFrame()
        layoutSideContainers(animate: true, duration: 0.0)
        layoutSidePanels()
        //        styleContainer(container: centerPanelContainer, animate: true, duration: 0.0)
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
     //        styleContainer(container: centerPanelContainer, animate: true, duration: duration)
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

}
