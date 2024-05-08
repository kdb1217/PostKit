//
//  MainView.swift
//  PostKit
//
//  Created by 김다빈 on 10/11/23.
//
import SwiftUI
import CoreData
//import CloudKit
import AppTrackingTransparency
import FirebaseRemoteConfig

struct MainView: View {
    @AppStorage("_isFirstLaunching") var isFirstLaunching: Bool = true
    @EnvironmentObject var appstorageManager: AppstorageManager
    @EnvironmentObject var pathManager: PathManager
    @State private var isShowingToast = false
    @State private var updateAlert = false
    //iCloud가 연동 확인 모델
//    @StateObject private var iCloudData = CloudKitUserModel()
    @ObservedObject var viewModel = ChatGptViewModel.shared
    @ObservedObject var loadingModel = LoadingViewModel.shared
    @ObservedObject var filterLike = LikeFilter.shared
    private let pasteBoard = UIPasteboard.general
    
    //CoreData Manager
    private let coreDataManager = CoreDataManager.instance
    private let hapticManger = HapticManager.instance
    //AppStorage iCloud버전
//    var keyStore = NSUbiquitousKeyValueStore()
    
    //CoreData 임시 Class
    @StateObject var storeModel = StoreModel( _storeName: "", _tone: [])
    @State private var captions: [CaptionModel] = []
    @State private var hashtags: [HashtagModel] = []
    
    //TabView의 선택된 View
    @State var selection = 0
    
    
    let appStoreAppID = "6470146461"
    let remoteConfig = RemoteConfig.remoteConfig()
    let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    
    var body: some View {
        ZStack {
            //이미 Bool 값이 True면 비교 불필요
            if isFirstLaunching {
                OnboardingView( isFirstLaunching: $isFirstLaunching, storeModel: storeModel)
            } else {
                NavigationStack(path: $pathManager.path) {
                    TabView(selection: $selection) {
                        MainCaptionView()
                            .tabItem {
                                if selection == 0 {
                                    VStack{
                                        Image(.captionFocus)
                                    }
                                } else {
                                    Image(.caption)
                                }
                                Text("글 쓰기")
                            }
                            .tag(0)
                        
                        MainHistoryView(selection: $selection)
                            .tabItem {
                                if selection == 1 {
                                    Image(.historyFocus)
                                } else {
                                    Image(.history)
                                }
                                Text("글 보기")
                            }
                            .tag(1)
                            .onChange(of: selection) { _ in
                                filterLike.isLiked = false
                            }
                    }
                    .accentColor(.main)
                    .navigationDestination(for: StackViewType.self) { stackViewType in
                        switch stackViewType {
                        case .Cafe:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.cafe)
                        case .Fashion:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.fashion)
                        case .Hair:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.hair)
                        case .Restaurant:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.restaurant)
                        case .NailSalon:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.nailSalon)
                        case .Gym:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.gym)
                        case .Cosmetics:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.cosmetics)
                        case .Flower:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.flower)
                        case .Studio:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.studio)
                        case .SettingHome:
                            SettingView(storeModel: storeModel)
                        case .SettingStore:
                            SettingStoreView(storeName: $storeModel.storeName)
                        case .SettingTone:
                            SettingToneView(storeTone: $storeModel.tone)
                        case .SettingCS:
                            MyWebView(urlToLoad: "https://postkit.channel.io/")
                        case .Loading:
                            LoadingView()
                        case .CaptionResult:
                            CaptionResultView(storeModel: storeModel)
                        case .HashtagResult:
                            HashtagResultView()
                        case .BrowShop:
                            CaptionView(storeModel: storeModel, categoryName: categoryType.browShop)
                        case .ErrorNetwork:
                            ErrorView(errorReasonState: .networkError, errorCasue: "네트워크 연결이\n원활하지 않아요", errorDescription: "네트워크 연결을 확인해주세요", errorImage: .errorNetwork)
                        case .ErrorResultFailed:
                            ErrorView(errorReasonState: .apiError, errorCasue: "생성을\n실패했어요", errorDescription: "예기치 못한 이유로 생성에 실패했어요\n다시 시도해주세요", errorImage: .errorFailed)
                        case .Hashtag:
                            HashtagView()
                        }
                    }
                    .onChange(of: pathManager.path) { _ in
                        filterLike.isLiked = false
                    }
                }
                .navigationBarBackButtonHidden()
                .onAppear {
                    fetchUpdate()
                    if appVersion < remoteConfig["var_require_ios"].stringValue ?? "오루" {
                        updateAlert = true
                    }
                    
                    let tabBarAppearance = UITabBarAppearance()
                        tabBarAppearance.configureWithDefaultBackground()
                        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                    
                    fetchStoreData()
                    viewModel.promptAnswer = "생성된 텍스트가 들어가요."
                    
                    fetchCaptionData()
                    fetchHashtagData()
                    loadingModel.inputArray.removeAll()
                    traceLog(remoteConfig["var_require_ios"].stringValue!)
                    traceLog(updateAlert)
//                    //Cloud 디버깅
//                    print("iCloud Status")
//                    print("IS SIGNED IN: \(iCloudData.isSignedIntoiCloud.description.uppercased())\nPermission Status: \(iCloudData.permissionStatus.description)\nUser Name: \(iCloudData.userName)")
//                    print("\(iCloudData.error)")
//
//                    saveToCloud()
                }
            }
        }
        .alert("업데이트가 필요합니다", isPresented: $updateAlert) {
            Button {
                forceUpdate()
            } label: {
                Text("확인")
            }
        }
    }
}

//MARK: extension MainView Functions
extension MainView {
    // MARK: - 카피 복사
    private func copyToClipboard() {
        hapticManger.notification(type: .success)
        pasteBoard.string = viewModel.promptAnswer
        isShowingToast = true
    }
    
    private func fetchUpdate() {
        remoteConfig.fetch(withExpirationDuration: TimeInterval(60)) { (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                remoteConfig.fetchAndActivate()
            } else {
                print("Config not fethed")
                print("Error: \(error?.localizedDescription ?? "No error availabe.")")
            }
        }
    }
    
    private func forceUpdate() {
        let url = URL(string: "https://apps.apple.com/kr/app/%ED%8F%AC%EC%8A%A4%ED%8A%B8%ED%82%B7-postkit/id" + appStoreAppID)!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension MainView : MainViewProtocol {
    
    func fetchStoreData() {
        let storeRequest = NSFetchRequest<StoreData>(entityName: "StoreData")
        
        do {
            let storeDataArray = try coreDataManager.context.fetch(storeRequest)
            if let storeCoreData = storeDataArray.last {
                self.storeModel.storeName = storeCoreData.storeName ?? ""
                // TODO: 코어데이터 함수 변경 필요
                self.storeModel.tone = storeCoreData.tones ?? []
            }
        } catch {
            print("ERROR STORE CORE DATA")
            print(error.localizedDescription)
        }
    }
    
    func fetchCaptionData() {
        let CaptionRequest = NSFetchRequest<CaptionResult>(entityName: "CaptionResult")
        
        do {
               let captionArray = try coreDataManager.context.fetch(CaptionRequest)
            captions = captionArray.map { captionCoreData in
                return CaptionModel(
                    _id: captionCoreData.resultId ?? UUID(),
                    _date: captionCoreData.date ?? Date(),
                    _category: captionCoreData.category ?? "",
                    _caption: captionCoreData.caption ?? "",
                    _like: captionCoreData.like
                )
            }
            captions.sort { $0.date > $1.date }
           } catch {
               print("ERROR FETCHING CAPTION CORE DATA")
               print(error.localizedDescription)
           }
    }
    
    func fetchHashtagData() {
        let HashtagRequest = NSFetchRequest<HashtagData>(entityName: "HashtagData")
        
        do {
            let hashtagDataArray = try coreDataManager.context.fetch(HashtagRequest)
            hashtags = hashtagDataArray.map{ hashtagCoreData in
                return HashtagModel(
                    _id: hashtagCoreData.resultId ?? UUID(),
                    _date: hashtagCoreData.date ?? Date(),
                    _locationTag: hashtagCoreData.locationTag ?? [""],
                    _keyword: hashtagCoreData.keyword ?? [""],
                    _hashtag: hashtagCoreData.hashtag ?? "",
                    _isLike: hashtagCoreData.like
                )
            }
            hashtags.sort { $0.date > $1.date }
        } catch {
            print("ERROR STORE CORE DATA")
            print(error.localizedDescription)
        }
    }
    
    func saveCaptionData(_uuid: UUID, _result: String, _like: Bool) {
        let fetchRequest = NSFetchRequest<CaptionResult>(entityName: "CaptionResult")
        
        // captionModel의 UUID가 같을 경우
        let predicate = NSPredicate(format: "resultId == %@", _uuid as CVarArg)
        fetchRequest.predicate = predicate
        
        if let existingCaptionResult = try? coreDataManager.context.fetch(fetchRequest).first {
            // UUID에 해당하는 데이터를 찾았을 경우 업데이트
            existingCaptionResult.caption = _result
            existingCaptionResult.like = _like
            
            coreDataManager.save() // 변경사항 저장
            
            traceLog("Caption 수정 완료!\n resultId : \(String(describing: existingCaptionResult.resultId))\n Date : \(String(describing: existingCaptionResult.date))\n Category : \(String(describing: existingCaptionResult.category))\n Caption : \(String(describing: existingCaptionResult.caption))\n")
        } else {
            // UUID에 해당하는 데이터가 없을 경우 새로운 데이터 생성
            let newCaption = CaptionResult(context: coreDataManager.context)
            newCaption.resultId = _uuid
            newCaption.caption = _result
            newCaption.like = _like
            
            coreDataManager.save() // 변경사항 저장
            
            traceLog("Caption 새로 저장 완료!\n resultId : \(_uuid)\n Date : \(String(describing: newCaption.date))\n Category : \(String(describing: newCaption.category))\n Caption : \(String(describing: newCaption.caption))\n")
        }
    }
    
    func saveHashtagData(_uuid: UUID, _result: String, _like: Bool) {
        let fetchRequest = NSFetchRequest<HashtagData>(entityName: "HashtagData")
        
        // captionModel의 UUID가 같을 경우
        let predicate = NSPredicate(format: "resultId == %@", _uuid as CVarArg)
        fetchRequest.predicate = predicate
        
        if let existingCaptionResult = try? coreDataManager.context.fetch(fetchRequest).first {
            // UUID에 해당하는 데이터를 찾았을 경우 업데이트
            existingCaptionResult.hashtag = _result
            existingCaptionResult.like = _like
            
            coreDataManager.save() // 변경사항 저장
            traceLog("Hashtag 수정 완료!\n resultId : \(String(describing: existingCaptionResult.resultId))\n Date : \(String(describing: existingCaptionResult.date))\nHashtag : \(String(describing: existingCaptionResult.hashtag))\n")
        } else {
            // UUID에 해당하는 데이터가 없을 경우 새로운 데이터 생성
            let newCaption = HashtagData(context: coreDataManager.context)
            newCaption.resultId = _uuid
            newCaption.hashtag = _result
            newCaption.like = _like
            
            coreDataManager.save() // 변경사항 저장
            traceLog("Hashtag 수정 완료!\n resultId c: \(String(describing: newCaption.resultId))\n Date : \(String(describing: newCaption.date))\nHashtag : \(String(describing: newCaption.hashtag))\n")
        }
    }
    
    func deleteCaptionData(_uuid: UUID) {
        let fetchRequest = NSFetchRequest<CaptionResult>(entityName: "CaptionResult")
        
        // NSPredicate를 사용하여 UUID가 같을 경우 삭제
        let predicate = NSPredicate(format: "resultId == %@", _uuid as CVarArg)
        fetchRequest.predicate = predicate
        
        do {
            let captionArray = try coreDataManager.context.fetch(fetchRequest)
            
            //이곳에서 삭제 합니다.
            for captionEntity in captionArray {
                coreDataManager.context.delete(captionEntity)
            }
            
            //코어데이터에 삭제 후 결과를 저장
            try coreDataManager.context.save()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
    
    func deleteHashtagData(_uuid: UUID) {
        let fetchRequest = NSFetchRequest<HashtagData>(entityName: "HashtagData")
        
        // NSPredicate를 사용하여 UUID가 같을 경우 삭제
        let predicate = NSPredicate(format: "resultId == %@", _uuid as CVarArg)
        fetchRequest.predicate = predicate
        
        do {
            let hashtagArray = try coreDataManager.context.fetch(fetchRequest)
            
            for hashtagEntity in hashtagArray {
                coreDataManager.context.delete(hashtagEntity)
            }
            
            try coreDataManager.context.save()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
    
    func convertDate(date: Date) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
      
        var convertDate = formatter.string(from: date)
        
        return convertDate
    }
}

//extension MainView : iCloudProtocol {
//    func fetchAllFromCloud() {
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: "Store",predicate: predicate)
//        let operation = CKQueryOperation(query: query)
//        operation.database =  CKContainer(identifier: "iCloud.com.PostKit")
//            .publicCloudDatabase
//
//        operation.recordMatchedBlock = { recordID, result in
//            print("💿", recordID)
//            switch result {
//            case .success(let record):
//                print("📀", record)
//            case .failure(let error):
//                print(error)
//            }
//        }
//
//        operation.start()
//    }
//
//    func saveToCloud() {
//        let record = CKRecord(recordType: "Store")
//        record.setValuesForKeys(["StoreName": "TestStoreName", "StoreTone": "저장톤"])
//
//        let container = CKContainer(identifier: "iCloud.com.PostKit")
//        container.publicCloudDatabase.save(record) { record, error in
//            print("저장완료! \(record)")
//        }
//    }
//
//    func updateCloud() {
//        //아직
//    }
//
//    func deleteCloud() {
//        //개발중
//    }
//}
