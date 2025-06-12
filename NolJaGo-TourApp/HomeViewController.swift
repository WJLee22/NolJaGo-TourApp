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
    
    // courses array populated from TourAPI
    var courses: [Course] = []
    private let locationManager = CLLocationManager()
    
    // 현재 위치 정보를 앱 전역에서 공유할 수 있게 싱글톤 사용
    static var sharedLocation: CLLocation?
    static var sharedLocationName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
        
        cityPickerView.dataSource = self
        cityPickerView.delegate = self
        
        // 위치를 못 찾을 경우 5초 후 타임아웃으로 기본값 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if HomeViewController.sharedLocation == nil && self?.courses.isEmpty == true {
                // 📍 한성대 상상빌리지 fallback
                let fallbackLat = 37.582573
                let fallbackLon = 127.011159
                self?.locationLabel.text = "📍 현재 위치: 서울특별시 삼선동2가"
                self?.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
            }
        }
    }
    
    private func setupUI() {
        // 피커뷰 스타일 설정
        cityPickerView.layer.cornerRadius = 15
        cityPickerView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        
        // 설명 레이블 스타일 설정
        descriptionLabel.layer.cornerRadius = 15
        descriptionLabel.clipsToBounds = true
        descriptionLabel.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1.0)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        
        // 위치 레이블 스타일 설정
        locationLabel.font = UIFont.boldSystemFont(ofSize: 17)
        locationLabel.textColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
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
            self.locationLabel.text = "📍 현재 위치: 서울특별시 삼선동2가"
            self.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
        @unknown default:
            break
        }
    }
    
    // MARK: - Load Courses from TourAPI
    func loadCourses(longitude lon: Double, latitude lat: Double) {
        HomeViewController.sharedLocation = CLLocation(latitude: lat, longitude: lon)
        
        let serviceKey = "JaFInBZVqUQWbu41s8hN/sSLKXH57dqeTBSPpDSUrodv85m5BZqXrVl6xT15V5SsFMvHaz3a2VbyWRIDJlhIyQ=="
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/locationBasedList2?serviceKey=\(serviceKey)&mapX=\(lon)&mapY=\(lat)&radius=10000&MobileOS=IOS&MobileApp=NolJaGo&_type=json&arrange=E&contentTypeId=25"
        guard let url = URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        
        // 로딩 표시
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
                DispatchQueue.main.async {
                    self.descriptionLabel.text = "데이터를 불러오는데 실패했습니다. 다시 시도해주세요."
                }
                return
            }
            self.courses = wrapper.response.body.items.item
            DispatchQueue.main.async {
                self.cityPickerView.reloadAllComponents()
                if self.courses.isEmpty {
                    self.descriptionLabel.text = "해당 위치에 추천 코스가 없습니다. 다른 위치에서 시도해보세요."
                } else {
                    self.cityPickerView.selectRow(0, inComponent: 0, animated: false)
                    self.updateDetail(for: 0)
                }
            }
        }.resume()
    }
    
    // MARK: - Update Detail Box
    func updateDetail(for index: Int) {
        guard index >= 0, index < courses.count else {
            descriptionLabel.text = "코스 정보가 없습니다."
            return
        }
        
        let course = courses[index]
        
        // HTML 포맷을 사용하여 풍부한 정보 표시
        let htmlContent = """
        <html>
        <head>
            <style>
                body {
                    font-family: -apple-system, 'SF Pro Display';
                    margin: 0;
                    padding: 10px;
                    color: #333;
                }
                .title {
                    font-size: 18px;
                    font-weight: bold;
                    color: #333;
                    margin-bottom: 10px;
                }
                .info {
                    font-size: 14px;
                    margin: 5px 0;
                    color: #555;
                }
                .highlight {
                    color: #F60;
                    font-weight: bold;
                }
                .address {
                    margin-top: 5px;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="title">📍 \(course.title)</div>
        """
        
        // 주소 정보 추가
        var contentHtml = htmlContent
        if let addr = course.addr1, !addr.isEmpty {
            contentHtml += "<div class='address'>주소: \(addr)</div>"
        }
        
        if let addr2 = course.addr2, !addr2.isEmpty {
            contentHtml += "<div class='address'>\(addr2)</div>"
        }
        
        // 거리 정보 추가
        if let dist = course.dist {
            if let distInt = Int(dist) {
                let distanceText = distInt > 1000 ? 
                    String(format: "%.1f km", Double(distInt) / 1000.0) : 
                    "\(dist) m"
                contentHtml += "<div class='info'>현재 위치로부터 거리: <span class='highlight'>\(distanceText)</span></div>"
            } else {
                contentHtml += "<div class='info'>거리: \(dist)</div>"
            }
        }
        
        // 전화번호 정보 추가 (있을 경우)
        if let tel = course.tel, !tel.isEmpty {
            contentHtml += "<div class='info'>연락처: \(tel)</div>"
        }
        
        // 카테고리 정보 표시 (있을 경우)
        if let cat3 = course.cat3 {
            let categoryName = getCategoryName(for: cat3)
            contentHtml += "<div class='info'>카테고리: <span class='highlight'>\(categoryName)</span></div>"
        }
        
        contentHtml += "</body></html>"
        
        // HTML 컨텐츠를 NSAttributedString으로 변환
        if let htmlData = contentHtml.data(using: .utf8) {
            do {
                let attributedString = try NSAttributedString(
                    data: htmlData,
                    options: [.documentType: NSAttributedString.DocumentType.html,
                              .characterEncoding: String.Encoding.utf8.rawValue],
                    documentAttributes: nil
                )
                descriptionLabel.attributedText = attributedString
            } catch {
                print("HTML 변환 에러: \(error)")
                // 실패 시 기본 텍스트로 표시
                descriptionLabel.text = "📍 \(course.title)"
            }
        }
    }
    
    // 카테고리 코드에 따른 이름 반환
    private func getCategoryName(for categoryCode: String) -> String {
        switch categoryCode {
        case "C01110001": return "자연관광지"
        case "C01120001": return "역사/문화 관광지"
        case "C01130001": return "휴양/체험 관광지"
        case "C01140001": return "산업 관광지"
        case "C01150001": return "건축/조형물"
        case "C01160001": return "문화시설"
        case "C01170001": return "축제"
        case "C01180001": return "공연/행사"
        case "C01190001": return "레포츠"
        default: return "기타 관광지"
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


extension HomeViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width * 0.8, height: 200))
        
        // 카드 효과를 위한 배경 뷰
        let cardView = UIView(frame: CGRect(x: 20, y: 10, width: containerView.frame.width - 40, height: containerView.frame.height - 20))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowRadius = 4
        
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
        updateDetail(for: row)
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

        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            if let pm = placemarks?.first {
                let locality = pm.locality ?? ""
                let sub = pm.subLocality ?? ""
                let locationName = "\(locality) \(sub)".trimmingCharacters(in: .whitespaces)
                HomeViewController.sharedLocationName = locationName
                
                DispatchQueue.main.async {
                    self.locationLabel.text = "📍 현재 위치: \(locationName)"
                }
            }
        }

        loadCourses(longitude: lon, latitude: lat)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("위치 가져오기 실패: \(error.localizedDescription)")

        // 한성대 상상빌리지 fallback
        let fallbackLat = 37.582573
        let fallbackLon = 127.011159

        DispatchQueue.main.async {
            self.locationLabel.text = "📍 현재 위치: 서울특별시 삼선동2가"
            self.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: - Models for TourAPI
struct TourResponse: Decodable {
    let response: TourInnerResponse
}

struct TourInnerResponse: Decodable {
    let body: TourBody
}

struct TourBody: Decodable {
    let items: TourItems
    let numOfRows: Int?
    let pageNo: Int?
    let totalCount: Int?
}

struct TourItems: Decodable {
    let item: [Course]
}

struct Course: Decodable {
    let contentid: String?
    let title: String
    let firstimage: String?
    let firstimage2: String?
    let addr1: String?
    let addr2: String?
    let mapx: String?
    let mapy: String?
    let dist: String?
    let tel: String?
    let cat3: String?
    
    enum CodingKeys: String, CodingKey {
        case contentid, title, firstimage, firstimage2, addr1, addr2, mapx, mapy, dist, tel, cat3
    }
}
