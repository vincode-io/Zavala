//
//  BuildInfo.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/23.
//

import Foundation

struct BuildInfo: Codable {
	
	static let shared = {
		guard let buildInfoPlist = Bundle.main.url(forResource: "BuildInfo", withExtension: "plist"),
			  let data = try? Data(contentsOf: buildInfoPlist),
			  let buildInfo = try? PropertyListDecoder().decode(BuildInfo.self, from: data) else {
			return BuildInfo()
		}
		return buildInfo
	}()
	
	let buildTime: String
	let gitBranch: String
	let gitTag: String
	let gitCommitHash: String
	
	enum CodingKeys: String, CodingKey {
		case buildTime = "BuildTime"
		case gitBranch = "GitBranch"
		case gitTag = "GitTag"
		case gitCommitHash = "GitCommitHash"
	}
	
	var appName: String {
		return Bundle.main.infoDictionary?["CFBundleName"] as! String
	}
	
	var versionNumber: String {
		return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
	}
	
	var buildNumber: String {
		return Bundle.main.infoDictionary?["CFBundleVersion"] as! String
	}
	
	var versionLabel: String {
		return "Version \(BuildInfo.shared.versionNumber) (\(BuildInfo.shared.buildNumber))"
	}
	
	var buildLabel: String {
		return "Build: (branch: \(gitBranch))\(gitTag.isEmpty ? "" : ", (tag: \(gitTag))"), (hash: \(gitCommitHash))"
	}
	
	init() {
		self.buildTime = "***"
		self.gitBranch = "***"
		self.gitTag = "***"
		self.gitCommitHash = "***"
	}

}
