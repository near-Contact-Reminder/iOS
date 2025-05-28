import Foundation
import SwiftUI

extension Image {
    
    // Basic Icons
    enum Icon {
        static let arrowRight = Image("icon_12_arrow_right")
        static let arrowChat = Image("icon_24_arrow_chat")
        static let copy = Image("icon_24_copy")
        static let down = Image("icon_24_down")
        static let handle = Image("icon_24_handle")
        static let next = Image("icon_24_next")
        static let share = Image("icon_24_share")
        static let bellDot = Image("icon_32_bell_dot")
        static let bell = Image("icon_32_bell")
        static let menu = Image("icon_32_menu")
        static let down40 = Image("icon_40_down")
        static let addUser = Image("icon_64_adduser")
        static let backBlack = Image("icon_back_32_black")
        static let close24Black = Image("icon_close_24_black")
        static let close32Black = Image("icon_close_32_black")
    }
    
    // Visual Icons
    enum Visual {
        static let emoji0 = Image("icon_visual_24_emoji_0")
        static let emoji50 = Image("icon_visual_24_emoji_50")
        static let emoji100 = Image("icon_visual_24_emoji_100")
        static let heart = Image("icon_visual_24_heart")
        static let cake = Image("icon_visual_cake")
        static let mail = Image("icon_visual_mail")
    }
    
    // Characters
    enum Character {
        static let `default` = Image("img_100_character_default")
        static let success = Image("img_100_character_success")
        static let question = Image("img_100_character_question")
        static let empty = Image("img_100_character_empty")
    }

    // Login Icons
    enum Login {
        static let contact24 = Image("img_24_contact")
        static let kakao24 = Image("img_24_kakao")
        static let apple32 = Image("img_32_apple")
        static let contactSquare32 = Image("img_32_contact_square")
        static let kakaoSquare32 = Image("img_32_kakao_square")
        static let kakao32 = Image("img_32_kakao")
        static let blueLogo = Image("img_120x48_logo_blue")
    }
    
    // User Profile Images
    enum Profile {
        static let user1_64 = Image("_img_64_user1")
        static let user2_64 = Image("_img_64_user2")
        static let user3_64 = Image("_img_64_user3")
        static let user1_80 = Image("_img_80_user1")
    }
    
    // OnBoardings
    enum OnBoarding {
        static let Onboarding1_Home = Image("Onboarding1_Home")
        static let Onboarding2_addProfile = Image("Onboarding2_addProfile")
        static let Onboarding3_Frequency = Image("Onboarding3_Frequency")
        static let Onboarding4_ProfileDetail = Image("Onboarding4_ProfileDetail")
    }
}

// MARK: - Example
/*
Image.Character.default
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 160, height: 160)
*/
