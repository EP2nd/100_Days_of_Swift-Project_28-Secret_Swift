//
//  ViewController.swift
//  Project28
//
//  Created by Edwin Przeźwiecki Jr. on 03/11/2022.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    @IBOutlet var secret: UITextView!
    
    /// Challenge 1:
    var doneButton: UIBarButtonItem!
    
    /// Challenge 2:
    var password = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        /// Challenge 1:
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
        navigationItem.rightBarButtonItem = doneButton
        doneButton.isHidden = true
        
        /// Challenge 2:
        load(key: "Password", object: &password)
        
        /// Challenge 2:
        if password == "" {
            let ac = UIAlertController(title: "Password", message: "Please set a backup password.", preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak ac] _ in
                guard let password = ac?.textFields?[0].text else { return }
                self?.save(password, key: "Password")
                self?.password = password
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        /// Challenge 2:
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified. Please use your password.", preferredStyle: .alert)
                        ac.addTextField()
                        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            guard let passwordString = ac.textFields?[0].text else { return }
                            if passwordString == self?.password {
                                self?.unlockSecretMessage()
                            } else {
                                let ac = UIAlertController(title: "Wrong password", message: "Sorry, the secret message can not be unlocked.", preferredStyle: .alert)
                                ac.addAction(UIAlertAction(title: "OK", style: .default))
                                self?.present(ac, animated: true)
                            }
                        })
                        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            /// Challenge 2:
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication. Please use your password.", preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                guard let passwordString = ac.textFields?[0].text else { return }
                if passwordString == self?.password {
                    self?.unlockSecretMessage()
                } else {
                    let ac = UIAlertController(title: "Wrong password", message: "Sorry, the secret message can not be unlocked.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(ac, animated: true)
                }
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(ac, animated: true)
        }
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        /// Challenge 2:
        //KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        save(secret.text, key: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        /// Challenge 1:
        doneButton.isHidden = true
        
        title = "Nothing to see here"
    }
    
    /// Challenge 2:
    func save(_ text: String, key: String) {
        KeychainWrapper.standard.set(text, forKey: key)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        /// Challenge 1:
        doneButton.isHidden = false
        title = "Secret stuff!"
        
        /// Optional:
        //secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
        
        /* if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
            secret.text = text
        } */
        /// Challenge 2:
        load(key: "SecretMessage", object: &secret.text)
    }
    
    /// Challenge 2:
    func load(key: String, object: inout String) {
        if let text = KeychainWrapper.standard.string(forKey: key) {
            object = text
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardScreenEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
}
