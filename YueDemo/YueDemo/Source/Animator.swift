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

struct AnimatedSegment {
    var image: UIImage?
    let delayTime: TimeInterval
    static func null() -> AnimatedSegment {
        return AnimatedSegment(image: .none, delayTime: 0.0)
    }
}

class Animator{
//    let maxFrameCount: Int = 100 //最大帧数
    var imageSource: CGImageSource! //imageSource 处理帧相关操作
    var animatedSegments = [AnimatedSegment]() //动画帧的集合
    var frameCount = 0 // 帧的数量
    var currentFrameIndex = 0 // 当前帧下标
    var currentFrameDidShowTime : TimeInterval = 0.0 //当前帧已经显示的时间
    var loopCount = 0//循环次数
    let maxTimeStep: TimeInterval = 1.0//最大间隔
    var currentFrame: UIImage? {
        if isCache {
            return frameAtIndex(index: currentFrameIndex)
        }else{
            let currentImage = currentSegmentWithoutCache?.image
            preloadNextSegmentAsynchronously()
            return currentImage
        }
        
    }
    func preloadNextSegmentAsynchronously() {
        preloadQueue.async { [weak self] in
            var preloadindex = (self?.currentFrameIndex)! + 1 // 一直累加
            // 这里取了余数 即 当index = count 时，重置为0
            
            preloadindex = preloadindex % (self?.frameCount)!
            
            self?.nextSegmentWithoutCache = self?.prepareFrame(index: preloadindex)
            
        }
        
    }
    var nextSegmentWithoutCache : AnimatedSegment?
    var currentSegmentWithoutCache : AnimatedSegment?
    
    init(data:NSData){
        self.createImageSource(data: data)
        self.CalculateImageSize()
        if self.isCache {
            print("有缓存")
            self.prepareFramesAsynchronously()
        }else{
            print("没有缓存")
        }
        
    }
    //2.0
    var coverImage : UIImage? //Gif 的封面图片
    var sizeForImageSource : Int = 0
    var isCache : Bool = true
    
    
    
//    var frameCacheSizeCurrent: Int = 0 // 当前被缓存帧的数量(范围是1到frameCount)
//    var frameCacheSizeMax: Int = 0 //最多允许缓存多少帧 0意味着没有限制
    
    var contentMode: UIViewContentMode = .scaleAspectFill
    
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.yue.preloadQueue")
    }()
    
    //取出对应缓存的图片
    //为了立即返回结果，在主线程调用，缓存不存在则返回nil
    func frameLazilyCachedAtIndex( index: Int ) -> AnimatedSegment?{
        return nil
    }
    /**
     根据data创建 CGImageSource
     
     - parameter data: gif data
     */
    func createImageSource(data:NSData){
        //kCGImageSourceShouldCache 表示是否在存储的时候就解码
        // kCGImageSourceTypeIdentifierHint : 指明source type
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(value: false)]
        
        //todo -- 这里有个坑，imageSource可能不存在 Swift中怎么处理更好？
        imageSource = CGImageSourceCreateWithData(data, options)

        
        
        guard let imageSourceContainerType = CGImageSourceGetType(imageSource),
            UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF) else{
            print("不是gif 图片")
            return
        }
        
    }
    

    /// 准备某照片的 的 AnimatedFrame
    func prepareFrame(index: Int) -> AnimatedSegment {
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
        var delayTime : NSNumber
        if let time = (gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber){
            delayTime = time
        }else if let time = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber){
            delayTime = time
        }else{
            return AnimatedSegment.null()
        }
        
        //这里或许可以直接用 cgImage一个参数就够了？
        let image = UIImage(cgImage: imageRef , scale: UIScreen.main.scale , orientation: UIImageOrientation.up)
        
        return AnimatedSegment(image: image, delayTime: Double(delayTime))
    }
    
    func prepareFramesAsynchronously() {
        preloadQueue.async { [weak self] in
            self?.prepareFrames()
        }
    }
    
    func CalculateImageSize(){
        coverImage = prepareFrame(index: 0).image
        // 总共帧数
        currentSegmentWithoutCache = prepareFrame(index: 0)
        frameCount = CGImageSourceGetCount(imageSource)
        guard let image = coverImage else{
           return
        }
        sizeForImageSource = Int(image.size.height*image.size.width*4)*frameCount/(1000*1008)
        isCache = sizeForImageSource < defultMemoryLimit
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
        

//        let frameToProcess = min(frameCount, maxFrameCount)
        let frameToProcess = frameCount
        
        
        animatedSegments.reserveCapacity(frameToProcess)
        
        // 相当于累加
//        animatedFrames = (0..<frameToProcess).reduce([]) { $0 + pure(value: prepareFrame(index: $1))}
        
        
        // 上面相当于这个
        for i in 0..<frameToProcess {
            animatedSegments.append(prepareFrame(index: i))
        }
        
    }

    
    /**
     根据下标获取图片
     */
    func frameAtIndex(index: Int) -> UIImage? {

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
        currentFrameDidShowTime += min(maxTimeStep, duration)
        
        
        guard let frameDuration = animatedSegments[safe:currentFrameIndex]?.delayTime,
            duration <= currentFrameDidShowTime else {
                return false
        }
        // 减掉 我们每帧间隔时间
        currentFrameDidShowTime -= frameDuration
        
        addOneToCurrentFrameIndex()
        
        return true
    }
    func updateCurrentFrameWithoutCache(duration: CFTimeInterval) -> Bool {
        currentFrameDidShowTime += min(maxTimeStep, duration)
        
        
        guard let frameDuration = currentSegmentWithoutCache?.delayTime,
            duration <= currentFrameDidShowTime else {
                return false
        }
        currentSegmentWithoutCache = nextSegmentWithoutCache
        
        // 减掉 我们每帧间隔时间
        currentFrameDidShowTime -= frameDuration
        //        let lastFrameIndex = currentFrameIndex
        
        addOneToCurrentFrameIndex()
        
        return true
        
    }
    
    func addOneToCurrentFrameIndex(){
        currentFrameIndex += 1 // 一直累加
        // 这里取了余数 即 当index = count 时，重置为0
        currentFrameIndex = currentFrameIndex % frameCount
    }
    
    
}
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
private func pure<T>(value: T) -> [T] { return [value] }
