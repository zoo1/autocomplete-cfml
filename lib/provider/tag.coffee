attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/

module.exports =
  selector: '.text.cf, .text.html.cfml, .text.cf.cfscript'
  disableForSelector: '.comment, .source.cfscript'

  suggestionPriority: 2

  tags: {}

  limitedTags: ['cfelse', 'cfif', 'cfelseif', 'cfloop', 'cfloop (index)', 'cfloop (condition)', 'cfloop (query)', 'cfloop (list)', 'cfloop (array)', 'cfloop (file)', 'cfloop (collection)']

  getSuggestions: (request) ->
    {prefix} = request

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

  isTagStartWithNoPrefix: ({editor, bufferPosition, prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return false if @hasTagScope(scopes)
    return false if @isEndTag(editor, bufferPosition, prefix.length)
    /^<?(c?|(cf)?)$/.test(prefix) and not /^\s*$/.test(prefix)

  isTagStartTagWithPrefix: ({editor, bufferPosition, prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return false if /^\s*$/.test(prefix)
    return false if @isEndTag(editor, bufferPosition, prefix.length)
    not @hasTagScope(scopes) or @isTagName(scopes)

  isAttributeStartWithNoPrefix: ({editor, bufferPosition, prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return false if @isPastTag(editor, bufferPosition, prefix.length)
    @hasTagScope(scopes) and not @isTagName(scopes)

  isAttributeStartWithPrefix: ({prefix, scopeDescriptor}) ->
    return false if /^\s*$/.test(prefix)

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
    scopes.indexOf('entity.name.tag.cfml') isnt -1 or
      scopes.indexOf('punctuation.definition.tag.begin.cfml') isnt -1

  hasStringScope: (scopes) ->
    scopes.indexOf('string.quoted.double.cfml') isnt -1 or
      scopes.indexOf('string.quoted.single.cfml') isnt -1

  hasLimitedScope: (scopes) ->
    scopes.indexOf('meta.scope.cfquery.cfml') isnt -1 or
      scopes.indexOf('source.css.embedded.html') isnt -1 or
        scopes.indexOf('source.js.embedded.html') isnt -1

  getTagNameCompletions: (prefix, {scopeDescriptor, editor, bufferPosition}) ->
    completions = []
    scopes = scopeDescriptor.getScopesArray()

    filteredTags = {}
    if @hasLimitedScope(scopes) and (not prefix? or prefix.substring(0, 2) isnt 'cf')
      return []
    else if @hasLimitedScope(scopes)
      filteredTags[value] = @tags[value] for value in @limitedTags
      if scopes.indexOf('meta.scope.cfquery.cfml') isnt -1
        filteredTags['cfqueryparam'] = @tags['cfqueryparam']
    else
      filteredTags = @tags

    openTag = @hasOpenTag(editor, bufferPosition, if prefix? then prefix.length else 0)
    for tag, attributes of filteredTags when not prefix or tag.indexOf(prefix) isnt -1
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
    if name in ['cfelse', 'cfoutput', 'cfscript', 'cfsilent']
      snippet += '>'
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

  hasOpenTag: (editor, bufferPosition, prefixLength) ->
    {row, column} = bufferPosition
    startColumn = column - prefixLength - 1
    return false if startColumn < 0
    editor.lineTextForBufferRow(row)[startColumn] is '<'

  isEndTag: (editor, bufferPosition, prefixLength) ->
    {row, column} = bufferPosition
    startColumn = column - prefixLength - 2
    return false if startColumn < 0
    editor.lineTextForBufferRow(row)[startColumn] is '<' and
      editor.lineTextForBufferRow(row)[startColumn + 1] is '/'

  isPastTag: (editor, bufferPosition, prefixLength) ->
    {row, column} = bufferPosition
    startColumn = column - prefixLength - 1
    return false if startColumn < 0
    editor.lineTextForBufferRow(row)[startColumn] is '>'

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
