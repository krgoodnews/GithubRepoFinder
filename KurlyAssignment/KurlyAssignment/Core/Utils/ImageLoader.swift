//
//  ImageLoader.swift
//  KurlyAssignment
//
//  Created by Cursor on 12/19/25.
//

import Foundation
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private init() {}

    func loadImage(url: URL) async -> UIImage? {
        if let cached = ImageMemoryCache.shared.image(for: url) {
            return cached
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }

            guard let image = UIImage(data: data) else {
                return nil
            }

            ImageMemoryCache.shared.setImage(image, for: url)
            return image
        } catch {
            return nil
        }
    }
}
