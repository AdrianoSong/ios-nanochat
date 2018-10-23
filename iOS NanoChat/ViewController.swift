//
//  ViewController.swift
//  iOS NanoChat
//
//  Created by Adriano Song on 18/10/16.
//  Copyright © 2016 Adriano Song. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navItem.hidesBackButton = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func actionLogout(_ sender: UIBarButtonItem) {
        
        try! FIRAuth.auth()?.signOut()
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "login") as! LoginViewController
        //self.navigationController?.popToViewController(self, animated: false)
        self.navigationController?.pushViewController(vc, animated: true)
    }

}

