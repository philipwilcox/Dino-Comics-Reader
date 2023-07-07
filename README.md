# Dino-Comics-Reader

thin ios wrapper app for Dinosaur Comics to extract and display all the alt texts below the page

doesn't do anything fancy, just extracts the text so you don't have to. wraps the HTML as-is.

TODOs include:
* Look at MVVM tutorial here https://www.toptal.com/swift/static-patterns-swift-mvvm-tutorial
* clone navigation buttons on sides in ipad wide view for touchscreen remote or bluetooth controller
* Unit tests
* Support for UNDOING favorite deletion 
* add auto-migration for old-formatted internal navigation links in news? what was this pattern?
* better layout, especially for phone; be able to parse HTML in phone mode...
* add a limit to how many history items are kept
* Research better navigation view stuff
* Add some way to "reject" a remote state update, and get better control over when this happen; maybe based on https://stackoverflow.com/posts/63424212/revisions subscribing ? 
* TV/Mac support for fun
    * increase font size/zoom on Mac
    * pad layout on Mac
* update faves as CSV
* try to debug cloudkit notification listener stuff in addition to timer-based world
