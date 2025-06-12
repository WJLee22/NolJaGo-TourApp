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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        // 마커 클릭을 위한 설정
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(tapGesture)
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
    
    // MARK: - 지도 터치 처리
    @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // 먼저 현재 표시된 정보 카드 숨기기
        hideInfoCardView()
        
        let tapPoint = gestureRecognizer.location(in: mapView)
        
        // 탭한 지점에 마커가 있는지 확인
        for annotation in mapView.annotations {
            let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
            let distance = sqrt(pow(annotationPoint.x - tapPoint.x, 2) + pow(annotationPoint.y - tapPoint.y, 2))
            
            // 마커 주변 영역 (30포인트 이내)을 탭했다면
            if distance <= 30 {
                // 해당 마커에 대한 정보 표시
                for (index, course) in courses.enumerated() {
                    guard let mapxStr = course.mapx, let mapyStr = course.mapy,
                          let mapx = Double(mapxStr), let mapy = Double(mapyStr) else {
                        continue
                    }
                    
                    if annotation.coordinate.latitude == mapy && annotation.coordinate.longitude == mapx {
                        selectedCourse = course
                        showInfoCardForCourse(course, at: index)
                        break
                    }
                }
                break
            }
        }
    }
    
    // MARK: - 장소 정보 카드 표시
    private func showInfoCardForCourse(_ course: Course, at index: Int) {
        // 카드 뷰 생성
        let cardView = UIView(frame: CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 250))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowRadius = 4
        
        // 이미지 뷰
        let imageView = UIImageView(frame: CGRect(x: 15, y: 15, width: 120, height: 120))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        cardView.addSubview(imageView)
        
        // 제목 레이블
        let titleLabel = UILabel(frame: CGRect(x: 145, y: 15, width: cardView.frame.width - 160, height: 50))
        titleLabel.text = course.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        cardView.addSubview(titleLabel)
        
        // 주소 레이블
        let addressLabel = UILabel(frame: CGRect(x: 145, y: 70, width: cardView.frame.width - 160, height: 40))
        addressLabel.text = course.addr1 ?? "주소 정보 없음"
        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textColor = .darkGray
        addressLabel.numberOfLines = 2
        cardView.addSubview(addressLabel)
        
        // 거리 레이블
        let distanceLabel = UILabel(frame: CGRect(x: 145, y: 115, width: cardView.frame.width - 160, height: 20))
        if let dist = course.dist {
            // 안전한 Optional 처리로 변경
            if let distValue = Int(dist) {
                distanceLabel.text = distValue > 1000 ? 
                    String(format: "거리: %.1f km", Double(distValue) / 1000.0) : 
                    "거리: \(dist) m"
            } else {
                // 숫자로 변환할 수 없는 경우
                distanceLabel.text = "거리: \(dist)"
            }
        } else {
            distanceLabel.text = "거리 정보 없음"
        }
        distanceLabel.font = UIFont.systemFont(ofSize: 14)
        distanceLabel.textColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        cardView.addSubview(distanceLabel)
        
        // 구분선
        let separatorView = UIView(frame: CGRect(x: 15, y: 150, width: cardView.frame.width - 30, height: 1))
        separatorView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        cardView.addSubview(separatorView)
        
        // 즐겨찾기 버튼
        let favoriteButton = UIButton(frame: CGRect(x: cardView.frame.width / 2 - 75, y: 165, width: 150, height: 40))
        favoriteButton.setTitle("❤️ 찜하기", for: .normal)
        favoriteButton.setTitleColor(.white, for: .normal)
        favoriteButton.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        favoriteButton.layer.cornerRadius = 20
        favoriteButton.tag = index
        favoriteButton.addTarget(self, action: #selector(saveFavorite(_:)), for: .touchUpInside)
        cardView.addSubview(favoriteButton)
        
        // 닫기 버튼
        let closeButton = UIButton(frame: CGRect(x: cardView.frame.width - 40, y: 10, width: 30, height: 30))
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.darkGray, for: .normal)
        closeButton.addTarget(self, action: #selector(hideInfoCardView), for: .touchUpInside)
        cardView.addSubview(closeButton)
        
        // 이미지 로드
        if let urlStr = course.firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
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
        
        view.addSubview(cardView)
        infoCardView = cardView
        
        // 애니메이션 효과
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3) {
            cardView.alpha = 1
            cardView.transform = .identity
        }
    }
    
    @objc private func hideInfoCardView() {
        guard let cardView = infoCardView else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            cardView.removeFromSuperview()
            self.infoCardView = nil
            self.selectedCourse = nil
        }
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
        
        let identifier = "PlaceMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        // 마커 색상 설정 (카테고리별 다른 색상)
        if let markerView = annotationView as? MKMarkerAnnotationView {
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

