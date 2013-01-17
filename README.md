# haxe.unit

This is the Haxe unit testing framework, with some improvements.

## Improvements

* The textbox wordwraps by default (so you can read it)
* `trace()` output lines are colored blue
* The line of the test that triggered the error is colored red
* adds `globalSetup` - setup that is run once per class of tests
* adds `globalTeardown` - analogous to `globalSetup`
* adds `beforeEach` - run before each individual function test
* adds `afterEach` - analogous to `beforeEach`
* adds `assertNotEquals`
* adds `assertThrows`
* adds `assertDoesNotThrow`
* adds `assertDotEquals` (same as `assertEquals`, but does comparisons with .equals() rather than ==)
* adds `assertNotDotEquals`
* adds `globalAsyncSetup` - same as `globalSetup`, except with async semantics as seen below.

## Async methods

Sometimes, we have to deal with async methods. Most of the time, it devolves into callback soup. Fortunately, that's not the case here.

If you need to do some asynchronous setup, call your method `asyncGlobalSetup`, and have it take a parameter called `done`. When the async method has finished, have it call `done()`. That's it!

Here's an example if you don't believe it's as simple as it sounds.

    function asyncGlobalSetup(done: Void -> Void) {
      haxe.Timer.delay(function() {
          nme.Lib.current.stage.addChild(new MovieClip());

          done();
      }, 1000);
    }
