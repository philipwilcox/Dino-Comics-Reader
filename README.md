# Dino-Comics-Reader

thin ios wrapper app for Dinosaur Comics to extract and display all the alt texts below the page

doesn't do anything fancy, just extracts the text so you don't have to. wraps the HTML as-is.

TODOs include:
* Unit tests
* Support for UNDOING favorite deletion
* dropdown in top bar for available iwouldratherbereading overlays
* export faves as CSV
* add auto-migration for old-formatted internal navigation links in news? what was this pattern?
* better layout, especially for phone; be able to parse HTML in phone mode...
* add a limit to how many history items are kept
* Research better navigation view stuff
* clone navigation buttons on sides in ipad wide view for touchscreen remote or bluetooth controller
* Play with UI to get landscape mode layout working better on my iPhone Pro Max - if we do this, do it through webview controls!
* Add some way to "reject" a remote state update, and get better control over when this happen; maybe based on https://stackoverflow.com/posts/63424212/revisions subscribing ? 
* Look at MVVM tutorial here https://www.toptal.com/swift/static-patterns-swift-mvvm-tutorial - this pattern is quite different, static view models
* Look at this pattern https://www.kodeco.com/5542-enum-driven-tableview-development 
* TV/Mac support for fun
    * increase font size/zoom on Mac
    * pad layout on Mac
* try to debug cloudkit notification listener stuff in addition to timer-based world
