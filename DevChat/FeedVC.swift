//
//  FeedVC.swift
//  DevChat
//
//  Created by Sebastian DiPirro on 5/29/17.
//  Copyright © 2017 Sebastian DiPirro. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Firebase
import UserNotifications

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var captionField: FancyField!
    
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
            
            if granted {
                print("SEB: Notification access granted")
            } else {
                print(error?.localizedDescription)
            }
            
        })
        
        captionField.delegate = self
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissKeyboard")))
        
        tableView.delegate = self
        tableView.dataSource = self
         
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    print("SNAP: \(snap)")
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                         let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.posts.reverse()
            self.tableView.reloadData()
            
        })

        
    }
    
    func dismissKeyboard() {
        captionField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        captionField.resignFirstResponder()
        return true

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            
            
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img)
            } else {
                cell.configureCell(post: post)
            }
            return cell
        } else {
            return PostCell()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
        } else {
            print("SEB: A valid Image was not selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addImageTapped(_ sender: AnyObject) {
       present(imagePicker, animated: true, completion: nil )
    }
    
    
    @IBAction func postBtnTapped(_ sender: AnyObject) {
        guard let caption = captionField.text, caption != "" else {
            print("SEB: Caption must be entered")
            return
        }
        guard let img = imageAdd.image, imageSelected == true else {
            print("SEB: An image must be selected")
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("SEB: Unable to upload to upload image to Firbase")
                } else {
                    print("SEB: Succsessfully uploaded image to Firbase")
                    let downloadUrl = metadata?.downloadURL()?.absoluteString
                    if let url = downloadUrl {
                        self.postToFirebase(imgUrl: url)
                }
             }
          }
       }
    }
    
    
    func postToFirebase(imgUrl: String) {
        let post: Dictionary<String, AnyObject> = [
            "caption": captionField.text! as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "likes": 0 as AnyObject
            ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
        
        tableView.reloadData()
    }

    @IBAction func signOutTapped(_ sender: AnyObject) {
        let keychainResult = KeychainWrapper.defaultKeychainWrapper.remove(key: KEY_UID)
        print("SEB: ID removed from keychain \(keychainResult)")
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
        
    }
   
}
