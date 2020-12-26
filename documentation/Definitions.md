# Definitions
These are common terms used by the project. They might not be in common use, so we define them here.

### Document Container
This generalization of Smart Container and Folder.

### Smart Container
This is container that programmatically determines its contents.  Contents can’t be added to directly.
They have to be added to a Folder and qualify for what ever criteria is used by the Smart Container.
An example of this would be Favorites in the Library.

### Folder
This is a Document Container that actually stores Documents.

### Document
This is a generalization of Script and Outline.

### Script
Code that can be executed to manipulate entities in Zavala.

### Outline
A hierarchal structure of Rows.

### Row
A generalization of Image Row, Text Row, etc… A Row may have other child Rows.

### Image Row
Contains a single image.

### Text Row
Contains both a Topic and a Note.

## Topic
The main text entry type in an Outline.  Sometimes called a Headline.

### Note
Detail information about the Topic is associated with.
