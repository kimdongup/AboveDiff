import Foundation

@MainActor
public enum ThreeWayCompareLauncher {
    public static func openCompare() {
        guard let selection =
            ThreeWayFilePicker.selectFiles(
                title: "Three-Way Compare"
            )
        else {
            return
        }

        ThreeWayDiffWindowPresenter.open(
            localURL: selection.localURL,
            baseURL: selection.baseURL,
            remoteURL: selection.remoteURL
        )
    }

    public static func openMerge() {
        guard let selection =
            ThreeWayFilePicker.selectFiles(
                title: "Three-Way Merge"
            )
        else {
            return
        }

        ThreeWayMergeWindowPresenter.open(
            localURL: selection.localURL,
            baseURL: selection.baseURL,
            remoteURL: selection.remoteURL
        )
    }
}
