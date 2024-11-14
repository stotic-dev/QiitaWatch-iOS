//
//  QiitaUserSearchViewController.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/13.
//

import UIKit

final class QiitaUserSearchViewController: UIViewController {
    
    // MARK: - private property
    
    private var viewModel: QiitaUserSearchViewModel?
    
    // MARK: - factory method
    
    static func getInstance() -> UIViewController {
        
        let viewController = UIStoryboard(name: "QiitaUserSearchScene",
                                          bundle: nil)
            .instantiateViewController(withIdentifier: "QiitaUserSearchViewController")
        guard let qiitaUserSearchViewController = viewController as? QiitaUserSearchViewController,
              let context = AppDelegate.getDatabaseContainer()?.mainContext else { return viewController }
        qiitaUserSearchViewController.viewModel = QiitaUserSearchViewModel(context: context)
        return qiitaUserSearchViewController
    }
    
    // MARK: - lifecycle method

    override func viewDidLoad() {
        
        super.viewDidLoad()
        log.trace()
    }
}
