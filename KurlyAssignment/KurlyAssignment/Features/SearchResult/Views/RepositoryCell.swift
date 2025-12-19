//
//  RepositoryCell.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/19/25.
//

import UIKit

final class RepositoryCell: UITableViewCell {
    static let reuseIdentifier = "RepositoryCell"

    private enum Const {
        static let avatarSize: CGFloat = 40
    }
    
    @IBOutlet private weak var avatarView: AsyncImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
        avatarView.placeholder = UIImage(systemName: "photo")
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.imageView.layer.cornerRadius = Const.avatarSize / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    func configure(with repository: GitHubRepository) {
        titleLabel.text = repository.name
        subtitleLabel.text = repository.owner.login
        avatarView.url = repository.owner.avatarURL
    }
}
