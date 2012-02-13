var contentTypeRegexp = /image\//;
var responseTextRegexp = /<title>Index of/i;
var foundDirs = {};

chrome.webRequest.onResponseStarted.addListener(
  function(details){
    for(var i = 0; i < details.responseHeaders.length; i++){
      var header = details.responseHeaders[i];

      if(header.name == "Content-Type"){
        if(!contentTypeRegexp.test(header.name)) {
          var req = new XMLHttpRequest();
          var guessUrl = URI("./").absoluteTo(details.url).toString();

          if(guessUrl != details.url && !foundDirs.hasOwnProperty(guessUrl)) {
            req.open("GET", guessUrl, true);
            req.onload = function(e) {
              if(responseTextRegexp.test(req.responseText)) {
                if(!foundDirs[guessUrl]) {
                  foundDirs[guessUrl] = true;
                  notify('Found directory index: ' + guessUrl);
                  openUrlInNewTab(guessUrl);
                }
              }
            };
            req.send(null);
          }
        }

        break;
      }
    }
  },
  {
    urls: [
      "*://*/*"
    ],
    types: [
      "main_frame",
      "sub_frame",
      "stylesheet",
      "script",
      "image",
      "object",
      "xmlhttprequest",
      "other"
    ]
  },
  [
    "responseHeaders"
  ]
);

function notify(msg) {
  var notification = webkitNotifications.createNotification(
    'image2.gif',
    'Directory Index Finder',
    msg
  );

  notification.show();
}

function openUrlInNewTab(url) {
  chrome.tabs.create({
    url: url
  });
}
