contentTypeRegexp = /(image|text|application)\//
cxt = new AudioContext
voices = [
  cxt.createBufferSource()
  cxt.createBufferSource()
  cxt.createBufferSource()
  ]

class FakeAudioBuffer
  constructor: (arrayBuffer) ->
    @arrayBuffer = arrayBuffer
    @offset = @arrayBuffer.byteLength % 4
    @length = (@arrayBuffer.byteLength - @offset) / 4
    @sampleRate = 44100
    @numberOfChannels = 2
    @gain = 1
  getChannelData: (i) ->
    length = (@arrayBuffer.byteLength - @offset) / 2

    if i > 0
      new Float32Array(@arrayBuffer.subarray(0, length - (length % 4)))
    else
      new Float32Array(@arrayBuffer.subarray(length, length - (length % 4)))

# http://stackoverflow.com/questions/7372124/why-is-creating-a-float32array-with-an-offset-that-isnt-a-multiple-of-the-eleme
ArrayBuffer.prototype.subarray = (offset, length) ->
  sub = new ArrayBuffer(length)
  subView = new Int8Array(sub)
  thisView = new Int8Array(this)
  for i in [0...length]
    subView[i] = thisView[offset + i]
  sub

audible = (url) ->
  request = new XMLHttpRequest
  request.open("GET", url, true)
  request.responseType = "arraybuffer"
  request.onload = () ->
    arrayBuffer = request.response
    audioBuffer = new FakeAudioBuffer(arrayBuffer)
    uint8Array = Wav.createWaveFileData(audioBuffer)
    cxt.decodeAudioData(
      uint8Array.buffer
      (buffer) ->
        voice = voices[Math.floor(Math.random() * voices.length)]
        voice.buffer = buffer
        voice.loop = true
        voice.connect(cxt.destination)
        voice.start(0)
    )
  request.send(null)

listener = (details) ->
  # tabId is set to -1 if the request isn't related to a tab
  # http://code.google.com/chrome/extensions/trunk/webRequest.html
  if details.tabId > 0 && details.method == 'GET'
    details.responseHeaders.forEach (header) ->
      if header.name == "Content-Type" &&
          contentTypeRegexp.test(header.value)
        audible(details.url)

filter =
  urls: [
    "*://*/*"
  ]
  types: [
    "main_frame"
    "sub_frame"
    "stylesheet"
    "script"
    "image"
    "object"
    "xmlhttprequest"
    "other"
  ]

extra = [
  "responseHeaders"
  ]

chrome.webRequest.onResponseStarted.addListener(listener, filter, extra)
