import SwiftUI
import AboveDiffCore
import AboveDiffState

@MainActor
public struct GitIntegrationStatusView: View {
    @StateObject private var state =
        GitIntegrationState()

    public init() {}

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                Text("Git Mergetool")
                    .font(.headline)

                Spacer()

                Button("Refresh") {
                    state.refresh()
                }
                .disabled(
                    state.isRefreshing
                )
            }

            if state.isRefreshing {
                ProgressView()
            } else if let status =
                        state.status {
                statusContent(status)
            }

            if let message =
                state.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .task {
            state.refresh()
        }
    }

    private func statusContent(
        _ status:
            AboveDiffCore
            .GitMergetoolInstallStatus
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            statusRow(
                title:
                    "AboveDiff.app",
                ok:
                    status.appInstalled,
                detail:
                    status.appInstalled
                    ? "/Applications/AboveDiff.app"
                    : "Not installed"
            )

            statusRow(
                title:
                    "CLI",
                ok:
                    status.cliPath != nil,
                detail:
                    status.cliPath
                    ?? "abovediff not found in PATH"
            )

            statusRow(
                title:
                    "Git merge.tool",
                ok:
                    status.mergeToolName ==
                    "abovediff",
                detail:
                    status.mergeToolName
                    ?? "Not configured"
            )

            statusRow(
                title:
                    "trustExitCode",
                ok:
                    status.trustExitCode ==
                    true,
                detail:
                    status.trustExitCode
                    .map(String.init)
                    ?? "Not configured"
            )

            if status.isFullyConfigured {
                Label(
                    "AboveDiff is ready for git mergetool.",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .foregroundColor(.green)
                .padding(.top, 4)
            } else {
                Label(
                    "Git mergetool integration needs repair.",
                    systemImage:
                        "exclamationmark.triangle.fill"
                )
                .foregroundColor(.orange)
                .padding(.top, 4)
            }
        }
    }

    private func statusRow(
        title: String,
        ok: Bool,
        detail: String
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline
        ) {
            Image(
                systemName:
                    ok
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .foregroundColor(
                ok
                ? .green
                : .red
            )

            Text(title)
                .frame(
                    width: 120,
                    alignment: .leading
                )

            Text(detail)
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
                .textSelection(.enabled)
        }
    }
}
