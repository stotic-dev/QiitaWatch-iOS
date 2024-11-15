//
//  AlertManager.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/14.
//

import UIKit

struct AlertManager {
    
    @MainActor
    static func showAlert(_ alertCase: AlertCase, target: UIViewController) {
        
        let alert = UIAlertController(title: alertCase.title,
                                      message: nil,
                                      preferredStyle: .alert)
        
        switch alertCase {
            
        case .noHitQiitaUser(let firstHandler),
                .networkError(let firstHandler):
            alert.addAction(.init(title: alertCase.firstButtonTitle,
                                  style: .default) { _ in
                
                firstHandler()
            })
        }
        
        target.present(alert, animated: true)
    }
}
