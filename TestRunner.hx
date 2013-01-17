/*
 * Copyright (c) 2005, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package haxe.unit;
import Reflect;

using StringTools;
using Lambda;

class TestRunner {
	var result : TestResult;
	var cases  : Array<TestCase>;
  var casesLeft: Int = 0;

#if flash9
	static var tf : flash.text.TextField = null;
#elseif flash
	static var tf : flash.TextField = null;
#end

	public static dynamic function print( v : Dynamic, color : Int = 0x000000 ) untyped {
		#if flash9
      var textFormat: flash.text.TextFormat = new flash.text.TextFormat();
      textFormat.color = color;

			if( tf == null ) {
				tf = new flash.text.TextField();
				tf.width = flash.Lib.current.stage.stageWidth;
				tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
				tf.wordWrap = true;
				flash.Lib.current.addChild(tf);
			}

      var oldSize : Int = tf.length;
      tf.appendText(v);
      var newSize : Int = tf.length;

      tf.setTextFormat(textFormat, oldSize, newSize);

      if (v.indexOf("Test.hx") != -1) {
        var startIdx: Int = v.indexOf("Test.hx");

        textFormat.color = 0xFF0000;
        tf.setTextFormat(textFormat, oldSize + v.lastIndexOf('\n', startIdx) , oldSize + v.indexOf('\n', startIdx));
      }

		#elseif flash
			var root = flash.Lib.current;
			if( tf == null ) {
				root.createTextField("__tf",1048500,0,0,flash.Stage.width,flash.Stage.height+30);
				tf = root.__tf;
				tf.wordWrap = true;
			}
			var s = flash.Boot.__string_rec(v,"");
			tf.text += s;
			while( tf.textHeight > flash.Stage.height ) {
				var lines = tf.text.split("\r");
				lines.shift();
				tf.text = lines.join("\n");
			}
		#elseif neko
			__dollar__print(v);
		#elseif php
			php.Lib.print(v);
		#elseif cpp
			cpp.Lib.print(v);
		#elseif js
			var msg = StringTools.htmlEscape(js.Boot.__string_rec(v,"")).split("\n").join("<br/>");
			var d = document.getElementById("haxe:trace");
			if( d == null )
				alert("haxe:trace element not found")
			else
				d.innerHTML += msg;
		#elseif cs
			var str:String = v;
			untyped __cs__("System.Console.Write(str)");
		#elseif java
			var str:String = v;
			untyped __java__("java.lang.System.out.print(str)");
		#end
	}

	private static function customTrace( v, ?p : haxe.PosInfos ) {
		print(p.fileName+":"+p.lineNumber+": "+Std.string(v)+"\n", 0x0000FF);
	}

	public function new() {
		result = new TestResult();
		cases = new Array();
	}

	public function add( c:TestCase ) : Void{
		cases.push(c);
	}

	public function run() : Bool {
    //TODO - bleh, toss in async support here too
    //TODO - async setup (and teardown..?)

		result = new TestResult();
    casesLeft = cases.length;
    var currentCase: Int = 0;

    function recursivelyRunCases() {
      if (currentCase == cases.length) {
        //done
        return;
      }

      var currentCase: TestCase = cases[currentCase++];

      if (Type.getInstanceFields(Type.getClass(currentCase)).indexOf("globalAsyncSetup") != -1 
          && Reflect.isFunction(Reflect.field(currentCase, "globalAsyncSetup"))) {
        var alreadyCalled: Bool = false;
        var fn: (Void -> Void) -> Void = untyped currentCase.globalAsyncSetup;
        fn(function() {
          if (alreadyCalled) {
            trace("you're calling the callback more than once. bad times!");
            return;
          }

          alreadyCalled = true;
          runCase(currentCase);
          recursivelyRunCases();
        });

        haxe.Timer.delay(function() {
          if (!alreadyCalled) {
            trace("done callback probably never called in " + currentCase + " (or it's taking a long time).");
          }
        }, 1500);
      } else {
        runCase(currentCase);
        recursivelyRunCases();
      }
    }

    recursivelyRunCases();

		return result.success;
	}

  public function caseComplete() {
    casesLeft--;

    if (casesLeft == 0) {
      print(result.toString());
    }
  }

  /* Run a single test (function). */
  function runSingleTest(f: String, test: TestCase): Void {
    var field = Reflect.field(test, f);

    if (field == null) return;

    if (Reflect.isFunction(field)) {
      test.currentTest = new TestStatus();
      test.currentTest.classname = Type.getClassName(Type.getClass(test));
      test.currentTest.method = f;
      test.beforeEach();

      function showResult() {
        if (test.currentTest.success) {
          if (test.currentTest.done){
            test.currentTest.success = true;
            test.output += ".";
          } else {
            test.currentTest.success = false;
            test.currentTest.error = "(warning) no assert";
            test.output += "W";
          }
        } else {
          test.output += "F";
        }

        result.add(test.currentTest);
        test.afterEach();
      }

      Reflect.callMethod(test, field, []);
      showResult();
    }
  }

  /* tests every method in a class. */
	function runCase(t: TestCase): Void	{
		var old = haxe.Log.trace;
		var cl = Type.getClass(t);
		var fields = Type.getInstanceFields(cl);

		haxe.Log.trace = customTrace;

    t.output += "Class: "+Type.getClassName(cl)+" ";

    t.globalSetup();

		for (f in fields) {
      if (f.startsWith("test")) {
        runSingleTest(f, t);
      }
		}

    // done function
    t.globalTeardown();

    print(t.output + "\n");
    haxe.Log.trace = old;

    caseComplete();
	}
}
