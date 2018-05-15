import UIKit
import CocoaLumberjack
import Eureka
import DeviceKit
import SnapKit



class CenterVC: FormViewController {

    var tvColour = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
    var cellColour = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
    var titleTag = "Center VC"

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
