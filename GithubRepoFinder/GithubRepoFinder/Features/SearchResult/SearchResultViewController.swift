//
//  SearchResultViewController.swift
//  GithubRepoFinder
//
//  Created by Goodnews on 12/18/25.
//

import Combine
import UIKit

// MARK: - Search Results

final class SearchResultViewController: UIViewController {
    private let viewModel = RepositorySearchViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let querySubject = PassthroughSubject<String, Never>()
    private let imageLoader = ImageLoader.shared
    private enum Const {
        static let repositoryCellReuseIdentifier = "RepositoryCell"
        static let avatarSize: CGFloat = 40
    }
    
    private let tableFooterActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    @IBOutlet private weak var totalCountLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        configureViews()
        bind()
        bindQuery()
    }

    func update(keyword: String) {
        querySubject.send(keyword)
    }

    private func configureViews() {
        totalCountLabel.font = .preferredFont(forTextStyle: .headline)
        totalCountLabel.textColor = .secondaryLabel
        totalCountLabel.numberOfLines = 1

        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Const.repositoryCellReuseIdentifier)
    }

    private func bind() {
        viewModel.$totalCountText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.totalCountLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$repositories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isLoadingNextPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                self.updateTableFooterLoading(isLoading: isLoading)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self else { return }
                let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    private func bindQuery() {
        querySubject
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] keyword in
                guard let self else { return }
                self.viewModel.setKeyword(keyword)
            }
            .store(in: &cancellables)
    }
    
    private func updateTableFooterLoading(isLoading: Bool) {
        if isLoading {
            let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56))
            footer.addSubview(tableFooterActivityIndicator)
            
            NSLayoutConstraint.activate([
                tableFooterActivityIndicator.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
                tableFooterActivityIndicator.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
            ])
            
            tableView.tableFooterView = footer
            tableFooterActivityIndicator.startAnimating()
        } else {
            tableFooterActivityIndicator.stopAnimating()
            tableView.tableFooterView = UIView()
        }
    }

    private func openRepositoryURL(_ url: URL) {
        let webViewController = WebViewController(url: url)
        let navigationController = UINavigationController(rootViewController: webViewController)
        present(navigationController, animated: true)
    }
}

extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.repositories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repo = viewModel.repositories[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.repositoryCellReuseIdentifier, for: indexPath)
        cell.tag = repo.id

        var content = UIListContentConfiguration.subtitleCell()
        content.text = repo.name
        content.secondaryText = repo.owner.login

        content.image = UIImage(systemName: "photo")
        content.imageProperties.tintColor = .tertiaryLabel
        content.imageProperties.maximumSize = CGSize(width: Const.avatarSize, height: Const.avatarSize)
        content.imageProperties.reservedLayoutSize = CGSize(width: Const.avatarSize, height: Const.avatarSize)
        content.imageProperties.cornerRadius = Const.avatarSize / 2
        content.imageProperties.strokeColor = .tertiaryLabel.withAlphaComponent(0.5)
        content.imageProperties.strokeWidth = 0.5

        cell.contentConfiguration = content

        let expectedRepositoryID = repo.id
        let avatarURL = repo.owner.avatarURL

        Task { [weak self, weak cell] in
            guard let self else { return }
            guard let image = await self.imageLoader.loadImage(url: avatarURL) else { return }

            await MainActor.run {
                guard let cell else { return }
                guard cell.tag == expectedRepositoryID else { return }

                var updated = content
                updated.image = image
                cell.contentConfiguration = updated
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(currentIndex: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let repo = viewModel.repositories[indexPath.row]
        openRepositoryURL(repo.htmlURL)
    }
}
