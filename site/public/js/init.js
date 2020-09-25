(function($){
  $(function(){

    $('.sidenav').sidenav();
    $('.parallax').parallax();
    
  }); // end of document ready
})(jQuery); // end of jQuery name space

// DOM読み込み前初期化処理
$(document).ready(function(){
  $('select').formSelect();
});
