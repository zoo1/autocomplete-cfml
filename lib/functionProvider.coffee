{Point, Range} = require 'atom'

attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/

module.exports =
  selector: '.cfscript'
  disableForSelector: '.comment'

  suggestionPriority: 2

  getSuggestions: (request) ->
    if @isFunctionParamValue(request)
      @getFunctionParamValueCompletions(request)
    else if @isFunction(request)
      @getFunctionCompletions(request)
    else
      []

  isFunctionParamValue: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('meta.support.function-call.arguments.cfml') isnt -1

  isFunction: ({prefix, scopeDescriptor}) ->
    return false unless prefix
    not @hasTagScope(scopeDescriptor.getScopesArray())

  getFunctionCompletions: (prefix, openingTag) ->
    completions = []
    for tag, attributes of @tags when not prefix or tag.indexOf(prefix) isnt -1
      completions.push(@buildTagCompletion(tag, attributes, openingTag))
    completions

  buildTagCompletion: (tag, attributes, openingTag) ->
    snippet: @buildTagSnippet(attributes, openingTag)
    displayText: tag
    type: 'tag'
    description: attributes.help
    descriptionMoreURL: @getTagDocsURL(attributes.name)

  buildTagSnippet: (attributes, openingTag) ->
    name = attributes.name
    tabStopIndex = 1
    snippet = if openingTag then name else "<#{name}"
    for attribute, properties of attributes.parameter when properties.required
      snippet += " #{attribute}=\"${#{tabStopIndex++}:#{properties.default}}\""
    if name is "cfelse"
      snippet += ">"
    else
      snippet += if not attributes.endtagrequired then " $#{tabStopIndex++}/>" else " $#{tabStopIndex++}>"
    snippet += "\n\t$#{tabStopIndex++}\n</#{name}>" if attributes.endtagrequired
    snippet + "$#{tabStopIndex++}"

  getFunctionParamValueCompletions: ({editor, bufferPosition}, prefix) ->
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
      attributeData.values = ['true','false']
    for value in attributeData.values when not prefix or firstCharsEqual(value, prefix)
      @buildAttributeValueCompletion(tag, attribute, value)

  buildAttributeValueCompletion: (tag, attribute, value) ->
    text: value
    type: 'value'

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

  getFunctionDocsURL: (tag) ->
    "https://cfdocs.org/#{tag}"

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
