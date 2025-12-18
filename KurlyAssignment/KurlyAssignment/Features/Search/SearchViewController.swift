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
    private let recentKeywordStore = RecentKeywordStore()
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

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecentKeywordCell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func bind() {
        recentKeywordStore.$recentKeywords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
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

        recentKeywordStore.add(keyword: keyword)
        setShowingSearchResults(true)
        resultsViewController.update(keyword: keyword)
        searchBar.resignFirstResponder()
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
        recentKeywordStore.recentKeywords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentKeywordCell", for: indexPath)
        let item = recentKeywordStore.recentKeywords[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.keyword
        cell.contentConfiguration = content
        cell.selectionStyle = .none

        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "x.circle.fill", withConfiguration: symbolConfig), for: .normal)
        button.tintColor = .secondaryLabel
        button.accessibilityLabel = "최근 검색어 삭제"
        button.addAction(
            UIAction { [weak self] _ in
                self?.recentKeywordStore.remove(keyword: item.keyword)
            },
            for: .touchUpInside
        )
        cell.accessoryView = button

        return cell
    }
}
