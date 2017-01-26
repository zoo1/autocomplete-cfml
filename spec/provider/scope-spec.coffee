describe "scope autocompletions", ->
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
      provider = atom.packages.getActivePackage('autocomplete-cfml').mainModule.getProvider()[1]

    waitsFor -> Object.keys(provider.scopes).length > 0
    waitsForPromise -> atom.workspace.open('application.cfc')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "returns no completions when a nonexistant scope is used", ->
    editor.setText('seccion.')
    completions = getCompletions()
    expect(completions.length).toBe 0

    editor.setText('start seccion.')
    completions = getCompletions()
    expect(completions.length).toBe 0

    editor.setText('not.a.scope')
    completions = getCompletions()
    expect(completions.length).toBe 0

    editor.setText('other..none.scopes')
    completions = getCompletions()
    expect(completions.length).toBe 0

  it "returns no completions when invalid scope referrences are used", ->
    editor.setText('this..')
    completions = getCompletions()
    expect(completions.length).toBe 0

  it "returns completions for a first level scope without prefix", ->
    editor.setText('session.')
    completions = getCompletions()
    expect(completions.length).toBe 3
    expect(completions[0].text).toBe 'CFID'

    for completion in completions
      expect(completion.type).toBe 'value'

    editor.setText('SESSION.')
    completions = getCompletions()
    expect(completions.length).toBe 3

    editor.setText('<cfset test = Server.')
    completions = getCompletions()
    expect(completions.length).toBe 2

    for completion in completions
      expect(completion.type).toBe 'value'

  it "returns limited completions for a first level scope with a prefix", ->
    editor.setText('session.C')
    completions = getCompletions()
    expect(completions.length).toBe 2
    expect(completions[0].text).toBe 'CFID'

    for completion in completions
      expect(completion.type).toBe 'value'

    editor.setText('SESSION.c')
    completions = getCompletions()
    expect(completions.length).toBe 2

    editor.setText('<cfset test = CGI.S')
    completions = getCompletions()
    expect(completions.length).toBe 6

    for completion in completions
      expect(completion.type).toBe 'value'

  it "returns single completion for a first level scope with exact match", ->
    editor.setText('<cfset writeDump(cgi.HTTP_CONNECTION')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].text).toBe 'HTTP_CONNECTION'
    expect(completions[0].type).toBe 'value'
 
    editor.setText('<cfset test = session.cfid')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].text).toBe 'CFID'
    expect(completions[0].type).toBe 'value'

  it "returns completions for a second level scope without prefix", ->
    editor.setText('this.s3.')
    completions = getCompletions()
    expect(completions.length).toBe 3
    expect(completions[0].text).toBe 'accessKeyId'

    for completion in completions
      expect(completion.type).toBe 'value'

    editor.setText('<cfset test = THIS.wssettings.')
    completions = getCompletions()
    expect(completions.length).toBe 6

    for completion in completions
      expect(completion.type).toBe 'value'

  it "returns limited completions for a second level scope with a prefix", ->
    editor.setText('this.s3.a')
    completions = getCompletions()
    expect(completions.length).toBe 2
    expect(completions[0].text).toBe 'accessKeyId'

    for completion in completions
      expect(completion.type).toBe 'value'

  it "returns single completion for a second level scope with exact match", ->
    editor.setText('<cfset writeDump(this.s3.accessKeyId')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].text).toBe 'accessKeyId'
    expect(completions[0].type).toBe 'value'

    editor.setText('<cfset test = this.s3.defaultLocation')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].text).toBe 'defaultLocation'
    expect(completions[0].type).toBe 'value'

