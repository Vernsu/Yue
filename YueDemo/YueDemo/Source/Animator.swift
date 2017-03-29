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

let defultMemoryLimit = 20
let eps:Double = 1E-6

struct AnimatedSegment {
    var image: UIImage?
    let delayTime: TimeInterval
    static func null() -> AnimatedSegment {
        return AnimatedSegment(image: .none, delayTime: 0.0)
    }
}

class Animator{
    var imageSource: CGImageSource! //imageSource 处理帧相关操作
    var animatedSegments = [AnimatedSegment]() //动画帧的集合
    var segmentCount = 0 // 帧的数量
    var currentSegmentIndex = 0 // 当前帧下标
    var currentSegmentDidShowTime : TimeInterval = 0.0 //当前帧已经显示的时间
    var loopCount = 0//循环次数
    let maxTimeStep: TimeInterval = 1.0//最大间隔
    var currentImage: UIImage? {
        if isCache {
            return segmentAtIndex(index: currentSegmentIndex)
        }else{
            let currentImage = currentSegmentWithoutCache?.image
            preloadNextSegmentAsynchronously()
            return currentImage
        }
        
    }

    var nextSegmentWithoutCache : AnimatedSegment?
    var currentSegmentWithoutCache : AnimatedSegment?

    var coverImage : UIImage? //Gif 的封面图片
    var sizeForImageSource : Int = 0 //imageSource 大小估算
    var isCache : Bool = true
    
    init(data:NSData){
        self.createImageSource(data: data)
        self.CalculateImageSize()
        if self.isCache {
            print("有缓存")
            self.prepareSegmentsAsynchronously()
        }else{
            print("没有缓存")
        }
        
    }

//缓存池
//    var frameCacheSizeCurrent: Int = 0 // 当前被缓存帧的数量(范围是1到frameCount)
//    var frameCacheSizeMax: Int = 0 //最多允许缓存多少帧 0意味着没有限制
    
    var contentMode: UIViewContentMode = .scaleToFill
    
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.yue.preloadQueue")
    }()
    
    //取出对应缓存的图片
    //为了立即返回结果，在主线程调用，缓存不存在则返回nil
//    func frameLazilyCachedAtIndex( index: Int ) -> AnimatedSegment?{
//        return nil
//    }
    /**
     根据data创建 CGImageSource
     
     - parameter data: gif data
     */
    func createImageSource(data:NSData){
        //kCGImageSourceShouldCache 表示是否在存储的时候就解码
        // kCGImageSourceTypeIdentifierHint : 指明source type
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(value: false)]
        
        //todo -- imageSource可能不存在
        imageSource = CGImageSourceCreateWithData(data, options)

        guard let imageSourceContainerType = CGImageSourceGetType(imageSource),
            UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF) else{
            print("不是gif 图片")
            return
        }
        
    }
    

    /// 准备某照片的 的 AnimatedFrame
    func prepareSegment(index: Int) -> AnimatedSegment {
        // 获取对应帧的 CGImage
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index , nil) else {
            return AnimatedSegment.null()
        }
        // 获取到 gif每帧时间间隔
        //kCGImagePropertyGIFDelayTime 和 kCGImagePropertyGIFUnclampedDelayTime区别。前者如果时间小于50毫秒，实际得到的值为100毫秒。后者为精确值，大于等于0毫秒。
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index , nil) ,
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary
            else{
                return AnimatedSegment.null()
        }
        var delayTime : Double
        if let time = (gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double),
            time > eps
            {
            delayTime = time
        }else if let time = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double){
            delayTime = time
        }else{
            return AnimatedSegment.null()
        }
        
        //这里或许可以直接用 cgImage一个参数就够了？应该默认就是主屏幕scale
//        let image = UIImage(cgImage: imageRef , scale: UIScreen.main.scale , orientation: UIImageOrientation.up)
         let image = UIImage(cgImage: imageRef)
        
        return AnimatedSegment(image: image, delayTime: Double(delayTime))
    }
    
    func prepareSegmentsAsynchronously() {
        preloadQueue.async { [weak self] in
            self?.prepareSegments()
        }
    }
    
    func preloadNextSegmentAsynchronously() {
        preloadQueue.async { [weak self] in
            var preloadindex = (self?.currentSegmentIndex)! + 1 // 一直累加
            // 这里取了余数 即 当index = count 时，重置为0
            
            preloadindex = preloadindex % (self?.segmentCount)!
            
            self?.nextSegmentWithoutCache = self?.prepareSegment(index: preloadindex)
            
        }
        
    }
    func CalculateImageSize(){
        coverImage = prepareSegment(index: 0).image
        // 总共帧数
        currentSegmentWithoutCache = prepareSegment(index: 0)
        segmentCount = CGImageSourceGetCount(imageSource)
        guard let image = coverImage else{
           return
        }
        sizeForImageSource = Int(image.size.height * image.size.width * 4) * segmentCount / (1000 * 1008)
        isCache = sizeForImageSource < defultMemoryLimit
    }
    /**
     预备所有frames
     */
    func prepareSegments() {
        
        
        //得到内置的循环次数
        if let properties = CGImageSourceCopyProperties(imageSource, nil),
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int {
            self.loopCount = loopCount
        }
        
        let frameToProcess = segmentCount
        
        
        animatedSegments.reserveCapacity(frameToProcess)
        
        // 相当于累加
//        animatedFrames = (0..<frameToProcess).reduce([]) { $0 + pure(value: prepareFrame(index: $1))}
        
        
        // 上面相当于这个
        for i in 0..<frameToProcess {
            animatedSegments.append(prepareSegment(index: i))
        }
        
    }

    
    /**
     根据下标获取图片
     */
    func segmentAtIndex(index: Int) -> UIImage? {

         return animatedSegments[safe: index]?.image
        
    }
    
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        if isCache {
            return updateCurrentFrameWithCache(duration: duration)
        }else{
            return updateCurrentFrameWithoutCache(duration: duration)
        }
 
    }
    
    func updateCurrentFrameWithCache(duration: CFTimeInterval) -> Bool {
         // 计算当前帧已经显示的时间 每次进来都累加 直到frameDuration  <= timeSinceLastFrameChange 时候才继续走下去
        currentSegmentDidShowTime += min(maxTimeStep, duration)
        
        
        guard let frameDuration = animatedSegments[safe:currentSegmentIndex]?.delayTime,
            duration <= currentSegmentDidShowTime else {
                return false
        }
        // 减掉 我们每帧间隔时间
        currentSegmentDidShowTime -= frameDuration
        
        addOneToCurrentSegmentIndex()
        
        return true
    }
    func updateCurrentFrameWithoutCache(duration: CFTimeInterval) -> Bool {
        
        currentSegmentDidShowTime += min(maxTimeStep, duration)
        
        guard let frameDuration = currentSegmentWithoutCache?.delayTime,
            duration <= currentSegmentDidShowTime else {
                return false
        }
        currentSegmentWithoutCache = nextSegmentWithoutCache
        
        // 减掉 我们每帧间隔时间
        currentSegmentDidShowTime -= frameDuration
        //        let lastFrameIndex = currentFrameIndex
        
        addOneToCurrentSegmentIndex()
        
        return true
        
    }
    
    func addOneToCurrentSegmentIndex(){
        currentSegmentIndex += 1 // 一直累加
        // 这里取了余数 即 当index = count 时，重置为0
        currentSegmentIndex = currentSegmentIndex % segmentCount
    }
    
    
}
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
private func pure<T>(value: T) -> [T] { return [value] }
