//
//  ChatViewContoller.swift
//  iOS NanoChat
//
//  Created by Adriano Song on 18/10/16.
//  Copyright © 2016 Adriano Song. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import AlamofireImage
import Alamofire

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: IBOutlets
    
    @IBOutlet weak var txtMessage: UITextField!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var tblChat: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var placeForIndicator: UIView!
    
    //MARK: class attributes
    
    var chatMessagesArray = Array<ChatMessage>()
    var database = FIRDatabase.database()
    var auth = FIRAuth.auth()
    var storage = FIRStorage.storage()
    
    var userEmail = ""
    
    var loadingAlert: UIAlertController!
    
    var imagePicker = UIImagePickerController()
    
    //MARK: ViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupAndShowLoadingIndicator()
        
        setupDelegates()
        setupGestureRecognizer()
        
        getDataFromFirebase()
        
        getUserEmail()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: TableViewDelegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //create table view cell
        let cell = tblChat.dequeueReusableCell(withIdentifier: "cell") as! ChatTableViewCell
        
        //customize the cell
        let chatMessage = chatMessagesArray[indexPath.row]
        
        if chatMessage.message.range(of: "https://") != nil{
            
            cell.lblName.text = chatMessage.name
            
            //request image from firebase
            Alamofire.request(chatMessage.message).responseImage(completionHandler: { response in
                
                if let image = response.result.value {
                    cell.msgImage.image = image
                    cell.msgImage.isHidden = false
                }
            })
            
        }else {
        
            cell.lblName.text = chatMessage.name
            cell.lblMessage.text = chatMessage.message
            cell.msgImage.isHidden = true
        }
        
        //return the cell
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessagesArray.count
    }
    
    //MARK: IBActions
    
    @IBAction func actionBtnSend(_ sender: UIButton) {
        
        if txtMessage.text != "" {
            //updateTableViewData(txtMessage: txtMessage)
            
            //prepare data to send to firebase
            let chatMessage = ChatMessage()
            chatMessage.name = userEmail
            chatMessage.message = txtMessage.text!
            
            //send data to firebase
            let chatRef = database.reference().child("chat")
            chatRef.childByAutoId().setValue(["name": chatMessage.name, "message": chatMessage.message])
            
            txtMessage.text = ""
        }
    }
    
    @IBAction func actionPickupImage(_ sender: AnyObject) {
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: UIImagePicker delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        setupAndShowLoadingIndicator()
        
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage //2
        
        dismiss(animated: true, completion: nil)
        
        sendPickerImageToFirebase(image: chosenImage)
    }
    
    //MARK: TextField delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtMessage{
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    //MARK: class methods
    
    func getUserEmail(){
        
        if let user = FIRAuth.auth()?.currentUser{
            
            userEmail = user.email!
        }
    }
    
    func updateTableViewData(chatmessage: ChatMessage){
        
        chatMessagesArray.append(chatmessage)
        
        // Update Table Data
        let indexPath = IndexPath(row: chatMessagesArray.count - 1, section: 0)
        tblChat.insertRows(at: [indexPath], with: .left)
        tblChat.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func getDataFromFirebase(){
        
        let chatRef = database.reference().child("chat")
        chatRef.observe(.childAdded, with: { (FIRDataSnapshot) -> Void in
            
            //get the chat message from FIRDataSnapshot
            let data = FIRDataSnapshot.value as! Dictionary<String, String>
            guard let name = data["name"] as String! else {return}
            guard let message = data["message"] as String! else {return}
            
            let chatMessage = ChatMessage()
            chatMessage.name = name
            chatMessage.message = message
            
            print("deu certo \(chatMessage.message)")
            
            self.updateTableViewData(chatmessage: chatMessage)
            
            self.loadingIndicator.stopAnimating()
            self.placeForIndicator.isHidden = true
        })
    }
    
    ///send pick up image from the gallery to firebase storage
    func sendPickerImageToFirebase(image : UIImage){
        
        let imageData = UIImagePNGRepresentation(image)
        
        let photosRef = storage.reference().child("chat_photos")
        let photoRef = photosRef.child("\(UUID().uuidString).png")
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/png"
        
        photoRef.put(imageData!, metadata: metadata).observe(FIRStorageTaskStatus.success) { (FIRStorageTaskSnapshot) in
            
            let text = FIRStorageTaskSnapshot.metadata?.downloadURL()?.absoluteString
            
            self.sendMessageToFirebase(message: text!)
            
            self.loadingIndicator.stopAnimating()
            self.placeForIndicator.isHidden = true
            
        }
    }
    
    ///send message to firabse database
    func sendMessageToFirebase(message: String){
        //prepare data to send to firebase
        let chatMessage = ChatMessage()
        chatMessage.name = userEmail
        chatMessage.message = message
        
        //send data to firebase
        let chatRef = database.reference().child("chat")
        chatRef.childByAutoId().setValue(["name": chatMessage.name, "message": chatMessage.message])
    }
    
    ///setup loading indicator
    func setupAndShowLoadingIndicator(){
        
        placeForIndicator.isHidden = false
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
    }
    
    ///this method is for setup all class delegates
    func setupDelegates(){
        
        tblChat.delegate = self
        tblChat.dataSource = self
        imagePicker.delegate = self
        txtMessage.delegate = self
    }
    
    ///this method is for setup recognizer for keyboard tap outside to close it
    func setupGestureRecognizer(){
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        //logic of resize screen when keyboard appears and dissapear
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    ///Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
}
