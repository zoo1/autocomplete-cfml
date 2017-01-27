attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/

module.exports =
  selector: '.cfscript'
  disableForSelector: '.comment'

  suggestionPriority: 2

  functions: {}

  getSuggestions: (request) ->
    if @isFunction(request)
      @getFunctionCompletions(request)
    else
      []

  isFunctionParamValue: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('meta.support.function-call.arguments.cfml') isnt -1 or
      scopes.indexOf('meta.support.function-call.cfml') isnt -1

  isFunction: ({prefix, scopeDescriptor}) ->
    return false if /^\s*$/.test(prefix)
    return false unless prefix.length > 0
    true

  getFunctionCompletions: ({prefix}) ->
    completions = []
    for funct, attributes of @functions when firstCharsEqual(funct, prefix) and funct.toLowerCase().indexOf(prefix.toLowerCase()) isnt -1
      completions.push(@buildFunctionCompletion(funct, attributes))
    completions

  buildFunctionCompletion: (funct, attributes) ->
    snippet: @buildFunctionSnippet(attributes)
    displayText: funct
    type: 'function'
    description: attributes.help
    descriptionMoreURL: @getFunctionDocsURL(attributes.name)

  buildFunctionSnippet: (attributes) ->
    name = attributes.name
    tabStopIndex = 1
    snippet = "#{name}("
    for attribute, properties of attributes.parameter when properties.required
      if tabStopIndex is 1
        snippet += "${#{tabStopIndex++}:#{attribute}}"
      else
        snippet += ", ${#{tabStopIndex++}:#{attribute}}"
    snippet += ")$#{tabStopIndex++}"

  getFunctionParamValueCompletions: ({editor, bufferPosition}, prefix) ->
    completions = []
    funct = @getPreviousFunction(editor, bufferPosition)
    tagAttributes = @getFunctionAttributes(funct)

    for name, properties of tagAttributes when not prefix or firstCharsEqual(name, prefix)
      completions.push(@buildAttributeCompletion(properties, tag))
    completions

  buildParamValueCompletion: (attribute, tag) ->
    snippet: "#{attribute.name}=\"${1:#{attribute.default}}\" $2"
    displayText: attribute.name
    type: 'attribute'
    rightLabel: "<#{tag}>"
    description: attribute.help
    descriptionMoreURL: @getTagDocsURL(tag)

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

  getParamData: (tag, attribute) ->
    attribute = @functions[tag]?.parameter[attribute]

  getFunctionDocsURL: (funct) ->
    "https://cfdocs.org/#{funct}"

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
