//
//  ViewController.swift
//  Inception
//
//  Created by Kumar Mishra, R. F. on 5/21/18.
//  Copyright © 2018 iostreamh. All rights reserved.
//

import UIKit

class ViewController: UIViewController{
    
    @IBOutlet weak var faultButton: UIButton!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let alertController = UIAlertController(title: "Fault Code ", message:"Please keeps light center of the screen", preferredStyle: UIAlertControllerStyle.alert)
//        alertController.addAction(UIAlertAction(title: "Proceed!", style: UIAlertActionStyle.default,handler: nil))
//        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func faultAction(_ sender: Any) {
        self.performSegue(withIdentifier: "faultView", sender: nil)
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare")
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}

