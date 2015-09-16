//
//  DetailViewController.swift
//  SAHistoryNavigationViewControllerSample
//
//  Created by 鈴木大貴 on 2015/04/01.
//  Copyright (c) 2015年 &#37428;&#26408;&#22823;&#36020;. All rights reserved.
//

import UIKit
import QuartzCore

class DetailViewController: UIViewController {

    @IBOutlet weak var iconButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var iconImage: UIImage?
    var text: String?
    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        iconButton.layer.cornerRadius = 10
        iconButton.layer.masksToBounds = true
        setIconImage(iconImage)
        
        usernameLabel.text = username
        textView.text = text
        
        title = username
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setIconImage(image: UIImage?) {
        if let image = image {
            iconButton.setImage(image, forState: .Normal)
        }
    }
    
    @IBAction func didTapIconButton(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier("TimelineViewController")
        navigationController?.pushViewController(viewController, animated: true)
    }
}
