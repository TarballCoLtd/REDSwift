//
//  UserProfileView.swift
//  REDSwift
//
//  Created by Tarball on 12/6/22.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var model: REDAppModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("apiKey") var apiKey: String = ""
    @State var result: UserSearchResult
    @State var profile: UserProfile?
    @State var avatarExists: Bool = true
    @State var pfp: Image?
    @State var erroredOut: Bool = false
    init(_ result: UserSearchResult) {
        self._result = State(initialValue: result)
    }
    @ViewBuilder
    var profileName: some View {
        if let profile = profile {
            VStack {
                HStack {
                    Spacer()
                    Text(profile.username)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)
                    if profile.donor {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 20)
                            .foregroundColor(.red)
                    }
                    if profile.warned {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 20)
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
                .padding(.bottom, -5)
                HStack {
                    Spacer()
                    Text("(\(profile.userClass))")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.top, -5)
                Divider()
            }
            .padding(.horizontal, 20)
        }
    }
    @ViewBuilder
    var avatar: some View {
        if avatarExists {
            HStack {
                Spacer()
                if let pfp = pfp {
                    pfp
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.top, 10)
                    
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: 50)
                }
                Spacer()
            }
        }
    }
    @ViewBuilder
    var sections: some View {
        if let profile = profile {
            SectionTitle("Statistics") {
                UserStats(profile)
            }
            .padding(10)
            if UserRanks.shouldDisplay(profile) {
                SectionTitle("Percentile Rankings") {
                    UserRanks(profile)
                }
                .padding(10)
            }
            SectionTitle("Personal") {
                UserInfo(profile)
            }
            .padding(10)
            if UserCommunity.shouldDisplay(profile) {
                SectionTitle("Community") {
                    UserCommunity(profile)
                }
                .padding(10)
            }
        }
    }
    @ViewBuilder
    var loading: some View {
        VStack {
            Spacer()
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.horizontal, 2)
                Text("Loading...")
            }
            Spacer()
        }
        .onAppear { // this is dumb but for some reason when i use `.task(_:)`, it shits itself
            Task {
                do {
                    profile = try await model.api.requestUserProfile(user: result.userId)
                    avatarExists = profile!.avatar != ""
                } catch {
                    erroredOut = true
                }
                if avatarExists {
                    pfp = try? await model.api.requestProfilePicture(profile!.avatar)
                }
            }
        }
    }
    var body: some View {
        if let profile = profile {
            RefreshableScrollView { // the padding in this makes me :cringeharold:
                profileName
                avatar
                sections
                Spacer()
            } onRefresh: {
                do {
                    let profile = try await model.api.requestPersonalProfile()
                    model.personalProfile = try await model.api.requestUserProfile(user: profile.id)
                } catch {
                    erroredOut = true
                }
                model.pfp = try? await model.api.requestProfilePicture(model.personalProfile!.avatar)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(profile.username)
                        .fixedSize(horizontal: true, vertical: false)
                        .font(.headline)
                }
            }
        } else if apiKey != "" {
            loading
        } else if erroredOut {
            RequestError {
                do {
                    profile = try await model.api.requestUserProfile(user: result.userId)
                    avatarExists = profile!.avatar != ""
                } catch {
                    erroredOut = true
                }
                if avatarExists {
                    pfp = try? await model.api.requestProfilePicture(profile!.avatar)
                }
            }
        } else {
            VStack {
                Text("API Key Not Set")
                    .font(.title)
                Text("Your API key can be set in settings.")
            }
        }
    }
}
