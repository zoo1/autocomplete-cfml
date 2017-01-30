describe "function autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-cfml')
    waitsForPromise -> atom.packages.activatePackage('language-cfml')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-cfml').mainModule.getProvider()[0]

    waitsFor -> Object.keys(provider.functions).length > 0
    waitsForPromise -> atom.workspace.open('test.cfm')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "returns no completions when there isn't an appropriate prefix", ->
    editor.setText('<cfscript>')
    expect(getCompletions().length).toBe 0

    editor.setText('<cfscript>,')
    expect(getCompletions().length).toBe 0

    editor.setText('<cfscript>abs(')
    expect(getCompletions().length).toBe 0

  it "autocompletes functions with a prefix", ->
    editor.setText('<cfscript>ab')

    completions = getCompletions()
    expect(completions.length).toBe 1

    expect(completions[0].displayText).toBe 'abs'
    expect(completions[0].type).toBe 'function'
    expect(completions[0].leftLabel).toBe 'Numeric'

    editor.setText('<cfscript>abs(12);v')

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].displayText).toBe 'val'
    expect(completions[0].type).toBe 'function'
    expect(completions[0].leftLabel).toBe 'Numeric'
    expect(completions[1].displayText).toBe 'valueList'
    expect(completions[2].displayText).toBe 'verifyClient'

