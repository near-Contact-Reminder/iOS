//
//  ProfileDetailViewModel.swift
//  SwypApp2nd
//
//  Created by 정종원 on 4/15/25.
//

import Foundation

class ProfileDetailViewModel: ObservableObject {
    @Published var people: Friend
    
    init(people: Friend) {
        self.people = people
    }
}
