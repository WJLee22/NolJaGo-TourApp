import Foundation

// 기본 코스 정보 모델 (기존 코드 확장)
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
    
    // 추가 상세 정보 (API 호출 후 추가될 정보)
    var detailIntro: CourseDetailIntro?
    var subPlaces: [CourseSubPlace]?
    
    enum CodingKeys: String, CodingKey {
        case contentid, title, firstimage, firstimage2, addr1, addr2, mapx, mapy, dist, tel, cat3
    }
}

// Tour API 응답 모델 (기존)
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

// 새로 추가할 상세 정보 모델들
struct CourseDetailIntro {
    let distance: String
    let taketime: String
    let schedule: String
    let theme: String
}

struct CourseSubPlace {
    let subnum: Int
    let subname: String
    let subdetailoverview: String
    let subdetailimg: String?
    let subdetailalt: String?
}

// XML 파싱 유틸리티 클래스
class XMLParserHelper: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentValue = ""
    private var result: [String: String] = [:]
    
    func parseDetailIntro(data: Data) -> CourseDetailIntro? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        result = [:]
        
        if parser.parse() {
            return CourseDetailIntro(
                distance: result["distance"] ?? "정보 없음",
                taketime: result["taketime"] ?? "정보 없음",
                schedule: result["schedule"] ?? "정보 없음",
                theme: result["theme"] ?? "정보 없음"
            )
        }
        return nil
    }
    
    private var subPlaces: [CourseSubPlace] = []
    private var currentSubPlace: [String: String] = [:]
    private var isInItem = false
    
    func parseDetailInfo(data: Data) -> [CourseSubPlace] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        subPlaces = []
        currentSubPlace = [:]
        isInItem = false
        
        if parser.parse() {
            return subPlaces
        }
        return []
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            isInItem = true
            currentSubPlace = [:]
        } else if isInItem {
            currentValue = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInItem && !currentElement.isEmpty {
            currentValue += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            isInItem = false
            
            // detailInfo일 경우 subPlace 추가
            if currentSubPlace["subname"] != nil {
                let subPlace = CourseSubPlace(
                    subnum: Int(currentSubPlace["subnum"] ?? "0") ?? 0,
                    subname: currentSubPlace["subname"] ?? "",
                    subdetailoverview: currentSubPlace["subdetailoverview"] ?? "",
                    subdetailimg: currentSubPlace["subdetailimg"],
                    subdetailalt: currentSubPlace["subdetailalt"]
                )
                subPlaces.append(subPlace)
            }
        } else if isInItem {
            let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                currentSubPlace[elementName] = trimmedValue
            }
        } else {
            let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                result[elementName] = trimmedValue
            }
        }
        
        if elementName == currentElement {
            currentElement = ""
        }
    }
}