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
    var sidePanelController: JASidePanelController!


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
        self.window?.backgroundColor = UIColor.darkGray



        sidePanelController = JASidePanelController()
        sidePanelController.shouldDelegateAutorotateToVisiblePanel = false
        sidePanelController.panningLimitedToTopViewController = false



        let vc1 = ViewController()
        vc1.view.tag = 2
        sidePanelController.centerPanel = vc1

        let vc2 = ViewController()
        vc2.view.tag = 1
        sidePanelController.leftPanel = vc2

        let vc3 = ViewController()
        vc3.view.tag = 3
        sidePanelController.rightPanel = vc3

        self.window?.rootViewController = sidePanelController
        self.window?.makeKeyAndVisible()



        // if iPad
//        sidePanelController.style = .multipleActive
/*
        sidePanelController.allowLeftSwipe = false
        sidePanelController.allowRightSwipe = false
        sidePanelController.recognizesPanGesture = false

//        sidePanelController.leftPanelContainer.isUserInteractionEnabled = true
//        sidePanelController.centerPanelContainer.isUserInteractionEnabled = true
//        sidePanelController.rightPanelContainer.isUserInteractionEnabled = true

        sidePanelController.leftGapPercentage = 0.35
        sidePanelController.rightGapPercentage = sidePanelController!.leftGapPercentage

        sidePanelController.showLeftPanel(animated: true)
        sidePanelController.showRightPanel(animated: true)
*/

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
