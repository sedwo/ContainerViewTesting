import UIKit
import CocoaLumberjack
import Eureka
import DeviceKit
import SnapKit



class ViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogInfo("")

//        view.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
    }


    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)

        let sec0 = Section(header: "", footer: "") { section in }
        form +++ sec0

        var tvColour: UIColor
        var cellColour: UIColor

        if view.tag == 1 {
            tvColour = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
            cellColour = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        } else if view.tag == 2 {
            tvColour = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            cellColour = #colorLiteral(red: 0, green: 0.6035678983, blue: 1, alpha: 0.5)
        } else {
            tvColour = #colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1)
            cellColour = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        }

        self.tableView.backgroundColor = tvColour

        sec0 <<< LabelRow () {
            $0.title = "LabelRow"
            $0.value = "tap the row"
            } .onCellSelection { cell, row in
                row.title = (row.title ?? "") + " 👍 "
                row.reload() // or row.updateCell()
            }.cellSetup { cell, row in
                cell.backgroundColor = cellColour
        }





    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        DDLogError("")
    }


    deinit {
        DDLogWarn("")
    }


}
