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
    @IBOutlet weak var locationLabel: UILabel!
    
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
        
        // 위치 레이블 업데이트 및 스타일 설정
        updateLocationLabel()
        setupLocationLabelStyle()
        
        // 찜한 장소에서 위치 표시 요청 수신하기 위한 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showLocationFromFavorites(_:)),
            name: NSNotification.Name("ShowLocationOnMap"),
            object: nil
        )
    }
    
    // 찜한 장소에서 위치 표시 요청 수신 처리
    @objc private func showLocationFromFavorites(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let latitude = userInfo["latitude"] as? Double,
              let longitude = userInfo["longitude"] as? Double,
              let title = userInfo["title"] as? String,
              let category = userInfo["category"] as? String else {
            return
        }
        
        // 이전 카드 닫기
        hideInfoCardView()
        
        // 지도 이동
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        moveToLocation(location: coordinate)
        
        // 해당 카테고리로 세그먼트 컨트롤 변경
        switch category {
        case "관광지":
            categorySegmentedControl.selectedSegmentIndex = 0
            selectedContentTypeId = "12"
        case "숙박":
            categorySegmentedControl.selectedSegmentIndex = 1
            selectedContentTypeId = "32"
        case "음식점":
            categorySegmentedControl.selectedSegmentIndex = 2
            selectedContentTypeId = "39"
        case "축제/행사":
            categorySegmentedControl.selectedSegmentIndex = 3
            selectedContentTypeId = "15"
        default:
            break
        }
        
        // 주변 장소 데이터 로드 후 마커 표시
        loadNearbyPlaces()
        
        // 알림으로 마커 선택됨을 알림
        NotificationCenter.default.post(
            name: NSNotification.Name("LocationOnMapUpdated"),
            object: nil
        )
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
        // 세그먼트 컨트롤 스타일 설정 - 더 매력적으로
        categorySegmentedControl.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
        categorySegmentedControl.selectedSegmentTintColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        categorySegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], for: .normal)
        categorySegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
        ], for: .selected)
        
        // 세그먼트 컨트롤에 그림자 효과 추가
        categorySegmentedControl.layer.shadowColor = UIColor.black.cgColor
        categorySegmentedControl.layer.shadowOffset = CGSize(width: 0, height: 1)
        categorySegmentedControl.layer.shadowOpacity = 0.1
        categorySegmentedControl.layer.shadowRadius = 3
        categorySegmentedControl.layer.cornerRadius = 15
    }
    
    private func setupLocationLabelStyle() {
        // 위치 레이블 컨테이너 뷰 스타일링
        if let containerView = locationLabel.superview {
            // 그라디언트 배경 생성
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = containerView.bounds
            gradientLayer.colors = [
                UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0).cgColor,
                UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0)
            gradientLayer.cornerRadius = 25
            
            // 기존 배경색 제거하고 그라디언트 추가
            containerView.backgroundColor = UIColor.clear
            containerView.layer.insertSublayer(gradientLayer, at: 0)
            
            // 컨테이너 뷰 스타일링
            containerView.layer.cornerRadius = 25
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
            containerView.layer.shadowOpacity = 0.2
            containerView.layer.shadowRadius = 5
            
            // 테두리 효과
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        }
        
        // 위치 레이블 텍스트 스타일링
        locationLabel.textColor = .white
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        locationLabel.textAlignment = .center
        locationLabel.numberOfLines = 2
        
        // 텍스트 그림자 효과
        locationLabel.layer.shadowColor = UIColor.black.cgColor
        locationLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        locationLabel.layer.shadowOpacity = 0.3
        locationLabel.layer.shadowRadius = 2
    }
    
    private func updateLocationLabel() {
        if let locationName = HomeViewController.sharedLocationName {
            // 애니메이션과 함께 텍스트 업데이트
            UIView.transition(with: locationLabel, duration: 0.3, options: .transitionCrossDissolve) {
                // 위치명이 너무 길면 줄바꿈 처리
                if locationName.count > 25 {
                    let components = locationName.components(separatedBy: ", ")
                    if components.count > 1 {
                        let firstLine = components[0]
                        let remainingComponents = Array(components.dropFirst())
                        let secondLine = remainingComponents.joined(separator: ", ")
                        self.locationLabel.text = "🌏 \(firstLine)\n\(secondLine)"
                    } else {
                        self.locationLabel.text = "🌏 \(locationName)"
                    }
                } else {
                    self.locationLabel.text = "🌏 \(locationName)"
                }
            }
            
            // 펄스 애니메이션 효과
            addPulseAnimation()
        } else {
            locationLabel.text = "🌏 현재 위치를 확인하는 중..."
            
            // 로딩 애니메이션
            addLoadingAnimation()
        }
    }
    
    private func addPulseAnimation() {
        guard let containerView = locationLabel.superview else { return }
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 2
        
        containerView.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func addLoadingAnimation() {
        guard let containerView = locationLabel.superview else { return }
        
        let shimmerAnimation = CABasicAnimation(keyPath: "opacity")
        shimmerAnimation.duration = 1.0
        shimmerAnimation.fromValue = 0.7
        shimmerAnimation.toValue = 1.0
        shimmerAnimation.autoreverses = true
        shimmerAnimation.repeatCount = .infinity
        
        containerView.layer.add(shimmerAnimation, forKey: "loading")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 위치 정보가 업데이트되었을 수 있으므로 다시 확인
        updateLocationLabel()
        
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
            
            // fallback 위치에 대한 간단한 주소 정보 가져오기 (중복 제거)
            let fallbackLocation = CLLocation(latitude: fallbackLat, longitude: fallbackLon)
            CLGeocoder().reverseGeocodeLocation(fallbackLocation) { placemarks, error in
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
                        let fallbackAddress = addressComponents.joined(separator: " ")
                        HomeViewController.sharedLocationName = fallbackAddress
                        
                        DispatchQueue.main.async {
                            self.updateLocationLabel()
                        }
                    }
                }
            }
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
        // numOfRows=100 추가로 더 많은 장소 표시
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/locationBasedList2?serviceKey=\(serviceKey)&mapX=\(lon)&mapY=\(lat)&radius=10000&MobileOS=IOS&MobileApp=NolJaGo&_type=json&arrange=E&contentTypeId=\(selectedContentTypeId)&numOfRows=30"
        
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
            print("맵에서 로드된 장소 수: \(self.courses.count)") // 디버깅용
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
        //let tapPoint = gestureRecognizer.location(in: mapView)
        
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

    }
    
    // MARK: - 장소 정보 카드 표시
    private func showInfoCardForCourse(_ course: Course, at index: Int) {
        // 카드 뷰 생성
        let cardView = UIView(frame: CGRect(x: 15, y: 140, width: view.frame.width - 30, height: 290))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowOpacity = 0.15
        cardView.layer.shadowRadius = 8
        
        // 초기 상태 설정 - 투명하고 약간 작게
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        // 이미지 컨테이너 - 그림자 효과를 위한 컨테이너
        let imageContainer = UIView(frame: CGRect(x: 20, y: 20, width: 130, height: 130))
        imageContainer.backgroundColor = .clear
        imageContainer.layer.shadowColor = UIColor.black.cgColor
        imageContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageContainer.layer.shadowOpacity = 0.1
        imageContainer.layer.shadowRadius = 4
        cardView.addSubview(imageContainer)
        
        // 이미지 뷰 - 컨테이너 내부에 배치
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 130, height: 130))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        imageContainer.addSubview(imageView)
        
        // 로딩 인디케이터
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        activityIndicator.color = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        activityIndicator.startAnimating()
        imageView.addSubview(activityIndicator)
        
        // 제목 레이블 - 닫기 버튼과 겹치지 않도록 너비 조정
        let titleLabel = UILabel(frame: CGRect(x: 165, y: 20, width: cardView.frame.width - 220, height: 55))
        titleLabel.text = course.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        cardView.addSubview(titleLabel)
        
        // 카테고리 배지 - 더 세련된 디자인
        let categoryBadgeWidth: CGFloat = 70
        let categoryBadge = UIView(frame: CGRect(x: 165, y: 80, width: categoryBadgeWidth, height: 24))
        categoryBadge.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.2)
        categoryBadge.layer.cornerRadius = 12
        categoryBadge.layer.borderWidth = 1
        categoryBadge.layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.4).cgColor
        cardView.addSubview(categoryBadge)
        
        let categoryLabel = UILabel(frame: CGRect(x: 0, y: 0, width: categoryBadgeWidth, height: 24))
        let categoryText = getCategoryName(for: selectedContentTypeId)
        // 축제/공연/행사 → 축제/행사로 변경
        categoryLabel.text = categoryText == "축제/공연/행사" ? "축제/행사" : categoryText
        categoryLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        categoryLabel.textColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        categoryLabel.textAlignment = .center
        categoryBadge.addSubview(categoryLabel)
        
        // 주소 레이블 - 더 명확한 아이콘과 스타일
        let addressIcon = UILabel(frame: CGRect(x: 165, y: 115, width: 20, height: 20))
        addressIcon.text = "🌏"
        addressIcon.font = UIFont.systemFont(ofSize: 14)
        cardView.addSubview(addressIcon)
        
        let addressLabel = UILabel(frame: CGRect(x: 190, y: 115, width: cardView.frame.width - 210, height: 35))
        var fullAddress = course.addr1 ?? "주소 정보 없음"
        if let addr2 = course.addr2, !addr2.isEmpty {
            fullAddress += " \(addr2)"
        }
        addressLabel.text = fullAddress
        addressLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        addressLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        addressLabel.numberOfLines = 2
        cardView.addSubview(addressLabel)
        
        // 거리 정보 - 더 돋보이는 스타일
        let distanceIcon = UILabel(frame: CGRect(x: 20, y: 165, width: 20, height: 20))
        distanceIcon.text = "📏"
        distanceIcon.font = UIFont.systemFont(ofSize: 14)
        cardView.addSubview(distanceIcon)
        
        let distanceLabel = UILabel(frame: CGRect(x: 45, y: 165, width: 100, height: 20))
        if let dist = course.dist, let distValue = Double(dist) {
            if distValue >= 1000 {
                distanceLabel.text = String(format: "%.1f km", distValue / 1000.0)
            } else {
                distanceLabel.text = String(format: "%.0f m", distValue)
            }
        } else {
            distanceLabel.text = "거리 정보 없음"
        }
        distanceLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        distanceLabel.textColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        cardView.addSubview(distanceLabel)
        
        // 전화번호 (있는 경우) - 더 명확한 표시
        if let tel = course.tel, !tel.isEmpty {
            let phoneIcon = UILabel(frame: CGRect(x: 160, y: 165, width: 20, height: 20))
            phoneIcon.text = "📞"
            phoneIcon.font = UIFont.systemFont(ofSize: 14)
            cardView.addSubview(phoneIcon)
            
            let phoneLabel = UILabel(frame: CGRect(x: 185, y: 165, width: cardView.frame.width - 205, height: 20))
            phoneLabel.text = tel
            phoneLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            phoneLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            cardView.addSubview(phoneLabel)
        }
        
        // 정보 제공처 - 더 크고 잘 보이게 개선
        let infoContainer = UIView(frame: CGRect(x: 20, y: 190, width: cardView.frame.width - 40, height: 22))
        infoContainer.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        infoContainer.layer.cornerRadius = 11
        cardView.addSubview(infoContainer)
        
        let infoIcon = UILabel(frame: CGRect(x: 10, y: 3, width: 16, height: 16))
        infoIcon.text = "ℹ️"
        infoIcon.font = UIFont.systemFont(ofSize: 12)
        infoContainer.addSubview(infoIcon)
        
        let infoLabel = UILabel(frame: CGRect(x: 30, y: 3, width: infoContainer.frame.width - 40, height: 16))
        infoLabel.text = "한국관광공사 제공 정보"
        infoLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        infoLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        infoLabel.textAlignment = .left
        infoContainer.addSubview(infoLabel)
        
        // 구분선
        let separatorView = UIView(frame: CGRect(x: 20, y: 220, width: cardView.frame.width - 40, height: 1))
        separatorView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        cardView.addSubview(separatorView)
        
        // 버튼 컨테이너
        let buttonStackView = UIStackView(frame: CGRect(x: 20, y: 235, width: cardView.frame.width - 40, height: 45))
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 15
        cardView.addSubview(buttonStackView)
        
        // 즐겨찾기 버튼
        let favoriteButton = UIButton()
        favoriteButton.setTitle("❤️ 찜하기", for: .normal)
        favoriteButton.setTitleColor(.white, for: .normal)
        favoriteButton.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        favoriteButton.layer.cornerRadius = 22
        favoriteButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        favoriteButton.layer.shadowColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.4).cgColor
        favoriteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        favoriteButton.layer.shadowOpacity = 1.0
        favoriteButton.layer.shadowRadius = 4
        favoriteButton.tag = index
        favoriteButton.addTarget(self, action: #selector(saveFavorite(_:)), for: .touchUpInside)
        buttonStackView.addArrangedSubview(favoriteButton)
        
        // 길찾기 버튼
        let directionButton = UIButton()
        directionButton.setTitle("🔎 길찾기", for: .normal)
        directionButton.setTitleColor(UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), for: .normal)
        directionButton.backgroundColor = UIColor.white
        directionButton.layer.cornerRadius = 22
        directionButton.layer.borderWidth = 2
        directionButton.layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0).cgColor
        directionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        directionButton.layer.shadowColor = UIColor.lightGray.cgColor
        directionButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        directionButton.layer.shadowOpacity = 0.3
        directionButton.layer.shadowRadius = 4
        directionButton.addTarget(self, action: #selector(openDirections), for: .touchUpInside)
        buttonStackView.addArrangedSubview(directionButton)
        
        // 닫기 버튼
        let closeButton = UIButton(frame: CGRect(x: cardView.frame.width - 50, y: 10, width: 40, height: 40))
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        closeButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        cardView.addSubview(closeButton)
        
        // 카드를 화면에 추가
        view.addSubview(cardView)
        infoCardView = cardView
        
        // 애니메이션
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            cardView.alpha = 1.0
            cardView.transform = CGAffineTransform.identity
        })
        
        // 이미지 로드
        if let urlStr = course.firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        
                        imageView.alpha = 0
                        imageView.image = img
                        UIView.animate(withDuration: 0.3) {
                            imageView.alpha = 1
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        
                        let placeholderConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
                        imageView.image = UIImage(systemName: "photo", withConfiguration: placeholderConfig)
                        imageView.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
                        imageView.contentMode = .center
                    }
                }
            }
            task.resume()
        } else {
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                
                let placeholderConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
                imageView.image = UIImage(systemName: "photo", withConfiguration: placeholderConfig)
                imageView.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
                imageView.contentMode = .center
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
        
        // 퇴장 애니메이션
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            cardView.removeFromSuperview()
            
            if let annotation = self.selectedAnnotation {
                self.mapView.deselectAnnotation(annotation, animated: true)
                self.selectedAnnotation = nil
            }
            
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
        
        // 주소 형식 통일 - addr2가 있으면 포함
        var fullAddress = course.addr1 ?? "주소 정보 없음"
        if let addr2 = course.addr2, !addr2.isEmpty {
            fullAddress += " " + addr2
        }
        
        // FavoritePlace 객체 생성
        let favoritePlace = FavoritePlace(
            id: course.contentid ?? UUID().uuidString,
            title: course.title,
            address: fullAddress,
            imageUrl: course.firstimage ?? "",
            latitude: Double(course.mapy ?? "0") ?? 0,
            longitude: Double(course.mapx ?? "0") ?? 0,
            category: getCategoryName(for: selectedContentTypeId),
            tel: course.tel ?? "",
            savedDate: Date()
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
        case "15": return "축제/행사"  
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
        
        // 마커 처리 코드 개선
        let identifier = "PlaceMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            let markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            markerView.canShowCallout = false
            annotationView = markerView
        } else {
            annotationView?.annotation = annotation
        }
        
        if let markerView = annotationView as? MKMarkerAnnotationView {
            // 카테고리별 마커 스타일 설정 - 더 명확하고 세련되게
            switch selectedContentTypeId {
            case "12": // 관광지
                markerView.markerTintColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
                markerView.glyphImage = UIImage(systemName: "mountain.2")
                markerView.glyphTintColor = .white
            case "32": // 숙박시설
                markerView.markerTintColor = UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)
                markerView.glyphImage = UIImage(systemName: "bed.double")
                markerView.glyphTintColor = .white
            case "39": // 음식점
                markerView.markerTintColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
                markerView.glyphImage = UIImage(systemName: "fork.knife")
                markerView.glyphTintColor = .white
            case "15": // 축제/행사
                markerView.markerTintColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
                markerView.glyphImage = UIImage(systemName: "music.note")
                markerView.glyphTintColor = .white
            default:
                markerView.markerTintColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
                markerView.glyphTintColor = .white
            }
            
            // 마커 효과 추가
            markerView.animatesWhenAdded = true
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
    let tel: String
    let savedDate: Date
}

