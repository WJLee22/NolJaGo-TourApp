//
//  CityViewController.swift
//  MultipleViewController
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        checkLocationAuthorization()
        
        cityPickerView.dataSource = self
        cityPickerView.delegate = self
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
            self.locationLabel.text = "위치 권한이 거부되어 한성대 상상빌리지로 기본 설정됩니다."
            self.loadCourses(longitude: fallbackLon, latitude: fallbackLat)
        @unknown default:
            break
        }
    }
    
    // MARK: - Load Courses from TourAPI
    func loadCourses(longitude lon: Double, latitude lat: Double) {
        let serviceKey = "JaFInBZVqUQWbu41s8hN/sSLKXH57dqeTBSPpDSUrodv85m5BZqXrVl6xT15V5SsFMvHaz3a2VbyWRIDJlhIyQ=="
        let urlStr = "https://apis.data.go.kr/B551011/KorService2/locationBasedList2?serviceKey=\(serviceKey)&mapX=\(lon)&mapY=\(lat)&radius=10000&MobileOS=IOS&MobileApp=NolJaGo&_type=json&arrange=E&contentTypeId=25"
        guard let url = URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let wrapper = try? JSONDecoder().decode(TourResponse.self, from: data) else {
                return
            }
            self.courses = wrapper.response.body.items.item
            DispatchQueue.main.async {
                self.cityPickerView.reloadAllComponents()
                if self.courses.isEmpty {
                    self.descriptionLabel.text = "해당 위치에 추천 코스가 없습니다."
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
        descriptionLabel.text = "\(course.title)\n거리: \(course.dist ?? "-")m"
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
        let nameLabel = UILabel()
        nameLabel.text = courses[row].title
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if let urlStr = courses[row].firstimage, !urlStr.isEmpty, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async {
                        imageView.image = img
                    }
                }
            }.resume()
        } else {
            imageView.image = UIImage(named: "placeholder") // Assets.xcassets에 추가된 기본 이미지
        }
        let outer = UIStackView(arrangedSubviews: [imageView, nameLabel])
        outer.axis = .vertical
        return outer
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.height * 0.8
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

        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            if let pm = placemarks?.first {
                let locality = pm.locality ?? ""
                let sub = pm.subLocality ?? ""
                DispatchQueue.main.async {
                    self.locationLabel.text = "현재 위치: \(locality) \(sub)"
                }
            }
        }

        loadCourses(longitude: lon, latitude: lat)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 가져오기 실패: \(error.localizedDescription)")

        // 📍 한성대 상상빌리지 fallback
        let fallbackLat = 35.1944
        let fallbackLon = 129.0593

        DispatchQueue.main.async {
            self.locationLabel.text = "기본 위치: 한성대학교 상상빌리지(부산)"
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
}
struct TourItems: Decodable {
    let item: [Course]
}
struct Course: Decodable {
    let title: String
    let firstimage: String?
    let dist: String?
}
