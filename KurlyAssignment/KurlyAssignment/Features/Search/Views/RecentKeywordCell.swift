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

    private let keywordLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "x.circle.fill"), for: .normal)
        button.tintColor = .tertiaryLabel
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        configureViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        selectionStyle = .none
        configureViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        keywordLabel.text = nil
        onTapDelete = nil
    }

    func configure(keyword: String, onTapDelete: @escaping () -> Void) {
        keywordLabel.text = keyword
        self.onTapDelete = onTapDelete
    }

    private func configureViews() {
        keywordLabel.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(keywordLabel)
        contentView.addSubview(deleteButton)

        deleteButton.addAction(UIAction { [weak self] _ in
            self?.onTapDelete?()
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            keywordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            keywordLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            keywordLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -12),

            deleteButton.leadingAnchor.constraint(equalTo: keywordLabel.trailingAnchor, constant: 12),
            deleteButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

