contentTypeRegexp = /(image|text)\//
audios = [
  new Audio
  new Audio
  new Audio
]
urls = {}

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
    bb = new WebKitBlobBuilder
    bb.append(uint8Array.buffer)
    blob = bb.getBlob('audio/wav')
    audio = audios[Math.floor(Math.random() * audios.length)]
    audio.loop = true
    audio.src = webkitURL.createObjectURL(blob)
    audio.play()
  request.send(null)

listener = (details) ->
  details.responseHeaders.forEach (header) ->
    if header.name == "Content-Type" && contentTypeRegexp.test(header.value) && !urls[details.url]
      urls[details.url] = true
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
