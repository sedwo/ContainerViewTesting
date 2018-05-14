import UIKit
import CocoaLumberjack
import FPSCounter



struct ScreenSize {
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sidePanelController: FAPanelController!
//    var sidePanelController: JASidePanelController!


    override init() {
        // MARK: - Defaults(...)

        super.init()

        // Enable 'XcodeColors' plugin for CocoaLumberjack  (unsigned Xcode only)
        setenv("XcodeColors", "YES", 0);    // https://github.com/robbiehanson/XcodeColors
        setupLoggingFramework()
        DDLogInfo("")
    }


    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = #colorLiteral(red: 1, green: 0.5212053061, blue: 1, alpha: 1)
        self.window?.tag = -1


        sidePanelController = FAPanelController()
        sidePanelController.configs.restrictPanningToTopVC = false
//        sidePanelController.configs.pusheSidePanels = true
        sidePanelController.configs.handleAutoRotation = false  // Leave it to iOS child VC management

        sidePanelController.configs.resizeLeftPanel = true
        sidePanelController.configs.resizeRightPanel = true

        sidePanelController.configs.leftPanelWidth = 0
        sidePanelController.configs.rightPanelWidth = 0
        sidePanelController.configs.leftPanelGapPercentage = 0.5
        sidePanelController.configs.rightPanelGapPercentage = 0.5

        sidePanelController.leftPanelPosition = .front
        sidePanelController.rightPanelPosition = .front

        DDLogVerbose("set left VC")
        _ = sidePanelController.left(UINavigationController(rootViewController: LeftSideVC()))

        DDLogVerbose("set center VC")
        _ = sidePanelController.center(UINavigationController(rootViewController: CenterVC()))

        DDLogVerbose("set right VC")
        _ = sidePanelController.right(UINavigationController(rootViewController: RightSideVC()))



/*
        sidePanelController = JASidePanelController()
        sidePanelController.panningLimitedToTopViewController = false
        sidePanelController.pushesSidePanels = true
        sidePanelController.shouldDelegateAutorotateToVisiblePanel = false  // Leave it to iOS child VC management

        DDLogVerbose("set left VC")
        _ = sidePanelController.leftPanel = UINavigationController(rootViewController: LeftSideVC())

        DDLogVerbose("set center VC")
        _ = sidePanelController.centerPanel = UINavigationController(rootViewController: CenterVC())

        DDLogVerbose("set right VC")
        _ = sidePanelController.rightPanel = UINavigationController(rootViewController: RightSideVC())
*/


        self.window?.rootViewController = sidePanelController
        self.window?.makeKeyAndVisible()



        DDLogInfo("")

        return true
    }



    // MARK: - Private

    private func setupLoggingFramework() {
        // console
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.logFormatter = MyCustomFormatter()

        DDTTYLogger.sharedInstance.colorsEnabled = true
        let pinkColour = UIColor(red: 255/255.0, green: 58/255.0, blue: 159/255.0, alpha: 1.0)
        DDTTYLogger.sharedInstance.setForegroundColor(pinkColour, backgroundColor: nil, for: DDLogFlag.error)
        DDTTYLogger.sharedInstance.setForegroundColor(UIColor.yellow, backgroundColor: nil, for: DDLogFlag.warning)
        DDTTYLogger.sharedInstance.setForegroundColor(UIColor.cyan, backgroundColor: nil, for: DDLogFlag.debug)
        DDTTYLogger.sharedInstance.setForegroundColor(UIColor.orange, backgroundColor: nil, for: DDLogFlag.verbose)

        // file
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.maximumFileSize = (1 * 1048576);   // ~1MB
        fileLogger.logFileManager.maximumNumberOfLogFiles = 50
        fileLogger.logFormatter = MyCustomFormatter()
        DDLog.add(fileLogger)
    }


}


// MARK: - DDLogFormatter
public class MyCustomFormatter: NSObject, DDLogFormatter {
    let dateFormmater = DateFormatter()

    public override init() {
        super.init()
        dateFormmater.dateFormat = "yyyy/MM/dd HH:mm:ss:SSS"
    }


    public func format(message logMessage: DDLogMessage) -> String? {

        let dt = dateFormmater.string(from: logMessage.timestamp)
        let file = logMessage.fileName

        // let functionName = (logMessage.function ?? "").isEmpty ? "<empty function>" : logMessage.function!
        let functionName = logMessage.function!
        let lineNumber = logMessage.line
        let logMsg = logMessage.message

        return "\(dt) [\(file):@\(lineNumber):\(functionName)] - \(logMsg)"
    }
}
