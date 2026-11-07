import Photos
import SwiftUI

/// The main screen: "On this day" photos from every earlier year, newest year first.
struct ContentView: View {
    @State private var library = PhotoLibrary()
    @State private var selectedDate = Date()
    @State private var isShowingDatePicker = false
    @State private var selectedPhoto: PhotoSelection?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(selectedDate.formatted(.dateTime.month(.wide).day()))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingDatePicker = true
                        } label: {
                            Label("Choose Day", systemImage: "calendar")
                        }
                        .disabled(!library.canReadPhotos)
                    }
                }
        }
        .task {
            if library.authorizationStatus == .notDetermined {
                await library.requestAccess()
            }
            await library.loadPhotos(onSameDayAs: selectedDate)
        }
        .onChange(of: selectedDate) {
            Task { await library.loadPhotos(onSameDayAs: selectedDate) }
        }
        .onChange(of: scenePhase) {
            // Coming back to the app (maybe from Settings, maybe the next day): refresh.
            guard scenePhase == .active else { return }
            library.refreshAuthorizationStatus()
            Task { await library.loadPhotos(onSameDayAs: selectedDate) }
        }
        .sheet(isPresented: $isShowingDatePicker) {
            DayPickerSheet(selectedDate: $selectedDate)
        }
        .fullScreenCover(item: $selectedPhoto) { selection in
            PhotoDetailView(selection: selection)
        }
    }

    // MARK: - Screen states

    @ViewBuilder
    private var content: some View {
        switch library.authorizationStatus {
        case .notDetermined:
            ContentUnavailableView {
                Label("See Your Memories", systemImage: "photo.stack")
            } description: {
                Text("Time Capsule shows the photos you took on this day in previous years.")
            } actions: {
                Button("Allow Photo Access") {
                    Task {
                        await library.requestAccess()
                        await library.loadPhotos(onSameDayAs: selectedDate)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

        case .denied, .restricted:
            ContentUnavailableView {
                Label("No Photo Access", systemImage: "lock")
            } description: {
                Text("Allow access to your photos in Settings to see your memories.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

        default:
            photoList
        }
    }

    @ViewBuilder
    private var photoList: some View {
        if library.groups.isEmpty {
            if library.isLoading || !library.hasLoaded {
                ProgressView("Looking through your photos…")
            } else {
                ContentUnavailableView {
                    Label("No Memories", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("You didn't take any photos on \(selectedDate.formatted(.dateTime.month(.wide).day())) in earlier years.")
                } actions: {
                    Button("Choose Another Day") { isShowingDatePicker = true }
                }
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if library.authorizationStatus == .limited {
                        Text("You've shared only some of your photos with this app. You can change this in Settings › Privacy & Security › Photos.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    ForEach(library.groups) { group in
                        Section {
                            PhotoGrid(group: group) { index in
                                selectedPhoto = PhotoSelection(group: group, index: index)
                            }
                        } header: {
                            YearHeader(group: group)
                        }
                    }
                }
            }
            .refreshable {
                await library.loadPhotos(onSameDayAs: selectedDate)
            }
        }
    }
}

// MARK: - Pieces of the main screen

/// "3 years ago · 2023 — 12 photos"
private struct YearHeader: View {
    let group: YearGroup

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(group.yearsAgo == 1 ? "1 year ago" : "\(group.yearsAgo) years ago")
                .font(.title3.bold())
            Text(verbatim: String(group.year))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(group.assets.count == 1 ? "1 photo" : "\(group.assets.count) photos")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

/// A grid of square thumbnails, three per row.
private struct PhotoGrid: View {
    let group: YearGroup
    let onTap: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(group.assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                Button {
                    onTap(index)
                } label: {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay { AssetImage(asset: asset, contentMode: .fill) }
                        .clipped()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 16)
    }
}

/// Lets the user look at a day other than today.
private struct DayPickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Day", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
            .navigationTitle("Choose a Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Today") {
                        selectedDate = Date()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    ContentView()
}
