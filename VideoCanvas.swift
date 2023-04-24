//
//  VideoCanvas.swift
//  MoneyCall
//
//  Created by  on 28/08/21.
//

import SwiftUI

struct VideoCanvas : UIViewRepresentable {
    let rendererView = UIView()
    
    func makeUIView(context: Context) -> UIView {
        rendererView.backgroundColor = UIColor.gray
        return rendererView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct VideoView_Previews : PreviewProvider {
    static var previews: some View {
        VideoCanvas()
    }
}

