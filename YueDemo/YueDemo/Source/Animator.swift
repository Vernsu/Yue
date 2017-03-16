//
//  Animator.swift
//  YueDemo
//
//  Created by Vernsu on 2017/3/16.
//  Copyright © 2017年 swift.diagon.me. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import MobileCoreServices


struct AnimatedFrame {
    var image: UIImage?
    let duration: TimeInterval
    static func null() -> AnimatedFrame {
        return AnimatedFrame(image: .none, duration: 0.0)
    }
}

class Animator{
    let maxFrameCount: Int = 100 //最大帧数
    var imageSource: CGImageSource! //imageSource 处理帧相关操作
    var animatedFrames = [AnimatedFrame]() //
    var frameCount = 0 // 帧的数量
    var currentFrameIndex = 0 // 当前帧下标
    var currentFrameDidShowTime : TimeInterval = 0.0 //当前帧已经显示的时间
    var loopCount = 0//循环次数
    let maxTimeStep: TimeInterval = 1.0//最大间隔
    var currentFrame: UIImage? {
        return frameAtIndex(index: currentFrameIndex)
    }
    
    var contentMode: UIViewContentMode = .scaleToFill
    
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.sdfasfasdfasf.preloadQueue")
    }()
    
    /**
     根据data创建 CGImageSource
     
     - parameter data: gif data
     */
    func createImageSource(data:NSData){
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(value: true), kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        imageSource = CGImageSourceCreateWithData(data, options)
    }
    
    
    /// 准备某照片的 的 AnimatedFrame
    func prepareFrame(index: Int) -> AnimatedFrame {
        // 获取对应帧的 CGImage
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index , nil) else {
            return AnimatedFrame.null()
        }
        // 获取到 gif每帧时间间隔
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index , nil) ,
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber)
            else{
                return AnimatedFrame.null()
        }
        
        let image = UIImage(cgImage: imageRef , scale: UIScreen.main.scale , orientation: UIImageOrientation.up)
        print(frameDuration)
        return AnimatedFrame(image: image, duration: Double(frameDuration))
    }
    
    func prepareFramesAsynchronously() {
        preloadQueue.async { [weak self] in
            self?.prepareFrames()
        }
    }
    
    /**
     预备所有frames
     */
    func prepareFrames() {
        
        
        //得到内置的循环次数
        if let properties = CGImageSourceCopyProperties(imageSource, nil),
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int {
            self.loopCount = loopCount
        }
        
        // 总共帧数
        frameCount = CGImageSourceGetCount(imageSource)
        let frameToProcess = min(frameCount, maxFrameCount)
        
        animatedFrames.reserveCapacity(frameToProcess)
        
        // 相当于累加
        animatedFrames = (0..<frameToProcess).reduce([]) { $0 + pure(value: prepareFrame(index: $1))}
        
        
        // 上面相当于这个
        //        for i in 0..<frameToProcess {
        //            animatedFrames.append(prepareFrame(i))
        //        }
        
    }
    private func pure<T>(value: T) -> [T] { return [value] }
    
    /**
     根据下标获取图片
     */
    func frameAtIndex(index: Int) -> UIImage? {
        return animatedFrames[index].image
    }
    
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        // 计算当前帧已经显示的时间 每次进来都累加 直到frameDuration  <= timeSinceLastFrameChange 时候才继续走下去
        currentFrameDidShowTime += min(maxTimeStep, duration)
        let frameDuration = animatedFrames[currentFrameIndex].duration
        guard frameDuration <= currentFrameDidShowTime else {
            return false
        }
        // 减掉 我们每帧间隔时间
        currentFrameDidShowTime -= frameDuration
        //        let lastFrameIndex = currentFrameIndex
        currentFrameIndex += 1 // 一直累加
        // 这里取了余数 即 当index = count 时，重置为0
        currentFrameIndex = currentFrameIndex % animatedFrames.count
        
        return true
    }
    
    
    
    
}
