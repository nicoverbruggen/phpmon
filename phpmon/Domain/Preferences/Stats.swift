//
//  Stats.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
 
class Stats {
    
    /**
     Keep track of how many times the app has been successfully launched.
     
     This is used to determine whether it is time to show the sponsor
     encouragement alert, but I'd like to include this stat somewhere
     else as well.
     */
    public static var successfulLaunchCount: Int {
        UserDefaults.standard.integer(
            forKey: InternalStats.launchCount.rawValue
        )
    }
    
    /**
     Keep track of how many times the app has successfully switched
     between different PHP versions.
     
     This is used to determine whether it is time to show the sponsor
     encouragement alert, but I'd like to include this stat somewhere
     else as well.
     */
    public static var successfulSwitchCount: Int {
        UserDefaults.standard.integer(
            forKey: InternalStats.switchCount.rawValue
        )
    }
    
    /**
     Did the user see the sponsor encouragement / thank you message?
     Annoying the user is the worst, so let's not show the message twice.
     */
    public static var didSeeSponsorEncouragement: Bool {
        UserDefaults.standard.bool(
            forKey: InternalStats.didSeeSponsorEncouragement.rawValue
        )
    }
    
    /**
     Increment the successful launch count. This should only be
     called when the user has not encountered ANY issues starting
     up the application.
     */
    public static func incrementSuccessfulLaunchCount() {
        UserDefaults.standard.set(
            Stats.successfulLaunchCount + 1,
            forKey: InternalStats.launchCount.rawValue
        )
    }
    
    /**
     Increment the successful switch count.
     */
    public static func incrementSuccessfulSwitchCount() {
        UserDefaults.standard.set(
            Stats.successfulSwitchCount + 1,
            forKey: InternalStats.switchCount.rawValue
        )
    }
    
    public static func evaluateSponsorMessageShouldBeDisplayed() {
        if Bundle.main.bundleIdentifier?.contains("beta") ?? false {
            return Log.info("Sponsor messages never apply to beta builds.")
        }
        
        if Stats.didSeeSponsorEncouragement {
            return Log.info("Awesome, the user has already seen the sponsor message.")
        }
        
        if Stats.successfulLaunchCount < 7 && Stats.successfulSwitchCount < 40 {
            return Log.info("It is too soon to see the sponsor message (launched \(Stats.successfulLaunchCount) times, switched \(Stats.successfulSwitchCount) times).")
        }
        
        DispatchQueue.main.async {
            let donate = Alert.present(
                messageText: "startup.sponsor_encouragement.title".localized,
                informativeText: "startup.sponsor_encouragement.desc".localized,
                buttonTitle: "startup.sponsor_encouragement.accept".localized,
                secondButtonTitle: "startup.sponsor_encouragement.skip".localized,
                style: .informational)
            if donate {
                Log.info("The user is an absolute badass for choosing this option. Thank you.")
                guard let url = URL(string: "https://nicoverbruggen.be/sponsor#pay-now") else { return }
                NSWorkspace.shared.open(url)
            }
            UserDefaults.standard.set(true, forKey: InternalStats.didSeeSponsorEncouragement.rawValue)
        }
    }
    
}
