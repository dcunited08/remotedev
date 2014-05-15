fs = require('fs')
q = require('q')
Connection = require("ssh2")
fs2 = require('ssh2-fs')

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

    _conn: null
    _sftp: null



    deactivate: ->
        @remotedevView.destroy()

    serialize: ->
        remotedevViewState: @remotedevView.serialize()

    activate: (state) ->
        console.log 'remotedev activiated'

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

    download: (directory)->
        console.log directory
        unless directory?
            directory = @project.remote_path

        console.log "should download #{directory}"
        regex = "#{@project.remote_path}/"
        console.log regex
        regex = regex.replace(/\//, '_')
        console.log regex

        local_directory = directory.replace(/"#{@project.remote_path}"/, @project.path)
        console.log local_directory

        rtn =
        @_verifyLocalDirectory local_directory
        .then @sftp
        .then (sftp) =>
            [sftp, directory]
        .then @_getRemoteFileList
        .then (list, test)=>

            console.log list.length
            list
        .then @_removeIgnoredFiles
        .then (list, test) =>
            console.log 'last call'
            console.log list.length
            tst2 = for i, item of list
                if @isDirectory item
                    @download "#{directory}/#{item.filename}"

                else
                    @_downloadFile "#{directory}/#{item.filename}", "#{@project.path}/#{item.filename}"


            # console.log tst2
            tst2

        rtn


    upload: ->
        console.log "should upload"

    isDirectory: (item) ->

        char = item.longname.charAt 0


        if char is 'd'
            return true
        else
            return false

        return false


    sftp: (unused) ->
        unless @_sftp?
          @_sftp = @do_conn()
                  .then @do_sftp
        @_sftp

    conn: () ->
        unless @_conn?
          @_conn = @do_conn()
        @_conn

    do_sftp: (conn) =>

        deferred = q.defer()
        conn.sftp (err, sftp) =>

          if err
              deferred.reject err

          else

              deferred.resolve sftp

          return

        deferred.promise


    do_conn: =>
        console.log "try conn"




        deferred = q.defer()


        c = new Connection()

        c.on "ready", =>
            console.log "Connection :: ready"
            deferred.resolve c
            return

        c.on "error", (err) ->
          console.log "Connection :: error :: " + err
          return

        c.on "end", ->
          console.log "Connection :: end"
          return

        c.on "close", (had_error) ->
          console.log "Connection :: close"
          return

        c.connect
          host: "dev.p01.aug.me"
          port: 57600
          username: "dcook"
          password: "sam&matt1911",
          (error, data) =>
              console.log 'conn worked'
              console.log error
              console.log data

        deferred.promise


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

    _getRemoteFileList: (args) =>
        sftp = args[0]
        directory = args[1]
        deferred = q.defer()
        console.log directory

        sftp.opendir directory, readdir = (err, handle) =>
            if err
                deferred.reject err

            sftp.readdir handle, (err, _list) =>

                deferred.resolve _list
        deferred.promise

    _removeIgnoredFiles: (list) =>

        list2 = for i, item of list
            if item.filename isnt ".." and item.filename isnt "."
                item
            else
                continue

        list2

    _asdf: (i)=>
        console.log "asdf #{i}"
        #console.log i
        "dog"

    _verifyLocalDirectory: (directory) ->
        console.log directory
        deferred = q.defer()
        fs2.exists null, directory, (unused, exists) =>
            console.log exists
            if exists
                deferred.resolve true
            else
                fs2.mkdir null, directory, (err) =>
                    if err
                        deferred.reject err
                    else
                        deferred.resolve true


        deferred.promise

    _downloadFile: (remote_file, local_file) ->
        fileDownload = @conn()
            .then (c) =>
                deferred = q.defer()

                fs2.readFile c, remote_file, null, (err, list) =>
                    fs.writeFile local_file, list, {}, (err, list) =>
                      deferred.resolve list
                deferred.promise

        fileDownload
