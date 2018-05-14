import UIKit
import CocoaLumberjack
import DeviceKit
import SnapKit



extension JASidePanelController {

    // MARK: - Style
/*
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
*/

    func stylePanel(panel: UIView) {
        DDLogInfo("")
//        panel.layer.cornerRadius = 6.0
        panel.clipsToBounds = true
    }


    func configureContainers() {
        DDLogInfo("")
        leftPanelContainer.autoresizingMask  = [.flexibleHeight, .flexibleRightMargin]
        rightPanelContainer.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        centerPanelContainer.frame = view.bounds
        centerPanelContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }


    func layoutSideContainers(animate: Bool, duration: TimeInterval) {
        DDLogInfo("")

        var leftFrame = view.bounds
        var rightFrame = view.bounds

        if mode == .multipleActive {
            // left panel container
            leftFrame.size.width = leftVisibleWidth
            leftFrame.origin.x = centerPanelContainer.frame.origin.x - leftFrame.size.width

            // right panel container
            rightFrame.size.width = rightVisibleWidth
            rightFrame.origin.x = centerPanelContainer.frame.origin.x + centerPanelContainer.frame.size.width

        } else if pushesSidePanels && !centerPanelHidden {
            leftFrame.origin.x = centerPanelContainer.frame.origin.x - leftVisibleWidth
//            leftFrame.origin.x = 0
//            leftFrame.size.width = leftVisibleWidth
//            DDLogVerbose("leftFrame.origin.x = \(leftFrame.origin.x)")
            rightFrame.origin.x = centerPanelContainer.frame.origin.x + centerPanelContainer.frame.size.width
        }

        leftPanelContainer.frame = leftFrame
        rightPanelContainer.frame = rightFrame

//        styleContainer(container: leftPanelContainer, animate: animate, duration: duration)
//        styleContainer(container: rightPanelContainer, animate: animate, duration: duration)
    }


    func layoutSidePanels() {
        DDLogInfo("")

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
        DDLogInfo("")

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
        DDLogInfo("")

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



    // MARK: - Loading Panels

    func loadCenterPanelWithPreviousState(previousState: PanelState) {
        DDLogInfo("")

        placeButtonForLeftPanel()

        // for the multi-active style, it looks better if the new center starts out in it's fullsize and slides in
        if mode == .multipleActive {
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
        DDLogInfo("")

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
        DDLogInfo("")

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


    func unloadPanelsFromView() {
        DDLogInfo("")

        if canUnloadLeftPanel && leftPanel.isViewLoaded {
            leftPanel.view.removeFromSuperview()
        }

        if canUnloadRightPanel && rightPanel.isViewLoaded {
            rightPanel.view.removeFromSuperview()
        }
    }

    // MARK: - Animation

    func calculatedDuration() -> CGFloat {
        DDLogInfo("")

        let remaining = fabs(centerPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x)
        let max = locationBeforePan.x == centerPanelRestingFrame.origin.x ? remaining : fabs(locationBeforePan.x - centerPanelRestingFrame.origin.x)
        return max > 0.0 ? maximumAnimationDuration * (remaining / max) : maximumAnimationDuration
    }


    func animateCenterPanel(shouldBounce: Bool, completion: @escaping (_ finished: Bool) -> Void) {
        DDLogInfo("")

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
//            self.styleContainer(container: self.centerPanelContainer, animate: true, duration: TimeInterval(duration))
            if self.mode == .multipleActive || self.pushesSidePanels {
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
        DDLogInfo("")

        var frame = view.bounds

        switch state {
        case .centerVisible:
            frame.origin.x = 0.0
            if mode == .multipleActive {
                frame.size.width = view.bounds.size.width
            }
        case .leftVisible:
            frame.origin.x = leftVisibleWidth
            if mode == .multipleActive {
                frame.size.width = view.bounds.size.width - leftVisibleWidth
            }
        case .rightVisible:
            frame.origin.x = -rightVisibleWidth
            if mode == .multipleActive {
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
        DDLogInfo("")

        state = .leftVisible
        loadLeftPanel()
        _ = adjustCenterFrame()

        if animated {
            animateCenterPanel(shouldBounce: shouldBounce, completion: { _ in })
        } else {
            centerPanelContainer.frame = centerPanelRestingFrame
//            styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)

            if mode == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0.0)
            }
        }

        if mode == .singleActive {
            tapView = UIView()
        }

        toggleScrollsToTopForCenter(center: false, left: true, right: false)
    }


    func showRightPanel(animated: Bool, bounce shouldBounce: Bool) {
        DDLogInfo("")

        state = .rightVisible
        loadRightPanel()
        _ = adjustCenterFrame()

        if animated {
            animateCenterPanel(shouldBounce: shouldBounce, completion: { _ in })
        } else {
            centerPanelContainer.frame = centerPanelRestingFrame
//            styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)

            if mode == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0.0)
            }
        }

        if mode == .singleActive {
            tapView = UIView()
        }

        toggleScrollsToTopForCenter(center: false, left: false, right: true)
    }


    func showCenterPanel(animated: Bool, bounce shouldBounce: Bool) {
        DDLogInfo("")

        state = .centerVisible
        _ = adjustCenterFrame()

        if animated {
            animateCenterPanel(shouldBounce: shouldBounce, completion: {(finished) -> Void in
                self.leftPanelContainer.isHidden = true
                self.rightPanelContainer.isHidden = true
                self.unloadPanelsFromView()
            })
        } else {
            centerPanelContainer.frame = centerPanelRestingFrame
//            styleContainer(container: centerPanelContainer, animate: false, duration: 0.0)

            if mode == .multipleActive || pushesSidePanels {
                layoutSideContainers(animate: false, duration: 0.0)
            }

            leftPanelContainer.isHidden = true
            rightPanelContainer.isHidden = true
            unloadPanelsFromView()
        }

        tapView = nil
        toggleScrollsToTopForCenter(center: true, left: false, right: false)
    }


    func hideCenterPanel() {
        DDLogInfo("")

        centerPanelContainer.isHidden = true

        if centerPanel.isViewLoaded {
            centerPanel.view.removeFromSuperview()
        }
    }


    func unhideCenterPanel() {
        DDLogInfo("")

        centerPanelContainer.isHidden = false

        if !(centerPanel.view.superview != nil) {
            centerPanel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            centerPanel.view.frame = centerPanelContainer.bounds
            stylePanel(panel: centerPanel.view)
            centerPanelContainer.addSubview(centerPanel.view)
        }
    }


    func toggleScrollsToTopForCenter(center: Bool, left: Bool, right: Bool) {
        DDLogInfo("")

        // iPhone only supports 1 active UIScrollViewController at a time
        if device.isPhone {
            _ = toggleScrollsToTop(enabled: center, forView: centerPanelContainer)
            _ = toggleScrollsToTop(enabled: left, forView: leftPanelContainer)
            _ = toggleScrollsToTop(enabled: right, forView: rightPanelContainer)
        }
    }


    func toggleScrollsToTop(enabled: Bool, forView view: UIView) -> Bool {
//        DDLogInfo("")

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
        DDLogInfo("")
        if context == ja_kvoContext {
            if keyPath! == "view" {
                if centerPanel.isViewLoaded && recognizesPanGesture {
                    _ = addPanGestureToView(view: centerPanel.view)
                }
            } else if keyPath! == "viewControllers" && object as? UIViewController == centerPanel {
                // view controllers have changed, need to replace the button
                placeButtonForLeftPanel()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }


    func setCenterPanelHidden(isHidden: Bool, animated: Bool, duration: TimeInterval) {
        DDLogInfo("")
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
