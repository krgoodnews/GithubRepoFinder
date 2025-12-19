//
//  AsyncImageView.swift
//  KurlyAssignment
//
//  Created by Goodnews on 12/19/25.
//

#if canImport(UIKit)
import Foundation
import UIKit

@MainActor
@dynamicMemberLookup
public final class AsyncImageView: UIView {
    public var url: URL? {
        didSet {
            guard url != oldValue else { return }
            applyURLChange(from: oldValue, to: url)
        }
    }

    public var onStateChange: ((FetchingState<UIImage>) -> Void)?

    public var placeholder: UIImage? {
        didSet {
            guard url == nil else { return }
            imageView.image = placeholder
        }
    }

    public private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()

    private var fetchTask: Task<Void, Never>?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    deinit {
        fetchTask?.cancel()
    }

    private func configureViews() {
        addSubview(activityIndicatorView)
        addSubview(imageView)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),

            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        imageView.image = placeholder

        if let url {
            startFetch(for: url)
        }
    }

    private func applyURLChange(from oldURL: URL?, to newURL: URL?) {
        fetchTask?.cancel()
        fetchTask = nil

        activityIndicatorView.stopAnimating()

        guard let newURL else {
            imageView.image = placeholder
            onStateChange?(.idle)
            return
        }

        imageView.image = placeholder
        startFetch(for: newURL)
    }

    private func startFetch(for url: URL) {
        let requestedURL = url

        if let cached = ImageMemoryCache.shared.image(for: requestedURL) {
            imageView.image = cached
            onStateChange?(.fetched(cached))
            return
        }

        activityIndicatorView.startAnimating()
        onStateChange?(.fetching)

        fetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let image = try await Self.downloadImage(url: requestedURL)
                self.finishIfCurrent(url: requestedURL) {
                    ImageMemoryCache.shared.setImage(image, for: requestedURL)
                    self.imageView.image = image
                    self.onStateChange?(.fetched(image))
                }
            } catch is CancellationError {
                self.finishIfCurrent(url: requestedURL) {
                    self.onStateChange?(.idle)
                }
            } catch {
                self.finishIfCurrent(url: requestedURL) {
                    self.imageView.image = self.placeholder
                    self.onStateChange?(.error(message: error.localizedDescription))
                }
            }
        }
    }

    private func finishIfCurrent(url: URL, _ updates: @MainActor () -> Void) {
        guard !Task.isCancelled else { return }
        guard self.url == url else { return }

        activityIndicatorView.stopAnimating()
        updates()
    }

    private static func downloadImage(url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw AsyncImageViewError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw AsyncImageViewError.httpStatus(http.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw AsyncImageViewError.invalidImageData
        }

        return image
    }

    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<UIImageView, T>) -> T {
        get { imageView[keyPath: keyPath] }
        set { imageView[keyPath: keyPath] = newValue }
    }

    public func prepareForReuse() {
        url = nil
    }
}
#endif
