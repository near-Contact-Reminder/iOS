import Foundation
import FirebaseAnalytics

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() { }
    
    // MARK: - HomeView
    func myProfileLogAnalytics() {
        Analytics.logEvent("click_my_profile_btn", parameters: nil)
        print("📊 [Analytics] click_my_profile_btn 전송")
    }
    
    func notificationLogAnalytics() {
        Analytics.logEvent("click_notification_btn", parameters: nil)
        print("📊 [Analytics] click_notification_btn 전송")
    }
    
    func addPersonLogAnalytics() {
        Analytics.logEvent("click_add_person_btn", parameters: nil)
        print("📊 [Analytics] click_add_person_btn 전송")
    }
    
    func selectPersonLogAnalytics() {
        Analytics.logEvent("click_select_person_btn", parameters: nil)
        print("📊 [Analytics] click_select_person_btn 전송")
    }
    
    func trackHomeViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "HomeView",
                                       AnalyticsParameterScreenClass: "HomeView"])
    }
    
    // MARK: - LoginView
    func kakaoLoginLogAnalytics() {
        Analytics.logEvent("click_signup_btn", parameters: [
            "method": "kakao"
        ])
        print("📊 [Analytics] click_signup_btn: kakao 로 전송")
    }
    
    func appleLoginLogAnalytics() {
        Analytics.logEvent("click_signup_btn", parameters: [
            "method": "apple"
        ])
        print("📊 [Analytics] click_signup_btn: apple 로 전송")
    }
    
    func trackLoginViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "LoginView",
                                       AnalyticsParameterScreenClass: "LoginView"])
    }
    
    // MARK: - TermsView
    func agreementLogAnalytics() {
        Analytics.logEvent("click_agreement_btn", parameters: nil)
        print("📊 [Analytics] click_agreement_btn 전송")
    }
    
    func trackTermsViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "TermsView",
                                       AnalyticsParameterScreenClass: "TermsView"])
    }
    
    // MARK: - RegisterFriendsView
    func contactImportLogAnalytics() {
        Analytics.logEvent("click_contact_import_btn", parameters: nil)
        print("📊 [Analytics] click_contact_import_btn 전송")
    }
    
    func skipButtonLogAnalytics() {
        Analytics.logEvent("click_skip_btn", parameters: nil)
        print("📊 [Analytics] click_skip_btn 전송")
    }
    
    func nextButtonLogAnalytics() {
        Analytics.logEvent("click_next_btn", parameters: nil)
        print("📊 [Analytics] click_next_btn 전송")
    }
    
    func trackRegisterFriendsViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "RegisterFriendsView",
                                       AnalyticsParameterScreenClass: "RegisterFriendsView"])
    }
    
    // MARK: - ContactFrequencySettingsView
    func setCareFrequencyLogAnalytics() {
        Analytics.logEvent("click_set_care_frequency_btn", parameters: nil)
        print("📊 [Analytics] click_set_care_frequency_btn 전송")
    }
    
    func previousButtonLogAnalytics() {
        Analytics.logEvent("click_previous_btn", parameters: nil)
        print("📊 [Analytics] click_set_care_frequency_btn 전송")
    }
    
    func completeButtonLogAnalytics() {
        Analytics.logEvent("click_complete_profile_btn", parameters: nil)
        print("📊 [Analytics] click_complete_profile_btn 전송")
    }
    
    func trackContactFrequencySettingsViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "FrequencyView",
                                       AnalyticsParameterScreenClass: "FrequencyView"])
    }
    
    // MARK: - ProfileDetailView
    func callButtonLogAnalytics() {
        Analytics.logEvent("click_call_person_btn", parameters: nil)
        print("📊 [Analytics] click_call_person_btn 전송")
    }
    
    func messageButtonLogAnalytics() {
        Analytics.logEvent("click_message_person_btn", parameters: nil)
        print("📊 [Analytics] click_message_person_btn 전송")
    }
    
    func profileTabLogAnalytics() {
        Analytics.logEvent("click_tab_profile_btn", parameters: nil)
        print("📊 [Analytics] click_tab_profile_btn 전송")
    }
    
    func historyTapLogAnalytics() {
        Analytics.logEvent("click_tab_history_btn", parameters: nil)
        print("📊 [Analytics] click_tab_history_btn 전송")
    }
    
    func dailyCheckButtonLogAnalytics() {
        Analytics.logEvent("click_daily_check_btn", parameters: nil)
        print("📊 [Analytics] click_daily_check_btn 전송")
    }
    
    func trackProfileDetailViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "ProfileDetailView",
                                       AnalyticsParameterScreenClass: "ProfileDetailView"])
    }
    
    // MARK: - ProfileEditView
    func trackProfileEditViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "ProfileEditView",
                                       AnalyticsParameterScreenClass: "ProfileEditView"])
    }
    
    // MARK: - MyProfileView
    func notificationSettingButtonLogAnalytics(isOn: Bool) {
        Analytics.logEvent("click_notification_setting_btn", parameters: [
            "toggle_state": isOn ? "on" : "off"
        ])
        setNotificationOn(isOn)
        print("📊 [Analytics] click_notification_setting_btn: \(isOn) 로 전송")
    }
    
    func logoutButtonLogAnalytics() {
        Analytics.logEvent("click_logout_btn", parameters: nil)
        print("📊 [Analytics] click_logout_btn 전송")
    }
    
    func withdrawButtonLogAnalytics() {
        Analytics.logEvent("click_withdraw_btn", parameters: nil)
        print("📊 [Analytics] click_withdraw_btn 전송")
    }
    
    func trackMyProfileViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "MyProfileView",
                                       AnalyticsParameterScreenClass: "MyProfileView"])
    }
    
    // MARK: - WithDrawalView
    func trackWithDrawalViewLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "WithDrawalView",
                                       AnalyticsParameterScreenClass: "WithDrawalView"])
    }
        
    // MARK: - NotificationInbox
    /// 알림 리스트 클릭 시 ( care_type: "manual", "birthday", "anniversary" )
    func notificationListItemTapped(careType: String) {
        Analytics.logEvent("click_notification_list_item", parameters: [
            "care_type": careType
        ])
        print("📊 [Analytics] click_notification_list_item: \(careType) 로 전송")
    }
    
    func trackNotificationInboxLogAnalytics() {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: "NotificationInboxView",
                                       AnalyticsParameterScreenClass: "NotificationInboxView"])
    }
    
    // MARK: - PushNotification
    /// 푸시 알림 클릭 시 ( push_type: "manual_reminder", "birthday_reminder", "anniversary_reminder" )
    func pushListItemTapped(pushType: String) {
        Analytics.logEvent("click_push_list_item", parameters: [
            "push_type": pushType
        ])
        print("📊 [Analytics] click_push_list_item: \(pushType) 로 전송")
    }
    
    // MARK: - 사용자 속성
    func setProfileCountBucket(_ count: Int) {
        let bucket: String
        switch count {
        case 0: bucket = "0"
        case 1...3: bucket = "1-3"
        case 4...6: bucket = "4-6"
        default: bucket = "7+"
        }
        Analytics.setUserProperty(bucket, forName: "profile_count_bucket")
        print("📊 [Analytics] profile_count_bucket: \(bucket) 로 전송")
        
    }
    
    // TODO: - 온보딩 추가후 적용
    func setOnboardingDone() {
        Analytics.setUserProperty("y", forName: "onboarding_done")
        print("📊 [Analytics] onboarding_done: y 로 전송")
        
    }
    
    // TODO: - 첫 챙길 사람 등록 여부 어떻게..? 서버와 회의 필요
    func setFirstAddPersonDone() {
        Analytics.setUserProperty("y", forName: "first_add_person_done")
        print("📊 [Analytics] first_add_person_done: y 로 전송")
    }
    
    // TODO: - 푸시 또는 실행 어떻게..?
    /// 앱 실행 경로 ( channel: "direct", "push" )
    func setEntryChannel(_ channel: String) {
        Analytics.setUserProperty(channel, forName: "entry_channel")
        print("📊 [Analytics] entry_channel: \(channel) 로 전송")
    }
    
    func setNotificationOn(_ isOn: Bool) {
        Analytics.setUserProperty(isOn ? "y" : "n", forName: "notification_on")
        print("📊 [Analytics] notification_on: \(isOn) 로 전송")
    }
    
    // MARK: - Onboarding
    func onboarding(_ seen: Bool) {
        Analytics.setUserProperty(seen ? "y" : "n", forName: "onboarding_done")
        print("📊 [Analytics] onboarding_done: \(seen) 로 전송")
    }
}
