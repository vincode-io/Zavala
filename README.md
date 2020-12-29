# Zavala

A dedicated outliner for macOS, iPadOS, and iOS.

## Contributing

We are not currently looking for additional contributors yet. The project is in such an early state of development
that too many people working on the code would be chaotic. That will change as the project matures. I'll update
this README when we get to that point.

## Community

Let's talk outliners! Head over to [Discussions](https://github.com/vincode-io/Zavala/discussions) for outliner discussion and to express what you would like to see in an outliner application. Be sure to read our [Code of Conduct](/documentation/CodeOfConduct.md).

## Credits

I would like to thank [John Gruber](https://daringfireball.net) and [Brent Simmons](https://inessential.com)
for inspiring this project. Their dedication to outliners and disatisfaction with the current generation of
them is ultimately what got this project going.  In fact John [tweeted](https://twitter.com/gruber/status/1277329886080905219) this:

> I would kill for a good simple outliner that synced across iOS and Mac, and had a great *simple* UI on all three platforms.

If there was a mission statement for Zavala, that would be it.

## Project Documents

* [Planned Features](https://github.com/vincode-io/Zavala/wiki/Planned-Features)
* [Definitions](https://github.com/vincode-io/Zavala/wiki/Definitions)
* [Architecture Notebook](https://github.com/vincode-io/Zavala/wiki/Architecture-Notebook)
* [Dependencies](https://github.com/vincode-io/Zavala/wiki/Dependencies)

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
    Zavala.xcodeproj
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

If you have any problems, we will help you out in [Discussions](https://github.com/vincode-io/Zavala/discussions).
