//
//  RecentKeywordCell.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
//

import UIKit

final class RecentKeywordCell: UITableViewCell {
    static let reuseIdentifier = "RecentKeywordCell"

    @IBOutlet private weak var keywordLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM.dd"
        return formatter
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        keywordLabel.text = nil
        dateLabel.text = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    func configure(keyword: String, searchedAt: Date?) {
        keywordLabel.text = keyword
        if let searchedAt {
            dateLabel.isHidden = false
            dateLabel.text = Self.dateFormatter.string(from: searchedAt)
        } else {
            dateLabel.isHidden = true
            dateLabel.text = nil
        }
    }
}

