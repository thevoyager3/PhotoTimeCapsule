import Photos
import SwiftUI

/// Which photo the user tapped: the year it belongs to and its position in that year.
struct PhotoSelection: Identifiable {
    let group: YearGroup
    let index: Int

    var id: String { "\(group.year)-\(index)" }
}

/// Full-screen viewer. Swipe left and right to move between the photos of that year.
struct PhotoDetailView: View {
    let group: YearGroup
    @State private var index: Int
    @Environment(\.dismiss) private var dismiss

    init(selection: PhotoSelection) {
        group = selection.group
        _index = State(initialValue: selection.index)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(Array(group.assets.enumerated()), id: \.element.localIdentifier) { position, asset in
                    AssetImage(asset: asset, contentMode: .fit)
                        .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .status) {
                    Text(verbatim: "\(index + 1) of \(group.assets.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .toolbarBackground(.visible, for: .bottomBar)
            .toolbarColorScheme(.dark, for: .bottomBar)
        }
    }

    private var title: String {
        guard group.assets.indices.contains(index),
              let date = group.assets[index].creationDate else {
            return String(group.year)
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
