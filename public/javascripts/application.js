//  Displays and then fades a notice after a period of time.
AlertBox = Class.create() ;
AlertBox.prototype = {
  initialize: function(elementId,timeout) {
    this.elementId = elementId ;
    this.timeout = (timeout==undefined) ? 2 : timeout ;
  },

  show: function(text) {
    alert('Setting to: ' + text);
    $(this.elementId).innerHTML = text;
    setTimeout('showNotice', 200);
    setTimeout('fadeNotice', 2000);
//    new Effect.Appear(this.elementId, {duration: 0.3});
//    if (this.timeout != 0) setTimeout(this.fade.bind(this), this.timeout * 1000);
  },
  
  doIt: function() {
    new Effect.Appear(this.elementId, {duration: 0.3});
    if (this.timeout != 0) setTimeout(this.fade.bind(this), this.timeout * 1000);
  },
  
  fade: function() {
    new Effect.Fade(this.elementId, {duration: 0.3});
  }  
} ;

var Notice = new AlertBox('notice') ;

function showNotice() {
  alert("showing it...");
  new Effect.Appear('notice', {duration: 0.3});
}

function fadeNotice() {
  new Effect.Fade('notice', {duration: 0.3});
}