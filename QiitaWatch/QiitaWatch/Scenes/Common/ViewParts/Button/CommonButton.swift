//
//  CommonButton.swift
//  QiitaWatch
//
//  Created by 佐藤汰一 on 2024/11/15.
//

import UIKit

extension UIButton {
    
    /// スタイルを適用する
    /// - Parameters:
    ///   - foregroundColor: テキスト、画像、縁の色
    ///   - backgroundColor: 背景色
    ///   - pressedBackgroundColor: タップ時の色
    ///   - cornerRadius: 角丸の値
    ///   - strokeWidth: 縁の長さ
    func style(foregroundColor: UIColor = UIColor(resource: .primaryButtonForeground),
               backgroundColor: UIColor = UIColor(resource: .primaryButtonBackground),
               pressedBackgroundColor: UIColor = UIColor(resource: .primaryPressedButtonBackground),
               cornerRadius: CGFloat = 8,
               strokeWidth: CGFloat = .zero) {
        
        var config = self.configuration ?? .plain()
        config.baseForegroundColor = foregroundColor
        config.background.backgroundColor = backgroundColor
        config.background.strokeColor = foregroundColor
        config.background.cornerRadius = cornerRadius
        config.background.strokeWidth = strokeWidth
        self.configuration = config
        self.updateConfiguration()
        
        self.configurationUpdateHandler = { [weak self] in
            
            guard let self else { return }
            
            switch $0.state {
                
            case .highlighted, .disabled:
                self.updateBackground(background: pressedBackgroundColor)
                
            default:
                self.updateBackground(background: backgroundColor)
            }
        }
    }
}

private extension UIButton {
    
    func updateBackground(background: UIColor) {
        
        var config = self.configuration ?? .plain()
        config.background.backgroundColor = background
        self.configuration = config
        self.updateConfiguration()
    }
}
