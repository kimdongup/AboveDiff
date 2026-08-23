import SwiftUI
import AppKit
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct FileTableView: NSViewRepresentable {
    @ObservedObject var appState: AppState
    @ObservedObject var paneState: PaneState
    
    public init(appState: AppState, paneState: PaneState) {
        self.appState = appState
        self.paneState = paneState
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState, paneState: paneState)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        let tableView = FileNSTableView()
        tableView.appState = appState
        tableView.paneState = paneState
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(Coordinator.onRowDoubleClicked(_:))
        tableView.allowsMultipleSelection = true
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.headerView = NSTableHeaderView()
        tableView.rowHeight = 24
        tableView.intercellSpacing = NSSize(width: 8, height: 2)
        tableView.gridStyleMask = []
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        // Name Column
        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = L10n("column.name")
        nameCol.minWidth = 160
        nameCol.width = 240
        nameCol.sortDescriptorPrototype = NSSortDescriptor(key: "name", ascending: true)
        tableView.addTableColumn(nameCol)
        
        // Size Column
        let sizeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
        sizeCol.title = L10n("column.size")
        sizeCol.minWidth = 70
        sizeCol.width = 90
        sizeCol.sortDescriptorPrototype = NSSortDescriptor(key: "size", ascending: true)
        tableView.addTableColumn(sizeCol)
        
        // Kind Column
        let kindCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("kind"))
        kindCol.title = L10n("column.kind")
        kindCol.minWidth = 90
        kindCol.width = 130
        kindCol.sortDescriptorPrototype = NSSortDescriptor(key: "kind", ascending: true)
        tableView.addTableColumn(kindCol)
        
        // Date Modified Column
        let dateCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("dateModified"))
        dateCol.title = L10n("column.date_modified")
        dateCol.minWidth = 120
        dateCol.width = 145
        dateCol.sortDescriptorPrototype = NSSortDescriptor(key: "dateModified", ascending: true)
        tableView.addTableColumn(dateCol)
        
        // Permissions Column
        let permCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("permissions"))
        permCol.title = L10n("column.permissions")
        permCol.minWidth = 80
        permCol.width = 95
        permCol.sortDescriptorPrototype = NSSortDescriptor(key: "permissions", ascending: true)
        tableView.addTableColumn(permCol)
        
        scrollView.documentView = tableView
        context.coordinator.tableView = tableView
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tableView = nsView.documentView as? FileNSTableView else { return }
        context.coordinator.appState = appState
        context.coordinator.paneState = paneState
        tableView.appState = appState
        tableView.paneState = paneState
        
        // Update column header titles if language changed
        if let nameCol = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("name")) {
            nameCol.title = L10n("column.name")
        }
        if let sizeCol = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("size")) {
            sizeCol.title = L10n("column.size")
        }
        if let kindCol = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("kind")) {
            kindCol.title = L10n("column.kind")
        }
        if let dateCol = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("dateModified")) {
            dateCol.title = L10n("column.date_modified")
        }
        if let permCol = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("permissions")) {
            permCol.title = L10n("column.permissions")
        }
        
        let oldFiles = context.coordinator.cachedFiles
        let newFiles = paneState.files
        
        if oldFiles != newFiles {
            context.coordinator.cachedFiles = newFiles
            tableView.reloadData()
        }
        
        // Sync selection from paneState to tableView if needed
        context.coordinator.syncSelectionFromState(tableView: tableView)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    public final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var appState: AppState
        var paneState: PaneState
        var cachedFiles: [FileItem] = []
        weak var tableView: NSTableView?
        private var isSyncingSelection = false
        
        init(appState: AppState, paneState: PaneState) {
            self.appState = appState
            self.paneState = paneState
            self.cachedFiles = paneState.files
        }
        
        public func numberOfRows(in tableView: NSTableView) -> Int {
            paneState.files.count
        }
        
        public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row >= 0 && row < paneState.files.count else { return nil }
            let item = paneState.files[row]
            let colId = tableColumn?.identifier.rawValue ?? ""
            
            switch colId {
            case "name":
                let cellId = NSUserInterfaceItemIdentifier("FileNameCell")
                var cell = tableView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView
                if cell == nil {
                    cell = NSTableCellView()
                    cell?.identifier = cellId
                    
                    let imageView = NSImageView()
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    imageView.imageScaling = .scaleProportionallyUpOrDown
                    cell?.addSubview(imageView)
                    cell?.imageView = imageView
                    
                    let textField = NSTextField(labelWithString: "")
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    textField.lineBreakMode = .byTruncatingMiddle
                    cell?.addSubview(textField)
                    cell?.textField = textField
                    
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                        imageView.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 16),
                        imageView.heightAnchor.constraint(equalToConstant: 16),
                        
                        textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
                        textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                        textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
                    ])
                }
                
                cell?.imageView?.image = item.icon
                cell?.textField?.stringValue = item.name
                cell?.textField?.font = item.isDirectory ? .systemFont(ofSize: 12, weight: .semibold) : .systemFont(ofSize: 12)
                cell?.textField?.textColor = item.isHidden ? .secondaryLabelColor : .labelColor
                return cell
                
            case "size":
                return makeTextCell(tableView: tableView, identifier: "FileSizeCell", text: item.formattedSize, alignment: .right, isSecondary: true)
                
            case "kind":
                return makeTextCell(tableView: tableView, identifier: "FileKindCell", text: item.kind, alignment: .left, isSecondary: true)
                
            case "dateModified":
                return makeTextCell(tableView: tableView, identifier: "FileDateCell", text: item.formattedDate, alignment: .left, isSecondary: true)
                
            case "permissions":
                let cell = makeTextCell(tableView: tableView, identifier: "FilePermCell", text: item.permissionsString, alignment: .left, isSecondary: true)
                if let tf = (cell as? NSTableCellView)?.textField {
                    tf.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
                }
                return cell
                
            default:
                return nil
            }
        }
        
        private func makeTextCell(tableView: NSTableView, identifier: String, text: String, alignment: NSTextAlignment, isSecondary: Bool) -> NSView {
            let cellId = NSUserInterfaceItemIdentifier(identifier)
            var cell = tableView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView
            if cell == nil {
                cell = NSTableCellView()
                cell?.identifier = cellId
                
                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.lineBreakMode = .byTruncatingTail
                cell?.addSubview(textField)
                cell?.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
                ])
            }
            
            cell?.textField?.stringValue = text
            cell?.textField?.alignment = alignment
            cell?.textField?.font = .systemFont(ofSize: 12)
            cell?.textField?.textColor = isSecondary ? .secondaryLabelColor : .labelColor
            return cell!
        }
        
        public func tableViewSelectionDidChange(_ notification: Notification) {
            guard !isSyncingSelection, let tableView = notification.object as? NSTableView else { return }
            
            let selectedIndexes = tableView.selectedRowIndexes
            var newSelectedIDs = Set<UUID>()
            let files = paneState.files
            
            for index in selectedIndexes {
                if index >= 0 && index < files.count {
                    newSelectedIDs.insert(files[index].id)
                }
            }
            
            paneState.selectedItemIDs = newSelectedIDs
        }
        
        func syncSelectionFromState(tableView: NSTableView) {
            isSyncingSelection = true
            defer { isSyncingSelection = false }
            
            let currentSelected = paneState.selectedItemIDs
            var indexSet = IndexSet()
            let files = paneState.files
            
            for (idx, item) in files.enumerated() {
                if currentSelected.contains(item.id) {
                    indexSet.insert(idx)
                }
            }
            
            if tableView.selectedRowIndexes != indexSet {
                tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            }
        }
        
        @objc func onRowDoubleClicked(_ sender: NSTableView) {
            let row = sender.clickedRow >= 0 ? sender.clickedRow : sender.selectedRow
            guard row >= 0 && row < paneState.files.count else { return }
            let item = paneState.files[row]
            
            if item.isDirectory && !item.isPackage {
                paneState.navigateTo(url: item.url)
            } else {
                FileSystemService.shared.openWithDefaultApp(url: item.url)
            }
        }
        
        public func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard let descriptor = tableView.sortDescriptors.first, let key = descriptor.key else { return }
            
            switch key {
            case "name":
                paneState.sortField = .name
            case "size":
                paneState.sortField = .size
            case "kind":
                paneState.sortField = .kind
            case "dateModified":
                paneState.sortField = .dateModified
            case "permissions":
                paneState.sortField = .permissions
            default:
                break
            }
            paneState.sortAscending = descriptor.ascending
        }
    }
}

// MARK: - Custom NSTableView with Key Events & Context Menu

@MainActor
final class FileNSTableView: NSTableView {
    weak var appState: AppState?
    weak var paneState: PaneState?
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        // Set active pane immediately when clicked
        if let appState = appState, let paneState = paneState {
            if paneState === appState.leftPane {
                appState.activePaneIndex = 0
            } else if paneState === appState.rightPane {
                appState.activePaneIndex = 1
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        guard let paneState = paneState, let appState = appState else {
            super.keyDown(with: event)
            return
        }
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Return / Enter -> Open folder or file
        if event.keyCode == 36 || event.keyCode == 76 {
            let row = selectedRow
            if row >= 0 && row < paneState.files.count {
                let item = paneState.files[row]
                if item.isDirectory && !item.isPackage {
                    paneState.navigateTo(url: item.url)
                } else {
                    FileSystemService.shared.openWithDefaultApp(url: item.url)
                }
                return
            }
        }
        
        // Cmd + Down -> Open folder or file
        if flags == .command && event.keyCode == 125 {
            let row = selectedRow
            if row >= 0 && row < paneState.files.count {
                let item = paneState.files[row]
                if item.isDirectory && !item.isPackage {
                    paneState.navigateTo(url: item.url)
                } else {
                    FileSystemService.shared.openWithDefaultApp(url: item.url)
                }
                return
            }
        }
        
        // Cmd + Up -> Go up to parent folder
        if flags == .command && event.keyCode == 126 {
            paneState.goUp()
            return
        }
        
        // Backspace / Delete without Cmd -> If navigating, Backspace goes up
        if flags.isEmpty && event.keyCode == 51 {
            paneState.goUp()
            return
        }
        
        // Cmd + Backspace -> Move to Trash
        if flags == .command && event.keyCode == 51 {
            appState.deleteSelected(pane: paneState, permanently: false)
            return
        }
        
        // Option + Cmd + Backspace -> Permanent Delete
        if flags == [.command, .option] && event.keyCode == 51 {
            appState.deleteSelected(pane: paneState, permanently: true)
            return
        }
        
        // Spacebar -> Quick Look / Preview
        if event.keyCode == 49 && flags.isEmpty {
            let row = selectedRow
            if row >= 0 && row < paneState.files.count {
                let item = paneState.files[row]
                FileSystemService.shared.openWithDefaultApp(url: item.url)
                return
            }
        }
        
        // F2 -> Rename selected item
        if event.keyCode == 120 {
            if let first = paneState.selectedFiles.first {
                appState.activeToolSheet = .batchRename(files: [first])
                return
            }
        }
        
        // F5 or Cmd + 5 -> Copy to other pane
        if event.keyCode == 96 || (flags == .command && event.characters == "5") {
            appState.copyActiveToInactive()
            return
        }
        
        // F6 or Cmd + 6 -> Move to other pane
        if event.keyCode == 97 || (flags == .command && event.characters == "6") {
            appState.moveActiveToInactive()
            return
        }
        
        // Tab -> Switch pane
        if event.keyCode == 48 && flags.isEmpty {
            appState.switchActivePane()
            return
        }
        
        super.keyDown(with: event)
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let paneState = paneState, let appState = appState else { return nil }
        
        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        
        if row >= 0 && !selectedRowIndexes.contains(row) {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        
        let selectedFiles = paneState.selectedFiles
        guard !selectedFiles.isEmpty else {
            // Context menu for empty area
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: L10n("action.new_folder"), action: #selector(contextNewFolder), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: L10n("action.new_text_file"), action: #selector(contextNewFile), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: L10n("action.paste"), action: #selector(contextPaste), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: L10n("action.refresh"), action: #selector(contextRefresh), keyEquivalent: ""))
            return menu
        }
        
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: L10n("action.open"), action: #selector(contextOpen), keyEquivalent: "\r")
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem(title: L10n("action.show_in_finder"), action: #selector(contextRevealInFinder), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n("action.open_in_terminal"), action: #selector(contextOpenTerminal), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: L10n("action.copy"), action: #selector(contextCopy), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: L10n("action.cut"), action: #selector(contextCut), keyEquivalent: "x"))
        menu.addItem(NSMenuItem(title: L10n("action.paste"), action: #selector(contextPaste), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: L10n("action.duplicate"), action: #selector(contextDuplicate), keyEquivalent: "d"))
        
        if appState.dualPaneEnabled {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: L10n("action.copy_to_other_pane") + " (F5)", action: #selector(contextCopyToOtherPane), keyEquivalent: "5"))
            menu.addItem(NSMenuItem(title: L10n("action.move_to_other_pane") + " (F6)", action: #selector(contextMoveToOtherPane), keyEquivalent: "6"))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: L10n("action.batch_rename"), action: #selector(contextBatchRename), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: L10n("action.add_to_scrap"), action: #selector(contextAddToScrap), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n("action.calculate_checksum"), action: #selector(contextChecksum), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n("action.properties"), action: #selector(contextProperties), keyEquivalent: "i"))
        
        menu.addItem(NSMenuItem.separator())
        
        let trashItem = NSMenuItem(title: L10n("action.move_to_trash"), action: #selector(contextMoveToTrash), keyEquivalent: "\u{08}")
        menu.addItem(trashItem)
        
        let deleteItem = NSMenuItem(title: L10n("action.delete_permanently"), action: #selector(contextDeletePermanently), keyEquivalent: "")
        menu.addItem(deleteItem)
        
        return menu
    }
    
    // MARK: - Context Menu Actions
    
    @objc private func contextOpen() {
        guard let paneState = paneState, let item = paneState.selectedFiles.first else { return }
        if item.isDirectory && !item.isPackage {
            paneState.navigateTo(url: item.url)
        } else {
            FileSystemService.shared.openWithDefaultApp(url: item.url)
        }
    }
    
    @objc private func contextRevealInFinder() {
        guard let item = paneState?.selectedFiles.first else { return }
        FileSystemService.shared.revealInFinder(url: item.url)
    }
    
    @objc private func contextOpenTerminal() {
        guard let item = paneState?.selectedFiles.first else { return }
        FileSystemService.shared.openTerminal(at: item.url)
    }
    
    @objc private func contextCopy() {
        appState?.performCopy()
    }
    
    @objc private func contextCut() {
        appState?.performCut()
    }
    
    @objc private func contextPaste() {
        guard let paneState = paneState else { return }
        appState?.performPaste(in: paneState.currentURL)
    }
    
    @objc private func contextDuplicate() {
        guard let paneState = paneState else { return }
        for target in paneState.selectedFiles {
            _ = try? FileSystemService.shared.duplicateItem(at: target.url)
        }
        paneState.refresh()
    }
    
    @objc private func contextCopyToOtherPane() {
        appState?.copyActiveToInactive()
    }
    
    @objc private func contextMoveToOtherPane() {
        appState?.moveActiveToInactive()
    }
    
    @objc private func contextBatchRename() {
        guard let paneState = paneState, let appState = appState else { return }
        appState.activeToolSheet = .batchRename(files: paneState.selectedFiles)
    }
    
    @objc private func contextAddToScrap() {
        guard let paneState = paneState, let appState = appState else { return }
        appState.addToScrap(files: paneState.selectedFiles)
    }
    
    @objc private func contextChecksum() {
        guard let paneState = paneState, let appState = appState else { return }
        appState.activeToolSheet = .checksum(files: paneState.selectedFiles)
    }
    
    @objc private func contextProperties() {
        guard let paneState = paneState, let appState = appState, let first = paneState.selectedFiles.first else { return }
        appState.activeToolSheet = .fileProperties(file: first)
    }
    
    @objc private func contextMoveToTrash() {
        guard let paneState = paneState, let appState = appState else { return }
        appState.deleteSelected(pane: paneState, permanently: false)
    }
    
    @objc private func contextDeletePermanently() {
        guard let paneState = paneState, let appState = appState else { return }
        appState.deleteSelected(pane: paneState, permanently: true)
    }
    
    @objc private func contextNewFolder() {
        guard let paneState = paneState else { return }
        if let _ = try? FileSystemService.shared.createFolder(at: paneState.currentURL, name: "New Folder") {
            paneState.refresh()
        }
    }
    
    @objc private func contextNewFile() {
        guard let paneState = paneState else { return }
        if let _ = try? FileSystemService.shared.createTextFile(at: paneState.currentURL, name: "New File.txt") {
            paneState.refresh()
        }
    }
    
    @objc private func contextRefresh() {
        paneState?.refresh()
    }
}

extension FileItem {
    public var modificationDateTimestamp: Double {
        modificationDate?.timeIntervalSince1970 ?? 0
    }
}
