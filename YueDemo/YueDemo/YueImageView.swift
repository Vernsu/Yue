//
//  YueImageView.swift
//  YueDemo
//
//  Created by Vernsu on 2017/3/15.
//  Copyright © 2017年 swift.diagon.me. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import MobileCoreServices


class YueImageView : UIImageView {
    
    /// 防止循环引用
    class TargetProxy {
        private weak var target: YueImageView?
        
        init(target: YueImageView) {
            self.target = target
        }
        
        @objc func onScreenUpdate() {
            target?.updateFrame()
        }
    }
    
    // 是否自动播放
    public var autoPlayAnimatedImage = true
    
    /// `Animator` 对象 将帧和指定图片存储内存中
    private var animator: Animator?
    
    /// displayLink 为懒加载 避免还没有加载好的时候使用了 造成异常
    private var displayLinkInitialized: Bool = false
    
    // NSRunLoopCommonModes UITrackingRunLoopMode 这里默认滑动暂停，也可以改成滑动不暂停
    public var runLoopMode = RunLoopMode.defaultRunLoopMode {
        willSet {
            if runLoopMode == newValue {
                return
            } else {
                stopAnimating()
                displayLink.remove(from: RunLoop.main, forMode: runLoopMode)
                displayLink.add(to: RunLoop.main, forMode: newValue)
                startAnimating()
            }
        }
    }
    
    private lazy var displayLink: CADisplayLink = {
        self.displayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.add(to: RunLoop.main, forMode: self.runLoopMode)
        displayLink.isPaused = true
        return displayLink
    }()
    
    public var gifData:NSData?{
        didSet{
            if let gifData = gifData {
                animator = nil
                animator = Animator(data: gifData)
                contentMode = (animator?.contentMode)!
                didMove()
                
                layer.setNeedsDisplay()
            }
        }
    }
    
    private func didMove() {
        if autoPlayAnimatedImage && animator != nil {
            if let _ = superview, let _ = window {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    private func updateFrame() {
        if animator?.updateCurrentFrame(duration: displayLink.duration) ?? false {
            // 此方法会触发 displayLayer
            layer.setNeedsDisplay()

        }
    }
    override func display(_ layer: CALayer) {
        if let currentFrame = animator?.currentFrame {
            layer.contents = currentFrame.cgImage
        } else {
            layer.contents = image?.cgImage
        }
    }
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        didMove()
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        didMove()
    }
    override var isAnimating: Bool{
        if displayLinkInitialized {
            return !displayLink.isPaused
        } else {
            return super.isAnimating
        }
    }

    
    /// Starts the animation.
    override public func startAnimating() {
        if self.isAnimating {
            return
        } else {
            displayLink.isPaused = false
        }
    }
    
    /// Stops the animation.
    override public func stopAnimating() {
        super.stopAnimating()
        if displayLinkInitialized {
            displayLink.isPaused = true
        }
    }
    deinit {
        if displayLinkInitialized {
            displayLink.invalidate()
        }
    }

}

