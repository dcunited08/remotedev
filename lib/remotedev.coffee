fs = require('fs')
RemotedevView = require './remotedev-view'

module.exports =
    remotedevView: null
    configDefaults:
        showPath: false
        closeCurrent: false

    projectManagerView: null
    projectManagerAddView: null
    filename: 'remotedev.cson'
    fileDir: atom.getConfigDirPath()
    file: null
    project: null



    deactivate: ->
        @remotedevView.destroy()

    serialize: ->
        remotedevViewState: @remotedevView.serialize()

    activate: (state) ->
        console.log 'remotedev activiated'
        @remotedevView = new RemotedevView(state.remotedevViewState)
        @file = "#{@fileDir}/#{@filename}"

        atom.workspaceView.command 'remotedev:save-project', =>
            @createProjectManagerAddView(state).toggle(@)
        atom.workspaceView.command 'remotedev:download', =>
            @createProjectManagerView(state).toggle(@)
        atom.workspaceView.command 'remotedev:edit-config', =>
            @editProjects()
        atom.workspaceView.command 'remotedev:download', =>
            @download()

        atom.workspaceView.command 'remotedev:upload', =>
            @upload()

        fs.exists @file, (exists) =>
            default_file = "#{atom.packages.resolvePackagePath('remotedev')}/remotedev.cson.default"
            unless exists
                fs.readFile default_file, (error, text) =>
                    fs.writeFile @file, text, (error) =>
                        if error
                            console.log "Error: Could not create the file projects.cson - #{error}"
                        else
                            @loadSettings()

            if exists
                @loadSettings()


    loadSettings: ->
        console.log "loading settings"
        CSON = require 'season'
        CSON.readFile @file, (error, data) =>
            unless error
                for title, project of data
                    console.log title
                    if project.path is atom.project.getPath()
                        console.log "settings found"
                        @project = project
                        console.log @project
                        if project.settings?
                            @enableSettings(project.settings)
                            break

    enableSettings: (settings) ->
        for setting, value of settings
            atom.workspace.eachEditor (editor) ->
                console.log editor
                editor[setting](value)
                console.log editor

    addProject: (project) ->
        console.log 'Adding Project'
        CSON = require 'season'
        projects = CSON.readFileSync(@file) || {}
        projects[project.title] = project
        CSON.writeFileSync(@file, projects)

    openProject: ({title, paths}) ->
        atom.open options =
          pathsToOpen: paths

        if atom.config.get('remotedev.closeCurrent') or not atom.project.getPath()
          atom.close()

    editProjects: ->
        config =
          title: 'Config'
          paths: [@file]
        @openProject(config)

    download: ->
        console.log "should download"

    upload: ->
        console.log "should upload"


    createProjectManagerView: (state) ->
        unless @projectManagerView?
          ProjectManagerView = require './remotedev-view'
          @projectManagerView = new ProjectManagerView(state.projectManagerViewState)
        @projectManagerView

    createProjectManagerAddView: (state) ->
        unless @projectManagerAddView?
          ProjectManagerAddView = require './remotedev-add-view'
          @projectManagerAddView = new ProjectManagerAddView(state.projectManagerAddViewState)
        @projectManagerAddView
