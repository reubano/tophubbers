(function(){function require(e,t,n){t||(t=0);var r=require.resolve(e,t),i=require.m[t][r];if(!i)throw new Error('failed to require "'+e+'" from '+n);if(i.c){t=i.c,r=i.m,i=require.m[t][i.m];if(!i)throw new Error('failed to require "'+r+'" from '+t)}return i.exports||(i.exports={},i.call(i.exports,i,i.exports,require.relative(r,t))),i.exports}require.resolve=function(e,t){var n=e,r=e+".js",i=e+"/index.js";return require.m[t][r]&&r||require.m[t][i]&&i||n},require.relative=function(e,t){return function(n){if("."!=n.charAt(0))return require(n,t,e);var r=e.split("/"),i=n.split("/");r.pop();for(var s=0;s<i.length;s++){var o=i[s];".."==o?r.pop():"."!=o&&r.push(o)}return require(r.join("/"),t,e)}};
require.m = [];
require.m[0] = {
"lib/web/index.js": function(module, exports, require){
var Minilog = require("../common/minilog.js");

var oldEnable = Minilog.enable, oldDisable = Minilog.disable, isChrome = typeof navigator != "undefined" && /chrome/i.test(navigator.userAgent), console = require("./console.js");

Minilog.defaultBackend = isChrome ? console.minilog : console;

if (typeof window != "undefined") {
    try {
        Minilog.enable(JSON.parse(window.localStorage["minilogSettings"]));
    } catch (e) {}
    if (window.location && window.location.search) {
        var match = RegExp("[?&]minilog=([^&]*)").exec(window.location.search);
        match && Minilog.enable(decodeURIComponent(match[1]));
    }
}

Minilog.enable = function() {
    oldEnable.call(Minilog, true);
    try {
        window.localStorage["minilogSettings"] = JSON.stringify(true);
    } catch (e) {}
    return this;
};

Minilog.disable = function() {
    oldDisable.call(Minilog);
    try {
        delete window.localStorage.minilogSettings;
    } catch (e) {}
    return this;
};

exports = module.exports = Minilog;

exports.backends = {
    array: require("./array.js"),
    browser: Minilog.defaultBackend,
    localStorage: require("./localstorage.js"),
    jQuery: require("./jquery_simple.js")
};},
"lib/web/array.js": function(module, exports, require){
var Transform = require("../common/transform.js"), cache = [];

var logger = new Transform();

logger.write = function(name, level, args) {
    cache.push([ name, level, args ]);
};

logger.get = function() {
    return cache;
};

logger.empty = function() {
    cache = [];
};

module.exports = logger;},
"lib/web/console.js": function(module, exports, require){
var Transform = require("../common/transform.js");

var newlines = /\n+$/, logger = new Transform();

logger.write = function(name, level, args) {
    var i = args.length - 1;
    if (typeof console === "undefined" || !console.log) {
        return;
    }
    if (console.log.apply) {
        return console.log.apply(console, [ name, level ].concat(args));
    } else if (JSON && JSON.stringify) {
        if (args[i] && typeof args[i] == "string") {
            args[i] = args[i].replace(newlines, "");
        }
        try {
            for (i = 0; i < args.length; i++) {
                args[i] = JSON.stringify(args[i]);
            }
        } catch (e) {}
        console.log(args.join(" "));
    }
};

logger.formatters = [ "color", "minilog" ];

logger.color = require("./formatters/color.js");

logger.minilog = require("./formatters/minilog.js");

module.exports = logger;},
"lib/common/filter.js": function(module, exports, require){
var Transform = require("./transform.js");

var levelMap = {
    debug: 1,
    info: 2,
    warn: 3,
    error: 4
};

function Filter() {
    this.enabled = true;
    this.defaultResult = true;
    this.clear();
}

Transform.mixin(Filter);

Filter.prototype.allow = function(name, level) {
    this._white.push({
        n: name,
        l: levelMap[level]
    });
    return this;
};

Filter.prototype.deny = function(name, level) {
    this._black.push({
        n: name,
        l: levelMap[level]
    });
    return this;
};

Filter.prototype.clear = function() {
    this._white = [];
    this._black = [];
    return this;
};

function test(rule, name) {
    return rule.n.test ? rule.n.test(name) : rule.n == name;
}

Filter.prototype.test = function(name, level) {
    var i, len = Math.max(this._white.length, this._black.length);
    for (i = 0; i < len; i++) {
        if (this._white[i] && test(this._white[i], name) && levelMap[level] >= this._white[i].l) {
            return true;
        }
        if (this._black[i] && test(this._black[i], name) && levelMap[level] < this._black[i].l) {
            return false;
        }
    }
    return this.defaultResult;
};

Filter.prototype.write = function(name, level, args) {
    if (!this.enabled || this.test(name, level)) {
        return this.emit("item", name, level, args);
    }
};

module.exports = Filter;},
"lib/common/minilog.js": function(module, exports, require){
var Transform = require("./transform.js"), Filter = require("./filter.js");

var log = new Transform(), slice = Array.prototype.slice;

exports = module.exports = function create(name) {
    var o = function() {
        log.write(name, undefined, slice.call(arguments));
        return o;
    };
    o.debug = function() {
        log.write(name, "debug", slice.call(arguments));
        return o;
    };
    o.info = function() {
        log.write(name, "info", slice.call(arguments));
        return o;
    };
    o.warn = function() {
        log.write(name, "warn", slice.call(arguments));
        return o;
    };
    o.error = function() {
        log.write(name, "error", slice.call(arguments));
        return o;
    };
    o.suggest = exports.suggest;
    o.format = log.format;
    return o;
};

exports.defaultBackend = exports.defaultFormatter = null;

exports.pipe = function(dest) {
    return log.pipe(dest);
};

exports.end = exports.unpipe = exports.disable = function(from) {
    return log.unpipe(from);
};

exports.Transform = Transform;

exports.Filter = Filter;

exports.suggest = new Filter();

exports.enable = function() {
    if (exports.defaultFormatter) {
        return log.pipe(exports.suggest).pipe(exports.defaultFormatter).pipe(exports.defaultBackend);
    }
    return log.pipe(exports.suggest).pipe(exports.defaultBackend);
};},
"lib/common/transform.js": function(module, exports, require){
var microee = require("microee");

function Transform() {}

microee.mixin(Transform);

Transform.prototype.write = function(name, level, args) {
    this.emit("item", name, level, args);
};

Transform.prototype.end = function() {
    this.emit("end");
    this.removeAllListeners();
};

Transform.prototype.pipe = function(dest) {
    var s = this;
    s.emit("unpipe", dest);
    dest.emit("pipe", s);
    function onItem() {
        dest.write.apply(dest, Array.prototype.slice.call(arguments));
    }
    function onEnd() {
        !dest._isStdio && dest.end();
    }
    s.on("item", onItem);
    s.on("end", onEnd);
    s.when("unpipe", function(from) {
        var match = from === dest || typeof from == "undefined";
        if (match) {
            s.removeListener("item", onItem);
            s.removeListener("end", onEnd);
            dest.emit("unpipe");
        }
        return match;
    });
    return dest;
};

Transform.prototype.unpipe = function(from) {
    this.emit("unpipe", from);
    return this;
};

Transform.prototype.format = function(dest) {
    throw new Error([ "Warning: .format() is deprecated in Minilog v2! Use .pipe() instead. For example:", "var Minilog = require('minilog');", "Minilog", "  .pipe(Minilog.backends.console.formatClean)", "  .pipe(Minilog.backends.console);" ].join("\n"));
};

Transform.mixin = function(dest) {
    var o = Transform.prototype, k;
    for (k in o) {
        o.hasOwnProperty(k) && (dest.prototype[k] = o[k]);
    }
};

module.exports = Transform;},
"lib/web/localstorage.js": function(module, exports, require){
var Transform = require("../common/transform.js"), cache = false;

var logger = new Transform();

logger.write = function(name, level, args) {
    if (typeof window == "undefined" || typeof JSON == "undefined" || !JSON.stringify || !JSON.parse) return;
    try {
        if (!cache) {
            cache = window.localStorage.minilog ? JSON.parse(window.localStorage.minilog) : [];
        }
        cache.push([ new Date().toString(), name, level, args ]);
        window.localStorage.minilog = JSON.stringify(cache);
    } catch (e) {}
};},
"lib/web/jquery_simple.js": function(module, exports, require){
var Transform = require("../common/transform.js");

var cid = new Date().valueOf().toString(36);

function AjaxLogger(options) {
    this.url = options.url || "";
    this.cache = [];
    this.timer = null;
    this.interval = options.interval || 30 * 1e3;
    this.enabled = true;
    this.jQuery = window.jQuery;
}

Transform.mixin(AjaxLogger);

AjaxLogger.prototype.write = function(name, level, args) {
    if (!this.timer) {
        this.init();
    }

    if (args.length === 1) {
        arg = args[0]
        arg.app_name = name;
        arg.log_level = level;
        this.cache.push(arg);
    } else {
        this.cache.push([name, level, args]);
    }
};

AjaxLogger.prototype.init = function() {
    if (!this.enabled || !this.jQuery) return;
    var self = this;
    this.timer = setTimeout(function() {
        var i, logs = [];
        if (self.cache.length == 0) return self.init();
        for (i = 0; i < self.cache.length; i++) {
            try {
                logs.push(JSON.stringify(self.cache[i]));
            } catch (e) {}
        }
        self.jQuery.ajax(self.url + "?client_id=" + cid, {
            type: "POST",
            cache: false,
            processData: false,
            data: logs.join("\n"),
            contentType: "application/json",
            timeout: 1e4
        }).success(function(data, status, jqxhr) {
            if (data.interval) {
                self.interval = Math.max(1e3, data.interval);
            }
        }).error(function() {
            self.interval = 3e4;
        }).always(function() {
            self.init();
        });
        self.cache = [];
    }, this.interval);
};

AjaxLogger.prototype.end = function() {};

AjaxLogger.jQueryWait = function(onDone) {
    if (typeof window !== "undefined" && (window.jQuery || window.$)) {
        return onDone(window.jQuery || window.$);
    } else if (typeof window !== "undefined") {
        setTimeout(function() {
            AjaxLogger.jQueryWait(onDone);
        }, 200);
    }
};

module.exports = AjaxLogger;},
"lib/web/formatters/util.js": function(module, exports, require){
var hex = {
    black: "#000",
    red: "#c23621",
    green: "#25bc26",
    yellow: "#bbbb00",
    blue: "#492ee1",
    magenta: "#d338d3",
    cyan: "#33bbc8",
    gray: "#808080",
    purple: "#708"
};

function color(fg, isInverse) {
    if (isInverse) {
        return "color: #fff; background: " + hex[fg] + ";";
    } else {
        return "color: " + hex[fg] + ";";
    }
}

module.exports = color;},
"lib/web/formatters/color.js": function(module, exports, require){
var Transform = require("../../common/transform.js"), color = require("./util.js");

var colors = {
    debug: [ "cyan" ],
    info: [ "purple" ],
    warn: [ "yellow", true ],
    error: [ "red", true ]
}, logger = new Transform();

logger.write = function(name, level, args) {
    var fn = console.log;
    if (console[level] && console[level].apply) {
        fn = console[level];
        fn.apply(console, [ "%c" + name + " %c" + level, color("gray"), color.apply(color, colors[level]) ].concat(args));
    }
};

logger.pipe = function() {};

module.exports = logger;},
"lib/web/formatters/minilog.js": function(module, exports, require){
var Transform = require("../../common/transform.js"), color = require("./util.js");

colors = {
    debug: [ "gray" ],
    info: [ "purple" ],
    warn: [ "yellow", true ],
    error: [ "red", true ]
}, logger = new Transform();

logger.write = function(name, level, args) {
    var fn = console.log;
    if (level != "debug" && console[level]) {
        fn = console[level];
    }
    var subset = [], i = 0;
    if (level != "info") {
        for (;i < args.length; i++) {
            if (typeof args[i] != "string") break;
        }
        fn.apply(console, [ "%c" + name + " " + args.slice(0, i).join(" "), color.apply(color, colors[level]) ].concat(args.slice(i)));
    } else {
        fn.apply(console, [ "%c" + name, color.apply(color, colors[level]) ].concat(args));
    }
};

logger.pipe = function() {};

module.exports = logger;},
"microee": {"c":1,"m":"index.js"}};
require.m[1] = {
"index.js": function(module, exports, require){
function M() {
    this._events = {};
}

M.prototype = {
    on: function(ev, cb) {
        this._events || (this._events = {});
        var e = this._events;
        (e[ev] || (e[ev] = [])).push(cb);
        return this;
    },
    removeListener: function(ev, cb) {
        var e = this._events[ev] || [], i;
        for (i = e.length - 1; i >= 0 && e[i]; i--) {
            if (e[i] === cb || e[i].cb === cb) {
                e.splice(i, 1);
            }
        }
    },
    removeAllListeners: function(ev) {
        if (!ev) {
            this._events = {};
        } else {
            this._events[ev] && (this._events[ev] = []);
        }
    },
    emit: function(ev) {
        this._events || (this._events = {});
        var args = Array.prototype.slice.call(arguments, 1), i, e = this._events[ev] || [];
        for (i = e.length - 1; i >= 0 && e[i]; i--) {
            e[i].apply(this, args);
        }
        return this;
    },
    when: function(ev, cb) {
        return this.once(ev, cb, true);
    },
    once: function(ev, cb, when) {
        if (!cb) return this;
        function c() {
            if (!when) this.removeListener(ev, c);
            if (cb.apply(this, arguments) && when) this.removeListener(ev, c);
        }
        c.cb = cb;
        this.on(ev, c);
        return this;
    }
};

M.mixin = function(dest) {
    var o = M.prototype, k;
    for (k in o) {
        o.hasOwnProperty(k) && (dest.prototype[k] = o[k]);
    }
};

module.exports = M;},
"package.json": function(module, exports, require){
module.exports = {
  "name": "microee",
  "description": "A tiny EventEmitter-like client and server side library",
  "version": "0.0.2",
  "author": {
    "name": "Mikito Takada",
    "email": "mixu@mixu.net",
    "url": "http://mixu.net/"
  },
  "keywords": [
    "event",
    "events",
    "eventemitter",
    "emitter"
  ],
  "repository": {
    "type": "git",
    "url": "git://github.com/mixu/microee"
  },
  "main": "index.js",
  "scripts": {
    "test": "./node_modules/.bin/mocha --ui exports --reporter spec --bail ./test/microee.test.js"
  },
  "devDependencies": {
    "mocha": "*"
  },
  "readme": "# MicroEE\n\nA client and server side library for routing events.\n\nI was disgusted by the size of [MiniEE](https://github.com/mixu/miniee) (122 sloc, 4.4kb), so I decided a rewrite was in order.\n\nThis time, without the support for regular expressions - but still with the support for \"when\", which is my favorite addition to EventEmitters.\n\nMicroEE is a more satisfying (42 sloc, ~1100 characters), and passes the same tests as MiniEE (excluding the RegExp support, but including slightly tricky ones like removing callbacks set via once() using removeListener where function equality checks are a bit tricky).\n\n# Installing:\n\n    npm install microee\n\n# In-browser version\n\nUse the version in `./dist/`. It exports a single global, `microee`.\n\nTo run the in-browser tests, open `./test/index.html` in the browser after cloning this repo and doing npm install (to get Mocha).\n\n# Using:\n\n    var MicroEE = require('microee');\n    var MyClass = function() {};\n    MicroEE.mixin(MyClass);\n\n    var obj = new MyClass();\n    // set string callback\n    obj.on('event', function(arg1, arg2) { console.log(arg1, arg2); });\n    obj.emit('event', 'aaa', 'bbb'); // trigger callback\n\n# Supported methods\n\n- on(event, listener)\n- once(event, listener)\n- emit(event, [arg1], [arg2], [...])\n- removeListener(event, listener)\n- removeAllListeners([event])\n- when (not part of events.EventEmitter)\n- mixin (not part of events.EventEmitter)\n\n# Niceties\n\n- when(event, callback): like once(event, callback), but only removed if the callback returns true.\n- mixin(obj): adds the MicroEE functions onto the prototype of obj.\n- The following functions return `this`: on(), emit(), once(), when()\n\n# See also:\n\n    http://nodejs.org/api/events.html\n",
  "readmeFilename": "readme.md",
  "bugs": {
    "url": "https://github.com/mixu/microee/issues"
  },
  "_id": "microee@0.0.2",
  "_from": "microee@0.0.2"
};}};
Minilog = require('lib/web/index.js');
}());