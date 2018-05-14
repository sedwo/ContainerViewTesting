import UIKit
import CocoaLumberjack
import DeviceKit
import SnapKit



extension JASidePanelController {

    // MARK: - Gesture Recognizer Delegate

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == tapView {
            DDLogVerbose("")
            return true
        } else if panningLimitedToTopViewController && !isOnTopLevelViewController(root: centerPanel) {
            return false
        } else if gestureRecognizer is UIPanGestureRecognizer {
            let pan = gestureRecognizer as! UIPanGestureRecognizer
            let translate = pan.translation(in: centerPanelContainer)

            // determine if right swipe is allowed
            if translate.x < 0 && !allowRightSwipe { return false }
            // determine if left swipe is allowed
            if translate.x > 0 && !allowLeftSwipe { return false  }

            let possible = translate.x != 0 && ((fabs(translate.y) / fabs(translate.x)) < 1.0)
            if possible && (
                (translate.x > 0 && leftPanel != nil) ||
                (translate.x < 0 && rightPanel != nil)
                ) {
                DDLogVerbose("")
                return true
            }
        }

        return false
    }


    func addPanGestureToView(view: UIView) -> UIPanGestureRecognizer {
        DDLogInfo("")
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
        DDLogInfo("")

        if sender is UIPanGestureRecognizer {
            let pan = sender as! UIPanGestureRecognizer
            if pan.state == .began {
                locationBeforePan = centerPanelContainer.frame.origin
            }

            let translate = pan.translation(in: centerPanelContainer)
            var frame = centerPanelRestingFrame
            frame.origin.x += round(correctMovement(movement: translate.x))

            if mode == .multipleActive {
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
            if mode == .multipleActive || pushesSidePanels {
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
        DDLogInfo("")

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
        DDLogInfo("")

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
        DDLogInfo("")

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(centerPanelTapped))
        view.addGestureRecognizer(tapGesture)

        return tapGesture
    }


    @objc func centerPanelTapped(gesture: UIGestureRecognizer) {
        DDLogInfo("")
        showCenterPanel(animated: true, bounce: false)
    }


    // MARK: - Internal Methods

    func correctMovement(movement: CGFloat) -> CGFloat {
        DDLogInfo("")

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
            } else if (mode == .multipleActive || pushesSidePanels) && position > 0.0 {
                return -centerPanelRestingFrame.origin.x
            } else if position > rightPanelContainer.frame.origin.x {
                return rightPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x
            }

        } else if state == .leftVisible && !allowLeftOverpan {
            if position > leftVisibleWidth {
                return 0.0
            } else if (mode == .multipleActive || pushesSidePanels) && position < 0.0 {
                return -centerPanelRestingFrame.origin.x
            } else if position < leftPanelContainer.frame.origin.x {
                return leftPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x
            }
        }

        return movement
    }


    func validateThreshold(movement: CGFloat) -> Bool {
        DDLogInfo("")

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
        DDLogInfo("")

        if root is UINavigationController {
            let nav = root as! UINavigationController
            return nav.viewControllers.count == 1
        } else if root is UITabBarController {
            let tab = root as! UITabBarController
            return isOnTopLevelViewController(root: tab.selectedViewController!)
        }

        return true
    }

}
