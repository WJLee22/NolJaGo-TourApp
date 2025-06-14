//
//  MapViewController.swift
//  NolJaGo-TourApp
//
//  Created by wjlee on 5/8/25.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var categorySegmentedControl: UISegmentedControl!
    
    // 현재 선택된 카테고리
    private var selectedContentTypeId: String = "12" // 기본값: 관광지
    private var annotations = [MKPointAnnotation]()
    private var courses: [Course] = []
    
    // 상세 정보를 표시할 팝업 뷰
    private var infoCardView: UIView?
    private var selectedCourse: Course?
    private var selectedIndex: Int?
    
    // 선택된 어노테이션을 추적하기 위한 변수
    private var selectedAnnotation: MKAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        mapView.delegate = self
        mapView.showsUserLocation = true // 사용자 위치 표시 활성화
        
        // 현재 위치로 이동하는 버튼 추가
        addCurrentLocationButton()
        
        // 마커 클릭을 위한 설정 - 이전 코드 방식으로 변경
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(tapGesture)
    }
    
    // 현재 위치로 이동하는 버튼 추가
    private func addCurrentLocationButton() {
        let locationButton = UIButton(frame: CGRect(x: view.frame.width - 60, y: view.frame.height - 170, width: 50, height: 50))
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 25
        locationButton.layer.shadowColor = UIColor.black.cgColor
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        locationButton.layer.shadowOpacity = 0.2
        locationButton.layer.shadowRadius = 3
        
        // SF Symbol 또는 이미지 설정
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        locationButton.setImage(UIImage(systemName: "location.fill", withConfiguration: config), for: .normal)
        locationButton.tintColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        
        locationButton.addTarget(self, action: #selector(moveToCurrentLocation), for: .touchUpInside)
        view.addSubview(locationButton)
    }
    
    @objc private func moveToCurrentLocation() {
        if let location = HomeViewController.sharedLocation {
            moveToLocation(location: location.coordinate)
            
            // 애니메이션 효과
            UIView.animate(withDuration: 0.3, animations: {
                self.mapView.alpha = 0.7
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    self.mapView.alpha = 1.0
                }
            }
        }
    }
    
    private func setupUI() {
        // 세그먼트 컨트롤 스타일 설정
        categorySegmentedControl.backgroundColor = UIColor(red: 1.0, green: 0.93, blue: 0.85, alpha: 1.0)
        categorySegmentedControl.selectedSegmentTintColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        categorySegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        categorySegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 홈 화면에서 저장된 위치 정보 활용
        if let location = HomeViewController.sharedLocation {
            moveToLocation(location: location.coordinate)
            loadNearbyPlaces()
        } else {
            // 위치 정보가 없을 경우 한성대 위치 활용
            let fallbackLat = 37.582573
            let fallbackLon = 127.011159
            let coordinate = CLLocationCoordinate2D(latitude: fallbackLat, longitude: fallbackLon)
            moveToLocation(location: coordinate)
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: // 관광지
            selectedContentTypeId = "12"
        case 1: // 숙박시설
            selectedContentTypeId = "32"
        case 2: // 음식점
            selectedContentTypeId = "39"
        case 3: // 축제/공연/행사
            selectedContentTypeId = "15"
        default:
            selectedContentTypeId = "12"
        }
        
        hideInfoCardView()
        loadNearbyPlaces()
    }
    
    // MARK: - 주변 장소 데이터 로드
    private func loadNearbyPlaces() {
        guard let location = HomeViewController.sharedLocation else { return }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let serviceKey = "JaFInBZVqUQWbu41s8hN/sSLKXH57dqeTBSPpDSUrodv85m5BZqXrVl6xT15V5SsFMvHaz3a2VbyWRIDJlhIyQ=="
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/locationBasedList2?serviceKey=\(serviceKey)&mapX=\(lon)&mapY=\(lat)&radius=10000&MobileOS=IOS&MobileApp=NolJaGo&_type=json&arrange=E&contentTypeId=\(selectedContentTypeId)"
        
        guard let url = URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        
        // 로딩 인디케이터 표시
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.view.center
        activityIndicator.color = .orange
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
            
            guard let data = data, error == nil,
                  let wrapper = try? JSONDecoder().decode(TourResponse.self, from: data) else {
                return
            }
            
            self.courses = wrapper.response.body.items.item
            DispatchQueue.main.async {
                self.updateMapAnnotations()
            }
        }.resume()
    }
    
    // MARK: - 지도에 마커 업데이트
    private func updateMapAnnotations() {
        // 기존 마커 제거
        mapView.removeAnnotations(mapView.annotations)
        annotations.removeAll()
        
        for course in courses {
            guard let mapxStr = course.mapx, let mapyStr = course.mapy,
                  let mapx = Double(mapxStr), let mapy = Double(mapyStr) else {
                continue
            }
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: mapy, longitude: mapx)
            annotation.title = course.title
            
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }
    
    // MARK: - 지도 터치 처리 (이전 코드 방식)
    @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: mapView)
        
        // 기존 정보 카드 즉시 제거
        if let existingCard = infoCardView {
            existingCard.removeFromSuperview()
            infoCardView = nil
            // 선택된 어노테이션 해제
            if let annotation = selectedAnnotation {
                mapView.deselectAnnotation(annotation, animated: false) // 애니메이션 없이 즉시 해제
                selectedAnnotation = nil
            }
            selectedCourse = nil
            selectedIndex = nil
        }

        // 탭한 위치에 마커가 있는지 확인
        for annotation in mapView.annotations {
            if annotation is MKUserLocation { continue } // 사용자 위치 마커는 무시
            
            // 어노테이션 뷰를 가져와서 탭 위치와 비교
            if let annotationView = mapView.view(for: annotation) {
                let annotationViewPoint = gestureRecognizer.location(in: annotationView)
                if annotationView.bounds.contains(annotationViewPoint) {
                    // 마커가 탭된 경우
                    let annotationCoord = annotation.coordinate // 직접 사용
                    
                    for (index, course) in courses.enumerated() {
                        guard let mapxStr = course.mapx, let mapyStr = course.mapy,
                              let mapx = Double(mapxStr), let mapy = Double(mapyStr) else {
                            continue
                        }
                        
                        let latDiff = abs(annotationCoord.latitude - mapy)
                        let lonDiff = abs(annotationCoord.longitude - mapx)
                        
                        if latDiff < 0.000001 && lonDiff < 0.000001 {
                            selectedCourse = course
                            selectedIndex = index
                            selectedAnnotation = annotation // 현재 선택된 어노테이션 저장
                            mapView.selectAnnotation(annotation, animated: true) // 마커 선택 효과
                            showInfoCardForCourse(course, at: index) // 이 메서드를 호출
                            return // 일치하는 마커를 찾으면 더 이상 반복하지 않음
                        }
                    }
                }
            }
        }
        // 마커가 아닌 배경을 탭한 경우 (기존 카드가 이미 위에서 제거됨)
    }

    // MARK: - 장소 정보 카드 표시
    private func showInfoCardForCourse(_ course: Course, at index: Int) {
        // 카드 뷰 생성 - 높이를 줄여서 공유 버튼 공간 제거
        let cardView = UIView(frame: CGRect(x: 20, y: 140, width: view.frame.width - 40, height: 280))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowRadius = 4
        
        // 초기 상태 설정 - 투명하고 약간 작게
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        // 이미지 뷰
        let imageView = UIImageView(frame: CGRect(x: 15, y: 15, width: 120, height: 120))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        cardView.addSubview(imageView)
        
        // 로딩 인디케이터 추가
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        activityIndicator.color = .darkGray
        activityIndicator.startAnimating()
        imageView.addSubview(activityIndicator)
        
        // 제목 레이블
        let titleLabel = UILabel(frame: CGRect(x: 145, y: 15, width: cardView.frame.width - 160, height: 50))
        titleLabel.text = course.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        cardView.addSubview(titleLabel)
        
        // 카테고리 배지
        let categoryBadge = UIView(frame: CGRect(x: 145, y: 70, width: 60, height: 20))
        categoryBadge.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.2)
        categoryBadge.layer.cornerRadius = 10
        cardView.addSubview(categoryBadge)
        
        let categoryLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        categoryLabel.text = getCategoryName(for: selectedContentTypeId)
        categoryLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        categoryLabel.textColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        categoryLabel.textAlignment = .center
        categoryBadge.addSubview(categoryLabel)
        
        // 주소 레이블 (아이콘 추가)
        let addressIcon = UILabel(frame: CGRect(x: 145, y: 100, width: 15, height: 15))
        addressIcon.text = "📍"
        addressIcon.font = UIFont.systemFont(ofSize: 12)
        cardView.addSubview(addressIcon)
        
        let addressLabel = UILabel(frame: CGRect(x: 165, y: 95, width: cardView.frame.width - 180, height: 40))
        // addr2가 있으면 함께 표시
        var fullAddress = course.addr1 ?? "주소 정보 없음"
        if let addr2 = course.addr2, !addr2.isEmpty {
            fullAddress += " \(addr2)"
        }
        addressLabel.text = fullAddress
        addressLabel.font = UIFont.systemFont(ofSize: 13)
        addressLabel.textColor = .darkGray
        addressLabel.numberOfLines = 2
        cardView.addSubview(addressLabel)
        
        // 거리 정보 (아이콘 추가) - 개선된 포맷팅
        let distanceIcon = UILabel(frame: CGRect(x: 15, y: 145, width: 15, height: 15))
        distanceIcon.text = "📏"
        distanceIcon.font = UIFont.systemFont(ofSize: 12)
        cardView.addSubview(distanceIcon)
        
        let distanceLabel = UILabel(frame: CGRect(x: 35, y: 145, width: 120, height: 20))
        if let dist = course.dist, let distValue = Double(dist) {
            if distValue >= 1000 {
                // 1km 이상일 때는 km 단위로 표시 (소수점 1자리)
                distanceLabel.text = String(format: "%.1f km", distValue / 1000.0)
            } else {
                // 1km 미만일 때는 m 단위로 표시 (정수)
                distanceLabel.text = String(format: "%.0f m", distValue)
            }
        } else {
            distanceLabel.text = "거리 정보 없음"
        }
        distanceLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        distanceLabel.textColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        cardView.addSubview(distanceLabel)
        
        // 전화번호 (있는 경우)
        if let tel = course.tel, !tel.isEmpty {
            let phoneIcon = UILabel(frame: CGRect(x: 145, y: 145, width: 15, height: 15))
            phoneIcon.text = "📞"
            phoneIcon.font = UIFont.systemFont(ofSize: 12)
            cardView.addSubview(phoneIcon)
            
            let phoneLabel = UILabel(frame: CGRect(x: 165, y: 145, width: cardView.frame.width - 180, height: 20))
            phoneLabel.text = tel
            phoneLabel.font = UIFont.systemFont(ofSize: 13)
            phoneLabel.textColor = .darkGray
            cardView.addSubview(phoneLabel)
        }
        
        // 지역 정보 표시 - areacode 대신 다른 정보로 대체
        let locationIcon = UILabel(frame: CGRect(x: 15, y: 170, width: 15, height: 15))
        locationIcon.text = "ℹ️"
        locationIcon.font = UIFont.systemFont(ofSize: 12)
        cardView.addSubview(locationIcon)
        
        let locationLabel = UILabel(frame: CGRect(x: 35, y: 170, width: cardView.frame.width - 50, height: 20))
        locationLabel.text = "한국관광공사 제공 정보"
        locationLabel.font = UIFont.systemFont(ofSize: 11)
        locationLabel.textColor = .lightGray
        cardView.addSubview(locationLabel)
        
        // 구분선
        let separatorView = UIView(frame: CGRect(x: 15, y: 200, width: cardView.frame.width - 30, height: 1))
        separatorView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        cardView.addSubview(separatorView)
        
        // 버튼 컨테이너 - 위치 조정
        let buttonStackView = UIStackView(frame: CGRect(x: 20, y: 220, width: cardView.frame.width - 40, height: 40))
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        cardView.addSubview(buttonStackView)
        
        // 즐겨찾기 버튼
        let favoriteButton = UIButton()
        favoriteButton.setTitle("❤️ 찜하기", for: .normal)
        favoriteButton.setTitleColor(.white, for: .normal)
        favoriteButton.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        favoriteButton.layer.cornerRadius = 20
        favoriteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        favoriteButton.tag = index
        favoriteButton.addTarget(self, action: #selector(saveFavorite(_:)), for: .touchUpInside)
        buttonStackView.addArrangedSubview(favoriteButton)
        
        // 길찾기 버튼
        let directionButton = UIButton()
        directionButton.setTitle("🗺️ 길찾기", for: .normal)
        directionButton.setTitleColor(UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), for: .normal)
        directionButton.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.1)
        directionButton.layer.cornerRadius = 20
        directionButton.layer.borderWidth = 1
        directionButton.layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.3).cgColor
        directionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        directionButton.addTarget(self, action: #selector(openDirections), for: .touchUpInside)
        buttonStackView.addArrangedSubview(directionButton)
        
        // 닫기 버튼
        let closeButton = UIButton(frame: CGRect(x: cardView.frame.width - 40, y: 10, width: 30, height: 30))
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.darkGray, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        cardView.addSubview(closeButton)
        
        // 카드를 먼저 화면에 추가
        view.addSubview(cardView)
        infoCardView = cardView
        
        // 세련된 등장 애니메이션: 페이드 인 + 약간의 스케일 변화
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            cardView.alpha = 1.0
            cardView.transform = CGAffineTransform.identity
        })
        
        // 이미지는 카드 표시 후 비동기 로드
        if let urlStr = course.firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        // 인디케이터 제거
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        
                        // 이미지 페이드인 애니메이션
                        imageView.alpha = 0
                        imageView.image = img
                        UIView.animate(withDuration: 0.3) {
                            imageView.alpha = 1
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        // 이미지 로드 실패 시
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        imageView.image = UIImage(systemName: "photo")
                        imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                    }
                }
            }
            task.resume()
        } else {
            // URL이 없을 경우 즉시 기본 이미지 표시
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                imageView.image = UIImage(systemName: "photo")
                imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            }
        }
    }

    @objc private func openDirections() {
        guard let course = selectedCourse else { return }
        
        if let mapxStr = course.mapx, let mapyStr = course.mapy,
           let mapx = Double(mapxStr), let mapy = Double(mapyStr) {
            
            let coordinate = CLLocationCoordinate2D(latitude: mapy, longitude: mapx)
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = course.title
            
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }

    @objc private func hideInfoCardView(completion: (() -> Void)? = nil) {
        guard let cardView = infoCardView else {
            completion?()
            return
        }
        
        // 세련된 퇴장 애니메이션: 페이드 아웃 + 약간의 스케일 변화
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            cardView.removeFromSuperview()
            
            // 마커 강조 효과 해제
            if let annotation = self.selectedAnnotation {
                self.mapView.deselectAnnotation(annotation, animated: true)
                self.selectedAnnotation = nil
            }
            
            // 상태 초기화
            self.infoCardView = nil
            self.selectedCourse = nil
            self.selectedIndex = nil
            
            completion?()
        })
    }

    @objc private func closeButtonTapped() {
        hideInfoCardView()
    }

    @objc private func saveFavorite(_ sender: UIButton) {
        guard let course = selectedCourse else { return }
        
        // FavoritePlace 객체 생성
        let favoritePlace = FavoritePlace(
            id: course.contentid ?? UUID().uuidString,
            title: course.title,
            address: course.addr1 ?? "주소 정보 없음",
            imageUrl: course.firstimage ?? "",
            latitude: Double(course.mapy ?? "0") ?? 0,
            longitude: Double(course.mapx ?? "0") ?? 0,
            category: getCategoryName(for: selectedContentTypeId)
        )
        
        // UserDefaults에 저장
        saveFavoritePlaceToUserDefaults(favoritePlace)
        
        // 저장 확인 메시지
        let alert = UIAlertController(title: "저장 완료", message: "'\(course.title)'이(가) 찜 목록에 추가되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func getCategoryName(for contentTypeId: String) -> String {
        switch contentTypeId {
        case "12": return "관광지"
        case "32": return "숙박"
        case "39": return "음식점"
        case "15": return "축제/공연/행사"
        default: return "기타"
        }
    }
    
    private func saveFavoritePlaceToUserDefaults(_ place: FavoritePlace) {
        // 기존 저장된 목록 불러오기
        var favoritePlaces = loadFavoritePlaces()
        
        // 동일한 ID가 있는지 확인 (중복 방지)
        if !favoritePlaces.contains(where: { $0.id == place.id }) {
            favoritePlaces.append(place)
            
            // JSON 인코딩 후 저장
            if let encoded = try? JSONEncoder().encode(favoritePlaces) {
                UserDefaults.standard.set(encoded, forKey: "favoritePlaces")
            }
        }
    }
    
    private func loadFavoritePlaces() -> [FavoritePlace] {
        if let savedData = UserDefaults.standard.data(forKey: "favoritePlaces"),
           let decoded = try? JSONDecoder().decode([FavoritePlace].self, from: savedData) {
            return decoded
        }
        return []
    }
    
    private func moveToLocation(location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 사용자 현재 위치는 기본 파란점으로 표시
        if annotation is MKUserLocation {
            return nil
        }
        
        // 기존 마커 처리 코드
        let identifier = "PlaceMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }
        
        if let markerView = annotationView as? MKMarkerAnnotationView {
            // 카테고리별 마커 스타일 설정
            switch selectedContentTypeId {
            case "12": // 관광지
                markerView.markerTintColor = .systemBlue
                markerView.glyphImage = UIImage(systemName: "mountain.2")
            case "32": // 숙박시설
                markerView.markerTintColor = .systemPurple
                markerView.glyphImage = UIImage(systemName: "bed.double")
            case "39": // 음식점
                markerView.markerTintColor = .systemRed
                markerView.glyphImage = UIImage(systemName: "fork.knife")
            case "15": // 축제/공연/행사
                markerView.markerTintColor = .systemGreen
                markerView.glyphImage = UIImage(systemName: "music.note")
            default:
                markerView.markerTintColor = .systemOrange
            }
        }
        
        return annotationView
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - 즐겨찾기 모델
struct FavoritePlace: Codable {
    let id: String
    let title: String
    let address: String
    let imageUrl: String
    let latitude: Double
    let longitude: Double
    let category: String
    let savedDate: Date = Date()
}

