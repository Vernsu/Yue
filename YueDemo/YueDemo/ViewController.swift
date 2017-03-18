//
//  ViewController.swift
//  YueDemo
//
//  Created by Vernsu on 2017/3/15.
//  Copyright © 2017年 swift.diagon.me. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    var imageView2 : YueImageView!
    var imageView3 : FLAnimatedImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let path = Bundle.main.path(forResource: "hsk", ofType: "gif")!
        let data = NSData(contentsOfFile: path)

        imageView2 = YueImageView(frame: CGRect(x: 15, y: 100, width: 320, height: 320))

        imageView2.gifData = data

        self.contentView.addSubview(imageView2)

//        let image4 = FLAnimatedImage(animatedGIFData: data as Data!)
////        let image3 = FLAnimatedImage(animatedGIFData: data as Data!)
//            self.imageView3 = FLAnimatedImageView(frame:  CGRect(x: 15, y: 100, width: 320, height: 320))
//            self.imageView3.animatedImage = image4
//            self.contentView.addSubview(imageView3)


    }
    @IBAction func stopButtonTouched(_ sender: Any) {
        imageView2.stopAnimating()
    }
    @IBAction func playButtonTouched(_ sender: Any) {
        imageView2.startAnimating()
    }
    

}

