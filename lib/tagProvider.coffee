{Point, Range} = require 'atom'

attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/

module.exports =
  selector: '.text.cf, .text.html.cfml, .text.cf.cfscript'
  disableForSelector: '.comment, .source.js, source.css'

  suggestionPriority: 2

  tags: {}

  getSuggestions: (request) ->
    {editor, bufferPosition, prefix} = request

    if @isAttributeValueStartWithNoPrefix(request)
      @getAttributeValueCompletions(request)
    else if @isAttributeValueStartWithPrefix(request)
      @getAttributeValueCompletions(request, prefix)
    else if @isAttributeStartWithPrefix(request)
      @getAttributeNameCompletions(request, prefix)
    else if @isAttributeStartWithNoPrefix(request)
      @getAttributeNameCompletions(request)
    else if @isTagStartWithNoPrefix(request)
      @getTagNameCompletions(null, request)
    else if @isTagStartTagWithPrefix(request)
      @getTagNameCompletions(prefix, request)
    else
      []

  isTagStartWithNoPrefix: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return false if @hasTagScope(scopes)
    return true if prefix.length is 0
    /^<?(c?|(cf)?)$/.test(prefix)

  isTagStartTagWithPrefix: ({prefix, scopeDescriptor}) ->
    return false unless prefix
    not @hasTagScope(scopeDescriptor.getScopesArray()) or @isTagName(scopeDescriptor.getScopesArray())

  isAttributeStartWithNoPrefix: ({prefix, scopeDescriptor}) ->
    @hasTagScope(scopeDescriptor.getScopesArray()) and not @isTagName(scopeDescriptor.getScopesArray())

  isAttributeStartWithPrefix: ({prefix, scopeDescriptor}) ->
    return false unless prefix

    scopes = scopeDescriptor.getScopesArray()
    return true if scopes.indexOf('entity.other.attribute-name.cfml') isnt -1
    return false unless @hasTagScope(scopes)

    scopes.indexOf('punctuation.definition.tag.cfml') isnt -1 or
      scopes.indexOf('punctuation.definition.tag.end.cfml') isnt -1

  isAttributeValueStartWithNoPrefix: ({scopeDescriptor, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false unless lastPrefixCharacter in ['"', "'"]
    scopes = scopeDescriptor.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  isAttributeValueStartWithPrefix: ({scopeDescriptor, prefix}) ->
    false if prefix.length is 0
    scopes = scopeDescriptor.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  hasTagScope: (scopes) ->
    scopes.indexOf('meta.tag.cfml') isnt -1 or
      scopes.indexOf('meta.tag.other.cfml') isnt -1

  isTagName: (scopes) ->
    scopes.indexOf('entity.name.tag.cfml') isnt -1

  hasStringScope: (scopes) ->
    scopes.indexOf('string.quoted.double.cfml') isnt -1 or
      scopes.indexOf('string.quoted.single.cfml') isnt -1

  getTagNameCompletions: (prefix, {editor, bufferPosition}) ->
    completions = []
    openTag = @hasOpenTag(editor.getBuffer(), bufferPosition, if prefix? then prefix.length else 0)
    for tag, attributes of @tags when not prefix or tag.indexOf(prefix) isnt -1
      completions.push(@buildTagCompletion(tag, attributes, openTag))
    completions

  buildTagCompletion: (tag, attributes, openTag) ->
    snippet: @buildTagSnippet(attributes, openTag)
    displayText: tag
    type: 'tag'
    description: attributes.help
    descriptionMoreURL: @getTagDocsURL(attributes.name)

  buildTagSnippet: (attributes, openTag) ->
    name = attributes.name
    tabStopIndex = 1
    snippet = if openTag then name else "<#{name}"
    for attribute, properties of attributes.parameter when properties.required
      snippet += " #{attribute}=\"${#{tabStopIndex++}:#{properties.default}}\""
    if name is "cfelse" or name is "cfoutput"
      snippet += ">"
    else
      snippet += if not attributes.endtagrequired then " $#{tabStopIndex++}/>" else " $#{tabStopIndex++}>"
    snippet += "\n\t$#{tabStopIndex++}\n</#{name}>" if attributes.endtagrequired
    snippet + "$#{tabStopIndex++}"

  getAttributeNameCompletions: ({editor, bufferPosition}, prefix) ->
    completions = []
    tag = @getPreviousTag(editor, bufferPosition)
    tagAttributes = @getTagAttributes(tag)

    for name, properties of tagAttributes when not prefix or firstCharsEqual(name, prefix)
      completions.push(@buildAttributeCompletion(properties, tag))
    completions

  buildAttributeCompletion: (attribute, tag) ->
    snippet: "#{attribute.name}=\"${1:#{attribute.default}}\" $2"
    displayText: attribute.name
    type: 'attribute'
    rightLabel: "<#{tag}>"
    description: attribute.help
    descriptionMoreURL: @getTagDocsURL(tag)

  getAttributeValueCompletions: ({editor, bufferPosition}, prefix) ->
    tag = @getPreviousTag(editor, bufferPosition)
    attribute = @getPreviousAttribute(editor, bufferPosition)
    attributeData = @getAttributeData(tag, attribute)
    return [] unless attributeData?
    if attributeData.type.toLowerCase() is "boolean"
      attributeData.values = ['true', 'false']
    for value in attributeData.values when not prefix or firstCharsEqual(value, prefix)
      @buildAttributeValueCompletion(tag, attribute, value)

  buildAttributeValueCompletion: (tag, attribute, value) ->
    text: value
    type: 'value'

  hasOpenTag: (buffer, bufferPosition, prefixLength) ->
    if bufferPosition.column - prefixLength - 1 < 0
      false
    else
      p1 = new Point(bufferPosition.row, bufferPosition.column - prefixLength - 1)
      p2 = new Point(bufferPosition.row, bufferPosition.column - prefixLength)
      buffer.getTextInRange(new Range(p1, p2)) is "<"

  getPreviousTag: (editor, bufferPosition) ->
    {row} = bufferPosition
    while row >= 0
      tag = tagPattern.exec(editor.lineTextForBufferRow(row))?[1]
      return tag if tag
      row--
    return

  getPreviousAttribute: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).trim()

    # Remove everything until the opening quote
    quoteIndex = line.length - 1
    quoteIndex-- while line[quoteIndex] and not (line[quoteIndex] in ['"', "'"])
    line = line.substring(0, quoteIndex)

    attributePattern.exec(line)?[1]

  getAttributeData: (tag, attribute) ->
    attribute = @tags[tag]?.parameter[attribute]

  getTagAttributes: (tag) ->
    @tags[tag]?.parameter ? []

  getTagDocsURL: (tag) ->
    "https://cfdocs.org/#{tag}"

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
