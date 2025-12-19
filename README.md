## GithubRepoFinder

GitHub Search API를 이용해 **저장소 검색 → 검색 결과 리스트 → WebView 상세** 흐름을 제공하는 iOS 앱입니다.

- **검색 화면**: 최근 검색어(최대 10개) / 삭제 / 전체 삭제 / 자동완성(최근 검색어 기반)
- **검색 결과 화면**: 총 결과 수 / 리스트 / 중간 프리패치 페이지네이션 / 로딩 상태
- **상세 화면**: WKWebView로 저장소 페이지 이동

---

## 실행 방법

1. Xcode에서 `GithubRepoFinder/GithubRepoFinder.xcodeproj`를 엽니다.
2. Scheme `GithubRepoFinder`를 선택한 뒤 실행합니다.

---

## 요구사항 매핑

### 1) 검색 화면

- **검색어 입력 후 결과 표시**: 검색 버튼 클릭 시 검색 결과 화면을 노출하고 검색을 시작합니다.
- **검색어가 비어있으면 최근 검색어 최대 10개 노출**: 입력이 비어있거나 키보드가 내려간 상태에서는 최근 검색어(최대 10개)를 보여줍니다.
- **최근 검색어 내림차순(최신 우선)**: 저장 시점 기준으로 최신을 앞에 두도록 관리합니다.
- **최근 검색어 삭제 / 전체 삭제**: 스와이프 삭제 및 footer의 “전체 삭제”를 제공합니다.
- **앱 재시작 후에도 유지**: `UserDefaults`에 저장합니다.
- **최근 검색어 선택 시 결과 표시**: 최근 검색어 탭 시 즉시 검색 결과 화면으로 이동합니다.

[추가 구현]
- **자동완성(최근 검색어 기반)**: 입력 중(키보드 올라온 상태 + 1글자 이상)에는 최근 검색어에서 prefix/contains 매칭으로 자동완성을 제공합니다.
- **자동완성에 검색 날짜 표시**: 자동완성 모드에서 `MM.dd` 형태로 날짜를 함께 노출합니다.

### 2) 검색 결과 화면

- **List 형태로 결과 표시**: UITableView로 결과 목록을 표시합니다.
- **총 검색 결과 수 표시**: `total_count`를 받아 “N개 저장소” 형태로 표시합니다.
- **저장소 정보 표시**
  - Thumbnail: `owner.avatar_url`
  - Title: `name`
  - Description: `owner.login`
- **결과 선택 시 WebView 이동**: 선택한 저장소의 `html_url`을 WKWebView로 로드합니다.

[추가 구현]
- **중간 프리패치**: 리스트가 끝에 가까워지면 다음 페이지를 호출합니다.
- **Next Page 로딩 상태**: 다음 페이지 로딩 시 footer에 indicator를 노출합니다.

### 3) API

- Endpoint: `[GET] https://api.github.com/search/repositories?q={keyword}&page={page}`

---

## 기술 스택

- **Language**: Swift
- **UI**: UIKit + Storyboard(레이아웃) + Code(셀 구성/일부 뷰)
- **Architecture**: MVVM
- **Reactive**: Combine
- **Networking**: URLSession (`Combine` 기반 `dataTaskPublisher`)
- **WebView**: WebKit (WKWebView)

---

## 프로젝트 구조

```text
GithubRepoFinder/
└── GithubRepoFinder/
    ├── Features/
    │   ├── Search/        # 최근 검색어/자동완성 + 검색 트리거
    │   ├── SearchResult/  # 결과 리스트/페이지네이션
    │   └── Web/           # WKWebView
    └── Core/
        ├── Network/       # HTTPClient, GitHubSearchService, NetworkError
        ├── Storage/       # RecentKeywordStore(UserDefaults)
        ├── Models/        # GitHubSearchResponse
        └── Utils/         # ImageLoader, ImageMemoryCache
```

---

## 구현 포인트

- **최근 검색어 저장 정책**
  - 동일 키워드는 중복 저장하지 않고 **가장 최신으로 갱신**합니다.
  - 최대 노출 10개(표시 레벨)로 제한합니다.

- **자동완성 품질(단순하지만 체감 좋은 룰)**
  - 최근 검색어(최신 우선) 목록에서
    - **prefix match 우선**
    - **contains match 후순위**

- **페이지네이션 안정성**
  - 동일 키워드에 대해 **이미 로드한 page는 재요청하지 않음**(loadedPages).
  - 첫 페이지 로드 후, `items.count / 2`를 기준으로 threshold를 동적으로 조정해 프리패치 타이밍을 튜닝합니다.

- **이미지 로딩 최적화**
  - `NSCache` 기반 메모리 캐시를 두고, avatar는 캐시 hit 시 즉시 반환합니다.
  - 셀 재사용에 따른 이미지 오염 방지를 위해 `cell.tag`로 repository id를 저장하고 결과 적용 시 검증합니다.

- **에러 처리**
  - 네트워크/HTTP status/디코딩 오류를 `NetworkError`로 정리하고, 결과 화면에서 Alert로 사용자 피드백을 제공합니다.
