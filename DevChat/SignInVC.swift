//
//  ViewController.swift
//  DevChat
//
//  Created by Sebastian DiPirro on 1/26/17.
//  Copyright © 2017 Sebastian DiPirro. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController {
    
    @IBOutlet weak var emailFeild: FancyField!
    @IBOutlet weak var pwdField: FancyField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID) {
            performSegue(withIdentifier: "goToFeed", sender: nil)
            
        }
    }

    @IBAction func facebookBtnTapped(_ sender: AnyObject) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("SEB: unable to authenticate with Facebook - \(error)")
                
            } else if result?.isCancelled == true {
                print("SEB: User cancelled authentication")
            } else {
                print("SEB: Successfully authenticated with Facebook")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("SEB: Unable to athenticate with Firebase - \(error)")
            } else {
                print("Successfully authenticated with Firebase")
                if let user = user {
                  let userData = ["provider": credential.provider]
                  self.completeSignIn(id: user.uid, userData: userData)
                    
                }
                
            }
        })
    }
    @IBAction func signInTapped(_ sender: AnyObject) {
        if let email = emailFeild.text, let pwd = pwdField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("SEB: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                      self.completeSignIn(id: user.uid, userData: userData )
                    }
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("SEB: Unable to authenticate with Firebase with email")
                        } else {
                            print("SEB: Able to authenticate with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                              self.completeSignIn(id: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
        
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        let keychainResult = KeychainWrapper.defaultKeychainWrapper.set(id, forKey: KEY_UID)
        print("SEB: Data saved to keychain \(keychainResult)")
        performSegue(withIdentifier: "goToFeed", sender: nil)
    }

}

