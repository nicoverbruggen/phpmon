//
//  CrashReporter.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import CrashReporter

class CrashReporter {

    static func initialize() {

        if CrashReporter.isDebuggerAttached() {
            Log.err("[CrashReporter] The debugger is attached, won't start crash reporting.")
            return
        }

        let config = PLCrashReporterConfig(signalHandlerType: .mach, symbolicationStrategy: [])

        guard let crashReporter = PLCrashReporter(configuration: config) else {
            Log.err("[CrashReporter] Could not create an instance of PLCrashReporter.")
            return
        }

        do {
            try crashReporter.enableAndReturnError()
        } catch let error {
            Log.err("[CrashReporter] Could not enable crash reporter: \(error). Crashes will not be reported.")
        }

        if crashReporter.hasPendingCrashReport() {
            CrashReporter.requestSendingCrashReport(crashReporter)
        }
    }

    static func requestSendingCrashReport(_ crashReporter: PLCrashReporter) {
        do {
            let data = try crashReporter.loadPendingCrashReportDataAndReturnError()
            let report = try PLCrashReport(data: data)

            if let text = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS) {
                submitCrashReportToApi(text)
            } else {
                Log.err("[CrashReporter] Could not convert report to text.")
            }
        } catch let error {
            Log.err("[CrashReporter] Failed to load and parse with error: \(error)")
        }

        crashReporter.purgePendingCrashReport()
    }

    private static func submitCrashReportToApi(_ text: String) {
        let timeout = TimeInterval.seconds(10)

        var request = URLRequest(url: Constants.Urls.CrashReportingEndpoint)
        request.httpMethod = "POST"
        request.setValue("text/crash", forHTTPHeaderField: "Content-Type")
        request.setValue("phpmon-crashrep/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = text.data(using: .utf8)

        // Send the request synchronously, we want the report to be sent before anything else
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout

        let session = URLSession(configuration: config)
        let semaphore = DispatchSemaphore(value: 0)

        let task = session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }

            if let error = error {
                Log.err("[CrashReporter] Failed to send crash report: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    Log.info("[CrashReporter] Crash report sent successfully!")
                case 400...499:
                    Log.err("[CrashReporter] Client error when sending crash report: \(httpResponse.statusCode)")
                case 500...599:
                    Log.err("[CrashReporter] Server error when sending crash report: \(httpResponse.statusCode)")
                default:
                    Log.err("[CrashReporter] Unexpected response code: \(httpResponse.statusCode)")
                }
            }
        }

        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout)
    }

    /**
     Determines whether a debugger is attached.
     */
    private static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
