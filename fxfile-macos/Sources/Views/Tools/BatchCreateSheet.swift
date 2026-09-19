import SwiftUI
import AboveDiffCore
import AboveDiffLocalization
import AboveDiffState

@MainActor
public struct BatchCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let targetDirectory: URL
    
    @State private var selectedTab: Int = 0 // 0 = Pattern, 1 = Text List
    
    // Pattern state
    @State private var baseNamePattern: String = "Item_###"
    @State private var createFolders: Bool = true
    @State private var fileExtension: String = "txt"
    @State private var startNumber: Int = 1
    @State private var countNumber: Int = 10
    @State private var digitPadding: Int = 3
    
    // Text List state
    @State private var textList: String = "FolderA\nFolderB\nFolderC/Subfolder\nNotes.txt"
    @State private var listCreateType: Int = 0 // 0 = Auto/Mixed, 1 = Folders only, 2 = Files only
    
    @State private var createdCount: Int = 0
    @State private var errorMessage: String? = nil
    
    public init(appState: AppState, targetDirectory: URL) {
        self.appState = appState
        self.targetDirectory = targetDirectory
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("batchcreate.title"))
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
            
            Picker("", selection: $selectedTab) {
                Text(L10n("batchcreate.pattern_tab")).tag(0)
                Text(L10n("batchcreate.list_tab")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                // By Pattern
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Target Folder:")
                            .frame(width: 120, alignment: .trailing)
                        Text(targetDirectory.path)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(L10n("batchcreate.type"))
                            .frame(width: 120, alignment: .trailing)
                        Picker("", selection: $createFolders) {
                            Text(L10n("batchcreate.type_folder")).tag(true)
                            Text(L10n("batchcreate.type_file")).tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        
                        if !createFolders {
                            Text("Ext:")
                            TextField("txt", text: $fileExtension)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    
                    HStack {
                        Text(L10n("batchcreate.pattern"))
                            .frame(width: 120, alignment: .trailing)
                        TextField("e.g. Document_###", text: $baseNamePattern)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Count & Range:")
                            .frame(width: 120, alignment: .trailing)
                        Stepper("Start: \(startNumber)", value: $startNumber, in: 0...99999)
                        Stepper("Count: \(countNumber)", value: $countNumber, in: 1...1000)
                        Stepper("Digits: \(digitPadding)", value: $digitPadding, in: 1...6)
                    }
                    
                    // Preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview:")
                            .font(.subheadline.bold())
                        
                        let previewList = generatePatternPreview()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(previewList, id: \.self) { name in
                                    Text(name)
                                        .font(.system(.caption, design: .monospaced))
                                }
                            }
                            .padding(8)
                        }
                        .frame(height: 120)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
            } else {
                // By Text List
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n("batchcreate.lines_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $textList)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 200)
                        .border(Color.secondary.opacity(0.3))
                }
                .padding(.horizontal)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            Spacer()
            
            Divider()
            
            // Footer
            HStack {
                Button(L10n("action.cancel")) {
                    dismiss()
                }
                
                Spacer()
                
                Button(L10n("batchcreate.create_btn")) {
                    executeCreation()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 540, minHeight: 440)
    }
    
    private func generatePatternPreview() -> [String] {
        var results: [String] = []
        for i in 0..<min(countNumber, 10) {
            let num = startNumber + i
            let numStr = String(format: "%0\(digitPadding)d", num)
            let base = baseNamePattern.replacingOccurrences(of: "###", with: numStr)
            let full = createFolders || fileExtension.isEmpty ? base : "\(base).\(fileExtension)"
            results.append(full)
        }
        if countNumber > 10 {
            results.append("... and \(countNumber - 10) more items")
        }
        return results
    }
    
    private func executeCreation() {
        let fm = FileManager.default
        do {
            if selectedTab == 0 {
                // By pattern
                for i in 0..<countNumber {
                    let num = startNumber + i
                    let numStr = String(format: "%0\(digitPadding)d", num)
                    let base = baseNamePattern.replacingOccurrences(of: "###", with: numStr)
                    let full = createFolders || fileExtension.isEmpty ? base : "\(base).\(fileExtension)"
                    let itemURL = targetDirectory.appendingPathComponent(full)
                    
                    if createFolders {
                        try fm.createDirectory(at: itemURL, withIntermediateDirectories: true)
                    } else {
                        fm.createFile(atPath: itemURL.path, contents: nil)
                    }
                }
            } else {
                // By text list
                let lines = textList.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                for line in lines {
                    let itemURL = targetDirectory.appendingPathComponent(line)
                    let parent = itemURL.deletingLastPathComponent()
                    if !fm.fileExists(atPath: parent.path) {
                        try fm.createDirectory(at: parent, withIntermediateDirectories: true)
                    }
                    
                    if line.hasSuffix("/") || (itemURL.pathExtension.isEmpty && !line.contains(".")) {
                        try fm.createDirectory(at: itemURL, withIntermediateDirectories: true)
                    } else {
                        fm.createFile(atPath: itemURL.path, contents: nil)
                    }
                }
            }
            
            appState.activePane.refresh()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
