fs = require 'fs'
path = require 'path'
{Point, Range} = require 'atom'

trailingWhitespace = /\s$/
attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/

module.exports =
  selector: '.text.cf, .text.html.cfml, .text.cf.cfscript'
  disableForSelector: '.comment'

  getSuggestions: (request) ->
    {editor, bufferPosition, prefix} = request
    openTag = @hasOpenTag(editor.getBuffer(), bufferPosition, prefix.length)

    if @isAttributeStartWithNoPrefix(request)
      @getAttributeNameCompletions(request)
    else if @isAttributeStartWithPrefix(request)
      @getAttributeNameCompletions(request, prefix)
    else if @isTagStartWithNoPrefix(request)
      @getTagNameCompletions(null, openTag)
    else if @isTagStartTagWithPrefix(request)
      @getTagNameCompletions(prefix, openTag)
    else
      []

  hasOpenTag: (buffer, bufferPosition, prefixLength) ->
    if bufferPosition.column - prefixLength - 1 < 0
      false
    else
      p1 = new Point(bufferPosition.row, bufferPosition.column - prefixLength - 1)
      p2 = new Point(bufferPosition.row, bufferPosition.column - prefixLength)
      buffer.getTextInRange(new Range(p1, p2)) is "<"

  isTagStartWithNoPrefix: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    if scopes[0] is 'text.html.cfml'
      if prefix.length is 0
        true
      else
        /^<?(c?|(cf)?)$/.test(prefix)
    else
      false

  isTagStartTagWithPrefix: ({prefix, scopeDescriptor}) ->
    return false unless prefix
    return false if trailingWhitespace.test(prefix)
    # @hasTagScope(scopeDescriptor.getScopesArray())
    return true

  isAttributeStartWithNoPrefix: ({prefix, scopeDescriptor}) ->
    return false unless trailingWhitespace.test(prefix)
    @hasTagScope(scopeDescriptor.getScopesArray())

  isAttributeStartWithPrefix: ({prefix, scopeDescriptor}) ->
    return false unless prefix
    return false if trailingWhitespace.test(prefix)

    scopes = scopeDescriptor.getScopesArray()
    return true if scopes.indexOf('entity.other.attribute-name.cfml') isnt -1
    return false unless @hasTagScope(scopes)

    scopes.indexOf('punctuation.definition.tag.cfml') isnt -1 or
      scopes.indexOf('punctuation.definition.tag.end.cfml') isnt -1

  hasTagScope: (scopes) ->
    scopes.indexOf('meta.tag.cfml') isnt -1

  hasStringScope: (scopes) ->
    scopes.indexOf('string.quoted.double.html') isnt -1 or
      scopes.indexOf('string.quoted.single.html') isnt -1

  getTagNameCompletions: (prefix, openingTag) ->
    completions = []
    for tag, attributes of @completions.tags when not prefix or firstCharsEqual(tag, prefix)
      completions.push(@buildTagCompletion(attributes, openingTag))
    completions

  buildTagCompletion: (attributes, openingTag) ->
    tabStopIndex = 1
    snippet = if openingTag then attributes.name else "<#{attributes.name}"
    for attribute in attributes.parameter when attribute.required
      snippet += " #{attribute.name}=\"$#{tabStopIndex++}\""
    if attributes.name is "cfelse"
      snippet += ">"
    else
      snippet += if attributes.single then " $#{tabStopIndex++}/>" else " $#{tabStopIndex++}>"
    snippet += "\n\t$#{tabStopIndex++}\n</#{attributes.name}>" if attributes.endtagrequired
    snippet += "$#{tabStopIndex++}"

    snippet: snippet
    displayText: tag
    type: 'tag'
    description: attributes.help
    descriptionMoreURL: @getTagDocsURL(tag)

  getAttributeNameCompletions: ({editor, bufferPosition}, prefix) ->
    completions = []
    tag = @getPreviousTag(editor, bufferPosition)
    tagAttributes = @getTagAttributes(tag)

    for name, properties of tagAttributes when not prefix or firstCharsEqual(name, prefix)
      completions.push(@buildAttributeCompletion(properties, tag))
    completions

  buildAttributeCompletion: (attribute, tag) ->
    snippet: "#{attribute.name}=\"$1\"$0"
    displayText: attribute.name
    type: 'attribute'
    rightLabel: "<#{tag}>"
    description: attribute.help[0]
    descriptionMoreURL: @getTagDocsURL(tag)

  getAttributeValueCompletions: ({editor, bufferPosition}, prefix) ->
    tag = @getPreviousTag(editor, bufferPosition)
    attribute = @getPreviousAttribute(editor, bufferPosition)
    values = @getAttributeValues(attribute)
    for value in values when not prefix or firstCharsEqual(value, prefix)
      @buildAttributeValueCompletion(tag, attribute, value)

  buildAttributeValueCompletion: (tag, attribute, value) ->
    text: value
    type: 'value'
    description: "#{value} value for #{attribute} attribute local to <#{tag}>"
    descriptionMoreURL: @getTagDocsURL(tag)

  loadCompletions: ->
    @completions = {}
    fs.readFile path.resolve(__dirname, '../dictionary', 'cf11.json'), (error, content) =>
      @completions = JSON.parse(content) unless error?
      return

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

  getAttributeValues: (attribute) ->
    attribute = @completions.attributes[attribute]
    attribute?.attribOption ? []

  getTagAttributes: (tag) ->
    @completions.tags[tag]?.parameter ? []

  getTagDocsURL: (tag) ->
    "https://cfdocs.org/#{tag}"

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
