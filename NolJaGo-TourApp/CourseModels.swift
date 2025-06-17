import Foundation

// 기본 코스 정보 모델
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
    let cat2: String?  // 코스 유형 분류 코드 추가
    
    // 추가 상세 정보 (API 호출 후 추가될 정보)
    var detailIntro: CourseDetailIntro?
    var subPlaces: [CourseSubPlace]?
    
    enum CodingKeys: String, CodingKey {
        case contentid, title, firstimage, firstimage2, addr1, addr2, mapx, mapy, dist, tel, cat3, cat2
    }
}

// Tour API 응답 모델
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
    // DetailIntro 파싱용 변수
    private var introResult = [String: String]()
    private var currentElement = ""
    private var currentValue = ""
    private var isInIntroItem = false
    
    // DetailInfo 파싱용 변수
    private var subPlaces = [CourseSubPlace]()
    private var currentSubPlace = [String: String]()
    private var isInInfoItem = false
    private var parsingMode = ""  // 현재 파싱 모드 구분 (intro 또는 info)
    
    // MARK: - DetailIntro 파싱 (거리, 소요시간 등)
    func parseDetailIntro(data: Data) -> CourseDetailIntro? {
        parsingMode = "intro"
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        // 초기화
        introResult.removeAll()
        isInIntroItem = false
        currentElement = ""
        currentValue = ""
        
        if parser.parse() {
            //print("DetailIntro 파싱 결과: \(introResult)")
            
            return CourseDetailIntro(
                distance: introResult["distance"] ?? "4km",
                taketime: introResult["taketime"] ?? "5시간",
                schedule: introResult["schedule"] ?? "정보 없음",
                theme: introResult["theme"] ?? "정보 없음"
            )
        }
        return nil
    }
    
    // MARK: - DetailInfo 파싱 (코스 내부 장소들)
    func parseDetailInfo(data: Data) -> [CourseSubPlace] {
        parsingMode = "info"
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        // 초기화
        subPlaces.removeAll()
        currentSubPlace.removeAll()
        isInInfoItem = false
        currentElement = ""
        currentValue = ""
        
        if parser.parse() {
            //print("DetailInfo 파싱 결과: \(subPlaces.count)개 장소 파싱됨")
            return subPlaces
        }
        return []
    }
    
    // MARK: - XMLParserDelegate 메서드
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            if parsingMode == "intro" {
                isInIntroItem = true
            } else if parsingMode == "info" {
                isInInfoItem = true
                currentSubPlace = [:]  // 새 아이템 시작시 초기화
            }
            currentValue = ""
        } else if (isInIntroItem || isInInfoItem) && !currentElement.isEmpty {
            currentValue = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if (isInIntroItem || isInInfoItem) && !currentElement.isEmpty {
            currentValue += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // 아이템 종료 처리
            if parsingMode == "intro" {
                isInIntroItem = false
            } else if parsingMode == "info" {
                isInInfoItem = false
                
                // subPlace 객체 생성 및 추가
                if let subnumStr = currentSubPlace["subnum"], 
                    let subnum = Int(subnumStr),
                   let subname = currentSubPlace["subname"] {
                    
                    let subPlace = CourseSubPlace(
                        subnum: subnum,
                        subname: subname,
                        subdetailoverview: currentSubPlace["subdetailoverview"] ?? "",
                        subdetailimg: currentSubPlace["subdetailimg"],
                        subdetailalt: currentSubPlace["subdetailalt"]
                    )
                    subPlaces.append(subPlace)
                    print("장소 추가: \(subname)")
                }
            }
        } else if isInIntroItem && parsingMode == "intro" {
            // DetailIntro 파싱 중 요소 값 저장
            let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                introResult[elementName] = trimmedValue
            }
        } else if isInInfoItem && parsingMode == "info" {
            // DetailInfo 파싱 중 요소 값 저장
            let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                currentSubPlace[elementName] = trimmedValue
            }
        }
        
        if elementName == currentElement {
            currentElement = ""
        }
    }
}
