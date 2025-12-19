//
//  SearchResultViewController.swift
//  KurlyAssignment
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
    
    private let tableFooterActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let totalCountLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.estimatedRowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

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
        totalCountLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        let cellNib = UINib(nibName: "RepositoryCell", bundle: Bundle(for: RepositoryCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: RepositoryCell.reuseIdentifier)

        let stackView = UIStackView(arrangedSubviews: [totalCountLabel, tableView])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
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
}

extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.repositories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repo = viewModel.repositories[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: RepositoryCell.reuseIdentifier, for: indexPath)

        if let repositoryCell = cell as? RepositoryCell {
            repositoryCell.configure(with: repo)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(currentIndex: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
