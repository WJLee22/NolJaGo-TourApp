//
//  HomeViewController.swift
//  NolJaGo-TourApp
//
//  Created by wjlee on 5/8/25.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController {
    
    @IBOutlet weak var cityPickerView: UIPickerView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var placesCollectionView: UICollectionView!
    @IBOutlet weak var courseInfoView: UIView!
    @IBOutlet weak var courseTitle: UILabel!
    @IBOutlet weak var courseDistance: UILabel!
    @IBOutlet weak var courseTaketime: UILabel!
    @IBOutlet weak var courseTheme: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var courseInfoContainer: UIView!
    
    // 새로 추가된 아웃렛
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var appLogoImageView: UIImageView!
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var nearbyCoursesTitleLabel: UILabel!
    @IBOutlet weak var courseIncludedPlacesTitleLabel: UILabel!
    @IBOutlet weak var placesSectionHeaderView: UIView!
    
    // courses array populated from TourAPI
    var courses: [Course] = []
    private let locationManager = CLLocationManager()
    private let xmlParser = XMLParserHelper()
    private var selectedCourseIndex = 0
    
    // 현재 위치 정보를 앱 전역에서 공유할 수 있게 싱글톤 사용
    static var sharedLocation: CLLocation?
    static var sharedLocationName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBranding()
        setupUI()
        setupCollectionView()
        setupPickerView()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 초기 상태에서는 코스 정보 숨기기
        courseInfoContainer.isHidden = true
        
        cityPickerView.dataSource = self
        cityPickerView.delegate = self
        
        checkLocationAuthorization()
        
        // 위치를 못 찾을 경우 5초 후 타임아웃으로 기본값 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if HomeViewController.sharedLocation == nil && self?.courses.isEmpty == true {
                // 📍 한성대 상상빌리지 fallback
                let fallbackLat = 37.582573
                let fallbackLon = 127.011159
                self?.locationLabel.text = "📍 현재 위치: 서울특별시 성북구 삼선동2가"
                self?.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
            }
        }
    }
    
    private func setupBranding() {
        // 상단 앱 로고 및 타이틀 설정
        headerView.backgroundColor = UIColor.white
        UITheme.applyShadow(to: headerView, opacity: 0.1, radius: 4, offset: CGSize(width: 0, height: 2))
        
        // 로고 이미지 명시적 설정 (Asset 카탈로그 확인)
        if let logoImage = UIImage(named: "AppLogo") { // 대소문자 수정
            appLogoImageView.image = logoImage
        } else {
            print("Warning: AppLogo image not found in asset catalog")
            appLogoImageView.backgroundColor = UITheme.lightOrange
        }
        
        appLogoImageView.contentMode = .scaleAspectFit
        appLogoImageView.layer.cornerRadius = 15
        appLogoImageView.clipsToBounds = true
        
        appTitleLabel.text = "No Plans? NolJaGo!"
        appTitleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
        appTitleLabel.textColor = UITheme.primaryOrange
        
        // 네비게이션 바 숨기기
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 배경색 설정
        view.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
    }
    
private func setupPickerView() {
    // 피커뷰 배경 설정
    cityPickerView.backgroundColor = .clear
    
    // 여러 항목을 보여줄 수 있도록 설정
    cityPickerView.clipsToBounds = false
    cityPickerView.layer.masksToBounds = false
    
    // 피커뷰 내부 스타일 변경
    cityPickerView.subviews.forEach { subview in
        subview.backgroundColor = .clear
        // 구분선 숨기기
        if subview.bounds.height <= 1 {
            subview.isHidden = true
        }
    }
    
    // 피커뷰 부모 컨테이너 스타일 변경
    if let containerView = cityPickerView.superview {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 15
        containerView.clipsToBounds = false
        UITheme.applyShadow(to: containerView, opacity: 0.2, radius: 8)
    }
}
    
    private func setupCollectionView() {
        // 컬렉션뷰 등록 및 설정
        placesCollectionView.register(CourseSubPlaceCell.self, forCellWithReuseIdentifier: "CourseSubPlaceCell")
        placesCollectionView.dataSource = self
        placesCollectionView.delegate = self
        
        // 레이아웃 설정 - 셀 높이 축소
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 150, height: 160) // 셀 크기 축소
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        placesCollectionView.collectionViewLayout = layout
        
        // 디자인 설정
        placesCollectionView.backgroundColor = .clear
        placesCollectionView.showsHorizontalScrollIndicator = false
        
        // 섹션 헤더 스타일링
        placesSectionHeaderView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        placesSectionHeaderView.layer.cornerRadius = 10
        placesSectionHeaderView.clipsToBounds = true
        
        courseIncludedPlacesTitleLabel.text = "🔍 코스 포함 장소"
        courseIncludedPlacesTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        courseIncludedPlacesTitleLabel.textColor = UITheme.primaryOrange
    }
    
    private func setupUI() {
        // 주변 코스 섹션 제목 설정
        nearbyCoursesTitleLabel.text = "📍 내 주변 추천 여행 코스"
        nearbyCoursesTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nearbyCoursesTitleLabel.textColor = UITheme.textGray
        
        // 상세 정보 컨테이너 스타일링 (이미지 제거로 높이 감소)
        courseInfoContainer.layer.cornerRadius = 20
        courseInfoContainer.clipsToBounds = true
        UITheme.applyShadow(to: courseInfoContainer, opacity: 0.2, radius: 8)
        
        // 코스 정보 뷰 스타일링
        courseInfoView.layer.cornerRadius = 15
        courseInfoView.clipsToBounds = true
        courseInfoView.backgroundColor = .white
        
        // 레이블 스타일링 - 타이틀을 1줄로 제한
        courseTitle.font = UITheme.titleFont
        courseTitle.textColor = UITheme.textGray
        courseTitle.numberOfLines = 1 // 1줄로 제한
        courseTitle.lineBreakMode = .byTruncatingTail // 넘치는 텍스트는 ... 처리
        
        courseDistance.font = UITheme.captionFont
        courseDistance.textColor = UITheme.primaryOrange
        
        courseTaketime.font = UITheme.captionFont
        courseTaketime.textColor = UITheme.primaryOrange
        
        courseTheme.font = UITheme.captionFont
        courseTheme.textColor = UITheme.secondaryTextGray
        courseTheme.backgroundColor = UITheme.lightOrange
        courseTheme.layer.cornerRadius = 8
        courseTheme.clipsToBounds = true
        courseTheme.textAlignment = .center
        
        // 위치 레이블 스타일 설정
        locationLabel.font = UIFont.boldSystemFont(ofSize: 17)
        locationLabel.textColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
        
        // 로딩 인디케이터 설정
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = UITheme.primaryOrange
    }

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            let fallbackLat = 37.582573
            let fallbackLon = 127.011159
            self.locationLabel.text = "📍 현재 위치: 서울특별시 성북구 삼선동2가"
            self.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
        @unknown default:
            break
        }
    }
    
    // MARK: - Load Courses from TourAPI
    func loadCourses(longitude lon: Double, latitude lat: Double) {
        HomeViewController.sharedLocation = CLLocation(latitude: lat, longitude: lon)
        
        loadingIndicator.startAnimating()
        courseInfoContainer.isHidden = true
        
        let serviceKey = "JaFInBZVqUQWbu41s8hN/sSLKXH57dqeTBSPpDSUrodv85m5BZqXrVl6xT15V5SsFMvHaz3a2VbyWRIDJlhIyQ=="
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/locationBasedList2?serviceKey=\(serviceKey)&mapX=\(lon)&mapY=\(lat)&radius=10000&MobileOS=IOS&MobileApp=NolJaGo&_type=json&arrange=E&contentTypeId=25&numOfRows=20"
        guard let url = URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, error == nil,
                  let wrapper = try? JSONDecoder().decode(TourResponse.self, from: data) else {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showEmptyStateMessage("데이터를 불러오는데 실패했습니다. 다시 시도해주세요.")
                }
                return
            }
            
            // 먼저 데이터를 안전하게 저장
            self.courses = wrapper.response.body.items.item
            
            DispatchQueue.main.async {
                self.cityPickerView.reloadAllComponents()
                
                if self.courses.isEmpty {
                    self.loadingIndicator.stopAnimating()
                    self.showEmptyStateMessage("해당 위치에 추천 코스가 없습니다. 다른 위치에서 시도해보세요.")
                    self.courseInfoContainer.isHidden = true
                } else {
                    self.selectedCourseIndex = 0
                    self.cityPickerView.selectRow(0, inComponent: 0, animated: false)
                    self.loadCourseDetails(for: 0)
                }
            }
        }.resume()
    }
    
    private func showEmptyStateMessage(_ message: String) {
        let emptyStateLabel = UILabel()
        emptyStateLabel.text = message
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = UITheme.secondaryTextGray
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emptyStateView = UIView()
        emptyStateView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        emptyStateView.layer.cornerRadius = 15
        emptyStateView.tag = 100 // 태그로 식별
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateLabel)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: courseInfoContainer.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: courseInfoContainer.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: courseInfoContainer.widthAnchor),
            emptyStateView.heightAnchor.constraint(equalTo: courseInfoContainer.heightAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20)
        ])
    }
    
    private func removeEmptyStateMessage() {
        if let emptyStateView = view.viewWithTag(100) {
            emptyStateView.removeFromSuperview()
        }
    }
    
    // MARK: - Load Course Details
    private func loadCourseDetails(for index: Int) {
        // 안전 체크
        guard !courses.isEmpty, 
              index >= 0, 
              index < courses.count, 
              let contentId = courses[index].contentid else {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.courseInfoContainer.isHidden = true
                self.showEmptyStateMessage("코스 정보를 불러올 수 없습니다.")
            }
            return
        }
        
        let group = DispatchGroup()
        
        // 1. Load DetailIntro (코스 소요시간, 거리 정보)
        group.enter()
        loadDetailIntro(contentId: contentId) { [weak self] detailIntro in
            defer { group.leave() }
            guard let self = self, !self.courses.isEmpty, index < self.courses.count else { return }
            
            DispatchQueue.main.async {
                self.courses[index].detailIntro = detailIntro
            }
        }
        
        // 2. Load DetailInfo (코스 내부 장소들 정보)
        group.enter()
        loadDetailInfo(contentId: contentId) { [weak self] subPlaces in
            defer { group.leave() }
            guard let self = self, !self.courses.isEmpty, index < self.courses.count else { return }
            
            DispatchQueue.main.async {
                self.courses[index].subPlaces = subPlaces
            }
        }
        
        // 모든 API 호출이 완료되면 UI 업데이트
        group.notify(queue: .main) { [weak self] in
            guard let self = self, !self.courses.isEmpty, index < self.courses.count else { 
                self?.loadingIndicator.stopAnimating()
                self?.courseInfoContainer.isHidden = true
                return 
            }
            
            self.removeEmptyStateMessage()
            self.updateDetailUI(for: index)
            self.loadingIndicator.stopAnimating()
            self.courseInfoContainer.isHidden = false
            
            // 장소 섹션 타이틀 업데이트
            let placeCount = self.courses[index].subPlaces?.count ?? 0
            self.courseIncludedPlacesTitleLabel.text = "🔍 코스 포함 장소 (\(placeCount)개)"
            
            // 컬렉션뷰가 비어있으면 안내 메시지 표시
            if placeCount == 0 {
                self.showEmptyPlacesMessage()
            } else {
                self.removeEmptyPlacesMessage()
            }
            
            // 컬렉션뷰 리로드
            self.placesCollectionView.reloadData()
        }
    }
    
    private func showEmptyPlacesMessage() {
        let emptyPlacesLabel = UILabel()
        emptyPlacesLabel.text = "이 코스에는 등록된 장소가 없습니다."
        emptyPlacesLabel.textAlignment = .center
        emptyPlacesLabel.font = UIFont.systemFont(ofSize: 16)
        emptyPlacesLabel.textColor = UITheme.secondaryTextGray
        emptyPlacesLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyPlacesLabel.tag = 101 // 태그로 식별
        
        placesCollectionView.backgroundView = emptyPlacesLabel
    }
    
    private func removeEmptyPlacesMessage() {
        placesCollectionView.backgroundView = nil
    }
    
    private func loadDetailIntro(contentId: String, completion: @escaping (CourseDetailIntro?) -> Void) {
        let serviceKey = "JaFInBZVqUQWbu41s8hN/sSLKXH57dqeTBSPpDSUrodv85m5BZqXrVl6xT15V5SsFMvHaz3a2VbyWRIDJlhIyQ=="
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/detailIntro2?serviceKey=\(serviceKey)&contentId=\(contentId)&contentTypeId=25&MobileOS=IOS&MobileApp=NolJaGo&_type=xml"
        
        guard let url = URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                completion(nil)
                return
            }
            
            let detailIntro = self.xmlParser.parseDetailIntro(data: data)
            completion(detailIntro)
        }.resume()
    }
    
    private func loadDetailInfo(contentId: String, completion: @escaping ([CourseSubPlace]) -> Void) {
        let serviceKey = "JaFInBZVqUQWbu41s8hN/sSLKXH57dqeTBSPpDSUrodv85m5BZqXrVl6xT15V5SsFMvHaz3a2VbyWRIDJlhIyQ=="
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/detailInfo2?serviceKey=\(serviceKey)&contentId=\(contentId)&contentTypeId=25&MobileOS=IOS&MobileApp=NolJaGo&_type=xml"
        
        guard let url = URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                completion([])
                return
            }
            
            let subPlaces = self.xmlParser.parseDetailInfo(data: data)
            completion(subPlaces)
        }.resume()
    }
    
    // MARK: - Update Detail UI
    private func updateDetailUI(for index: Int) {
        // 안전 체크
        guard !courses.isEmpty, index >= 0, index < courses.count else {
            showEmptyStateMessage("코스 정보가 없습니다.")
            courseInfoContainer.isHidden = true
            return
        }
        
        let course = courses[index]
        
        // 코스 기본 정보 업데이트
        courseTitle.text = course.title
        
        // DetailIntro 정보 업데이트
        if let detailIntro = course.detailIntro {
            courseDistance.text = "🚶 코스 길이: \(detailIntro.distance)"
            courseTaketime.text = "⏱ 소요시간: \(detailIntro.taketime)"
            
            // cat2 코드로 코스 유형 결정
            let courseType = getCourseTypeText(cat2: course.cat2)
            courseTheme.text = "   \(courseType)   "
            
            // 디버그 정보 출력
            print("Course cat2: \(course.cat2 ?? "없음")")
        } else {
            courseDistance.text = "🚶 거리: 정보 없음"
            courseTaketime.text = "⏱ 소요시간: 정보 없음"
            courseTheme.text = "   추천코스   "
        }
    }
    
    // 코스 유형 변환 함수
    private func getCourseTypeText(cat2: String?) -> String {
        guard let cat2 = cat2 else { return "추천코스" }
        
        switch cat2 {
        case "C0112": return "가족코스"
        case "C0113": return "나홀로코스"
        case "C0114": return "힐링코스"
        case "C0115": return "도보코스"
        case "C0116": return "캠핑코스" 
        case "C0117": return "맛코스"
        default: return "추천코스"
        }
    }
}

extension HomeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return courses.count
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension HomeViewController: UIPickerViewDelegate {
    // 피커뷰 행 높이 설정
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 140
    }
    
    // 커스텀 뷰 개선 - 선택 표시 방식 변경
func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    // 안전 체크
    guard !courses.isEmpty, row < courses.count else {
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width * 0.8, height: 120))
        emptyView.backgroundColor = .clear
        return emptyView
    }
    
    // 컨테이너 뷰 크기 유지
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width * 0.8, height: 120))
    containerView.backgroundColor = .clear
    
    // 카드 크기 유지
    let cardView = UIView(frame: CGRect(x: 10, y: 5, width: containerView.frame.width - 20, height: 110))
    cardView.backgroundColor = .white
    cardView.layer.cornerRadius = 15
    
    // 모든 카드에 동일한 기본 그림자만 적용 (특별한 강조 없음)
    UITheme.applyShadow(to: cardView, opacity: 0.2, radius: 5)
    
    // 이미지뷰 설정
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cardView.frame.width, height: 85))
    imageView.contentMode = .scaleAspectFit // 이미지 비율 유지
    imageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 15
    imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
    // 더 적합한 기본 이미지 설정
    let defaultImage = UIImage(systemName: "photo.on.rectangle") ?? UIImage(systemName: "photo")
    imageView.image = defaultImage
    imageView.tintColor = UIColor.darkGray.withAlphaComponent(0.7)
    
    // 코스 유형 태그 추가
    let tagLabel = UILabel(frame: CGRect(x: 10, y: 10, width: 70, height: 22))
    tagLabel.text = "  " + getCourseTypeText(cat2: courses[row].cat2) + "  "
    tagLabel.backgroundColor = UITheme.lightOrange
    tagLabel.textColor = UITheme.primaryOrange
    tagLabel.font = UIFont.boldSystemFont(ofSize: 11)
    tagLabel.textAlignment = .center
    tagLabel.layer.cornerRadius = 11
    tagLabel.clipsToBounds = true
    
    // 제목 레이블 - 가독성 개선
    let titleLabel = UILabel(frame: CGRect(x: 5, y: imageView.frame.maxY, width: cardView.frame.width - 10, height: 25))
    titleLabel.text = courses[row].title
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.boldSystemFont(ofSize: 12) // 글자 크기 약간 키움
    titleLabel.textColor = .black
    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    
    // 이미지 로드
    if let urlStr = courses[row].firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let d = data, let img = UIImage(data: d) {
                DispatchQueue.main.async {
                    imageView.image = img
                    imageView.contentMode = .scaleAspectFill // 이미지 로드 후 채우기 모드로 변경
                }
            }
        }.resume()
    }
    
    cardView.addSubview(imageView)
    cardView.addSubview(titleLabel)
    imageView.addSubview(tagLabel)
    containerView.addSubview(cardView)
    
    return containerView
}
    
    // 피커뷰 선택 이벤트 처리 - 선택된 카드 스타일 업데이트 추가
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 안전 체크
        guard !courses.isEmpty, row < courses.count else { return }
        
        selectedCourseIndex = row
        loadingIndicator.startAnimating()
        courseInfoContainer.isHidden = true
        loadCourseDetails(for: row)
  
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 안전 체크 - 중요!
        guard !courses.isEmpty, selectedCourseIndex < courses.count else {
            return 0
        }
        return courses[selectedCourseIndex].subPlaces?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseSubPlaceCell", for: indexPath) as! CourseSubPlaceCell
        
        // 안전 체크
        guard !courses.isEmpty, 
              selectedCourseIndex < courses.count,
              let subPlaces = courses[selectedCourseIndex].subPlaces,
              indexPath.item < subPlaces.count else {
            return cell
        }
        
        let subPlace = subPlaces[indexPath.item]
        cell.configure(with: subPlace)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 안전 체크
        guard !courses.isEmpty,
              selectedCourseIndex < courses.count,
              let subPlaces = courses[selectedCourseIndex].subPlaces,
              indexPath.item < subPlaces.count else {
            return
        }
        
        let subPlace = subPlaces[indexPath.item]
        showSubPlaceDetail(subPlace)
    }
    
    private func showSubPlaceDetail(_ subPlace: CourseSubPlace) {
        // 장소 상세 정보를 보여주는 팝업 또는 알림 표시
        let alert = UIAlertController(title: subPlace.subname, message: subPlace.subdetailoverview, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let lon = loc.coordinate.longitude
        let lat = loc.coordinate.latitude
        
        // 전역 위치 저장
        HomeViewController.sharedLocation = loc

        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let pm = placemarks?.first {
                // 단순한 전체 주소 구성 (중복 제거)
                var addressComponents: [String] = []
                
                // 시/도 (예: 서울특별시)
                if let administrativeArea = pm.administrativeArea, !administrativeArea.isEmpty {
                    addressComponents.append(administrativeArea)
                }
                
                // 구/군 (예: 성북구)
                if let subAdministrativeArea = pm.subAdministrativeArea, !subAdministrativeArea.isEmpty {
                    addressComponents.append(subAdministrativeArea)
                }
                
                // 동/읍/면 (예: 삼선동2가) - thoroughfare와 중복 체크
                var localityAdded = false
                if let subLocality = pm.subLocality, !subLocality.isEmpty {
                    addressComponents.append(subLocality)
                    localityAdded = true
                }
                
                // 번지/도로명 (예: 298-2) - subLocality와 중복되지 않는 경우만 추가
                if let thoroughfare = pm.thoroughfare, !thoroughfare.isEmpty {
                    // thoroughfare가 이미 추가된 subLocality와 다른 경우에만 추가
                    if !localityAdded || thoroughfare != pm.subLocality {
                        if let subThoroughfare = pm.subThoroughfare, !subThoroughfare.isEmpty {
                            addressComponents.append("\(thoroughfare) \(subThoroughfare)")
                        } else {
                            addressComponents.append(thoroughfare)
                        }
                    } else if let subThoroughfare = pm.subThoroughfare, !subThoroughfare.isEmpty {
                        // thoroughfare는 중복이지만 subThoroughfare(번지)만 추가
                        addressComponents.append(subThoroughfare)
                    }
                } else if let subThoroughfare = pm.subThoroughfare, !subThoroughfare.isEmpty {
                    addressComponents.append(subThoroughfare)
                }
                
                // 최종 주소
                let finalAddress = addressComponents.isEmpty ? "위치 확인 중..." : addressComponents.joined(separator: " ")
                
                HomeViewController.sharedLocationName = finalAddress
                
                DispatchQueue.main.async {
                    self.locationLabel.text = "📍 현재 위치: \(finalAddress)"
                }
            }
        }

        loadCourses(longitude: lon, latitude: lat)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 가져오기 실패: \(error.localizedDescription)")

        // 한성대 상상빌리지 fallback
        let fallbackLat = 37.582573
        let fallbackLon = 127.011159
        
        // fallback 위치에 대해서도 역지오코딩 시도
        let fallbackLocation = CLLocation(latitude: fallbackLat, longitude: fallbackLon)
        CLGeocoder().reverseGeocodeLocation(fallbackLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            var fallbackAddress = "서울특별시 성북구 삼선동2가"
            
            if let pm = placemarks?.first {
                var addressComponents: [String] = []
                
                if let administrativeArea = pm.administrativeArea, !administrativeArea.isEmpty {
                    addressComponents.append(administrativeArea)
                }
                
                if let subAdministrativeArea = pm.subAdministrativeArea, !subAdministrativeArea.isEmpty {
                    addressComponents.append(subAdministrativeArea)
                }
                
                var localityAdded = false
                if let subLocality = pm.subLocality, !subLocality.isEmpty {
                    addressComponents.append(subLocality)
                    localityAdded = true
                }
                
                if let thoroughfare = pm.thoroughfare, !thoroughfare.isEmpty {
                    if !localityAdded || thoroughfare != pm.subLocality {
                        if let subThoroughfare = pm.subThoroughfare, !subThoroughfare.isEmpty {
                            addressComponents.append("\(thoroughfare) \(subThoroughfare)")
                        } else {
                            addressComponents.append(thoroughfare)
                        }
                    } else if let subThoroughfare = pm.subThoroughfare, !subThoroughfare.isEmpty {
                        addressComponents.append(subThoroughfare)
                    }
                } else if let subThoroughfare = pm.subThoroughfare, !subThoroughfare.isEmpty {
                    addressComponents.append(subThoroughfare)
                }
                
                if !addressComponents.isEmpty {
                    fallbackAddress = addressComponents.joined(separator: " ")
                }
            }
            
            HomeViewController.sharedLocationName = fallbackAddress
            DispatchQueue.main.async {
                self.locationLabel.text = "📍 현재 위치: \(fallbackAddress)"
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.locationLabel.text = "📍 현재 위치: 위치 확인 중..."
            self.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: - CourseSubPlaceCell
class CourseSubPlaceCell: UICollectionViewCell {
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let numberLabel = UILabel()
    // 설명 레이블 제거
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        // 컨테이너 뷰 설정
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        UITheme.applyShadow(to: containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 이미지 뷰 설정
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = UITheme.placeholderGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // 번호 라벨 설정
        numberLabel.textAlignment = .center
        numberLabel.textColor = .white
        numberLabel.font = UIFont.boldSystemFont(ofSize: 12)
        numberLabel.backgroundColor = UITheme.primaryOrange
        numberLabel.layer.cornerRadius = 10
        numberLabel.clipsToBounds = true
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(numberLabel)
        
        // 이름 라벨 설정
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.textColor = UITheme.textGray
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // 간소화된 레이아웃 설정
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalToConstant: 100), // 이미지 높이 축소
            
            numberLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5),
            numberLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 5),
            numberLabel.widthAnchor.constraint(equalToConstant: 20),
            numberLabel.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
        numberLabel.text = nil
    }
    
    func configure(with subPlace: CourseSubPlace) {
        nameLabel.text = subPlace.subname
        numberLabel.text = "\(subPlace.subnum + 1)"
        
        // 이미지 로드
        if let imageUrl = subPlace.subdetailimg, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }.resume()
        } else {
            imageView.image = UIImage(systemName: "photo")
        }
    }
}