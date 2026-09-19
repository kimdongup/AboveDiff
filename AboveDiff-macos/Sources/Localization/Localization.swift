import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case korean = "ko"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @AppStorage("abovediff_app_language") public var currentLanguage: AppLanguage = .english {
        didSet {
            objectWillChange.send()
        }
    }
    
    public init() {}
    
    public func string(_ key: String) -> String {
        if let table = localizedStrings[currentLanguage], let val = table[key] {
            return val
        }
        if let defaultTable = localizedStrings[.english], let val = defaultTable[key] {
            return val
        }
        return key
    }
}

public func L10n(_ key: String) -> String {
    return LocalizationManager.shared.string(key)
}

private let localizedStrings: [AppLanguage: [String: String]] = [
    .english: [
        // App
        "app.name": "AboveDiff",
        "app.tagline": "Advanced Dual-Pane File Manager for macOS",
        
        // Navigation & Menu
        "menu.file": "File",
        "menu.edit": "Edit",
        "menu.view": "View",
        "menu.go": "Go",
        "menu.tools": "Tools",
        "menu.window": "Window",
        "menu.help": "Help",
        "menu.preferences": "Preferences...",
        "menu.about": "About AboveDiff",
        "menu.quit": "Quit AboveDiff",
        
        // Actions
        "action.open": "Open",
        "action.open_with": "Open With...",
        "action.show_in_finder": "Show in Finder",
        "action.open_in_terminal": "Open in Terminal",
        "action.quick_look": "Quick Look",
        "action.cut": "Cut",
        "action.copy": "Copy",
        "action.paste": "Paste",
        "action.duplicate": "Duplicate",
        "action.rename": "Rename",
        "action.delete": "Delete",
        "action.move_to_trash": "Move to Trash",
        "action.delete_permanently": "Delete Permanently",
        "action.new_folder": "New Folder",
        "action.new_file": "New File",
        "action.new_tab": "New Tab",
        "action.close_tab": "Close Tab",
        "action.properties": "Get Info",
        "action.refresh": "Refresh",
        "action.select_all": "Select All",
        "action.invert_selection": "Invert Selection",
        "action.copy_path": "Copy Path",
        "action.copy_to_other_pane": "Copy to Other Pane",
        "action.move_to_other_pane": "Move to Other Pane",
        "action.add_to_scrap": "Add to Scrap Basket",
        "action.calculate_checksum": "Calculate Checksum",
        "action.batch_rename": "Batch Rename...",
        "action.search": "Search Files...",
        "action.sync_folders": "Synchronize Folders...",
        "action.split_join": "Split & Join Files...",
        "action.batch_create": "Batch Create...",
        "action.scrap_basket": "File Scrap Basket",
        "action.cancel": "Cancel",
        "action.apply": "Apply",
        "action.ok": "OK",
        "action.close": "Close",
        "action.save": "Save",
        "action.clear": "Clear",
        "action.start": "Start",
        "action.stop": "Stop",
        "action.compare": "Compare",
        "action.preview": "Preview",
        "action.execute": "Execute",
        
        // Function keys (Norton Commander style)
        "fkey.f2": "F2 Rename",
        "fkey.f3": "F3 View",
        "fkey.f4": "F4 Edit",
        "fkey.f5": "F5 Copy",
        "fkey.f6": "F6 Move",
        "fkey.f7": "F7 NewFolder",
        "fkey.f8": "F8 Delete",
        
        // Sidebar
        "sidebar.favorites": "Favorites",
        "sidebar.locations": "Locations",
        "sidebar.volumes": "Volumes",
        "sidebar.bookmarks": "Bookmarks",
        "sidebar.home": "Home",
        "sidebar.desktop": "Desktop",
        "sidebar.documents": "Documents",
        "sidebar.downloads": "Downloads",
        "sidebar.applications": "Applications",
        "sidebar.pictures": "Pictures",
        "sidebar.music": "Music",
        "sidebar.movies": "Movies",
        "sidebar.trash": "Trash",
        "sidebar.computer": "Computer",
        "sidebar.network": "Network",
        "sidebar.add_favorite": "Add Current to Favorites",
        "sidebar.remove_favorite": "Remove from Favorites",
        "sidebar.add_bookmark": "Add Current to Bookmarks",
        "sidebar.remove_bookmark": "Remove Bookmark",
        
        // Columns
        "column.name": "Name",
        "column.size": "Size",
        "column.kind": "Kind",
        "column.date_modified": "Date Modified",
        "column.permissions": "Permissions",
        "column.owner": "Owner",
        "column.extension": "Extension",
        
        // View modes & Layout
        "view.table": "Table",
        "view.grid": "Icons",
        "view.list": "List",
        "view.single_pane": "Single Pane",
        "view.dual_pane": "Dual Pane",
        "view.split_horizontal": "Horizontal Split",
        "view.split_vertical": "Vertical Split",
        "view.show_hidden": "Show Hidden Files",
        "view.hide_hidden": "Hide Hidden Files",
        
        // Tools: Batch Rename
        "rename.title": "Batch Rename",
        "rename.rule.replace": "Replace",
        "rename.rule.insert": "Insert",
        "rename.rule.delete": "Delete",
        "rename.rule.numbering": "Numbering",
        "rename.rule.case": "Case",
        "rename.rule.extension": "Extension",
        "rename.find": "Find Text:",
        "rename.replace_with": "Replace With:",
        "rename.use_regex": "Use Regular Expressions",
        "rename.case_sensitive": "Case Sensitive",
        "rename.prefix": "Prefix:",
        "rename.suffix": "Suffix:",
        "rename.insert_at": "Insert at Position:",
        "rename.delete_from_start": "Delete from start (chars):",
        "rename.delete_from_end": "Delete from end (chars):",
        "rename.start_number": "Start Number:",
        "rename.step": "Step:",
        "rename.digits": "Digits (Padding):",
        "rename.case_lower": "lowercase",
        "rename.case_upper": "UPPERCASE",
        "rename.case_title": "Title Case",
        "rename.case_capitalize": "Capitalize",
        "rename.new_extension": "New Extension:",
        "rename.original": "Original Name",
        "rename.new": "New Name",
        "rename.status": "Status",
        "rename.apply_button": "Rename Files",
        
        // Tools: Checksum
        "checksum.title": "Checksum & Hashes",
        "checksum.file": "Target File:",
        "checksum.algorithm": "Algorithm:",
        "checksum.calculate": "Calculate",
        "checksum.verify": "Verify Hash:",
        "checksum.match": "Hash matches perfectly!",
        "checksum.mismatch": "Hash does NOT match!",
        "checksum.copy": "Copy Hash",
        "checksum.export_sfv": "Export .sfv / .md5",
        
        // Tools: Split & Join
        "splitjoin.title": "File Split & Join",
        "splitjoin.tab_split": "Split File",
        "splitjoin.tab_join": "Join Files",
        "splitjoin.source_file": "Source File:",
        "splitjoin.chunk_size": "Chunk Size:",
        "splitjoin.output_folder": "Output Directory:",
        "splitjoin.split_btn": "Start Split",
        "splitjoin.first_part": "First Part File (.001):",
        "splitjoin.join_btn": "Start Join",
        "splitjoin.parts_found": "Parts Detected:",
        
        // Tools: Directory Sync
        "sync.title": "Directory Synchronization",
        "sync.source": "Source Folder:",
        "sync.target": "Target Folder:",
        "sync.direction": "Sync Direction:",
        "sync.dir_source_to_target": "Source -> Target (Update)",
        "sync.dir_mirror": "Source -> Target (Mirror)",
        "sync.dir_bidirectional": "Two-Way Bidirectional",
        "sync.include_subfolders": "Include Subfolders",
        "sync.status_missing": "Missing in Target",
        "sync.status_newer": "Newer in Source",
        "sync.status_older": "Older in Source",
        "sync.status_equal": "Equal",
        "sync.start_btn": "Synchronize Now",
        
        // Tools: File Search
        "search.title": "Advanced File Search",
        "search.search_in": "Search In:",
        "search.file_name": "File Name Pattern:",
        "search.content": "Containing Text:",
        "search.size_min": "Min Size:",
        "search.size_max": "Max Size:",
        "search.date_range": "Modified Date:",
        "search.results_count": "Results found:",
        "search.searching": "Searching...",
        
        // Tools: File Scrap
        "scrap.title": "File Scrap Basket",
        "scrap.empty": "The Scrap Basket is empty. Drop files here or use 'Add to Scrap Basket'.",
        "scrap.copy_all": "Copy All to Active Pane",
        "scrap.move_all": "Move All to Active Pane",
        "scrap.clear_all": "Clear Basket",
        
        // Tools: Batch Create
        "batchcreate.title": "Batch Create Files & Folders",
        "batchcreate.pattern_tab": "By Pattern",
        "batchcreate.list_tab": "From Text List",
        "batchcreate.pattern": "Name Pattern:",
        "batchcreate.type": "Type:",
        "batchcreate.type_folder": "Folders",
        "batchcreate.type_file": "Files",
        "batchcreate.lines_hint": "Enter one file/folder name per line. Paths with slashes create subfolders.",
        "batchcreate.create_btn": "Create Items",
        
        // Tools: Properties
        "properties.title": "File Info & Properties",
        "properties.general": "General",
        "properties.path": "Path:",
        "properties.size": "Size on Disk:",
        "properties.created": "Created:",
        "properties.modified": "Modified:",
        "properties.accessed": "Last Accessed:",
        "properties.permissions": "Permissions:",
        "properties.owner": "Owner:",
        "properties.group": "Group:",
        "properties.octal": "POSIX Octal:",
        
        // Preferences
        "prefs.title": "Preferences",
        "prefs.general": "General",
        "prefs.language": "Language:",
        "prefs.appearance": "Appearance:",
        "prefs.confirm_delete": "Confirm before deleting files",
        "prefs.show_hidden": "Show hidden files by default",
        "prefs.default_startup": "Startup Directory:",
        "prefs.calc_folder_sizes": "Calculate directory sizes",
        
        // Status & Messages
        "status.items": "items",
        "status.selected": "selected",
        "status.free": "Free",
        "status.loading": "Loading...",
        "prompt.new_folder": "Enter folder name:",
        "prompt.new_file": "Enter file name:",
        "prompt.rename": "Enter new name:",
        "dialog.confirm_delete_title": "Confirm Delete",
        "dialog.confirm_delete_msg": "Are you sure you want to permanently delete the selected item(s)?",
        "dialog.confirm_trash_msg": "Move selected item(s) to Trash?",
        "error.generic": "An error occurred: "
    ],
    .korean: [
        // App
        "app.name": "AboveDiff",
        "app.tagline": "macOS용 고급 듀얼 패널 파일 관리자",
        
        // Navigation & Menu
        "menu.file": "파일",
        "menu.edit": "편집",
        "menu.view": "보기",
        "menu.go": "이동",
        "menu.tools": "도구",
        "menu.window": "윈도우",
        "menu.help": "도움말",
        "menu.preferences": "환경설정...",
        "menu.about": "AboveDiff 정보",
        "menu.quit": "AboveDiff 종료",
        
        // Actions
        "action.open": "열기",
        "action.open_with": "다음으로 열기...",
        "action.show_in_finder": "Finder에서 보기",
        "action.open_in_terminal": "터미널에서 열기",
        "action.quick_look": "훑어보기 (Quick Look)",
        "action.cut": "잘라내기",
        "action.copy": "복사",
        "action.paste": "붙여넣기",
        "action.duplicate": "복제",
        "action.rename": "이름 바꾸기",
        "action.delete": "삭제",
        "action.move_to_trash": "휴지통으로 이동",
        "action.delete_permanently": "영구 삭제",
        "action.new_folder": "새 폴더",
        "action.new_file": "새 파일",
        "action.new_tab": "새 탭",
        "action.close_tab": "탭 닫기",
        "action.properties": "속성 / 정보 가져오기",
        "action.refresh": "새로고침",
        "action.select_all": "전체 선택",
        "action.invert_selection": "선택 반전",
        "action.copy_path": "경로 복사",
        "action.copy_to_other_pane": "반대편 창으로 복사",
        "action.move_to_other_pane": "반대편 창으로 이동",
        "action.add_to_scrap": "스크랩 바구니에 담기",
        "action.calculate_checksum": "체크섬(해시) 계산",
        "action.batch_rename": "일괄 이름 바꾸기...",
        "action.search": "파일 검색...",
        "action.sync_folders": "폴더 동기화...",
        "action.split_join": "파일 분할 및 합치기...",
        "action.batch_create": "일괄 파일/폴더 생성...",
        "action.scrap_basket": "파일 스크랩 바구니",
        "action.cancel": "취소",
        "action.apply": "적용",
        "action.ok": "확인",
        "action.close": "닫기",
        "action.save": "저장",
        "action.clear": "비우기",
        "action.start": "시작",
        "action.stop": "중지",
        "action.compare": "비교",
        "action.preview": "미리보기",
        "action.execute": "실행",
        
        // Function keys (Norton Commander style)
        "fkey.f2": "F2 이름바꾸기",
        "fkey.f3": "F3 보기",
        "fkey.f4": "F4 편집",
        "fkey.f5": "F5 복사",
        "fkey.f6": "F6 이동",
        "fkey.f7": "F7 새폴더",
        "fkey.f8": "F8 삭제",
        
        // Sidebar
        "sidebar.favorites": "즐겨찾기",
        "sidebar.locations": "위치",
        "sidebar.volumes": "드라이브 볼륨",
        "sidebar.bookmarks": "북마크",
        "sidebar.home": "홈",
        "sidebar.desktop": "데스크탑",
        "sidebar.documents": "문서",
        "sidebar.downloads": "다운로드",
        "sidebar.applications": "응용 프로그램",
        "sidebar.pictures": "사진",
        "sidebar.music": "음악",
        "sidebar.movies": "동영상",
        "sidebar.trash": "휴지통",
        "sidebar.computer": "컴퓨터",
        "sidebar.network": "네트워크",
        "sidebar.add_favorite": "현재 위치를 즐겨찾기에 추가",
        "sidebar.remove_favorite": "즐겨찾기에서 제거",
        "sidebar.add_bookmark": "현재 위치 북마크 추가",
        "sidebar.remove_bookmark": "북마크 삭제",
        
        // Columns
        "column.name": "이름",
        "column.size": "크기",
        "column.kind": "종류",
        "column.date_modified": "수정한 날짜",
        "column.permissions": "권한",
        "column.owner": "소유자",
        "column.extension": "확장자",
        
        // View modes & Layout
        "view.table": "테이블 보기",
        "view.grid": "아이콘 보기",
        "view.list": "목록 보기",
        "view.single_pane": "단일 창",
        "view.dual_pane": "듀얼 창 (2분할)",
        "view.split_horizontal": "좌우 분할",
        "view.split_vertical": "상하 분할",
        "view.show_hidden": "숨김 파일 표시",
        "view.hide_hidden": "숨김 파일 숨김",
        
        // Tools: Batch Rename
        "rename.title": "일괄 이름 바꾸기 (다중 이름 변경)",
        "rename.rule.replace": "문자열 바꾸기",
        "rename.rule.insert": "문자열 삽입",
        "rename.rule.delete": "문자열 삭제",
        "rename.rule.numbering": "번호 붙이기",
        "rename.rule.case": "대/소문자 변환",
        "rename.rule.extension": "확장자 변경",
        "rename.find": "찾을 문자열:",
        "rename.replace_with": "바꿀 문자열:",
        "rename.use_regex": "정규 표현식(Regex) 사용",
        "rename.case_sensitive": "대소문자 구분",
        "rename.prefix": "앞에 붙일 문자열(접두사):",
        "rename.suffix": "뒤에 붙일 문자열(접미사):",
        "rename.insert_at": "특정 위치에 삽입:",
        "rename.delete_from_start": "처음부터 삭제할 글자 수:",
        "rename.delete_from_end": "끝에서부터 삭제할 글자 수:",
        "rename.start_number": "시작 번호:",
        "rename.step": "증가값:",
        "rename.digits": "자릿수 (0 채우기):",
        "rename.case_lower": "소문자로 변환",
        "rename.case_upper": "대문자로 변환",
        "rename.case_title": "단어 첫 글자만 대문자",
        "rename.case_capitalize": "문장 첫 글자만 대문자",
        "rename.new_extension": "새 확장자:",
        "rename.original": "현재 파일 이름",
        "rename.new": "변경될 파일 이름",
        "rename.status": "상태",
        "rename.apply_button": "이름 변경 실행",
        
        // Tools: Checksum
        "checksum.title": "체크섬 & 해시 계산기",
        "checksum.file": "대상 파일:",
        "checksum.algorithm": "알고리즘:",
        "checksum.calculate": "계산하기",
        "checksum.verify": "해시 검증 (비교):",
        "checksum.match": "해시가 완벽히 일치합니다! (정상)",
        "checksum.mismatch": "해시가 일치하지 않습니다! (변조/오류)",
        "checksum.copy": "해시 복사",
        "checksum.export_sfv": ".sfv / .md5 파일 저장",
        
        // Tools: Split & Join
        "splitjoin.title": "파일 분할 및 합치기",
        "splitjoin.tab_split": "파일 분할",
        "splitjoin.tab_join": "파일 합치기",
        "splitjoin.source_file": "분할할 원본 파일:",
        "splitjoin.chunk_size": "분할 크기 단위:",
        "splitjoin.output_folder": "저장할 대상 폴더:",
        "splitjoin.split_btn": "분할 시작",
        "splitjoin.first_part": "첫 번째 분할 파일 (.001):",
        "splitjoin.join_btn": "합치기 시작",
        "splitjoin.parts_found": "감지된 분할 조각 수:",
        
        // Tools: Directory Sync
        "sync.title": "폴더 비교 및 동기화",
        "sync.source": "원본(Source) 폴더:",
        "sync.target": "대상(Target) 폴더:",
        "sync.direction": "동기화 방향:",
        "sync.dir_source_to_target": "원본 -> 대상 (업데이트)",
        "sync.dir_mirror": "원본 -> 대상 (미러링/잉여 삭제)",
        "sync.dir_bidirectional": "양방향 동기화",
        "sync.include_subfolders": "하위 폴더 포함",
        "sync.status_missing": "대상에 없음",
        "sync.status_newer": "원본이 더 최신",
        "sync.status_older": "대상이 더 최신",
        "sync.status_equal": "동일함",
        "sync.start_btn": "동기화 실행",
        
        // Tools: File Search
        "search.title": "고급 파일 및 내용 검색",
        "search.search_in": "검색 위치:",
        "search.file_name": "파일 이름 패턴:",
        "search.content": "포함된 문자열:",
        "search.size_min": "최소 크기:",
        "search.size_max": "최대 크기:",
        "search.date_range": "수정 날짜 범위:",
        "search.results_count": "검색 결과 항목 수:",
        "search.searching": "검색 진행 중...",
        
        // Tools: File Scrap
        "scrap.title": "파일 스크랩 바구니",
        "scrap.empty": "스크랩 바구니가 비어 있습니다. 파일을 끌어다 놓거나 '스크랩 바구니에 담기'를 사용하세요.",
        "scrap.copy_all": "활성 창으로 모두 복사",
        "scrap.move_all": "활성 창으로 모두 이동",
        "scrap.clear_all": "바구니 비우기",
        
        // Tools: Batch Create
        "batchcreate.title": "일괄 파일 및 폴더 생성",
        "batchcreate.pattern_tab": "규칙/패턴으로 생성",
        "batchcreate.list_tab": "텍스트 목록으로 생성",
        "batchcreate.pattern": "이름 패턴:",
        "batchcreate.type": "생성 항목 종류:",
        "batchcreate.type_folder": "폴더",
        "batchcreate.type_file": "빈 파일",
        "batchcreate.lines_hint": "한 줄에 하나씩 파일/폴더 이름을 입력하세요. 슬래시(/)를 넣으면 하위 폴더가 생성됩니다.",
        "batchcreate.create_btn": "항목 일괄 생성",
        
        // Tools: Properties
        "properties.title": "파일/폴더 정보 및 속성",
        "properties.general": "일반 정보",
        "properties.path": "전체 경로:",
        "properties.size": "실제 디스크 점유 크기:",
        "properties.created": "생성된 날짜:",
        "properties.modified": "수정된 날짜:",
        "properties.accessed": "최근 접근 날짜:",
        "properties.permissions": "POSIX 접근 권한:",
        "properties.owner": "소유자 계정:",
        "properties.group": "그룹:",
        "properties.octal": "8진수 권한값:",
        
        // Preferences
        "prefs.title": "환경설정",
        "prefs.general": "일반",
        "prefs.language": "언어 설정 (Language):",
        "prefs.appearance": "화면 테마:",
        "prefs.confirm_delete": "파일 삭제 시 확인 대화상자 표시",
        "prefs.show_hidden": "기본으로 숨김 파일 표시",
        "prefs.default_startup": "시작 시 열릴 폴더:",
        "prefs.calc_folder_sizes": "폴더 크기 자동 계산",
        
        // Status & Messages
        "status.items": "개 항목",
        "status.selected": "개 선택됨",
        "status.free": "여유 공간",
        "status.loading": "불러오는 중...",
        "prompt.new_folder": "새 폴더 이름을 입력하세요:",
        "prompt.new_file": "새 파일 이름을 입력하세요:",
        "prompt.rename": "새 이름을 입력하세요:",
        "dialog.confirm_delete_title": "삭제 확인",
        "dialog.confirm_delete_msg": "선택한 항목을 영구적으로 삭제하시겠습니까?",
        "dialog.confirm_trash_msg": "선택한 항목을 휴지통으로 이동하시겠습니까?",
        "error.generic": "오류가 발생했습니다: "
    ]
]
