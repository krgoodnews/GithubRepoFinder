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
<br>
## 구현 사항

### 1) 검색 화면
<p>
<img width="300" alt="CleanShot 2025-12-19 at 19 06 05@2x" src="https://github.com/user-attachments/assets/12184181-5538-44d4-9cbb-ce1529c7867b" />
<img width="300" alt="CleanShot 2025-12-19 at 19 06 31@2x" src="https://github.com/user-attachments/assets/2c6ffe96-30b4-4b69-a3ae-cac5217cad47" />
</p>

[추가 구현]
1. 검색어 입력 시, 자동완성을 보여줍니다.
2. 자동완성 노출 시, 검색 날짜를 같이 보여줍니다.
3. 자동완성은 최근 검색어에서 추출하여 사용합니다.
<br>

### 2) 검색 결과 화면
<p>
<img width="300" alt="CleanShot 2025-12-19 at 19 07 22@2x" src="https://github.com/user-attachments/assets/9e51c53f-53bb-4708-b4eb-66aafab615d4" />
<img width="300" alt="CleanShot 2025-12-19 at 19 07 27@2x" src="https://github.com/user-attachments/assets/7131b5bc-dbb2-4f9a-83ff-59d87e66034c" />
</p>
<br>

[추가 구현]
- **중간 프리패치**: 리스트가 끝에 가까워지면 다음 페이지를 호출합니다.

- **Next Page 로딩 상태**: 다음 페이지 로딩 시 footer에 indicator를 노출합니다.
<br>

### 3) API

- Endpoint: `[GET] https://api.github.com/search/repositories?q={keyword}&page={page}`
<br>

### 4) 다크모드 & Dynamic Type 지원
<img width="300" alt="CleanShot 2025-12-19 at 19 10 09@2x" src="https://github.com/user-attachments/assets/cee96970-8c43-4dd5-84c3-a54f444a8712" />

- Custom Cell이 아닌 `UIListConfiguration` 사용으로 큰 글자에서도 자연스러운 레이아웃을 제공합니다.
<br>
<br>
---

## 기술 스택

- **Language**: Swift
- **UI**: UIKit + Storyboard(레이아웃) + Code(셀 구성/일부 뷰)
- **Architecture**: MVVM
- **Reactive**: Combine
- **Networking**: URLSession (`Combine` 기반 `dataTaskPublisher`)
- **WebView**: WebKit (WKWebView)
---
<br>

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
<br>

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
