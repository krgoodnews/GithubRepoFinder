//
//  SearchViewController.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import UIKit

/// 검색 화면
final class SearchViewController: UIViewController {

    // MARK: - UI Component

    private var footerContainerView: UIView?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIStackView!
//    private let emptyView: UIView = {
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = "검색어를 입력해주세요"
//        label.textColor = .secondaryLabel
//        label.font = .preferredFont(forTextStyle: .body)
//        label.textAlignment = .center
//        label.numberOfLines = 0
//
//        container.addSubview(label)
//
//        NSLayoutConstraint.activate([
//            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
//            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
//            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
//        ])
//
//        return container
//    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: resultsViewController)
        controller.searchBar.placeholder = "저장소 검색"
        controller.searchBar.returnKeyType = .search
        controller.searchBar.delegate = self
        controller.searchResultsUpdater = self
        return controller
    }()

    private let resultsViewController = SearchResultViewController()
    private let viewModel = SearchHomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search"

        configureTableView()
        configureSearchController()
        bind()

        // 초기 진입 시(검색어 없음) 최근 검색어 노출
        setShowingSearchResults(false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let footerContainerView else { return }
        if footerContainerView.frame.width != tableView.bounds.width {
            footerContainerView.frame.size.width = tableView.bounds.width
            tableView.tableFooterView = footerContainerView
        }
    }

    private func configureTableView() {
        // NOTE: tableView/emptyView는 스토리보드에서 레이아웃을 잡습니다.
        // (addSubview/constraints를 코드에서 다시 만들면 스토리보드 제약이 깨지거나 충돌할 수 있음)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(
            UINib(nibName: "RecentKeywordCell", bundle: Bundle(for: RecentKeywordCell.self)),
            forCellReuseIdentifier: RecentKeywordCell.reuseIdentifier
        )

        let footerView = makeTableFooterView()
        footerContainerView = footerView
        tableView.tableFooterView = footerView

        // 최초 진입 시에도 상태가 맞도록 1회 반영(Combine 초기 emit이 안 오는 케이스 방어)
        let hasKeywords = viewModel.recentKeywords.isEmpty == false
        tableView.isHidden = !hasKeywords
        emptyView.isHidden = hasKeywords
    }

    private func makeTableFooterView() -> UIView {
        let footerHeight: CGFloat = 56
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: footerHeight))

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        var title = AttributedString("전체 삭제")
        title.font = .preferredFont(forTextStyle: .callout)
        configuration.attributedTitle = title
        configuration.baseForegroundColor = .systemRed
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        button.configuration = configuration
        button.addAction(UIAction { [weak self] _ in
            self?.viewModel.deleteAllRecentKeywords()
        }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    private func configureSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func bind() {
        viewModel.recentKeywordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keywords in
                guard let self else { return }
                let hasKeywords = keywords.isEmpty == false

                self.tableView.isHidden = !hasKeywords
                self.emptyView.isHidden = hasKeywords

                self.tableView.tableFooterView = self.footerContainerView

                self.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.output.showSearchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keyword in
                self?.showSearchResults(keyword: keyword)
            }
            .store(in: &cancellables)
    }

    private func setShowingSearchResults(_ isShowing: Bool) {
        // iOS 15+에서 제공되는 API로, 결과 컨트롤러 노출 여부를 제어할 수 있습니다.
        searchController.showsSearchResultsController = isShowing
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let keyword = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return }

        viewModel.submitSearch(keyword: keyword)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setShowingSearchResults(false)
        resultsViewController.update(keyword: "")
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let keyword = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if keyword.isEmpty {
            setShowingSearchResults(false)
            resultsViewController.update(keyword: "")
        } else {
            setShowingSearchResults(true)
            resultsViewController.update(keyword: keyword)
        }
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.recentKeywords.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel.recentKeywords.isEmpty == false else { return nil }

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
        viewModel.recentKeywords.isEmpty ? .leastNonzeroMagnitude : 44
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = viewModel.recentKeywords[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            self?.viewModel.deleteRecentKeyword(keyword: item.keyword)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.recentKeywords[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentKeywordCell.reuseIdentifier, for: indexPath)

        if let keywordCell = cell as? RecentKeywordCell {
            keywordCell.configure(keyword: item.keyword)
            return keywordCell
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = viewModel.recentKeywords[indexPath.row]
        viewModel.selectRecentKeyword(keyword: item.keyword)
    }
}

extension SearchViewController {
    private func showSearchResults(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        searchController.searchBar.text = trimmed
        searchController.isActive = true
        setShowingSearchResults(true)
        resultsViewController.update(keyword: trimmed)
        searchController.searchBar.resignFirstResponder()
    }
}
