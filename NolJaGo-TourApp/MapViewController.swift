//
//  MapViewController.swift
//  MultipleViewController
//
//  Created by wjlee on 5/8/25.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBAction func sgvValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .hybrid
        case 2:
            mapView.mapType =  .satellite
        default:
            break
        }
    }
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // 탭 제스처 등록
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
//        mapView.addGestureRecognizer(tapGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(segueViewController))
        
        mapView.addGestureRecognizer(tapGesture)
        self.navigationItem.backButtonTitle = "돌아가기"
    }
    
    @objc func segueViewController(sender: UITapGestureRecognizer){
        performSegue(withIdentifier: "wjlee", sender: self)
    }
    
//    @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
//        let tapPoint = gestureRecognizer.location(in: mapView)
//        let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
//        
//        print("Tapped at: \(tapCoordinate.latitude), \(tapCoordinate.longitude)")
//        
//        // 해당 위치로 주석 추가
//        attachAnnotation(location: tapCoordinate)
//    }
}

extension MapViewController{
    
    override func viewWillAppear(_ animated: Bool) {
        let parent = self.parent?.parent as! UITabBarController
        var selectCityName: String?
//        for vc in parent.viewControllers!{
//            selectCityName = (vc as? HomeViewController)?.getSelectedCity()
//            if selectCityName != nil{
//                break
//            }
//        }
        print("selected city = \(selectCityName)")
        
        getCLLocationCoordinate2D(cityName: selectCityName!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
}

extension MapViewController{
    func getCLLocationCoordinate2D(cityName: String){
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(cityName) {
            placemarks, error in
            guard error == nil else {return print(error!.localizedDescription)}
            guard let location = placemarks?.first?.location else { return print("no data")}
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            print("\(cityName): \(latitude), \(longitude))")
            
            self.move2Location(location: location.coordinate)
            self.attachAnnotation(location: location.coordinate)
        }
    }
}

extension MapViewController{
    func move2Location(location: CLLocationCoordinate2D){
        
        let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    func attachAnnotation(location: CLLocationCoordinate2D){
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
}

