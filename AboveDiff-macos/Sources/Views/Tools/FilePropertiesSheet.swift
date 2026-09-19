import SwiftUI
import AboveDiffCore
import AboveDiffLocalization

@MainActor
public struct FilePropertiesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let file: FileItem
    
    public init(file: FileItem) {
        self.file = file
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(nsImage: file.icon)
                    .resizable()
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.title3.bold())
                        .textSelection(.enabled)
                    Text(file.kind)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // General Section
                    Group {
                        Text(L10n("properties.general"))
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        propRow(label: L10n("properties.path"), value: file.path, isCopyable: true)
                        propRow(label: L10n("properties.size"), value: "\(file.formattedSize) (\(file.size) bytes)")
                        if let count = file.childCount {
                            propRow(label: "Contents:", value: "\(count) items inside")
                        }
                    }
                    
                    Divider()
                    
                    // Timestamps Section
                    Group {
                        Text("Timestamps")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        propRow(label: L10n("properties.created"), value: file.formattedCreationDate)
                        propRow(label: L10n("properties.modified"), value: file.formattedDate)
                        propRow(label: L10n("properties.accessed"), value: file.formattedAccessDate)
                    }
                    
                    Divider()
                    
                    // Permissions & Ownership Section
                    Group {
                        Text("Security & Permissions")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        propRow(label: L10n("properties.owner"), value: file.ownerName.isEmpty ? "Current User" : file.ownerName)
                        propRow(label: L10n("properties.group"), value: file.groupName.isEmpty ? "Staff" : file.groupName)
                        propRow(label: L10n("properties.permissions"), value: file.permissionsString)
                        propRow(label: L10n("properties.octal"), value: file.octalPermissionsString)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Reveal in Finder") {
                    FileSystemService.shared.revealInFinder(url: file.url)
                }
                
                Button("Open in Terminal") {
                    FileSystemService.shared.openTerminal(at: file.url)
                }
                
                Spacer()
                
                Button(L10n("action.close")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 460)
    }
    
    @ViewBuilder
    private func propRow(label: String, value: String, isCopyable: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.body.bold())
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .trailing)
            
            Text(value)
                .font(.body)
                .textSelection(.enabled)
            
            if isCopyable {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
}
