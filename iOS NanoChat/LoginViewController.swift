//
//  LoginViewController.swift
//  iOS NanoChat
//
//  Created by Adriano Song on 19/10/16.
//  Copyright © 2016 Adriano Song. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var txtEmail = UITextField()
    var txtPass = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///tornar uma tarefa assincrona em uma tarefa sincrona
        DispatchQueue.global().async {
            DispatchQueue.main.sync {
                FIRAuth.auth()?.addStateDidChangeListener({ (FIRAuth, FIRUser) in
                
                    if let _ = FIRUser {
                        //usuario logado enviar para proxima vc
                        self.sendUserToMainViewController()
                    }
                
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func actionEmailSignIn(_ sender: AnyObject) {
        
        let refreshAlert = UIAlertController(title: "Novo usuário", message: "Digite e-mail e senha", preferredStyle: UIAlertControllerStyle.alert)
        
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
            //TODO implementar ainda com a chamada de metodo com logica
            
            self.createUser(email: self.txtEmail.text!, senha: self.txtPass.text!)
            
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (UIAlertAction) in
            //nada somente fecha o popup
        }))
        
        refreshAlert.addTextField(configurationHandler: { (textField) -> Void in
        
            self.txtEmail = textField
            self.txtEmail.delegate = self
            self.txtEmail.keyboardType = UIKeyboardType.emailAddress
            self.txtEmail.placeholder = "Escreva seu e-mail"
            
        })
        
        refreshAlert.addTextField { (UITextField) in
            
            self.txtPass = UITextField
            self.txtPass.delegate = self
            self.txtPass.isSecureTextEntry = true
            self.txtPass.placeholder = "Escreva a sua senha"
            
        }
        
        present(refreshAlert, animated: true, completion: nil)
        
    }
    
    func createUser(email: String, senha: String){
        
        if email != "" && senha != "" {
            FIRAuth.auth()?.createUser(withEmail: email, password: senha, completion: { (FIRUser, Error) in
                
                if FIRUser != nil{
                    print("User Add com sucesso!! \(FIRUser?.email) ")
                    
                    self.sendUserToMainViewControllerWithAnimation()
                }
                
                if Error != nil {
                    print("Nao deu certo \(Error.debugDescription)")
                }
                
            })
        }
    }
    
    ///without animation
    func sendUserToMainViewController(){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "main") as! ViewController
        self.navigationController?.popToViewController(self, animated: false)
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    ///with animation
    func sendUserToMainViewControllerWithAnimation(){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "main") as! ViewController
        self.navigationController?.popToViewController(self, animated: false)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
