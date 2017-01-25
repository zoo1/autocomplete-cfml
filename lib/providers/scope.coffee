scopePattern = /[^a-zA-Z0-9\.][a-zA-Z0-9\.]+$/

module.exports =
  selector: '.text.cf, .text.html.cfml, .cfscript'
  disableForSelector: '.comment'

  suggestionPriority: 2

  scopes: {}

  getSuggestions: ({editor, bufferPosition, prefix}) ->
    return [] if bufferPosition.column == 0

    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    scopes = line.match(scopePattern)
    return [] unless scopes
    scopes = scopes[0].trim().split(".")
    return [] unless scopes.length == 2 or scopes.length == 3
    return [] if scopes[0] == "this" and editor.getTitle().toLowerCase() != "application.cfc"
    @getScopeCompletions(scopes)

  getScopeCompletions: (scopes) ->
    currentScope = @scopes[scopes[0].toLowerCase()]
    return [] unless currentScope
    #single scope ending with .
    return @buildCompletionForScope(currentScope) if scopes[1].length == 0
    innerScope = currentScope[scopes[1].toLowerCase()]
    #double scope ending with a . or a prefix
    return @buildCompletionForScope(innerScope.vars, scopes[2]) if innerScope
    @buildCompletionForScope(currentScope, scopes[1])

  buildCompletionForScope: (scope, prefix) ->
    completions = []
    for name, attributes of scope when not prefix or firstCharsEqual(name, prefix)
      completions.push
        text: attributes.name
        type: 'value'
        description: attributes.help
    completions

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()