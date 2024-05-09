//
//  AppDelegate.swift
//  PostKit
//
//  Created by 김다빈 on 11/1/23.
//
import Mixpanel
import SwiftUI
import UIKit
import AppTrackingTransparency
import AdSupport
import Firebase
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {

    @AppStorage("userId") var userId: String?
    private let firebaseManager = FirebaseManager()
    private var mixpanelKey: String?

    func getRandomKey() {
        // 개발용 "mixpanelDev"
        // 배포용 "mixpanelRelease"
        let chatGptAPIKey = firebaseManager.getDoucument(apiName: "mixpanelDev") { [weak self] (key) in
            self?.mixpanelKey = key
            traceLog("앱 시작")
            traceLog(self?.mixpanelKey ?? "키 값 오류")
            
            DispatchQueue.main.async { [self] in
                Mixpanel.initialize(token: self?.mixpanelKey ?? "믹스패널 키 오류", trackAutomaticEvents: true)
                Mixpanel.mainInstance().identify(distinctId: self?.userId ?? "Not Asigned")
                Mixpanel.mainInstance().track(event: "App Open")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        getRandomKey() // 랜덤 키를 가져오는 함수를 호출해주세요.
        GADMobileAds.sharedInstance().start(completionHandler: nil) //구글 광고 초기화
        return true
    }
}
