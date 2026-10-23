//
//  OnboardingAccount.swift
//  TRAVEL GUIDED TOUR
//
//  Screens 5 and 6 create a REAL account (owner, 2026-10-06: "why would
//  'create an account' be anything except a real account"). Until then they
//  were a design only, and the handoff said so.
//
//  · Apple / Google → the same `AuthService` sign-in the Sign in sheet uses.
//    The form then asks only what the provider could not give.
//  · Email → `AuthService.signUp`. Email confirmation is ON for this project,
//    so a new email account has no session until its link is tapped. The name
//    and username are then held in `OnboardingState` and applied the first
//    time that account signs in — see `applyPendingProfile`.
//
//  🔴 A profile that already exists is never overwritten. "Create an account"
//  with Apple can land on an account someone made last year; `saveProfile`
//  writes bio and website too, and would blank them.
//

import Foundation
import AuthenticationServices
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Applying the profile

extension OnboardingCoordinator {
    /// Give a freshly made account the name (and, for email, the username)
    /// typed in onboarding. Only ever fills an account with NO profile yet.
    /// Throws only for a refused username, whose words are already for people.
    func applyProfile(displayName: String, username: String?,
                      using profiles: MakerProfileService) async throws {
        await profiles.loadMyMaker()
        let isNew = profiles.myMaker == nil
        if isNew, !displayName.isEmpty {
            try await profiles.saveProfile(displayName: displayName, bio: "", websiteURL: nil)
        }
        if let username, !username.isEmpty, isNew || profiles.usernameIsAutomatic {
            _ = try await profiles.ensureMaker()
            try await profiles.changeUsername(username)
        }
    }

    /// Run on every sign-in: an email account made in onboarding gets its
    /// name and username the first time it actually signs in (after the
    /// confirmation link). Cleared once applied, or once it can never apply.
    func applyPendingProfile(using profiles: MakerProfileService) async {
        let name = state.pendingDisplayName ?? ""
        let username = state.pendingUsername
        guard !name.isEmpty || !(username ?? "").isEmpty else { return }
        // A refused username (taken in the meantime) is not retried forever;
        // they can set one on their profile.
        try? await applyProfile(displayName: name, username: username, using: profiles)
        update {
            $0.pendingDisplayName = nil
            $0.pendingUsername = nil
        }
    }
}

// MARK: - Sign in with Apple, from our own button

/// Runs the native Apple flow from screen 5's own capsule, and hands back
/// what Supabase needs plus the name — which Apple gives only the FIRST time
/// someone authorises the app, so it is caught here or never.
@MainActor
final class OnboardingAppleSignIn: NSObject {
    struct Result {
        let idToken: String
        let nonce: String
        let givenName: String?
        let familyName: String?
    }

    private var continuation: CheckedContinuation<Result, Error>?
    private var nonce = ""

    func run() async throws -> Result {
        nonce = AppleNonce.random()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleNonce.sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        #if canImport(UIKit)
        controller.presentationContextProvider = self
        #endif
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

extension OnboardingAppleSignIn: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithAuthorization authorization: ASAuthorization) {
        MainActor.assumeIsolated {
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.identityToken,
                  let token = String(data: data, encoding: .utf8)
            else {
                continuation?.resume(throwing: OnboardingAccountError.appleNoToken)
                continuation = nil
                return
            }
            continuation?.resume(returning: Result(
                idToken: token, nonce: nonce,
                givenName: credential.fullName?.givenName,
                familyName: credential.fullName?.familyName))
            continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithError error: Error) {
        MainActor.assumeIsolated {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

#if canImport(UIKit)
extension OnboardingAppleSignIn: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
#endif

enum OnboardingAccountError: LocalizedError {
    case appleNoToken
    var errorDescription: String? {
        "Apple sign-in didn't return a token. Please try again."
    }
}

/// Did the person just close the provider's own sheet? That is a change of
/// mind, not an error worth a red line.
func isUserCancellation(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if (error as? ASAuthorizationError)?.code == .canceled { return true }
    let ns = error as NSError
    return ns.domain == "com.apple.AuthenticationServices.WebAuthenticationSession"
}

/// Words for a failed provider sign-in. Apple's own errors read as codes
/// ("AuthorizationError error 1000" — e.g. no Apple Account on the device),
/// so they get a sentence instead.
func friendlyAccountError(_ error: Error) -> String {
    if error is ASAuthorizationError {
        return "Sign in with Apple didn't finish. Please try again."
    }
    return error.localizedDescription
}

// MARK: - Nonce (Apple ⇄ Supabase)

/// Apple receives the SHA256 of a random nonce; Supabase receives the raw
/// value to verify the token's `nonce` claim. Shared with `SignInView`.
enum AppleNonce {
    static func random(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        while result.count < length {
            for byte in (0..<16).map({ _ in UInt8.random(in: 0...255) }) where result.count < length {
                result.append(charset[Int(byte) % charset.count])
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
