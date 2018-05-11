import Foundation
import UIKit

extension UIViewController {
    func sidePanelController() -> JASidePanelController {
        var iter = self.parent
        while iter != nil {
            if iter is JASidePanelController {
                return (iter as! JASidePanelController)
            } else if iter!.parent! != iter {
                iter = iter!.parent!
            } else {
                iter = nil
            }
        }
        return JASidePanelController()
    }
}
