/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a single landmark.
*/

import Foundation
import SwiftUI
import CoreLocation

struct City: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var country: String
    var description: String
    var imageName: String
    
    init(id: Int, name: String, country: String, description: String, imageName: String) {
        self.id = id
        self.name = name
        self.country = country
        self.description = description
        self.imageName = imageName
    }

    func uiImage(size: CGSize? = nil) -> UIImage?{
        let image = UIImage(named: imageName)!
        
        guard let size = size else{ return image}
        
        // context를 획득 (사이즈, 투명도, scale 입력)
        // scale의 값이 0이면 현재 화면 기준으로 scale을 잡고, sclae의 값이 1이면 self(이미지) 크기 기준으로 설정
        UIGraphicsBeginImageContext(size)

        // 이미지를 context에 그린다.
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 그려진 이미지 가져오기
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!.withRenderingMode(.alwaysOriginal)
        
        // context 종료
        UIGraphicsEndImageContext()
        return resizedImage
    }

    var image: Image {
        Image(imageName)
    }
}

extension City{
    static func toDict(city: City) -> [String: Any]{
        var dict = [String: Any]()
        
        dict["id"] = city.id
        dict["name"] = city.name
        dict["country"] = city.country
        dict["description"] = city.description
        dict["imageName"] = city.imageName

        return dict
    }
    
    static func fromDict(dict: [String: Any]) -> City{
        
        let id = dict["id"] as! Int
        let name = dict["name"] as! String
        let country = dict["country"] as! String
        let description = dict["description"] as! String
        let imageName = dict["imageName"] as! String

        return City(id: id, name: name, country: country, description: description, imageName: imageName)
    }
}

