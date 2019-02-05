//
//  TodoTableViewCell.swift
//  Todoey
//
//  Created by Angel Solorio on 2/3/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import SwipeCellKit
import BEMCheckBox

protocol TodoCellDelegate {
    func checkBoxTapped(cell: TodoTableViewCell)
}


class TodoTableViewCell: SwipeTableViewCell, BEMCheckBoxDelegate {
    var checkBoxDelegate: TodoCellDelegate?
    var itemIndex: Int = -1

    @IBOutlet weak var checkBox: BEMCheckBox!
    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        checkBox.delegate = self
        checkBox.backgroundColor = .clear
        checkBox.boxType = .circle
        checkBox.onAnimationType = .fade
    }


    // MARK: - BEMCheckBox Delegate Methods

    func didTap(_ checkBox: BEMCheckBox) {
        checkBoxDelegate?.checkBoxTapped(cell: self)
    }
}
