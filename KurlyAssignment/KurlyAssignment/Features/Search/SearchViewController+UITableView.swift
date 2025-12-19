//
//  SearchViewController+UITableView.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/19/25.
//

import UIKit

// MARK: - UITableView

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    private static let searchedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = Const.searchedAtDateFormat
        return formatter
    }()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedKeywords.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard keywordListMode == .recent else { return nil }
        guard displayedKeywords.isEmpty == false else { return nil }

        let container = UIView()
        container.backgroundColor = .systemBackground

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "최근 검색"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12)
        ])

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard keywordListMode == .recent else { return .leastNonzeroMagnitude }
        return displayedKeywords.isEmpty ? .leastNonzeroMagnitude : 44
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard keywordListMode == .recent else { return nil }
        let item = displayedKeywords[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            self?.viewModel.deleteRecentKeyword(keyword: item.keyword)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = displayedKeywords[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.keywordCellReuseIdentifier, for: indexPath)
        cell.selectionStyle = .none

        var content = UIListContentConfiguration.valueCell()
        content.text = item.keyword
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.textProperties.color = .label

        switch keywordListMode {
        case .recent:
            content.secondaryText = nil
        case .autocomplete:
            content.secondaryText = Self.searchedAtFormatter.string(from: item.searchedAt)
            content.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
            content.secondaryTextProperties.color = .secondaryLabel
            content.prefersSideBySideTextAndSecondaryText = true
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = displayedKeywords[indexPath.row]
        viewModel.selectRecentKeyword(keyword: item.keyword)
    }
}
