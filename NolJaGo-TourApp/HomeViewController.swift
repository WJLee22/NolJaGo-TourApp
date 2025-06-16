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
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var placesCollectionView: UICollectionView!
    @IBOutlet weak var courseInfoView: UIView!
    @IBOutlet weak var courseTitle: UILabel!
    @IBOutlet weak var courseImage: UIImageView!
    @IBOutlet weak var courseDistance: UILabel!
    @IBOutlet weak var courseTaketime: UILabel!
    @IBOutlet weak var courseTheme: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var courseInfoContainer: UIView!
    
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
        setupUI()
        setupCollectionView()
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
    
    private func setupCollectionView() {
        // 컬렉션뷰 등록 및 설정
        placesCollectionView.register(CourseSubPlaceCell.self, forCellWithReuseIdentifier: "CourseSubPlaceCell")
        placesCollectionView.dataSource = self
        placesCollectionView.delegate = self
        
        // 레이아웃 설정
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 180, height: 220)
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        placesCollectionView.collectionViewLayout = layout
        
        // 디자인 설정
        placesCollectionView.backgroundColor = .clear
        placesCollectionView.showsHorizontalScrollIndicator = false
    }
    
    private func setupUI() {
        // 피커뷰 스타일 설정
        cityPickerView.layer.cornerRadius = 15
        cityPickerView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        
        // 상세 정보 컨테이너 스타일링
        courseInfoContainer.layer.cornerRadius = 20
        courseInfoContainer.clipsToBounds = true
        UITheme.applyShadow(to: courseInfoContainer, opacity: 0.2, radius: 8)
        
        // 코스 정보 뷰 스타일링
        courseInfoView.layer.cornerRadius = 15
        courseInfoView.clipsToBounds = true
        
        // 코스 이미지 스타일링
        courseImage.layer.cornerRadius = 10
        courseImage.clipsToBounds = true
        courseImage.contentMode = .scaleAspectFill
        
        // 레이블 스타일링
        courseTitle.font = UITheme.titleFont
        courseTitle.textColor = UITheme.textGray
        
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
        
        // 컬렉션뷰 스타일링
        placesCollectionView.backgroundColor = UITheme.backgroundGray
        
        // 설명 레이블 스타일 설정
        descriptionLabel.layer.cornerRadius = 15
        descriptionLabel.clipsToBounds = true
        descriptionLabel.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        
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
                    self.descriptionLabel.text = "데이터를 불러오는데 실패했습니다. 다시 시도해주세요."
                }
                return
            }
            
            // 먼저 데이터를 안전하게 저장
            self.courses = wrapper.response.body.items.item
            
            DispatchQueue.main.async {
                self.cityPickerView.reloadAllComponents()
                
                if self.courses.isEmpty {
                    self.loadingIndicator.stopAnimating()
                    self.descriptionLabel.text = "해당 위치에 추천 코스가 없습니다. 다른 위치에서 시도해보세요."
                    self.courseInfoContainer.isHidden = true
                } else {
                    self.selectedCourseIndex = 0
                    self.cityPickerView.selectRow(0, inComponent: 0, animated: false)
                    self.loadCourseDetails(for: 0)
                }
            }
        }.resume()
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
                self.descriptionLabel.text = "코스 정보를 불러올 수 없습니다."
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
            
            self.updateDetailUI(for: index)
            self.loadingIndicator.stopAnimating()
            self.courseInfoContainer.isHidden = false
            
            // 컬렉션뷰 리로드
            self.placesCollectionView.reloadData()
        }
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
            descriptionLabel.text = "코스 정보가 없습니다."
            courseInfoContainer.isHidden = true
            return
        }
        
        let course = courses[index]
        
        // 코스 기본 정보 업데이트
        courseTitle.text = course.title
        
        // 이미지 설정
        if let urlStr = course.firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
            courseImage.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        self?.courseImage.image = img
                    }
                }
            }.resume()
        } else {
            courseImage.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            courseImage.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        }
        
    // DetailIntro 정보 업데이트 부분 수정
    if let detailIntro = course.detailIntro {
        courseDistance.text = "🚶 코스 길이: \(detailIntro.distance)"
        courseTaketime.text = "⏱ 소요시간: \(detailIntro.taketime)"
    
        // cat2 코드로 코스 유형 결정
        let courseType = getCourseTypeText(cat2: course.cat2)
        courseTheme.text = "   \(courseType)   "
    } else {
        courseDistance.text = "🚶 거리: 정보 없음"
        courseTaketime.text = "⏱ 소요시간: 정보 없음"
        courseTheme.text = "   추천코스   "
    }

    // 코스 유형 변환 함수 추가
    func getCourseTypeText(cat2: String?) -> String {
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
        
        // 주소 및 기타 정보로 설명 레이블 업데이트
        var addressInfo = ""
        if let addr1 = course.addr1, !addr1.isEmpty {
            addressInfo += "📍 주소: \(addr1)"
            
            if let addr2 = course.addr2, !addr2.isEmpty {
                addressInfo += " \(addr2)"
            }
        }
        
        if let tel = course.tel, !tel.isEmpty {
            addressInfo += "\n☎️ 연락처: \(tel)"
        }
        
        // 서브 플레이스 개수 정보 추가
        let placeCount = course.subPlaces?.count ?? 0
        let placeCountText = placeCount > 0 ? 
            "\n🔍 이 코스에는 \(placeCount)개의 장소가 포함되어 있습니다." : 
            "\n🔍 이 코스의 세부 장소 정보가 없습니다."
        
        descriptionLabel.text = addressInfo.isEmpty ? placeCountText : addressInfo + placeCountText
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension HomeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return courses.count
    }
}

extension HomeViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        // 안전 체크
        guard !courses.isEmpty, row < courses.count else {
            let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width * 0.8, height: 200))
            emptyView.backgroundColor = .clear
            return emptyView
        }
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width * 0.8, height: 200))
        
        // 카드 효과를 위한 배경 뷰
        let cardView = UIView(frame: CGRect(x: 20, y: 10, width: containerView.frame.width - 40, height: containerView.frame.height - 20))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        UITheme.applyShadow(to: cardView)
        
        // 이미지뷰
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: cardView.frame.width - 20, height: 130))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        
        // 제목 레이블
        let nameLabel = UILabel(frame: CGRect(x: 10, y: imageView.frame.maxY + 5, width: cardView.frame.width - 20, height: 40))
        nameLabel.text = courses[row].title
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.numberOfLines = 2
        nameLabel.textColor = .darkText
        
        // 이미지 로드
        if let urlStr = courses[row].firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
            imageView.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        imageView.image = img
                    }
                }
            }.resume()
        } else {
            imageView.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        }
        
        cardView.addSubview(imageView)
        cardView.addSubview(nameLabel)
        containerView.addSubview(cardView)
        
        return containerView
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 220
    }
    
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
    private let descriptionLabel = UILabel()
    
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
        
        // 설명 라벨 설정
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = UITheme.secondaryTextGray
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        // 레이아웃 설정
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            numberLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5),
            numberLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 5),
            numberLabel.widthAnchor.constraint(equalToConstant: 20),
            numberLabel.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
        numberLabel.text = nil
        descriptionLabel.text = nil
    }
    
    func configure(with subPlace: CourseSubPlace) {
        nameLabel.text = subPlace.subname
        numberLabel.text = "\(subPlace.subnum + 1)"
        
        // 설명 텍스트 처리 - 길이 제한
        let maxLength = 50
        let overview = subPlace.subdetailoverview
        if overview.count > maxLength {
            let index = overview.index(overview.startIndex, offsetBy: maxLength)
            descriptionLabel.text = overview[..<index] + "..."
        } else {
            descriptionLabel.text = overview
        }
        
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