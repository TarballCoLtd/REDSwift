//
//  MessageView.swift
//  REDSwift
//
//  Created by Tarball on 12/5/22.
//

import SwiftUI

struct MessageView: View {
    let message: ConversationMessage
    @State var html: String?
    init(_ message: ConversationMessage) {
        self.message = message
        self.html = nil
    }
    var body: some View {
        VStack {
            HStack {
                Text(message.senderName)
                    .bold()
                    .foregroundColor(.red)
                + Text(":")
                    .foregroundColor(.gray)
                Spacer()
            }
            if let html = html {
                HStack {
                    Text(html)
                    Spacer()
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .onAppear { // shits itself for some reason unless i do this bullshit (im going insane)
                        html = message.body.htmlToString()
                    }
            }
        }
    }
}

extension String {
    func htmlToString() -> String {
        return try! NSAttributedString(data: self.data(using: .utf8)!, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string
    }
}
