# Architecture Notebook
Without context it can be hard to understand decisions people make.  Here we try to explain our rational
behind why we do what we do.  This is a living document and will be changed as we learn more and change
our minds.

## Major Architectural Goals

### Cross Platform
We are focusing on Apple platforms, that is macOS, iOS, and iPadOS. By narrowing our focus to only these
platforms we feel that we can create a better product than if we tried to also support Window, Linux, Android, etc.. 

So when we say Cross Platform, we mean within Apple’s platforms. This is a matter of economics. The more
code we can share the better, so we are trying to use a portable Toolkit within Apple platforms.

### Scriptable
This hasn’t been fully determined, but we would like to embed a scripting environment to manipulate the Outlines. AppleScript and Shortcuts support will be made available as well.

### iCloud Sync
This is expected of any program that manages data these days.

### Realtime Collaboration
We should be able to share Outlines and collaborate with others in as close to realtime as is technically feasible.

## Templeton
This is the core framework that contains as much business logic and persistence logic as possible. Ideally, it
should have as few platform checks as possible and be able to support different Toolkits, be that UIKit, AppKit,
or SwiftUI.

### Database
The “database” is a collection of binary plist files. We will discourage external manipulation of the database files. They should be fully exportable for programatic manipulation or being manipulated in the script environment.

By using plain file system files, we can easily share these files across multiple running processes. This
is especially useful for Extensions that run out of process. For example Shortcuts or Share Extensions.

### Model
This is where most of the “business” logic resides. The model also maintains the Shadow Table.

### Shadow Table
The Shadow Table backs an index based user interface element that displays the Outline Rows.  This could be
anything in the NSTableView family, for example we currently use UICollectionView.

### Shadow Table Changes
Add, delete, move, and reload indexes are all provided so that the UI can animate any changes that it needs
to make.  This is how we make the UI fully animatable, but the logic that computes it is fully portable to
another framework.

### Command Pattern
We leverage this pattern implementation provided by RSCore.  It allows the UI to issue commands that can provide undo support.  By putting these in Templton, they are reusable by different UI Toolkits.

## Zavala
This is the UI layer of the application.

### UIKit/Catalyst
The choice of UIKit to do cross platform development is more a function of the year that the app was developed
in. SwiftUI would be a great choice, but in the fall of 2020, it wasn’t ready to be used in a production
environment. That leaves us with doing native implementations of UIKIt and AppKit or using UIKit with Catalyst.

Since either way, a UIKIt implementation is in the works, we went with UIKIt with Catalyst. Thus far it has
worked pretty well. Not as good on the Mac as an AppKit implementation, but not too bad either.

## Dependencies

### [RSCore](https://github.com/Ranchero-Software/RSCore)
Used to supplement Foundation.  Also used by NetNewsWire.  Thanks Brent!

### [MarkdownAttributedString](https://github.com/vincode-io/MarkdownAttributedString)
This is used for import and export of markdown strings. These are used in markdown file exports and OPML imports and exports.  Thanks CHOCK!

### [SWXMLHash](https://github.com/drmohundro/SWXMLHash)
This is a simple XML parser and currently is only used for importing OPML files. It should be trivial to replace
if necessary.

### [ZipArchive](https://github.com/ZipArchive/ZipArchive)
Use to create and restore file archives of the current database.  Why isn't this in Foundation yet?