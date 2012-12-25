# haxe.unit

This is the Haxe unit testing framework, with some improvements.

## Improvements

* The textbox wordwraps by default (so you can read it).
* `trace()` output lines are colored blue.
* The line of the test that triggered the error is colored red. 
* adds `assertNotEquals`
* adds `assertThrows`
* adds `assertDoesNotThrow`
* adds `assertDotEquals` (same as `assertEquals`, but does comparisons with .equals() rather than ==)
* adds `assertNotDotEquals`
