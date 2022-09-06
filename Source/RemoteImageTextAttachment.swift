//
//  RemoteImageTextAttachment.swift
//  RemoteImageTextAttachment
//
//  Created by Hoang Le Pham on 26/11/2020.
//  Copyright © 2020 Pham Le. All rights reserved.
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public class RemoteImageTextAttachment: NSTextAttachment {
  
  // The label that this attachment is being added to
  public weak var label: UILabel?
  
  // The size to display the image. If nil, the image's size will be used
  public var displaySize: CGSize?
  
  public var downloadQueue: DispatchQueue?
  public let imageUrl: URL
  
  private weak var textContainer: NSTextContainer?
  private var isDownloading = false
  
  public init(imageURL: URL, displaySize: CGSize? = nil, downloadQueue: DispatchQueue? = nil) {
    self.imageUrl = imageURL
    self.displaySize = displaySize
    self.downloadQueue = downloadQueue
    super.init(data: nil, ofType: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }
  
  override public func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
    
    if let displaySize = displaySize {
      return CGRect(origin: .zero, size: displaySize)
    }
    
    if let originalImageSize = image?.size {
      return CGRect(origin: .zero, size: originalImageSize)
    }
    
    // If we return .zero, the image(forBounds:textContainer:characterIndex:) function won't be called
    let placeholderSize = CGSize(width: 1, height: 1)
    return CGRect(origin: .zero, size: placeholderSize)
  }
  
  override public func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
    
    if let image = image {
      return image
    }
    
    self.textContainer = textContainer
    
    guard !isDownloading else {
      return nil
    }
    
    isDownloading = true
    
    let imageUrl = self.imageUrl
    let downloadQueue = self.downloadQueue ?? DispatchQueue.global()
    downloadQueue.async { [weak self] in
      let data = try? Data(contentsOf: imageUrl)
      DispatchQueue.main.async { [weak textContainer] in
        guard let strongSelf = self else {
          return
        }
        
        defer {
          strongSelf.isDownloading = false
        }
        
        guard let data = data else {
          return
        }
        
        strongSelf.image = UIImage(data: data)
        strongSelf.label?.setNeedsDisplay()
        
        // For UITextView/NSTextView
        if let layoutManager = self?.textContainer?.layoutManager,
          let ranges = layoutManager.rangesForAttachment(strongSelf) {
          ranges.forEach { range in
            layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
          }
        }
      }
    }
    
    return nil
  }
}

public extension NSLayoutManager {
  func rangesForAttachment(_ attachment: NSTextAttachment) -> [NSRange]? {
    guard let textStorage = textStorage else {
      return nil
    }
    var ranges: [NSRange] = []
    textStorage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textStorage.length), options: [], using: { (attribute, range, _) in
      
      if let foundAttribute = attribute as? NSTextAttachment, foundAttribute === attachment {
        ranges.append(range)
      }
    })
    
    return ranges
  }
}
