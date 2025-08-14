// channels@0.0.4 downloaded from https://ga.jspm.io/npm:channels@0.0.4/channels.js

import n from"domain";var e="undefined"!==typeof globalThis?globalThis:"undefined"!==typeof self?self:global;var t={};var o;try{o=n}catch(n){}t.channels=function(n){(this||e).channels={};(this||e).operatorFunction=n};t.channels.prototype.emit=function(n,t){var a=this||e;if(a.channels[n]){o&&o.active&&(t.__domain=o.active);a.channels[n].push(t)}else{a.channels[n]=[];a.operatorFunction(t,(function iterator(){var e=a.channels[n].shift();if(void 0!==e)if(e.__domain){var t=e.__domain;delete e.__domain;t.run((function(){a.operatorFunction(e,iterator)}))}else a.operatorFunction(e,iterator);else delete a.channels[n]}))}};const a=t.channels;export default t;export{a as channels};

