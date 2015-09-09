p    = require 'path'
S    = require 'underscore.string'
CSON = require 'season'

module.exports =
  # This will work on Alda files but not on comments in Alda files
  selector: '.source.alda'
  disableForSelector: '.source.alda .comment'

  # This will take priority over the default provider, Alda is a very specific
  # language that doesn't require a lot of words, so there's no great need to
  # allow regular autocomplete to happen.
  inclusionPriority: 1
  excludeLowerPriority: true

  # Return an array of suggestions or null
  # `request` has the following properties:
  # * editor: The current TextEditor
  # * bufferPosition: The position of the cursor
  # * scopeDescriptor: The scope descriptor for the current cursor position
  # * prefix: The prefix for the word immediately preceding the current cursor
  #   position
  getSuggestions: (request) ->
    completions = null

    if @isCompletingMarker(request)
      completions = @getMarkerComps(request)
    else if @isCompletingAttribute(request)
      completions = @getAttributeComps(request)
    else if @isCompletingInstrument(request)
      completions = @getInstrumentComps(request)

    completions

  loadCompletions: ->
    CSON.readFile p.resolve(__dirname, '..', 'completions.cson'), (err, src) =>
      {@attributes, @instruments} = src unless err?
      return

  isCompletingMarker: ({scopeDescriptor}) ->
    scopeDescriptor.getScopesArray()
      .indexOf('entity.name.function.at-marker.alda') isnt -1

  isCompletingAttribute: ({scopeDescriptor}) ->
    scopeDescriptor.getScopesArray().indexOf('meta.attribute.alda') isnt -1

  isCompletingInstrument: ({bufferPosition, prefix}) ->
    prefix.length > 2 and not S.include(prefix, ':') and
      bufferPosition.column - prefix.length is 0

  getMarkerComps: ({prefix, editor}) ->
    console.log 'Getting markers'
    markers = []
    completions = []
    if prefix
      for word in S.words(editor.getText()) when firstCharsEqual(word, "%")
        markers.push(word.substr(1))
      for marker in markers when firstCharsEqual(marker, prefix)
        completions.push(@buildMarkerComp(marker))
      completions

  buildMarkerComp: (marker) ->
    type: 'marker'
    text: marker
    iconHTML: '<i class="icon-pin"></i>'
    rightLabel: 'Marker'

  getAttributeComps: ({prefix}) ->
    completions = []
    if prefix
      for attr in @attributes when firstCharsEqual(attr, prefix)
        completions.push(@buildAttributeComp(attr))
      completions

  buildAttributeComp: (attr) ->
    type: 'attribute'
    snippet: "#{attr} ${1:99}$2"
    displayText: attr
    iconHTML: '<i class="icon-settings"></i>'
    rightLabel: 'Attribute'

  getInstrumentComps: ({prefix}) ->
    completions = []
    if prefix
      for instr in @instruments when firstCharsEqual(instr, prefix)
        completions.push(@buildInstrumentComp(instr))
      completions

  buildInstrumentComp: (instr) ->
    type: 'insturment'
    text: instr
    iconHTML: '<i class="icon-unmute"></i>'
    rightLabel: 'Instrument'

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
