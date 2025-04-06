//
//  TextWithDetail.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI

struct TextWithDetail: View {
    
    var title: String
    var detail: String
    var disableFlag: Bool
    
    init(_ title: String, _ detail: String, disabled: Bool = false) {
        self.title = title
        self.detail = detail
        self.disableFlag = disabled
    }
    
    var body: some View {
        VStack{
            Text(title)
                .frame(maxWidth: .infinity, alignment:.leading)
                .strikethrough(disableFlag)
            Text(detail)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment:.leading)
                .strikethrough(disableFlag)
        }

    }
    
    func disabled(_ flag: Bool) -> Self {
        TextWithDetail(self.title, self.detail, disabled: flag)
    }
}
