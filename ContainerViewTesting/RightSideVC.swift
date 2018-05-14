import UIKit
import CocoaLumberjack
import Eureka
import DeviceKit
import SnapKit



class RightSideVC: FormViewController {

    var tvColour = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
    var cellColour = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
    var titleTag = "Right VC"

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
