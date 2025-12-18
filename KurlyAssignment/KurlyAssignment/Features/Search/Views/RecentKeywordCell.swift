//
//  RecentKeywordCell.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/18/25.
//

import UIKit

final class RecentKeywordCell: UITableViewCell {
    static let reuseIdentifier = "RecentKeywordCell"

    var onTapDelete: (() -> Void)?

    @IBOutlet private weak var keywordLabel: UILabel!
    @IBOutlet private weak var deleteButton: UIButton!

    override func prepareForReuse() {
        super.prepareForReuse()
        keywordLabel.text = nil
        onTapDelete = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        deleteButton.setImage(UIImage(systemName: "x.circle.fill"), for: .normal)
        deleteButton.tintColor = .tertiaryLabel
        deleteButton.addAction(UIAction { [weak self] _ in
            self?.onTapDelete?()
        }, for: .touchUpInside)
    }

    func configure(keyword: String, onTapDelete: @escaping () -> Void) {
        keywordLabel.text = keyword
        self.onTapDelete = onTapDelete
    }
}

