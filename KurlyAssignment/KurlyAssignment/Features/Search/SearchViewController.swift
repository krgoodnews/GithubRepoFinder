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

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: resultsViewController)
        controller.searchBar.placeholder = "저장소 검색"
        controller.searchBar.returnKeyType = .search
        controller.searchBar.delegate = self
        controller.searchResultsUpdater = self
        return controller
    }()

    private let resultsViewController = SearchResultViewController()
    private let viewModel = SearchScreenViewModel()
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
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UINib(nibName: "RecentKeywordCell", bundle: Bundle(for: RecentKeywordCell.self)),
            forCellReuseIdentifier: RecentKeywordCell.reuseIdentifier
        )

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let footerView = makeTableFooterView()
        footerContainerView = footerView
        tableView.tableFooterView = footerView
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
            .sink { [weak self] _ in
                self?.tableView.reloadData()
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.recentKeywords[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentKeywordCell.reuseIdentifier, for: indexPath)

        if let keywordCell = cell as? RecentKeywordCell {
            keywordCell.configure(keyword: item.keyword) { [weak self] in
                self?.viewModel.deleteRecentKeyword(keyword: item.keyword)
            }
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
