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

        imageView2 = YueImageView(frame: CGRect(x: 15, y: 100, width: 320, height: 320))
        let data = NSData(contentsOfFile: path)
        imageView2.gifData = data

        self.contentView.addSubview(imageView2)
    }
    @IBAction func stopButtonTouched(_ sender: Any) {
        imageView2.stopAnimating()
    }
    @IBAction func playButtonTouched(_ sender: Any) {
        imageView2.startAnimating()
    }
    

}

