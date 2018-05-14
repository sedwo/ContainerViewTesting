import UIKit
import CocoaLumberjack
import Eureka
import DeviceKit
import SnapKit



class LeftSideVC2: FormViewController {

    var tvColour = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
    var cellColour = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
    var titleTag = "Left VC.2"

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogInfo("")

        navigationItem.title = titleTag
    }


    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)

        let sec0 = Section(header: "", footer: "") { section in }
        form +++ sec0

        sec0 <<< LabelRow (titleTag) {
            $0.title = titleTag
            $0.value = "tap the row"
            } .onCellSelection { [unowned self] cell, row in
                row.title = (row.title ?? "") + " 👍 "
                row.reload() // or row.updateCell()


            }.cellSetup { [unowned self] cell, row in
                cell.backgroundColor = self.cellColour
        }

        self.tableView.backgroundColor = tvColour


    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        DDLogError("")
    }


    deinit {
        DDLogWarn("")
    }


}
