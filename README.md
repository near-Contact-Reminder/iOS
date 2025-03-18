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
    	
    - SwypAppwnd
    	- Resources
    		- Assets.xcassets
    	- Sources
    		- Views
    		  - ex) Home
    		    - HomeView.swift
    		    - Components (하위 컴포넌트)
    		- ViewModels
			- CommonComponents
    		- Models
    		- Networks
    		- Services
    		- Tests
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
