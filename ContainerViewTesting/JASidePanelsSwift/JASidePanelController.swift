import UIKit
import CocoaLumberjack
import DeviceKit
import SnapKit



extension JASidePanelController {

    // MARK: - Style

    func styleContainer(container: UIView, animate: Bool, duration: TimeInterval) {
        if styleContainerWithShadow {
            let shadowPath = UIBezierPath(roundedRect: container.bounds, cornerRadius: 0.0)
            if animate {
                let animation = CABasicAnimation(keyPath: "shadowPath")
                animation.fromValue = container.layer.shadowPath
                animation.toValue = shadowPath.cgPath
                animation.duration = duration
                container.layer.add(animation, forKey: "shadowPath")
            }
            container.layer.shadowPath = shadowPath.cgPath
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowRadius = 10.0
            container.layer.shadowOpacity = 0.75
            container.clipsToBounds = false
        }
    }


    func stylePanel(panel: UIView) {
//        panel.layer.cornerRadius = 6.0
        panel.clipsToBounds = true
    }


    func configureContainers() {
        leftPanelContainer.autoresizingMask  = [.flexibleHeight, .flexibleRightMargin]
        rightPanelContainer.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        centerPanelContainer.frame = view.bounds
        centerPanelContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }


    func layoutSideContainers(animate: Bool, duration: TimeInterval) {
        var leftFrame = view.bounds
        var rightFrame = view.bounds

        if style == .multipleActive {
            // left panel container
            leftFrame.size.width = leftVisibleWidth
            leftFrame.origin.x = centerPanelContainer.frame.origin.x - leftFrame.size.width

            // right panel container
            rightFrame.size.width = rightVisibleWidth
            rightFrame.origin.x = centerPanelContainer.frame.origin.x + centerPanelContainer.frame.size.width

        } else if pushesSidePanels && !centerPanelHidden {
            leftFrame.origin.x = centerPanelContainer.frame.origin.x - leftVisibleWidth
            rightFrame.origin.x = centerPanelContainer.frame.origin.x + centerPanelContainer.frame.size.width
        }

        leftPanelContainer.frame = leftFrame
        rightPanelContainer.frame = rightFrame

        styleContainer(container: leftPanelContainer, animate: animate, duration: duration)
        styleContainer(container: rightPanelContainer, animate: animate, duration: duration)
    }


    func layoutSidePanels() {
        if leftPanel != nil {
            if leftPanel.isViewLoaded {
                var frame = leftPanelContainer.bounds
                if shouldResizeLeftPanel {
                    frame.size.width = leftVisibleWidth
                }
                leftPanel.view.frame = frame
            }
        }

        if rightPanel != nil {
            if rightPanel.isViewLoaded {
                var frame = rightPanelContainer.bounds
                if shouldResizeRightPanel {
                    if !pushesSidePanels {
                        frame.origin.x = rightPanelContainer.bounds.size.width - rightVisibleWidth
                    }
                    frame.size.width = rightVisibleWidth
                }
                rightPanel.view.frame = frame
            }
        }
    }



    // MARK: - Panels

    func swapCenter(previous: UIViewController, previousState: PanelState, with next: UIViewController) {
        if previous != next {
            previous.willMove(toParentViewController: nil)
            previous.view.removeFromSuperview()
            previous.removeFromParentViewController()
            if next != UIViewController() {
                loadCenterPanelWithPreviousState(previousState: previousState)
                addChildViewController(next)
                centerPanelContainer.addSubview(next.view)
                next.didMove(toParentViewController: self)
            }
        }
    }



    // MARK: - Panel Buttons

    func placeButtonForLeftPanel() {
        if leftPanel != nil {
            var buttonController = centerPanel

            if buttonController is UINavigationController {
                let nav = (buttonController as! UINavigationController)
                if nav.viewControllers.count > 0 {
                    buttonController = nav.viewControllers[0]
                }
            }

            if buttonController?.navigationItem.leftBarButtonItem == nil {
                buttonController?.navigationItem.leftBarButtonItem = leftButtonForCenterPanel()
            }
        }
    }



    // MARK: - Gesture Recognizer Delegate

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == tapView {
            return true
        } else if panningLimitedToTopViewController && !isOnTopLevelViewController(root: centerPanel) {
            return false
        } else if gestureRecognizer is UIPanGestureRecognizer {
            let pan = (gestureRecognizer as! UIPanGestureRecognizer)
            let translate = pan.translation(in: centerPanelContainer)
            // determine if right swipe is allowed
            if translate.x < 0 && !allowRightSwipe {
                return false
            }

            // determine if left swipe is allowed
            if translate.x > 0 && !allowLeftSwipe {
                return false
            }

            let possible = translate.x != 0 && ((fabs(translate.y) / fabs(translate.x)) < 1.0)
            if possible && ((translate.x > 0 && (leftPanel != nil)) || (translate.x < 0 && (rightPanel != nil))) {
                return true
            }
        }

        return false
    }



    // MARK: - Pan Gestures

    func addPanGestureToView(view: UIView) -> UIPanGestureRecognizer {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))

        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)

        return panGesture
    }


    @objc func handlePan(sender: UIGestureRecognizer) {
        if !recognizesPanGesture {
            return
        }

        if sender is UIPanGestureRecognizer {
            let pan = sender as! UIPanGestureRecognizer
            if pan.state == .began {
                locationBeforePan = centerPanelContainer.frame.origin
            }

            let translate = pan.translation(in: centerPanelContainer)
            var frame = centerPanelRestingFrame
            frame.origin.x += round(correctMovement(movement: translate.x))

            if style == .multipleActive {
                frame.size.width = view.bounds.size.width - frame.origin.x
            }
            centerPanelContainer.frame = frame

            // if center panel has focus, make sure correct side panel is revealed
            if state == .centerVisible {
                if frame.origin.x > 0.0 {
                    loadLeftPanel()
                } else if frame.origin.x < 0.0 {
                    loadRightPanel()
                }
            }

            // adjust side panel locations, if needed
            if style == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0)
            }

            if sender.state == .ended {
                let deltaX: CGFloat = frame.origin.x - locationBeforePan.x
                if validateThreshold(movement: deltaX) {
                    completePan(deltaX: deltaX)
                } else {
                    undoPan()
                }
            } else if sender.state == .cancelled {
                undoPan()
            }
        }
    }


    func completePan(deltaX: CGFloat) {
        switch state {
        case .centerVisible:
            if deltaX > 0 {
                showLeftPanel(animated: true, bounce: bounceOnSidePanelOpen)
            } else {
                showRightPanel(animated: true, bounce: bounceOnSidePanelOpen)
            }
        case .leftVisible:
            showCenterPanel(animated: true, bounce: bounceOnSidePanelClose)
        case .rightVisible:
            showCenterPanel(animated: true, bounce: bounceOnSidePanelClose)
        case .unknown:
            break
        }
    }


    func undoPan() {
        switch state {
        case .centerVisible:
            showCenterPanel(animated: true, bounce: false)
        case .leftVisible:
            showLeftPanel(animated: true, bounce: false)
        case .rightVisible:
            showRightPanel(animated: true, bounce: false)
        case .unknown:
            break
        }
    }


    // MARK: - Tap Gesture

    func addTapGestureToView(view: UIView) -> UITapGestureRecognizer {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(centerPanelTapped))
        view.addGestureRecognizer(tapGesture)

        return tapGesture
    }


    @objc func centerPanelTapped(gesture: UIGestureRecognizer) {
        showCenterPanel(animated: true, bounce: false)
    }



    // MARK: - Internal Methods

    func correctMovement(movement: CGFloat) -> CGFloat {
        let position: CGFloat = centerPanelRestingFrame.origin.x + movement

        if state == .centerVisible {
            if (position > 0.0 && leftPanel == nil) || (position < 0.0 && rightPanel == nil) {
                return 0.0
            } else if !allowLeftOverpan && position > leftVisibleWidth {
                return leftVisibleWidth
            } else if !allowRightOverpan && position < -rightVisibleWidth {
                return -rightVisibleWidth
            }

        } else if state == .rightVisible && !allowRightOverpan {
            if position < -rightVisibleWidth {
                return 0.0
            } else if (style == .multipleActive || pushesSidePanels) && position > 0.0 {
                return -centerPanelRestingFrame.origin.x
            } else if position > rightPanelContainer.frame.origin.x {
                return rightPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x
            }

        } else if state == .leftVisible && !allowLeftOverpan {
            if position > leftVisibleWidth {
                return 0.0
            } else if (style == .multipleActive || pushesSidePanels) && position < 0.0 {
                return -centerPanelRestingFrame.origin.x
            } else if position < leftPanelContainer.frame.origin.x {
                return leftPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x
            }
        }

        return movement
    }


    func validateThreshold(movement: CGFloat) -> Bool {
        let minimum: CGFloat = floor(view.bounds.size.width * minimumMovePercentage)

        switch state {
        case .leftVisible:
            return movement <= -minimum
        case .centerVisible:
            return fabs(movement) >= minimum
        case .rightVisible:
            return movement >= minimum
        case .unknown:
            break
        }

        return false
    }


    func isOnTopLevelViewController(root: UIViewController) -> Bool {
        if root is UINavigationController {
            let nav = root as! UINavigationController
            return nav.viewControllers.count == 1
        } else if root is UITabBarController {
            let tab = root as! UITabBarController
            return isOnTopLevelViewController(root: tab.selectedViewController!)
        }

        return true
    }



    // MARK: - Loading Panels

    func loadCenterPanelWithPreviousState(previousState: PanelState) {
        placeButtonForLeftPanel()

        // for the multi-active style, it looks better if the new center starts out in it's fullsize and slides in
        if style == .multipleActive {
            switch previousState {
            case .leftVisible:
                var frame = centerPanelContainer.frame
                frame.size.width = view.bounds.size.width
                centerPanelContainer.frame = frame

            case .rightVisible:
                var frame = centerPanelContainer.frame
                frame.size.width = view.bounds.size.width
                frame.origin.x = -rightVisibleWidth
                centerPanelContainer.frame = frame

            default:
                break
            }
        }

        centerPanel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        centerPanel.view.frame = centerPanelContainer.bounds
        stylePanel(panel: centerPanel.view)
    }


    func loadLeftPanel() {
        rightPanelContainer.isHidden = true

        if leftPanelContainer.isHidden && leftPanel != nil {
            if leftPanel.view.superview == nil {
                layoutSidePanels()
                leftPanel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                stylePanel(panel: leftPanel.view)
                leftPanelContainer.addSubview(leftPanel.view)
            }

            leftPanelContainer.isHidden = false
        }
    }


    func loadRightPanel() {
        leftPanelContainer.isHidden = true

        if rightPanelContainer.isHidden && rightPanel != nil {
            if rightPanel.view.superview == nil {
                layoutSidePanels()
                rightPanel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                stylePanel(panel: rightPanel.view)
                rightPanelContainer.addSubview(rightPanel.view)
            }
            rightPanelContainer.isHidden = false
        }
    }


    func unloadPanels() {
        if canUnloadLeftPanel && leftPanel.isViewLoaded {
            leftPanel.view.removeFromSuperview()
        }

        if canUnloadRightPanel && rightPanel.isViewLoaded {
            rightPanel.view.removeFromSuperview()
        }
    }

    // MARK: - Animation

    func calculatedDuration() -> CGFloat {
        let remaining = fabs(centerPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x)
        let max = locationBeforePan.x == centerPanelRestingFrame.origin.x ? remaining : fabs(locationBeforePan.x - centerPanelRestingFrame.origin.x)
        return max > 0.0 ? maximumAnimationDuration * (remaining / max) : maximumAnimationDuration
    }


    func animateCenterPanel(shouldBounce: Bool, completion: @escaping (_ finished: Bool) -> Void) {
        var shouldBounces = shouldBounce
        let bounceDistance: CGFloat = (centerPanelRestingFrame.origin.x - centerPanelContainer.frame.origin.x) * bouncePercentage

        // looks bad if we bounce when the center panel grows
        if centerPanelRestingFrame.size.width > centerPanelContainer.frame.size.width {
            shouldBounces = false
        }

        let duration: CGFloat = calculatedDuration()
        UIView.animate(withDuration: TimeInterval(duration),
                       delay: 0.0,
                       options: [.curveLinear, .layoutSubviews],
                       animations: { [unowned self] () -> Void in
            self.centerPanelContainer.frame = self.centerPanelRestingFrame
            self.styleContainer(container: self.centerPanelContainer, animate: true, duration: TimeInterval(duration))
            if self.style == .multipleActive || self.pushesSidePanels {
                self.layoutSideContainers(animate: false, duration: 0.0)
            }
            }, completion: { [unowned self] (finished: Bool) -> Void in
                if shouldBounces {
                    // make sure correct panel is displayed under the bounce
                    if self.state == .centerVisible {
                        if bounceDistance > 0 {
                            self.loadLeftPanel()
                        } else {
                            self.loadRightPanel()
                        }
                    }

                    // animate the bounce
                    UIView.animate(withDuration: TimeInterval(self.bounceDuration),
                                   delay: 0.0,
                                   options: .curveEaseOut,
                                   animations: { [unowned self] () -> Void in
                        var bounceFrame = self.centerPanelRestingFrame
                        bounceFrame.origin.x += bounceDistance
                        self.centerPanelContainer.frame = bounceFrame
                        }, completion: { [unowned self] (finished2) -> Void in
                            UIView.animate(withDuration: TimeInterval(self.bounceDuration),
                                           delay: 0.0,
                                           options: .curveEaseIn,
                                           animations: { [unowned self] () -> Void in
                                self.centerPanelContainer.frame = self.centerPanelRestingFrame
                                }, completion: completion)
                    })
                } else {
                    completion(finished)
                }
        })
    }


    // MARK: - Panel Sizing

    func adjustCenterFrame() -> CGRect {
        var frame = view.bounds

        switch state {
        case .centerVisible:
            frame.origin.x = 0.0
            if style == .multipleActive {
                frame.size.width = view.bounds.size.width
            }
        case .leftVisible:
            frame.origin.x = leftVisibleWidth
            if style == .multipleActive {
                frame.size.width = view.bounds.size.width - leftVisibleWidth
            }
        case .rightVisible:
            frame.origin.x = -rightVisibleWidth
            if style == .multipleActive {
                frame.origin.x = 0.0
                frame.size.width = view.bounds.size.width - rightVisibleWidth
            }
        case .unknown:
            break
        }

        centerPanelRestingFrame = frame
        return centerPanelRestingFrame
    }



    // MARK: - Showing Panels

    func showLeftPanel(animated: Bool, bounce shouldBounce: Bool) {
        state = .leftVisible
        loadLeftPanel()
        _ = adjustCenterFrame()

        if animated {
            animateCenterPanel(shouldBounce: shouldBounce, completion: { _ in })
        } else {
            centerPanelContainer.frame = centerPanelRestingFrame
            styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)

            if style == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0.0)
            }
        }

        if style == .singleActive {
            tapView = UIView()
        }

        toggleScrollsToTopForCenter(center: false, left: true, right: false)
    }


    func showRightPanel(animated: Bool, bounce shouldBounce: Bool) {
        state = .rightVisible
        loadRightPanel()
        _ = adjustCenterFrame()

        if animated {
            animateCenterPanel(shouldBounce: shouldBounce, completion: { _ in })
        } else {
            centerPanelContainer.frame = centerPanelRestingFrame
            styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)

            if style == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0.0)
            }
        }

        if style == .singleActive {
            tapView = UIView()
        }

        toggleScrollsToTopForCenter(center: false, left: false, right: true)
    }


    func showCenterPanel(animated: Bool, bounce shouldBounce: Bool) {
        state = .centerVisible
        _ = adjustCenterFrame()

        if animated {
            animateCenterPanel(shouldBounce: shouldBounce, completion: {(finished) -> Void in
                self.leftPanelContainer.isHidden = true
                self.rightPanelContainer.isHidden = true
                self.unloadPanels()
            })
        } else {
            centerPanelContainer.frame = centerPanelRestingFrame
            styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)

            if style == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0.0)
            }

            leftPanelContainer.isHidden = true
            rightPanelContainer.isHidden = true
            unloadPanels()
        }

        tapView = nil
        toggleScrollsToTopForCenter(center: true, left: false, right: false)
    }


    func hideCenterPanel() {
        centerPanelContainer.isHidden = true

        if centerPanel.isViewLoaded {
            centerPanel.view.removeFromSuperview()
        }
    }


    func unhideCenterPanel() {
        centerPanelContainer.isHidden = false

        if !(centerPanel.view.superview != nil) {
            centerPanel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            centerPanel.view.frame = centerPanelContainer.bounds
            stylePanel(panel: centerPanel.view)
            centerPanelContainer.addSubview(centerPanel.view)
        }
    }


    func toggleScrollsToTopForCenter(center: Bool, left: Bool, right: Bool) {
        // iPhone only supports 1 active UIScrollViewController at a time
        if device.isPhone {
            _ = toggleScrollsToTop(enabled: center, forView: centerPanelContainer)
            _ = toggleScrollsToTop(enabled: left, forView: leftPanelContainer)
            _ = toggleScrollsToTop(enabled: right, forView: rightPanelContainer)
        }
    }


    func toggleScrollsToTop(enabled: Bool, forView view: UIView) -> Bool {
        if view is UIScrollView {
            let scrollView = (view as! UIScrollView)
            scrollView.scrollsToTop = enabled
            return true
        } else {
            for subview: UIView in view.subviews {
                if toggleScrollsToTop(enabled: enabled, forView: subview) {
                    return true
                }
            }
        }
        return false
    }



    // MARK: - Key Value Observing

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                    change: [NSKeyValueChangeKey: Any]?,
                                    context: UnsafeMutableRawPointer?) {
        if context == ja_kvoContext {
            if keyPath! == "view" {
                if centerPanel.isViewLoaded && recognizesPanGesture {
                    addPanGestureToView(view: centerPanel.view)
                }
            } else if keyPath! == "viewControllers" && object as? UIViewController == centerPanel {
                // view controllers have changed, need to replace the button
                placeButtonForLeftPanel()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }


    // MARK: - Public Methods

    func leftButtonForCenterPanel() -> UIBarButtonItem {
        return UIBarButtonItem(image: JASidePanelController.defaultImage,
                               style: .plain,
                               target: self,
                               action: #selector(toggleLeftPanel))
    }


    public func showLeftPanel(animated: Bool) {
        showLeftPanelAnimated(animated: animated)
    }


    public func showRightPanel(animated: Bool) {
        showRightPanelAnimated(animated: animated)
    }


    public func showCenterPanel(animated: Bool) {
        showCenterPanelAnimated(animated: animated)
    }


    public func showLeftPanelAnimated(animated: Bool) {
        showLeftPanel(animated: animated, bounce: false)
    }


    public func showRightPanelAnimated(animated: Bool) {
        showRightPanel(animated: animated, bounce: false)
    }


    func showCenterPanelAnimated(animated: Bool) {
        // make sure center panel isn't hidden
        if centerPanelHidden {
            centerPanelHidden = false
            unhideCenterPanel()
        }

        showCenterPanel(animated: animated, bounce: false)
    }


    @objc func toggleLeftPanel(sender: AnyObject) {
        if state == .leftVisible {
            showCenterPanel(animated: true, bounce: false)
        } else if state == .centerVisible {
            showLeftPanel(animated: true, bounce: false)
        }

    }


    func toggleRightPanel(sender: AnyObject) {
        if state == .rightVisible {
            showCenterPanel(animated: true, bounce: false)
        } else if state == .centerVisible {
            showRightPanel(animated: true, bounce: false)
        }

    }


    func setCenterPanelHidden(isHidden: Bool, animated: Bool, duration: TimeInterval) {
        if isHidden != centerPanelHidden && state != .centerVisible {
            centerPanelHidden = isHidden
            let duration = animated ? duration : 0.0

            if centerPanelHidden {
                UIView.animate(withDuration: duration,
                               animations: { [unowned self] () -> Void in
                    var frame = self.centerPanelContainer.frame
                    frame.origin.x = (self.state == .leftVisible) ?
                        self.centerPanelContainer.frame.size.width : -self.centerPanelContainer.frame.size.width
                    self.centerPanelContainer.frame = frame
                    self.layoutSideContainers(animate: false, duration: 0)
                    if self.shouldResizeLeftPanel || self.shouldResizeRightPanel {
                        self.layoutSidePanels()
                    }
                }, completion: { [unowned self] finished -> Void in
                        // need to double check in case the user tapped really fast
                    if self.centerPanelHidden {
                            self.hideCenterPanel()
                        }
                })
            } else {
                unhideCenterPanel()

                UIView.animate(withDuration: duration,
                               animations: { [unowned self] () -> Void in
                    if self.state == .leftVisible {
                        self.showLeftPanelAnimated(animated: false)
                    } else {
                        self.showRightPanelAnimated(animated: false)
                    }

                    if self.shouldResizeLeftPanel || self.shouldResizeRightPanel {
                        self.layoutSidePanels()
                    }
                })
            }
        }
    }

}
