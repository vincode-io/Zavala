//
//  CrashReporter.swift
//  Zavala
//
//  Created by Maurice Parker on 1/7/21.
//

#if targetEnvironment(macCatalyst)

import UIKit
import CrashReporter

struct CrashReporter {
	
	private var reporter: PLCrashReporter
	
	init() {
		let reporterConfig = PLCrashReporterConfig.defaultConfiguration()
		reporter = PLCrashReporter(configuration: reporterConfig)
		reporter.enable()
	}
	
	func check(presentingController: UIViewController) {
		guard reporter.hasPendingCrashReport(),
			  let crashData = reporter.loadPendingCrashReportData(),
			  let crashReport = try? PLCrashReport(data: crashData),
			  let crashLogText = PLCrashReportTextFormatter.stringValue(for: crashReport, with: PLCrashReportTextFormatiOS) else { return }

		let restoreAction = UIAlertAction(title: L10n.emailIt, style: .default) { _ in
			emailIt(crashLogText: crashLogText)
			reporter.purgePendingCrashReport()
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
			reporter.purgePendingCrashReport()
		}
		
		let alert = UIAlertController(title: L10n.crashReporterTitle, message: L10n.crashReporterMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(restoreAction)
		
		presentingController.present(alert, animated: true, completion: nil)
	}
}

extension CrashReporter {
	
	private func emailIt(crashLogText: String) {
		var components = URLComponents(string: "mailto:mo@vincode.io")
		var queryItems = [URLQueryItem]()
		queryItems.append(URLQueryItem(name: "subject", value: "Crash Report"))
		queryItems.append(URLQueryItem(name: "body", value: crashLogText))
		components?.queryItems = queryItems
		
		guard let url = components?.url else { return }
		if UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		}
	}
	
}
#endif
