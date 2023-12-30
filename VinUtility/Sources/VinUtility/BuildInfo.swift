//
//  BuildInfo.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/23.
//

import Foundation

public struct BuildInfo: Codable {
	
	public static let shared = {
		guard let buildInfoPlist = Bundle.main.url(forResource: "BuildInfo", withExtension: "plist"),
			  let data = try? Data(contentsOf: buildInfoPlist),
			  let buildInfo = try? PropertyListDecoder().decode(BuildInfo.self, from: data) else {
			return BuildInfo()
		}
		return buildInfo
	}()
	
	public let buildTime: String
	public let gitBranch: String
	public let gitTag: String
	public let gitCommitHash: String
	
	enum CodingKeys: String, CodingKey {
		case buildTime = "BuildTime"
		case gitBranch = "GitBranch"
		case gitTag = "GitTag"
		case gitCommitHash = "GitCommitHash"
	}
	
	public var appName: String {
		return Bundle.main.infoDictionary?["CFBundleName"] as! String
	}
	
	public var versionNumber: String {
		return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
	}
	
	public var buildNumber: String {
		return Bundle.main.infoDictionary?["CFBundleVersion"] as! String
	}
	
	public var versionLabel: String {
		return "Version \(BuildInfo.shared.versionNumber) (\(BuildInfo.shared.buildNumber))"
	}
	
	public var buildLabel: String {
		return "Build: (branch: \(gitBranch))\(gitTag.isEmpty ? "" : ", (tag: \(gitTag))"), (hash: \(gitCommitHash))"
	}
	
	init() {
		self.buildTime = "***"
		self.gitBranch = "***"
		self.gitTag = "***"
		self.gitCommitHash = "***"
	}

}
