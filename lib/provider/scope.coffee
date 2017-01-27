scopePattern = /(^|[^a-zA-Z0-9_\.])([a-zA-Z0-9_\.]+)$/

module.exports =
  selector: '.text.cf, .text.html.cfml, source.cfml, .cfscript'
  disableForSelector: '.comment'

  suggestionPriority: 2

  scopes: {}

  getSuggestions: ({editor, bufferPosition, prefix}) ->
    return [] if bufferPosition.column is 0

    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    scopes = line.match(scopePattern)
    return [] unless scopes? and scopes[2]? and not scopes[2].includes("..")
    scopes = scopes[2].split(".")
    return [] unless scopes.length in [2, 3]
    return [] if scopes[0] is "this" and editor.getTitle().toLowerCase() isnt "application.cfc"
    @getScopeCompletions(scopes)

  getScopeCompletions: (scopes) ->
    currentScope = @scopes[scopes[0].toLowerCase()]
    return [] unless currentScope
    #single scope ending with .
    return @buildCompletionForScope(currentScope) if scopes[1].length is 0
    innerScope = currentScope[scopes[1].toLowerCase()]
    #double scope without .
    return @buildCompletionForScope([innerScope]) if innerScope and not scopes[2]?
    #double scope ending with a . or a prefix
    return @buildCompletionForScope(innerScope, scopes[2]) if innerScope
    @buildCompletionForScope(currentScope, scopes[1])

  buildCompletionForScope: (scope, prefix) ->
    completions = []
    for name, attributes of scope when (not prefix or name.indexOf(prefix.toLowerCase()) is 0) and name[0] isnt '_'
      completions.push
        text: attributes._name
        type: 'property'
        description: attributes._help
        leftLabel: attributes._type
    completions
