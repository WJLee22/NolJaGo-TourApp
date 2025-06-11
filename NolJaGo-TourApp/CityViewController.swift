//
//  CityViewController.swift
//  MultipleViewController
//
//  Created by wjlee on 5/8/25.
//

import UIKit

class CityViewController: UIViewController {
    
    @IBOutlet weak var cityPickerView: UIPickerView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var cities: [String: [String:Double]] = [
        "Seoul" : ["lon":126.9778, "lat":37.5683], "Athens": ["lon":23.7162, "lat":37.9795],
        "Bangkok": ["lon":100.5167, "lat":13.75], "Berlin": ["lon":13.4105, "lat":52.5244],"Jerusalem": ["lon":35.2163, "lat":31.769],"Lisbon": ["lon":-9.1333, "lat":38.7167],"London": ["lon":-0.1257, "lat":51.5085],"New York": ["lon":-74.006, "lat":40.7143],"Paris": ["lon":2.3488, "lat":48.8534],"Sydney": ["lon":151.2073, "lat":-33.8679]
    ]
    
    var landmarks: [City] = NolJaGo_TourApp.load("cityData.json")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cityPickerView.dataSource = self // 데이터 공급자로 등록
        cityPickerView.delegate = self // 대리자로 등록
        
        // 처음으로 선택하고자 하는 row 선택
        cityPickerView.selectRow(1, inComponent: 0, animated: true)
        descriptionLabel.text = landmarks[1].description
    }
    
    
}

extension CityViewController: UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return landmarks.count
    }
}


extension CityViewController: UIPickerViewDelegate{
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = landmarks[row].name
        let imageView = UIImageView(image: landmarks[row].uiImage())
        
        var outer = UIStackView(arrangedSubviews: [imageView, nameLabel])
        outer.axis = .vertical
        return outer
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
       
        return pickerView.frame.size.height / 2
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        descriptionLabel.text = landmarks[row].description
    }
    
}

extension CityViewController{
func getSelectedCity() -> String{
return landmarks[cityPickerView.selectedRow(inComponent: 0)].name
}
}

