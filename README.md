# haxe.unit

This is the Haxe unit testing framework, with some improvements.

## Improvements

* The textbox wordwraps by default (so you can read it)
* `trace()` output lines are colored blue
* The line of the test that triggered the error is colored red
* adds `assertNotEquals`
* adds `assertThrows`
* adds `assertDoesNotThrow`
* adds `assertDotEquals` (same as `assertEquals`, but does comparisons with .equals() rather than ==)
* adds `assertNotDotEquals`
* adds `async*` - methods that start with `async` are treated as async methods. More explanation below.


## Async methods

Sometimes, we have to deal with async methods. Most of the time, it devolves into callback soup. Fortunately, that's not the case here.

If your method requires a callback, start it with `async` and have it take a parameter called `done`. When the async method has finished, have it call `done()`. That's it!

Here's an example if you don't believe it's as simple as it sounds.

    function asyncWaitAWhileThenAssertOnePlusOneEqualsTwo(done: Void -> Void) {
      haxe.Timer.delay(function() {
          assertEquals(1 + 1, 2);

          done();
      }, 1000);
    }
