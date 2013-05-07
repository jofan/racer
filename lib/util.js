var deepIs = require('deep-is');

var isServer = typeof window === 'undefined';
var isProduction = isServer && process.env.NODE_ENV === 'production';

module.exports = {
  isServer: isServer
, isProduction: isProduction

, asyncGroup: asyncGroup
, copyObject: copyObject
, deepCopy: deepCopy
, deepEqual: deepIs
, equal: equal
, equalsNaN: equalsNaN
, mergeInto: mergeInto
, mayImpact: mayImpact
, mayImpactAny: mayImpactAny
, serverRequire: serverRequire
};

function asyncGroup(cb) {
  var group = new AsyncGroup(cb);
  return function asyncGroupAdd() {
    return group.add();
  };
}
function AsyncGroup(cb) {
  this.cb = cb;
  this.isDone = false;
  this.count = 0;
}
AsyncGroup.prototype.add = function() {
  this.count++;
  var self = this;
  return function(err) {
    self.count--;
    if (self.isDone) return;
    if (err) {
      self.isDone = true;
      self.cb(err);
      return;
    }
    if (self.count > 0) return;
    self.isDone = true;
    self.cb();
  };
};

function copyObject(object) {
  var out = new object.constructor;
  for (var key in object) {
    if (object.hasOwnProperty(key)) {
      out[key] = object[key];
    }
  }
  return out;
}

function deepCopy(value) {
  if (value instanceof Date) return new Date(value);
  if (typeof value === 'object') {
    var copy;
    if (Array.isArray(value)) {
      copy = [];
      for (var i = value.length; i--;) {
        copy[i] = deepCopy(value[i]);
      }
      return copy;
    }
    copy = new value.constructor;
    for (var key in value) {
      if (value.hasOwnProperty(key)) {
        copy[key] = deepCopy(value[key]);
      }
    }
    return copy;
  }
  return value;
}

function equal(a, b) {
  return (a === b) || (equalsNaN(a) && equalsNaN(b));
}

function equalsNaN(x) {
  return x !== x;
}

function mayImpactAny(segmentsList, testSegments) {
  for (var i = 0, len = segmentsList.length; i < len; i++) {
    if (mayImpact(segmentsList[i], testSegments)) return true;
  }
  return false;
}

function mayImpact(segments, testSegments) {
  var len = Math.min(segments.length, testSegments.length);
  for (var i = 0; i < len; i++) {
    if (segments[i] !== testSegments[i]) return false;
  }
  return true;
}

function mergeInto(to, from) {
  for (var key in from) {
    to[key] = from[key];
  }
  return to;
}

function serverRequire(name) {
  if (!isServer) return;
  // Tricks Browserify into not logging a warning
  var _require = require;
  return _require(name);
}