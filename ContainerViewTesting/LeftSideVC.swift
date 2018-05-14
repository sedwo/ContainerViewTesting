import UIKit
import CocoaLumberjack
import Eureka
import DeviceKit
import SnapKit



class LeftSideVC: FormViewController {

    var tvColour = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    var cellColour = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
    var titleTag = "Left VC"

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogInfo("")

        navigationItem.title = titleTag


        let sec0 = Section(header: "", footer: "") { section in }
        form +++ sec0

        sec0 <<< LabelRow (titleTag) {
            $0.title = titleTag
            $0.value = "tap the row"
            } .onCellSelection { [unowned self] cell, row in
                row.title = (row.title ?? "") + " 👍 "
                row.reload() // or row.updateCell()

                self.navigationController?.pushViewController(LeftSideVC2(), animated: true)

            }.cellSetup { [unowned self] cell, row in
                cell.backgroundColor = self.cellColour
        }

        self.tableView.backgroundColor = tvColour

    }


    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)

    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        DDLogError("")
    }


    deinit {
        DDLogWarn("")
    }


}
