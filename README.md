# 스위프 앱 1기 2팀 프로젝트 설정 방법

## 목차
- [1️⃣ 프로젝트 클론](#1️⃣-프로젝트-클론)   
- [2️⃣ SwiftUI 코드컨벤션](#2️⃣-swiftui-코드컨벤션)
- [3️⃣ Git 커밋컨벤션](#3️⃣-git-커밋컨벤션) 

## 1️⃣ 프로젝트 클론
```
git clone [gitUrl]
cd SwypApp2nd
```
2️⃣ Tuist 설치 (최초 1회만 실행)<br/>
둘 중 하나만 선택 brew를 사용한다면 아래 실행
```
curl -Ls https://install.tuist.io | bash
brew install tuist
```
3️⃣ 의존성 패키지 설치
```
tuist install
```
4️⃣ Xcode 프로젝트 생성
```
tuist generate
```
정상적으로 완료됐다면 생성된 SwypApp2nd.xcworkspace 실행 후 개발하면 됩니다.

만약 brew나 tuist를 실행할 때 command not found가 나온다면
1. Homebrew가 설치되어 있는지 확인
```
which brew
```
만약 아무 결과도 나오지 않는다면, 아래 명령어로 Homebrew를 설치
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
2. Tuist가 설치된 경로 확인
```
which tuist
```
3. 다시 Tuist 설치(brew로 할거면)
```
brew install tuist
```
4. Tuist가 설치되었지만 command not found가 발생한다면, 환경 변수 문제일 수 있음 명령어 실행 후, tuist가 정상적으로 실행되는지 확인
```
export PATH="$HOME/.tuist/bin:$PATH"
tuist version
```
5. 만약 시뮬레이터를 실행해도 아무 반응이 없을 경우 Cmd + Shift + , -> Info -> Executable을 SwypApp2nd.app으로 설정하면 시뮬레이터가 실행됩니다.

6. tuist 재설정
```
tuist clean
tuist install
tuist generate
```

## 2️⃣ SwiftUI 코드컨벤션

### 파일 및 폴더명

- View 이름은 화면의 목적을 반영하여 명확히 작성 (ex. `LoginView.swift`)
- 폴더 구조 예시:
    
    ```
    - Drived
    	- InfoPlist
    	- Sources
    	
    - SwypApp2nd
    	- Resources
    		- Assets.xcassets: 이미지, 아이콘 및 리소스 에셋 관리
    	- Sources
    		- Views
				- 각 화면을 구성하는 UI 코드가 위치하며 화면 단위로 구분합니다.
				- 예시: Home
					- HomeView.swift: 홈 화면의 뷰를 구현한 파일입니다.
					- Components: 홈 화면에 사용되는 하위 컴포넌트(예: 버튼, 카드, 리스트 등)가 모여 있습니다.
			- ViewModels
				- 뷰와 모델 사이에서 데이터를 처리하며, 뷰가 화면에 필요한 데이터를 손쉽게 표시할 수 있도록 비즈니스 로직을 구현하는 코드가 포함됩니다.
			- CommonComponents
				- 앱 전반에서 재사용 가능한 공통 UI 컴포넌트(예: 커스텀 버튼, 네비게이션바, 탭바 등)가 정의되어 있습니다.
			- Models
				- 앱에서 사용하는 데이터 모델, 데이터 구조체 등을 정의하며, API 응답 데이터를 파싱한 모델도 포함될 수 있습니다.
			- Networks
				- Alamofire 또는 URLSession을 활용하여 외부 API와의 통신을 담당하는 네트워크 계층 코드가 포함되어 있습니다. (ex: NetworkService.swift, Endpoint.swift 등)
			- Services
				- 비즈니스 로직을 처리하는 서비스 계층 코드로서, 네트워크에서 받은 데이터를 가공하거나 추가적인 로직을 처리하는 서비스 코드가 포함됩니다.
			- Tests
				- 유닛 테스트 및 UI 테스트 코드가 포함된 폴더로, XCTest를 활용하여 각 컴포넌트 및 기능을 테스트할 수 있습니다.
    ```
    

### 네이밍 규칙

- 클래스, 구조체, 프로토콜: UpperCamelCase
- 변수, 함수, 메서드, enum 케이스: lowerCamelCase
- 상수 및 정적 변수: lowerCamelCase
- SwiftUI 뷰: 명확한 역할을 나타내는 UpperCamelCase 사용

### View 구성 규칙

- 뷰 구성 시 body 내의 컴포넌트가 복잡할 경우 최대한 작은 서브뷰로 나눠 관리
- ViewModel과 View를 분리하여 MVVM 패턴 준수
- body 내의 복잡한 로직을 computed property 또는 별도의 View로 분리하여 가독성 향상
- 최대 가로 길이: 120자 이하 유지
- 들여쓰기: Space 4칸
- 불필요한 주석과 공백 제거

---

## 3️⃣ Git 커밋컨벤션

### 커밋 타입

- feat: 기능 추가
- fix: 버그 수정
- docs: 문서 추가 및 수정
- style: 코드 포맷팅, 세미콜론 추가 등 코드 변경 없는 스타일 수정
- refactor: 코드 리팩토링
- test: 테스트 코드 추가 및 수정
- chore: 빌드 업무, 패키지 매니저 수정 등

### Git 브랜치 관리

- `main`: 배포 가능한 안정적인 코드
- `develop`: 개발 단계 코드 관리
- `feature/기능명`: 기능 단위로 브랜치 생성 후 작업, 완료 후 develop으로 Pull Request
- `hotfix/이슈번호`: 긴급한 버그 수정, 즉시 main으로 병합

### 커밋 메시지 형식

```
[type]: 간단한 설명 (#이슈번호)

- 상세한 설명(필요시)
```

### 커밋 메시지 예시

```
feat: 로그인 화면 구현 (#12)
fix: 메인 화면 크래시 현상 해결 (#15)
refactor: HomeViewModel 코드 최적화 (#32)
```

### PR 규칙

- 하나의 Pull Request에는 하나의 기능 또는 이슈 해결
- 리뷰어 최소 1명의 승인 후 merge
- PR 제목에 커밋 타입 명시하여 작성 (ex. `feat: 로그인 기능 추가`)
