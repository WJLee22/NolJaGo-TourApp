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
            self.locationLabel.text = "위치 권한이 거부되었습니다."
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
            self.courses = wrapper.body.items.item
            DispatchQueue.main.async {
                self.cityPickerView.reloadAllComponents()
                if !self.courses.isEmpty {
                    self.cityPickerView.selectRow(0, inComponent: 0, animated: false)
                    self.updateDetail(for: 0)
                }
            }
        }.resume()
    }
    
    // MARK: - Update Detail Box
    func updateDetail(for index: Int) {
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
        if let urlStr = courses[row].firstimage, let url = URL(string: urlStr) {
            // simple async image load
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    DispatchQueue.main.async { imageView.image = img }
                }
            }.resume()
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
                    self.locationLabel.text = "\(locality) \(sub)"
                }
            }
        }

        loadCourses(longitude: lon, latitude: lat)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 가져오기 실패: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: - Models for TourAPI
struct TourResponse: Decodable {
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

