import Photos
import SwiftUI

/// All the photos taken on the chosen day in one earlier year.
struct YearGroup: Identifiable {
    let year: Int
    let yearsAgo: Int
    let assets: [PHAsset]

    var id: Int { year }
}

// PHAsset objects are safe to pass between threads, so tell Swift that's fine.
extension YearGroup: @unchecked Sendable {}

/// Talks to the iPhone's photo library: asks for permission and finds
/// the photos taken on the same month and day in every earlier year.
@MainActor
@Observable
final class PhotoLibrary {
    var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    var groups: [YearGroup] = []
    var isLoading = false
    var hasLoaded = false
    private var latestLoadID = 0

    /// Shows the system "Allow access to your photos?" prompt (only the first time).
    func requestAccess() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Re-reads the permission, e.g. after the user changed it in Settings.
    func refreshAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    var canReadPhotos: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    /// Loads every photo taken on the same month/day as `date`, in all years before this one.
    func loadPhotos(onSameDayAs date: Date) async {
        guard canReadPhotos else { return }
        latestLoadID += 1
        let loadID = latestLoadID
        isLoading = true
        // Searching the library can take a moment, so do it off the main thread
        // to keep the interface smooth.
        let result = await Task.detached(priority: .userInitiated) {
            PhotoLibrary.fetchGroups(onSameDayAs: date)
        }.value
        // If the user picked another day while we were searching, ignore this old result.
        guard loadID == latestLoadID else { return }
        groups = result
        isLoading = false
        hasLoaded = true
    }

    // MARK: - Searching the library

    nonisolated static func fetchGroups(onSameDayAs date: Date) -> [YearGroup] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // No need to look further back than the oldest photo in the library.
        guard let oldestYear = oldestPhotoYear(calendar: calendar), oldestYear < currentYear else {
            return []
        }

        var groups: [YearGroup] = []
        for year in stride(from: currentYear - 1, through: oldestYear, by: -1) {
            // Build midnight-to-midnight for that day. Skip days that don't exist
            // in that year (Feb 29 in a non-leap year would otherwise become Mar 1).
            guard
                let startOfDay = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                calendar.component(.month, from: startOfDay) == month,
                calendar.component(.day, from: startOfDay) == day,
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            else { continue }

            let options = PHFetchOptions()
            options.predicate = NSPredicate(
                format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
                PHAssetMediaType.image.rawValue,
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

            let fetchResult = PHAsset.fetchAssets(with: options)
            var assets: [PHAsset] = []
            assets.reserveCapacity(fetchResult.count)
            fetchResult.enumerateObjects { asset, _, _ in assets.append(asset) }

            if !assets.isEmpty {
                groups.append(YearGroup(year: year, yearsAgo: currentYear - year, assets: assets))
            }
        }
        return groups
    }

    private nonisolated static func oldestPhotoYear(calendar: Calendar) -> Int? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.fetchLimit = 1
        guard let oldestDate = PHAsset.fetchAssets(with: options).firstObject?.creationDate else {
            return nil
        }
        return calendar.component(.year, from: oldestDate)
    }
}
