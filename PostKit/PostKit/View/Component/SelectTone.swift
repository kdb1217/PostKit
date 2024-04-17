//
//  SelectTone.swift
//  PostKit
//
//  Created by 김다빈 on 10/13/23.

import SwiftUI

struct SelectTone: View {
    @Binding var selectedTones: [String]
    @Binding var isShowToast: Bool
    
    let tones: [Tone] = [
        Tone(tone: "친절한", toneExample: "오늘은 행복한 하루 되세요! 😊", isBest: true),
        Tone(tone: "감성적인", toneExample: "가을 바람에 흩날리는 낙엽 소리가 마음을 울려요. 🍂", isBest: true),
        Tone(tone: "논리적인", toneExample: "운동은 건강에 매우 중요하다고 합니다.", isBest: false),
        Tone(tone: "간단한", toneExample: "햇살 가득한 날, 책과 차 한잔으로 힐링하기 좋아요.", isBest: false),
        Tone(tone: "애교있는", toneExample: "함께하는 시간이 너무 즐거워요.💕", isBest: false),
        Tone(tone: "재치있는", toneExample: "인생도 가끔은 예상치 못한 상황에 대비해야 해요. 😄☔️", isBest: false)
    ]
    
    var body: some View {
        toggleBtns
    }
}

//MARK: Extension: View
extension SelectTone {
    private var toggleBtns: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 배열에 추가되면 자동으로 생성하게 해주는 기능을 만들었어요!
            ForEach(tones, id: \.self) { rowIndex in
                toggleBtn(concept: rowIndex.tone, conceptExample: rowIndex.toneExample, isBest: rowIndex.isBest) {
                    addTone(tone: rowIndex.tone)
                    print(selectedTones)
                }
            }
        }
    }
    
    private func toggleBtn(concept: String, conceptExample: String, isBest: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack{
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(concept)
                            .body1Bold(textColor: selectedTones.contains(concept) ? Color.gray5 : Color.gray4)
                        
                        if isBest {
                            Text("BEST")
                                .body2Bold(textColor: .main)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(Color.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(conceptExample)
                        .body2Bold(textColor: .gray4)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.all, 20)
            .background(selectedTones.contains(concept) ? Color.sub : Color.gray1)
            .cornerRadius(radius1)
            .overlay(
                RoundedRectangle(cornerRadius: radius1)
                    .stroke(selectedTones.contains(concept) ? Color.main : Color.gray1, lineWidth: 2)
            )
        }
    }
}

extension SelectTone {
    private func addTone(tone: String) {
        if !selectedTones.contains(tone) && selectedTones.count < 3 {
            selectedTones.append(tone)
        }
        else if selectedTones.contains(tone) {
            selectedTones.removeAll(where: {$0 == tone})
        }
        else {
           isShowToast = true
        }
    }
}
