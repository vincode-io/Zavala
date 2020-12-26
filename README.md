# Zavala

A dedicated outliner application for macOS, iPadOS and iOS.

## Contributing

We are currently looking for additional contributors yet.  The project is in such an early state of development
that too many people working on the code would be chaotic.  That will change as the project matures.  I'll update
this README when we get to that point.

## Community

Let's talk outliners!  Head over to the Github Forums for outliner discussion and to express what you would like
to see in an outliner application.  Be sure to read our [Code of Conduct](/documentation/CodeOfConduct.md).

## Project Documents

* [Definitions](/documentation/Definitions.md)
* [Architecture Notebook](/documentation/ArchitectureNotebook.md)

## Building

You can build and test Zavala without a paid developer account.

```bash
git clone https://github.com/vincode-io/Zavala.git
```

You can locally override the Xcode settings for code signing
by creating a `DeveloperSettings.xcconfig` file locally at the appropriate path.
This allows for a pristine project with code signing set up with the appropriate
developer ID and certificates, and for dev to be able to have local settings
without needing to check in anything into source control.

Make a directory SharedXcodeSettings next to where you have this repository.

The directory structure is:

```
aDirectory/
  SharedXcodeSettings/
    DeveloperSettings.xcconfig
  Zavala
    Zavala.xcworkspace
```
Example:

If your Zavala Xcode project file is at:
`/Users/Shared/git/Zavala/Zavala.xcodeproj`

Create your `DeveloperSettings.xcconfig` file at
`/Users/Shared/git/SharedXcodeSettings/DeveloperSettings.xcconfig`

Then create a plain text file in it: `SharedXcodeSettings/DeveloperSettings.xcconfig` and
give it the contents:

```
CODE_SIGN_IDENTITY = Mac Developer
DEVELOPMENT_TEAM = <Your Team ID>
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = <Your Domain Name Reversed>
DEVELOPER_ENTITLEMENTS = -dev
PROVISIONING_PROFILE_SPECIFIER =
```

Set `DEVELOPMENT_TEAM` to your Apple supplied development team.  You can use Keychain
Access to [find your development team ID](/documentation/FindingYourDevelopmentTeamID.md).
Set `ORGANIZATION_IDENTIFIER` to a reversed domain name that you control or have made up.
Note that `PROVISIONING_PROFILE_SPECIFIER` should not have a value associated with it.

You can now open the `Zavala.xccodeproj` in Xcode.

Now you should be able to build without code signing errors and without modifying
the Zavala Xcode project.  This is a special build of Zavala with some
functionality disabled.  For example iCloud syncing is disabled because you need
a paid developer account to build for it.

If you have any problems, we will help you out in the Github Forums.
