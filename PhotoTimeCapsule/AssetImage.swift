import Photos
import SwiftUI

/// Shows one photo from the library, loading it at the size it is drawn on screen.
/// A blurry preview appears first and is replaced by the sharp version when ready.
/// Photos stored only in iCloud are downloaded automatically.
struct AssetImage: View {
    let asset: PHAsset
    var contentMode: ContentMode = .fill

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .task(id: geometry.size) {
                await load(pointSize: geometry.size)
            }
        }
    }

    private func load(pointSize: CGSize) async {
        guard pointSize.width > 0, pointSize.height > 0 else { return }
        let pixelSize = CGSize(width: pointSize.width * displayScale,
                               height: pointSize.height * displayScale)

        for await loaded in Self.images(for: asset, targetSize: pixelSize, contentMode: contentMode) {
            image = loaded
        }
    }

    /// Wraps the Photos image request in an async stream. The stream may deliver a
    /// low-quality image first and then the final one. Scrolling a cell off screen
    /// cancels the SwiftUI task, which cancels the request.
    private static func images(for asset: PHAsset,
                               targetSize: CGSize,
                               contentMode: ContentMode) -> AsyncStream<UIImage> {
        AsyncStream { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            let manager = PHImageManager.default()
            let requestID = manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode == .fill ? .aspectFill : .aspectFit,
                options: options
            ) { image, info in
                if let image {
                    continuation.yield(image)
                }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil
                if !isDegraded || isCancelled || hasError {
                    continuation.finish()
                }
            }

            continuation.onTermination = { _ in
                manager.cancelImageRequest(requestID)
            }
        }
    }
}
