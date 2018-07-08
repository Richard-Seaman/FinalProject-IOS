//
//  SignInVC.swift
//  MyHome
//
//  Created by Richard Seaman on 24/06/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInVC: UIViewController, GIDSignInUIDelegate{
    
    @IBOutlet weak var signInButton: GIDSignInButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                // Signed in
                print ("SignInVC - signed in")
                self.performSegue(withIdentifier: "toMain", sender: self)
            } else {
                // Not signed in
                print ("SignInVC - not signed in")
                GIDSignIn.sharedInstance().signIn()
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signOut(_ sender: Any) {
        print ("sign out")
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
}
