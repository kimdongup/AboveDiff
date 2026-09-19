import SwiftUI
import AboveDiffCore
import AboveDiffLocalization
import AboveDiffState

@MainActor
public struct PreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @ObservedObject private var locManager = LocalizationManager.shared
    
    @AppStorage("abovediff_confirm_delete") private var confirmDelete: Bool = true
    @AppStorage("abovediff_show_hidden_global") private var showHidden: Bool = false
    @AppStorage("abovediff_calc_folder_sizes") private var calcFolderSizes: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("prefs.title"))
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            Form {
                Section(L10n("prefs.general")) {
                    Picker(L10n("prefs.language"), selection: $locManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle(L10n("prefs.confirm_delete"), isOn: $confirmDelete)
                    Toggle(L10n("prefs.show_hidden"), isOn: $showHidden)
                    Toggle(L10n("prefs.calc_folder_sizes"), isOn: $calcFolderSizes)
                }
                
                Section("Dual Pane Settings") {
                    Toggle("Enable Dual-Pane Mode on Start", isOn: $appState.dualPaneEnabled)
                    Picker("Split Orientation", selection: $appState.dualPaneOrientation) {
                        Text(L10n("view.split_horizontal")).tag(Axis.horizontal)
                        Text(L10n("view.split_vertical")).tag(Axis.vertical)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            HStack {
                Spacer()
                Button(L10n("action.close")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 480, minHeight: 380)
    }
}
