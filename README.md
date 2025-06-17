# NolJaGo (놀자고)

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=FF8C00&height=200&section=header&text=NolJaGo:%20iOS%20%EA%B5%AD%EB%82%B4%EC%97%AC%ED%96%89%20%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98&fontSize=34&fontColor=ffffff&fontAlignY=40&animation=fadeIn" />
</p>


> **지금 여기, 바로 떠나는 여행.**  
> **No Plans? NolJaGo!**  
> 여행코스, 관광, 음식, 숙소, 축제까지 - 국내여행에 필요한 모든 것을 하나의 앱으로.

<br><br>

# 📋 프로젝트 개요  

## ⭐️ 프로젝트 소개

+ NolJaGo는 사용자의 현재 위치 기반으로  
여행의 핵심 컨텐츠인 **`여행 코스 / 관광지 / 숙박 / 음식 / 축제&행사`** 정보들을 통합하여    
사용자가 실시간으로 한눈에 효율적으로 탐색할 수 있도록 구현된 국내여행 통합 애플리케이션입니다.
      

+ 복잡한 검색 및 계획 없이도    
**`“지금 여기서, 바로 놀고 먹고 자고!”`**   
를 실현할 수 있도록 직관적인 인터페이스와 신뢰성있는 여행 콘텐츠를 사용자에게 빠르고 편리하게 제공합니다.  

<br>

## 🙋‍♂️ 프로젝트 배경 및 문제 제기

최근 해외여행 수요가 급증하면서 국내여행에 대한 관심이 점차 줄어들고 있는 추세입니다.    

하지만 즉흥적 소비와 경험을 중시하는 MZ세대를 중심으로 “YOLO(You Only Live Once)” 트렌드가 확산됨에 따라    
국내에서 언제 어디서나 쉽고 빠르게 떠날 수 있는, 즉흥성과 경험 중심의 YOLO 트렌드에 부합하는 여행 콘텐츠에 대한 수요가 높아지고 있습니다.     

또한 기존의 여행 앱들은 다수의 정보 및 기능들을 분산된 형태로 제공하며, 이로인해 별도의 검색 앱, 경로 탐색 앱이나 지도 앱, 메모 앱 등을 번갈아 사용해야하는 번거로움이 존재합니다.   

<br>

## 💡 개발 동기 및 목적

이러한 문제 인식 속에서 **NolJaGo**는 다음과 같은 목표를 가지고 개발되었습니다.  


- 🔹 **국내 여행 활성화**를 위한 통합 여행 플랫폼 구축
  
- 🔹 **여행 코스, 관광지, 숙박, 음식, 행사/축제** 등 여행 핵심 정보를 한 곳에서 통합 제공
  
- 🔹 **현재 위치 기반 콘텐츠 탐색** 기능(CoreLocation 활용)으로 즉흥적 여행 실현 지원
  
- 🔹 **Apple Maps 연계 길찾기** 기능을 통해 여행 실행을 실제로 돕는 실용성 강화
  
- 🔹 찜한 장소(즐겨찾기)를 저장하고 관리할 수 있는 사용자 중심 기능 제공
  
- 🔹 공공데이터 기반(TourAPI 4.0)으로 신뢰성 있는 장소 정보 제공
  
- 🔹 **직관적인 UI/UX** 구성으로 연령 불문 누구나 쉽게 사용할 수 있도록 설계  

> **복잡한 계획 없이 “지금 여기서, 바로 놀고 먹고 자고!”를 실현하는 국내 여행 통합 도우미 앱을 만들고자 했습니다.**

<br>

## 🏗️ 프로젝트 구조
![IOS프로젝트 구조도](https://github.com/user-attachments/assets/30374f24-2b4c-4189-8703-72c074928f8c)

<br>

## ⚙️ 사용 기술 및 외부 API

| 항목        | 기술                       |
| ----------- | -------------------------- |
| 개발 언어   | Swift 5.0                  |
| UI 구성     | UIKit, Storyboard          |
| 위치 서비스 | CoreLocation               |
| 지도 서비스 | MapKit, Apple Maps 연동    |
| REST API    | TourAPI 4.0 (한국관광공사) |

<br>

## ✨ 주요 기능
> **‘NolJaGo’ 애플리케이션의 핵심 기능은 다음과 같습니다:**

### 🗺️ 여행 코스 탐색

- **한국관광공사 TourAPI 4.0** 기반 다중 REST API 연동:
  - `locationBasedList2`: 현재 위치 반경 10km 내 **여행 코스**(`contentTypeId=25`) 목록 조회
  - `detailIntro2`: 각 코스의 **거리, 소요시간, 유형** 등 상세 정보 조회
  - `detailInfo2`: **코스에 포함된 장소 목록 및 상세 설명** 조회
- **PickerView**를 통한 코스 선택 UI 제공
- **CollectionView**로 각 코스에 포함된 장소들을 카드 형태로 시각화

<br>

### 🧭 주변 여행콘텐츠 탐색

- **CoreLocation** 기반으로 사용자의 현재 위치 파악
- TourAPI 4.0의 다양한 `contentTypeId`로 카테고리별 데이터 실시간 조회:
  - 관광지: `contentTypeId=12`
  - 숙박시설: `contentTypeId=32`
  - 음식점: `contentTypeId=39`
  - 행사/축제: `contentTypeId=15`
- **MapKit** 기반 `MKPointAnnotation` 마커로 지도에 시각화
- **세그먼트 컨트롤**을 통해 카테고리 필터링 제공

<br>

### 📋 장소 상세정보 제공

- 지도 내 마커 클릭 시, **장소 상세 카드 UI** 표시
  - **장소 이름, 주소, 전화번호, 현재 위치와의 거리, 유형 뱃지 등** 표시

<br>

### ❤️ 즐겨찾기(찜한 장소) 관리

- `UserDefaults` 기반 로컬 저장소에 데이터 영구 저장
- **UITableView** + 커스텀 셀을 통해 저장된 장소 리스트 제공
- **편집 모드**를 통한 항목 삭제 / 순서 변경 가능
- 리스트 아이템 클릭시 해당 장소에 대한 상세정보 확인 가능  

<br>

### 🌎 Apple 지도 연동 길찾기

- **Apple Maps 딥링크 연동**:
- 현재 위치 → 선택 장소까지의 **실시간 경로 탐색 및 도착 시간 안내 등 유용한 기능 제공**

<br>

### 🛠 직관적인 UI/UX 설계

- `UIKit` 기반 다양한 UI 컴포넌트 활용:
  - **PickerView, CollectionView, TableView, MapView**
- 커스텀 전환 애니메이션 및 **부드러운 화면 전환 구현**
- 카테고리별 색상 코드 및 아이콘 체계로 **일관된 디자인 시스템 구축**
- **UITheme 유틸리티 클래스**를 통한 일관된 테마 및 스타일 적용

<br>

# 📱 주요 화면 구성

## 🚀 스플래시 화면
| 스플래시 화면 |
| :---------: |
|<img width="300" alt="image" src="https://github.com/user-attachments/assets/1946ee8d-5d35-4e10-ba45-08d8f2b4d20c">|

- **앱 실행 시 NolJaGo 로고&슬로건과 함께 2초 간의 론칭시간**
- **사용자에게 깔끔한 첫인상 제공**

<br>

## 🏚 홈 화면 <추천 여행 코스>

| 현재 위치 접근 허용 | 홈 화면 | 코스 포함 장소 클릭 시 |
| :----------: | :------------: | :-------: |
| <img width="250" alt="image" src="https://github.com/user-attachments/assets/f118c4a5-6edb-4c2f-8dbf-7b440bbfd753"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/dbf4cd27-263b-4d55-a199-012cd874dbce"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/fb58429e-5866-4c06-ad89-aadc17db76eb"> |


- **현재 위치 접근 허용**: coreLocation 기반 현재 위치 접근을 허용하여 현재 위치 제공
  
- **현재 위치 표시**: 현재 위치에 대한 주소를 화면 상단에 표시
  
- **피커 뷰: 추천 여행 코스**: **`반경 10KM 이내의 여행 코스`** 를 피커 뷰 형식으로 표시. 피커 뷰에는 해당 코스의 대표 이미지 & 코스 유형 & 코스 이름을 표시
  
- **코스 상세정보**: 피커 뷰 하단 코스 상세정보 컨테이너에는 **`해당 코스의 이름`** 과 **`코스의 전체 거리`** & **`코스 전체를 경험하는데 소요되는 시간`** & **`코스의 유형`** 을 표시
  
- **컬렉션 뷰: 코스 포함 장소**: 최하단 컬렉션 뷰에는 피커 뷰에서 선택된 코스에 포함된 장소들을 카드 형태로 표현. **`해당 장소 카드 클릭시 장소에 대한 상세정보가 안내창에 출력되어 제공`**
  
<br>

## 🗺 맵 화면 <내 주변 여행컨텐츠>

| 관광지 | 숙박 시설 | 음식점 | 축제/행사 |
| :----------: | :------------: | :-------: | :-------: |
| <img width="250" alt="image" src="https://github.com/user-attachments/assets/2e176597-4c76-402f-a649-4dde3e852d9e"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/6fb0de74-aaee-4c27-8631-93fa3ab68b71"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/97402780-899c-423c-987a-1b0bd4d1d858"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/c294e451-dab0-4eeb-93a0-0993daad5e99"> |

| 장소 마커 클릭: 상세정보 카드 | 찜하기 버튼 클릭 | 길찾기 버튼 클릭1 | 길찾기 버튼 클릭2 |
| :----------: | :------------: | :-------: | :-------: |
| <img width="250" alt="image" src="https://github.com/user-attachments/assets/a2bbd099-0c25-47fc-a6cd-5ddfa3dd074e"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/40370922-4d86-4121-bc8b-14c4d78eeeee"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/92f1f423-63a1-40b6-a420-0e700e52ca4f"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/2daf4a9d-f07c-4033-b0e8-97632cef734f"> |

- **세그먼트 컨트롤: 내 주변 여행컨텐츠 표시**: **`관광지 - 숙박 시설 - 음식점 - 축제/행사`** 버튼 클릭시, 현재 위치 기준 10KM 반경 이내의 해당 컨텐츠에 해당하는 장소들이 마커로 표시됨 
  
- **상세정보 카드**: 장소 마커 클릭 시, **`해당 장소의 이름 - 유형 - 주소 - 현 위치에서의 거리 - 연락처`** 와 같은 상세정보를 보여주는 카드가 등장. 추가로, 찜하기 버튼 & 길찾기 버튼도 제공 
  
- **찜하기 버튼**: 찜하기 버튼 클릭 시, 찜한 장소 화면에서 확인가능한 `찜목록에 해당 장소가 저장`됨
  
- **길찾기 버튼**: 길찾기 버튼 클릭 시, **Apple Maps 와 즉시 연계하여 현재 위치 <-> 해당 장소 간의 디테일한 길찾기 기능 제공: `추천 경로 - 최단 경로 - 도착 예정 시간 등 유용한 정보 제공`**

  
<br>

## ❤ 찜한 장소 화면

| 찜 목록 | 목록 수정 | 리스트 아이템 클릭: 상세정보 카드 |
| :----------: | :------------: | :------------: |
| <img width="250" alt="image" src="https://github.com/user-attachments/assets/fcccd28f-db1e-4320-ab6a-32a7865a37d9"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/d8b091df-760b-44c4-9029-a3e69b30b9cc"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/21c62885-c5fe-4ac6-8e11-081911089d9c"> |


| 지도에서 보기 버튼 클릭: 맵 화면 이동 & 해당 장소로 포커스  | 길찾기 버튼 클릭 |
| :----------: | :------------: |
| <img width="250" alt="image" src="https://github.com/user-attachments/assets/ac9c00f6-5e58-46a1-aefe-2c2540935006"> | <img width="250" alt="image" src="https://github.com/user-attachments/assets/08db3612-ee38-4e75-b436-aac9f78f29c4"> |



- **테이블 뷰: 찜 목록**: 사용자가 맵 화면에서 찜해둔 장소들이 테이블 뷰 리스트 아이템으로 저장되어 나타남 
  
- **목록 수정**: 우측 상단 편집버튼 클릭 시 **`수정모드로 변경`** -> 리스트 아이템 간의 **`순서 변경` & `아이템 삭제`** 가능
  
- **상세정보 카드**: 테이블 뷰의 각 장소 아이템 클릭 시, 해당 장소에 대한 상세정보 카드가 나타남 -> **`장소 이름 - 주소 - 연락처 - 찜한 날짜`** 와 같은 상세정보가 출력 

- **지도에서 보기 버튼**: 지도에서 보기 버튼 클릭 시, 맵 화면으로 이동 후 해당 장소 마커를 중심으로 포커스 되어져 찜한 장소를 지도에서 편하게 확인 가능
  
- **길찾기 버튼**: 길찾기 버튼 클릭 시, **Apple Maps 와 즉시 연계하여 현재 위치 <-> 해당 장소 간의 디테일한 길찾기 기능 제공: `추천 경로 - 최단 경로 - 도착 예정 시간 등 유용한 정보 제공`**
  
<br>


## 📊 기대 효과

- **국내 여행 활성화 기여**: 최근 해외여행 수요 증가로 관심이 다소 줄어든 국내 관광에 새로운 활력 기대  
  
- **간편하고 효율적인 여행 플래닝 제공**: 사용자는 별도의 복잡한 검색 없이 앱 하나로 `여행 코스, 관광, 숙박, 식사, 행사/축제` 등 주요 여행컨텐츠에 대한 모든 정보들을 이 하나의 앱을 통해 간편하게 탐색할 수 있어 빠르고 효율적인 여행 계획 수립 가능  
  
- **TourAPI 4.0 공공데이터 기반의 신뢰도 확보**: TourAPI 기반으로 신뢰도있는 정확한 장소 정보 제공  

- **사용 편의성 강화**: 직관적 UI와 간결한 인터페이스로 연령 불문 누구나 쉽게 사용 가능  



<br>

## 🎬 시연 영상
 >  ### 🔗 아래 썸네일을 클릭하면 YouTube 시연 영상으로 이동합니다

[![Demonstration video](https://github.com/user-attachments/assets/dd163123-9af6-4a4f-b1e7-543bdceb7a1f)](https://youtu.be/6-nIDs3ufg4?si=Jhty8wuMLy_zPsFU)

<br>

> ⏰ 개발 기간: 2025년 5월 20일 ~ 6월 17일  
> © 2025 NolJaGo | All Rights Reserved

<br>
