//
//  RecentKeywordCell.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/18/25.
//

import UIKit

final class RecentKeywordCell: UITableViewCell {
    static let reuseIdentifier = "RecentKeywordCell"

    @IBOutlet private weak var keywordLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        keywordLabel.text = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    func configure(keyword: String) {
        keywordLabel.text = keyword
    }
}

