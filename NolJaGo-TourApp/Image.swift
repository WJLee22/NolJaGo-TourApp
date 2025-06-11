//
//  Image.swift
//  TableViewCollectionView
//
//  Created by wjlee on 5/31/25.
//

import Foundation

import UIKit
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
