import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct BatchRenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let initialFiles: [FileItem]
    
    @State private var selectedTab: Int = 0
    
    // Rule: Replace
    @State private var findText: String = ""
    @State private var replaceWithText: String = ""
    @State private var useRegex: Bool = false
    @State private var caseSensitive: Bool = false
    
    // Rule: Insert
    @State private var prefixText: String = ""
    @State private var suffixText: String = ""
    @State private var insertText: String = ""
    @State private var insertIndex: Int = 0
    
    // Rule: Delete
    @State private var deleteFromStart: Int = 0
    @State private var deleteFromEnd: Int = 0
    
    // Rule: Numbering
    @State private var numberPosition: NumberingPosition = .prefix
    @State private var startNumber: Int = 1
    @State private var stepNumber: Int = 1
    @State private var digitPadding: Int = 3
    
    // Rule: Case
    @State private var caseOption: RenameCaseOption = .lowercase
    
    // Rule: Extension
    @State private var newExtension: String = ""
    @State private var removeExtension: Bool = false
    @State private var lowercaseExtension: Bool = false
    
    @State private var previews: [RenamePreviewItem] = []
    @State private var errorMessage: String? = nil
    
    public init(appState: AppState, files: [FileItem]) {
        self.appState = appState
        self.initialFiles = files
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("rename.title"))
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
            
            // Rules Selector Tab
            Picker("", selection: $selectedTab) {
                Text(L10n("rename.rule.replace")).tag(0)
                Text(L10n("rename.rule.insert")).tag(1)
                Text(L10n("rename.rule.delete")).tag(2)
                Text(L10n("rename.rule.numbering")).tag(3)
                Text(L10n("rename.rule.case")).tag(4)
                Text(L10n("rename.rule.extension")).tag(5)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Rule Parameters View
            VStack(alignment: .leading, spacing: 10) {
                switch selectedTab {
                case 0:
                    // Replace
                    HStack {
                        Text(L10n("rename.find"))
                            .frame(width: 120, alignment: .trailing)
                        TextField("", text: $findText)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(L10n("rename.replace_with"))
                            .frame(width: 120, alignment: .trailing)
                        TextField("", text: $replaceWithText)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Spacer().frame(width: 120)
                        Toggle(L10n("rename.use_regex"), isOn: $useRegex)
                        Toggle(L10n("rename.case_sensitive"), isOn: $caseSensitive)
                    }
                    
                case 1:
                    // Insert
                    HStack {
                        Text(L10n("rename.prefix"))
                            .frame(width: 140, alignment: .trailing)
                        TextField("", text: $prefixText)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(L10n("rename.suffix"))
                            .frame(width: 140, alignment: .trailing)
                        TextField("", text: $suffixText)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(L10n("rename.insert_at"))
                            .frame(width: 140, alignment: .trailing)
                        TextField("Text", text: $insertText)
                            .textFieldStyle(.roundedBorder)
                        Stepper("Pos: \(insertIndex)", value: $insertIndex, in: 0...100)
                    }
                    
                case 2:
                    // Delete
                    HStack {
                        Text(L10n("rename.delete_from_start"))
                            .frame(width: 180, alignment: .trailing)
                        Stepper("\(deleteFromStart)", value: $deleteFromStart, in: 0...100)
                    }
                    HStack {
                        Text(L10n("rename.delete_from_end"))
                            .frame(width: 180, alignment: .trailing)
                        Stepper("\(deleteFromEnd)", value: $deleteFromEnd, in: 0...100)
                    }
                    
                case 3:
                    // Numbering
                    HStack {
                        Picker("Position:", selection: $numberPosition) {
                            Text("Prefix").tag(NumberingPosition.prefix)
                            Text("Suffix").tag(NumberingPosition.suffix)
                            Text("Replace").tag(NumberingPosition.replace)
                        }
                        .frame(width: 200)
                        
                        Stepper(L10n("rename.start_number") + " \(startNumber)", value: $startNumber, in: 0...99999)
                        Stepper(L10n("rename.step") + " \(stepNumber)", value: $stepNumber, in: 1...100)
                        Stepper(L10n("rename.digits") + " \(digitPadding)", value: $digitPadding, in: 1...8)
                    }
                    
                case 4:
                    // Case
                    Picker("Case:", selection: $caseOption) {
                        Text(L10n("rename.case_lower")).tag(RenameCaseOption.lowercase)
                        Text(L10n("rename.case_upper")).tag(RenameCaseOption.uppercase)
                        Text(L10n("rename.case_title")).tag(RenameCaseOption.titleCase)
                        Text(L10n("rename.case_capitalize")).tag(RenameCaseOption.capitalized)
                    }
                    .pickerStyle(.radioGroup)
                    .padding(.leading, 40)
                    
                case 5:
                    // Extension
                    HStack {
                        Text(L10n("rename.new_extension"))
                            .frame(width: 120, alignment: .trailing)
                        TextField("e.g. png, txt", text: $newExtension)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Spacer().frame(width: 120)
                        Toggle("Remove extension", isOn: $removeExtension)
                        Toggle("Lowercase extension", isOn: $lowercaseExtension)
                    }
                    
                default:
                    EmptyView()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Preview Table
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n("action.preview") + " (\(previews.count) \(L10n("status.items")))")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Table(previews) {
                    TableColumn(L10n("rename.original")) { item in
                        Text(item.originalFullName)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(L10n("rename.new")) { item in
                        Text(item.fullNewName)
                            .fontWeight(.medium)
                            .foregroundColor(item.hasConflict ? .red : .primary)
                    }
                    TableColumn(L10n("rename.status")) { item in
                        if item.hasConflict {
                            Text(item.errorMessage ?? "Conflict")
                                .foregroundColor(.red)
                                .font(.caption.bold())
                        } else {
                            Text("OK")
                                .foregroundColor(.green)
                                .font(.caption.bold())
                        }
                    }
                }
                .frame(minHeight: 220)
            }
            .padding(.top, 4)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Divider()
            
            // Footer Action Buttons
            HStack {
                Button(L10n("action.cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                let hasConflicts = previews.contains { $0.hasConflict }
                Button(L10n("rename.apply_button")) {
                    executeRename()
                }
                .buttonStyle(.borderedProminent)
                .disabled(hasConflicts || previews.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 680, minHeight: 520)
        .onAppear {
            updatePreview()
        }
        .onChange(of: selectedTab) { _ in updatePreview() }
        .onChange(of: findText) { _ in updatePreview() }
        .onChange(of: replaceWithText) { _ in updatePreview() }
        .onChange(of: useRegex) { _ in updatePreview() }
        .onChange(of: caseSensitive) { _ in updatePreview() }
        .onChange(of: prefixText) { _ in updatePreview() }
        .onChange(of: suffixText) { _ in updatePreview() }
        .onChange(of: insertText) { _ in updatePreview() }
        .onChange(of: insertIndex) { _ in updatePreview() }
        .onChange(of: deleteFromStart) { _ in updatePreview() }
        .onChange(of: deleteFromEnd) { _ in updatePreview() }
        .onChange(of: numberPosition) { _ in updatePreview() }
        .onChange(of: startNumber) { _ in updatePreview() }
        .onChange(of: stepNumber) { _ in updatePreview() }
        .onChange(of: digitPadding) { _ in updatePreview() }
        .onChange(of: caseOption) { _ in updatePreview() }
        .onChange(of: newExtension) { _ in updatePreview() }
        .onChange(of: removeExtension) { _ in updatePreview() }
        .onChange(of: lowercaseExtension) { _ in updatePreview() }
    }
    
    private func currentRules() -> [BatchRenameRule] {
        var rules: [BatchRenameRule] = []
        switch selectedTab {
        case 0:
            if !findText.isEmpty {
                if useRegex {
                    rules.append(.replaceRegex(pattern: findText, template: replaceWithText))
                } else {
                    rules.append(.replaceText(find: findText, replaceWith: replaceWithText, caseSensitive: caseSensitive))
                }
            }
        case 1:
            if !prefixText.isEmpty { rules.append(.addPrefix(prefix: prefixText)) }
            if !suffixText.isEmpty { rules.append(.addSuffix(suffix: suffixText)) }
            if !insertText.isEmpty { rules.append(.insertAt(text: insertText, index: insertIndex)) }
        case 2:
            if deleteFromStart > 0 { rules.append(.deleteRange(fromStart: 0, count: deleteFromStart)) }
            if deleteFromEnd > 0 { rules.append(.deleteFromEnd(count: deleteFromEnd)) }
        case 3:
            rules.append(.numbering(position: numberPosition, start: startNumber, step: stepNumber, digits: digitPadding))
        case 4:
            rules.append(.changeCase(option: caseOption))
        case 5:
            rules.append(.changeExtension(newExt: newExtension, remove: removeExtension, lowercase: lowercaseExtension))
        default:
            break
        }
        return rules
    }
    
    private func updatePreview() {
        let rules = currentRules()
        self.previews = BatchRenameEngine.shared.generatePreview(files: initialFiles, rules: rules)
    }
    
    private func executeRename() {
        do {
            _ = try BatchRenameEngine.shared.executeRename(previews: previews)
            appState.activePane.refresh()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
