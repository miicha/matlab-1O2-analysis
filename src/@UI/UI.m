classdef UI < handle
    %UI 
    properties (SetAccess = private)
        modes; % started modes
        current_mode = 1;
        online_ver = 'http://www.daten.tk/webhook/tags.php?owner=sebastian.pfitzner&project=sisa-scan-auswertung';
    end
    
    properties
        version = '0.0.0';
        lastopened = 0;
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0, 'folderstruct', struct); 
                      
        scale = [5 5 5 3];          % distance between the centers of two pixels in units
        units = {'mm', 'mm', 'mm', 's'};
        
        par_size = 16;  % when doing parallel processing: how many "tasks" should be sent to all threads?
        file_opened = 0;
        data_read = false;
        
        genericname;
        openpath; % persistent, in ini
        savepath; % persistent, in ini
        dbpath; % persistent, in ini
        open_nsTAS_path; % persistent, in ini
        siox_config; % persistent, in ini
        fluo_config; % persistent, in ini
        basepath;
        databasefunction = false;
        
        FileType;
        
        hyper_pos = false;
        inipath;
        lastfiles = struct();
        

        h = struct();        % handles
    end
    
    properties (SetAccess = protected)
        db_config = struct();
    end
    

    methods
    % create new instance with basic controls
        function this = UI(path, name, pos, maximised)
            p = get_executable_dir();
            this.inipath = fullfile(p, 'config.ini');
            try
                this.version = fileread([p filesep '..' filesep 'version.txt']);
            end
            this.db_config.dbuser = '';
            this.db_config.dbserver = 'localhost';
            this.db_config.dbpw = '';
            this.db_config.dbname = '';
            this.db_config.dbport = 3306;
            %% initialize all UI objects:
            this.h.f = figure();
            
            this.h.menu = uimenu(this.h.f);
            this.h.configmenu = uimenu(this.h.f);
            
            this.h.DBconfigmenu = uimenu(this.h.f);
            
            this.h.helpmenu = uimenu(this.h.f);
            
            this.h.bottombar = uipanel();
                this.h.info = uicontrol(this.h.bottombar);
            
            this.h.modepanel = uitabgroup();              
                
            
            scsize = get(0,'screensize');
            
            if scsize(4) < 680 || scsize(3) < 900
                warndlg('Bildschirm zu klein.')
                return
            end
            
            %% Figure, menu, bottombar
            set(this.h.f, 'units', 'pixels',...
                        'position', [scsize(3)-950 scsize(4)-750 900 680],...
                        'numbertitle', 'off',...
                        'menubar', 'none',...
                        'name', 'Scan',...
                        'resize', 'on',...
                        'Color', [.95, .95, .95],...
                        'ResizeFcn', @this.resize,...
                        'DeleteFcn', @this.destroy_cb);
     
            set(this.h.menu, 'Label', 'File');
            uimenu(this.h.menu, 'label', 'Open File...',...
                              'callback', @this.open_file_cb);
                          
            this.h.last_files = uimenu(this.h.menu, 'label', 'Last Files');
                          
            uimenu(this.h.menu, 'label', 'Open Folder...',...
                              'callback', @this.open_folder_cb);
            uimenu(this.h.menu, 'label', 'Open Database...',...
                              'callback', @this.open_db_cb);
            uimenu(this.h.menu, 'label', 'Open nsTAS File...',...
                              'callback', @this.open_nsTAS_cb);
            uimenu(this.h.menu, 'label', 'Save Plot',...
                              'callback', @this.save_fig_cb);
            uimenu(this.h.menu, 'label', 'Save State (experimentell!)',...
                              'callback', @this.save_global_state_cb);
                          
            uimenu(this.h.menu, 'label', 'Close all figures',...
                              'callback', @this.destroy_children_cb);
                          
            this.h.configmenu.Label = 'Settings';
            this.h.config_read_fluo = uimenu(this.h.configmenu,...
                              'label', 'Read Fluorescence',...
                              'callback', @this.config_read_fluo_cb);
            this.h.config_read_all_fluo = uimenu(this.h.configmenu,...
                              'label', 'Read all Fluorescence',...
                              'callback', @this.config_read_all_fluo_cb);
            this.h.config_remove_non_sisa = uimenu(this.h.configmenu,...
                              'label', 'Remove non SiSa',...
                              'callback', @this.config_remove_non_sisa_cb);
                          
            this.h.config_3d = uimenu(this.h.configmenu,...
                              'label', '3D-samples',...
                              'callback', @this.config_3d_cb);
                          
            this.h.config_load_bounds = uimenu(this.h.configmenu,...
                              'label', 'Use saved bounds',...
                              'callback', @this.config_load_bounds_cb);
                          
            this.h.config_keep_AR = uimenu(this.h.configmenu,...
                              'label', 'Keep Aspect Ratio',...
                              'callback', @this.config_keep_AR_cb);
            this.h.config_check_version = uimenu(this.h.configmenu,...
                              'label', 'Check for new Version at startup',...
                              'callback', @this.config_check_version_cb,...
                              'checked', 'on');
            this.h.config_database = uimenu(this.h.configmenu,...
                              'label', 'Database functionality',...
                              'callback', @this.config_database_cb);
                          
            this.h.DBconfigmenu.Label = 'DB Settings';
            this.h.config_database_no_DWZ = uimenu(this.h.DBconfigmenu,...
                              'label', 'select No DW Z Files',...
                              'checked', 'on',...
                              'callback', @this.config_database_noDWZ_cb);
            
            set(this.h.helpmenu, 'Label', '?');
            uimenu(this.h.helpmenu, 'label', 'über',...
                                  'Callback', @this.open_versioninfo_cb);
            
            set(this.h.bottombar, 'units', 'pixels',...
                                'position', [2 3 1000 18],...
                                'bordertype', 'none');
                            
            set(this.h.info, 'units', 'pixels',...
                           'style', 'text',...
                           'string', this.fileinfo.path,...
                           'HorizontalAlignment', 'left',...
                           'BackgroundColor', get(this.h.f, 'Color'),...
                           'ForegroundColor', [.3 .3 .3],...
                           'FontSize', 9,...
                           'position', [0 0 1000 15]);
            
            set(this.h.modepanel, 'units', 'pixels',...
                                  'position', [0 18 1000 680],...
                                  'SelectionChangedFcn', @this.mode_change_cb);
                             
            %% check version
            
            this.loadini();
            if this.check_version()
                this.restart();
                return
            end
            
            if isfield(this.lastfiles(1),'path')
                for i = 1:length(this.lastfiles)
                    this.h.("last_file_entry"+i) = uimenu(this.h.last_files, 'label', this.lastfiles(i).name,...
                                                            'callback',@this.openLastFile_cb,...
                                                            'tag', num2str(i));
                end
            end
                                 
            %% limit size with java
            unsafe_limit_size(this.h.f, [900 680]);
            
            %% get numbers of cores and set par_size accordingly
            this.par_size = feature('numCores')*6;
            
            %% add to PATH
            softwarefolder = strsplit(get_executable_dir, filesep());
            softwarefolder = strjoin(softwarefolder(1:end-1),filesep());
            addpath(genpath([softwarefolder filesep() '3rd-party']));
            addpath([softwarefolder filesep() 'src']);
            
            %% init
            this.resize();
            
            if nargin > 1
                if nargin > 3
                    if maximised
                        this.maximise();
                    else
                        set(this.h.f, 'position', pos);
                    end
                elseif nargin > 2
                    set(this.h.f, 'position', pos);
                end
                pause(.1);
                this.open_file(path, name);
            end
                        
        end
        
    % functions for opening and reading various files:
        function open_file(this, path, name)
            this.loadini();
            
            this.fileinfo.path = path;
            this.openpath = path;
            filepath = path;
            if iscell(name)
                % multiple selection
                % TODO: check if all files end with *.diff
                this.fileinfo.name = name;
                [~, n, ext] = fileparts(name{1});
                if regexp(ext, 'diff$')
                    this.openDIFF();
                elseif regexp(ext, 'asc$')
                    this.openASC();
                elseif regexp(ext, 'h5$')
                    this.openMultipleHDF5();
                end
            elseif isstruct(name)
                % multiple selection (including multiple folders)
                this.fileinfo.folderstruct = name;
                this.fileinfo.name = '';
                this.openDIFF();

                [~, n] = fileparts(name(1).name);
            else
                % single selection
                [~, n, ext] = fileparts(name);
                
                this.genericname = n;
                
                if regexp(ext, 'h5$')
                    this.fileinfo.name = {name};
                    this.openHDF5();
                elseif regexp(ext, 'state$')
                    this.saveini();
                    this.load_global_state([filepath name])
                    return
                elseif regexp(ext, 'diff$')
                    this.fileinfo.name = {name};
                    this.openDIFF();
                elseif regexp(ext, 'asc$')
                    this.fileinfo.name = {name};
                    this.openASC();
                end
            end
            
            this.saveini();
        end
        
        function openMultipleHDF5(this)
            
            if strcmp(this.h.config_read_fluo.Checked,'on')
                readfluo = true;
            else
                readfluo = false;
            end
            
            filepath = fullfile(this.fileinfo.path, this.fileinfo.name{1});
            reader = HDF5_reader(filepath);
            reader.readfluo = readfluo;
            reader.set_progress_cb(@this.update_infos);
            reader.read_data();
            
            pooled_camera_data(:,:,:,1) = reader.get_camera_data();
            num_images_in_file = size(pooled_camera_data,3);
            
            for i = 2: length(this.fileinfo.name)
                filepath = fullfile(this.fileinfo.path, this.fileinfo.name{i});
                
                tmp_reader = HDF5_reader(filepath);
                tmp_reader.readfluo = readfluo;
                
                tmp_reader.set_progress_cb(@this.update_infos);
                tic
                tmp_reader.read_data();
                tmp = tmp_reader.get_camera_data();
                pooled_camera_data(1:size(tmp,1),1:size(tmp,2),1:size(tmp,3),i) = tmp;
            end
            
            reader.replace_camera_data(pooled_camera_data);
            this.open_modes(reader);            
        end
        
        function openHDF5(this)
            filepath = fullfile(this.fileinfo.path, this.fileinfo.name{1});
            
            % File-Version und Typ auslesen (geht nur bei neuen Dateien)
            
            if strcmp(this.h.config_read_fluo.Checked,'on')
                readfluo = true;
            else
                readfluo = false;
            end
            if strcmp(this.h.config_read_all_fluo.Checked,'on')
                read_all_fluo = true;
            else
                read_all_fluo = false;
            end
            
            if strcmp(this.h.config_remove_non_sisa.Checked,'on')
                remove_non_sisa = true;
            else
                remove_non_sisa = false;
            end
            
            % Daten einlesen (abhängig von Einstellungen)
            reader = HDF5_reader(filepath,readfluo,read_all_fluo,remove_non_sisa);            
            reader.set_progress_cb(@this.update_infos);
            tic
            reader.read_data();
            read_data = toc
            tic
            this.open_modes(reader);
            open_modes = toc
        end
        
        function open_modes(this, reader)
            try
                fn = fieldnames(reader.meta.fileinfo);
                for i = 1:length(fn)
                    this.fileinfo.(fn{i}) = reader.meta.fileinfo.(fn{i});
                end
                scale = reader.meta.scale;
                this.scale = [scale, ones(4-numel(scale))];
                try
                    this.units = reader.meta.units;
                end
            end
            this.FileType = reader.fileType;
            
            i = 1;
            this.modes = {};
%             reader.meta.modes_in_file
            for mode = reader.meta.modes_in_file
                mode = mode{1};
                switch mode
                    case {'sisa','NIR'}
                        % open a SiSa tab
                        switch this.FileType
                            case 'oneFolderDiff'
                                this.modes{i} = SiSaMode(this, reader.get_sisa_data(), reader, i, this.siox_config);
                            case 'multiFolderDiff'
                                this.modes{i} = SiSaMode(this, reader.get_sisa_data(), reader, i, this.siox_config);
                            case {'scanning', 'bakterien'}
                                this.modes{i} = SiSaMode(this, reader.get_sisa_data(), reader, i, this.siox_config);
                            case 'in-vivo'
                                tmp = size(reader.data.sisa.data);
                                this.fileinfo.size = tmp(1:4);
                                this.modes{i} = InvivoMode(this, reader.get_sisa_data(),...
                                                         reader.data.sisa.verlauf,...
                                                         reader.meta.sisa.int_time, reader, i,this.siox_config);
                            case 'in-vivo-dual'
                                tmp = size(reader.data.sisa_1270.data);
                                this.fileinfo.size = tmp(1:4);
                                this.modes{i} = InvivoMode(this, double(reader.data.sisa_1211.data(1:tmp(1), 1:tmp(2), 1:tmp(3), 1:tmp(4), :)),...
                                                         reader.data.sisa_1211.verlauf,...
                                                         reader.meta.sisa.int_time, reader, i);
                                this.modes{i} = InvivoMode(this, double(reader.data.sisa_1270.data),...
                                                         reader.data.sisa_1270.verlauf,...
                                                         reader.meta.sisa.int_time, reader, i);
                            otherwise
                                warndlg(['Kann das Dateiformat ' this.FileType ' nicht öffnen!']);
                        end
                        i = i + 1;
                    case {'fluo', 'spec'}
                        if reader.readfluo % open a fluorescence tab
                            this.modes{i} = FluoMode(this, reader.get_fluo_data(),...
                                reader.get_fluo_x_achse(),...
                                reader.get_fluo_int_time(), reader.get_fluo_background(), i, this.fluo_config);
                            i = i + 1;
                        end
                    case 'temp'
                        % open a temperature tab
                        this.modes{i} = TempMode(this, reader.data.temp, i);
                        i = i + 1;
                    case 'laserpower'
                        this.modes{i} = LaserMode(this, reader.data.laserpower, i);
                        i = i + 1;
                        
                    case 'camera'
%                         figure(789)
%                         imshow(reader.data.camera(:,:,1), [5000, 11000])
                        intTime = 2000;
                        this.modes{i} = CameraMode(this, reader.data.camera,intTime, i);
                end
            end
            switch this.FileType
                case {'in-vivo', 'in-vivo-dual'}
                    % open a meta tab
                    if isfield(reader.data, 'temp') && isfield(reader.data, 'int')
                        this.modes{i} = MetaMode(this, double(reader.data.temp), double(reader.data.int));
                    elseif isfield(reader.data, 'temp')
                        this.modes{i} = MetaMode(this, double(reader.data.temp), []);
                    elseif isfield(reader.data, 'int')
                        this.modes{i} = MetaMode(this, [], double(reader.data.int));
                    else
                        this.modes{i} = MetaMode(this, [], []);
                    end
            end
            this.data_read = true;
        end
        
        function close_modes(this)
            this.modes
%             this.destroy(true);
            for i = 1:length(this.modes)
                this.modes{i}.destroy(false);
            end
        end
        
        function openDIFF(this)
            reader = file_reader(this.fileinfo.path, this.fileinfo.name, this.fileinfo.folderstruct);
            this.fileinfo.name = reader.fileinfo.name;
            this.open_modes(reader);
        end
        
        function open_sisa_data(this,path, displayname)
            data = load(path);
            data = data.sisadata;
            reader = this.read_meta();
            
            this.fileinfo.path = displayname;
            this.fileinfo.name = {path};
            tmp =  size(data);
            this.fileinfo.size = tmp(1:4);
            
            this.modes{1} = SiSaMode(this, data,reader,1, this.siox_config);
        end
        
        function set_savepath(this, path)
            this.savepath = path; 
        end

        function load_global_state(this, file)
            load(file, '-mat');
            v = str2double(strsplit(this.version));
            nv = str2double(strsplit(this_new.version));
            if sum(nv > v) > 0
                wh = warndlg({['Version des geladenen Files (' num2str(this_new.version)...
                              ') entspricht nicht der Version des aktuellen Programms'...
                              ' (' this.version '). Dies wird zu unerwartetem '...
                              'Verhalten (bspw. fehlender Funktionalität) führen!'], ...
                              ['Zum Umgehen dieses Problems sollten die zugrundeliegenden '...
                              'Daten erneut geöffnet und gefittet werden']}, 'Warnung', 'modal');
                pos = wh.Position;
                wh.Position = [pos(1) pos(2) pos(3)+20 pos(4)];
                wh.Children(3).Children.FontSize = 9;
                
            end
%             this_new.destroy(true);
            unsafe_limit_size(this_new.h.f, [900 680]);
            close(this.h.f);
            delete(this);
        end
        
        function fig = get_figure(this)
            fig = this.h.f;
        end
        
    % functions for updating the GUI
        function update_infos(this, text)
            str = [[this.fileinfo.path this.fileinfo.name{1}] '  |   Dimensionen: ' num2str(this.fileinfo.size)];

            if nargin < 2
                text = '';
                if this.data_read
                    str = [str '   |    Daten eingelesen.'];
                end
            end

            set(this.h.info, 'string', [str text]);
            if verLessThan('matlab', '8.5')
                drawnow update;
            else
                drawnow limitrate;
            end
        end

        function updated = check_version(this, varargin)
            force = false;
            try
                varargin{1}.String;
                force = true;
            end
            updated = false;
            
            % check at most once per hour
            if force || (strcmp(this.h.config_check_version.Checked,'on') && (now() - this.lastopened > 1/24))
                strct.lastopened = now();
                writeini(this.inipath, strct, false, true);
                try
                    nv_str = webread(this.online_ver);
                    newversion = num2str(nv_str);
                    
                    if UI.compare_versions(this.version, nv_str)
                        answer = questdlg(['Soll ein Update auf Version ' newversion ' versucht werden?'],...
                            'Update verfügbar', ...
                            'Ja', ...
                            'Nein', 'Nein');
                        %                     pos = wh.Position;
                        %                     wh.Position = [pos(1) pos(2) pos(3)+20 pos(4)];
                        %                     wh.Children(3).Children.FontSize = 9;
                        
                        if strcmp(answer, 'Ja')
                            'updating ...'
                            local_path = [mfilename('fullpath') filesep '..' filesep '..' filesep '..' filesep];
                            alternative_path = [filesep filesep 'pbpsa' filesep 'PBP_SHARE' filesep 'Software' filesep 'Deployment' filesep 'sisa-scan-auswertung'];
                            if update_software(local_path, alternative_path, newversion)
                                ['alles auf version ' newversion]
                                updated = true;
                            end
                        end
                    end
                catch
                    % no internet connection.
                end
            end
        end
        
        function restart(this)
            close(this.h.f);
            delete(this);
            UI();
        end
        
        %% Ini Krams
        
        function loadini(this, resize)
            if exist(this.inipath, 'file')
                conf = readini(this.inipath);
                if isfield(conf, 'UI_position')
                    this.h.f.Position = conf.UI_position;
                end
                if isfield(conf, 'openpath')
                    this.openpath = conf.openpath;
                    if this.openpath(end) ~= filesep
                        this.openpath(end+1) = filesep;
                    end
                else
                    this.openpath = '';
                end
                
                if isfield(conf, 'dbpath')
                    this.dbpath = conf.dbpath;
                else
                    this.dbpath = [p filesep()];
                end
                
                if isfield(conf, 'dbuser')
                    this.db_config.dbuser = conf.dbuser;
                end
                if isfield(conf, 'dbserver')
                    this.db_config.dbserver = conf.dbserver;
                end
                if isfield(conf, 'dbpw')
                    this.db_config.dbpw = conf.dbpw;
                end
                if isfield(conf, 'dbname')
                    this.db_config.dbname = conf.dbname;
                end
                if isfield(conf, 'dbport')
                    this.db_config.dbport = conf.dbport;
                end
                
                if isfield(conf, 'savepath')
                    this.savepath = conf.savepath;
                else
                    this.savepath = [p filesep()];
                end
                if isfield(conf, 'version')
                    if UI.compare_versions(conf.version, this.version)
                        % this version is newer than the one that was run
                        % last time
                        
                        % should do something with this...
                    end
                else
                    this.savepath = [p filesep()];
                end
                if isfield(conf, 'lastopened')
                    this.lastopened = conf.lastopened;
                end
                if isfield(conf, 'read_fluo')
                    this.h.config_read_fluo.Checked = conf.read_fluo;
                end
                if isfield(conf, 'read_all_fluo')
                    this.h.config_read_all_fluo.Checked = conf.read_all_fluo;
                end
                if isfield(conf, 'remove_non_sisa')
                    this.h.config_remove_non_sisa.Checked = conf.remove_non_sisa;
                end
                
                if isfield(conf, 'single_3d')
                    this.h.config_3d.Checked = conf.single_3d;
                end
                if isfield(conf, 'check_version')
                    this.h.config_check_version.Checked = conf.check_version;
                end
                if isfield(conf, 'keep_aspect')
                    this.h.config_keep_AR.Checked = conf.keep_aspect;
                end
                if isfield(conf, 'weighting')
                    this.siox_config.weighting = conf.weighting;
                else
                    this.siox_config.weighting = 1;
                end
                if isfield(conf, 'short_siox')
                    this.siox_config.short_siox = conf.short_siox;
                else
                    this.siox_config.short_siox = 0;
                end
                if isfield(conf, 'short_third')
                    this.siox_config.short_third = conf.short_third;
                else
                    this.siox_config.short_third = 0;
                end
                if isfield(conf, 'last_model')
                    this.siox_config.last_model = conf.last_model;
                else
                    this.siox_config.last_model = 1;
                end
                if isfield(conf, 'basepath')
                    this.basepath = conf.basepath;
                end
                if isfield(conf, 'databasefunction')
                    if strcmpi(conf.databasefunction, 'on')
                        this.databasefunction = true;
                        this.h.config_database.Checked = 'on';
                    end
                end
                i = 1;
                while isfield(conf, "lastfile_"+i)
                    tmp = conf.("lastfile_"+i);
                    [filepath,name,ext] = fileparts(tmp);
                    this.lastfiles(i).path = filepath;
                    this.lastfiles(i).name = [name ext];
                    i = i+1;
                end
                
                
                if isfield(conf, 'fluo_show_wl')
                    this.fluo_config.fluo_show_wl = conf.fluo_show_wl;
                else
                    this.fluo_config.fluo_show_wl = 720;
                end
                
                if isfield(conf, 'load_bounds')
                    file = fullfile(fileparts(this.inipath), 'bounds.mat');
                    this.h.config_load_bounds.Checked = conf.load_bounds;
                    this.siox_config.vals = [];
                    if strcmp(conf.load_bounds, 'on') && exist(file, 'file')
                        vals = load(file);
                        this.siox_config.vals = vals.vals;
                    end
                end
            else
                p = get_executable_dir();
                this.openpath = [p filesep()];
                this.savepath = [p filesep()];
                this.siox_config.last_model = 1;
                this.siox_config.short_siox = 0;
                this.siox_config.short_third = 0;
                this.siox_config.weighting = 1;
                this.fluo_config.fluo_show_wl = 720;
            end
        end
        
        function saveini(this)
            strct.version = this.version;
            strct.openpath = this.openpath;
            strct.dbpath = this.dbpath;
            strct.dbuser = this.db_config.dbuser;
            strct.dbserver = this.db_config.dbserver;
            strct.dbpw = this.db_config.dbpw;
            strct.dbname = this.db_config.dbname;
            strct.dbport = this.db_config.dbport;
            strct.open_nsTAS_path = this.open_nsTAS_path;
            strct.savepath = this.savepath;
            strct.read_fluo = this.h.config_read_fluo.Checked;
            strct.read_all_fluo = this.h.config_read_all_fluo.Checked;
            strct.remove_non_sisa = this.h.config_remove_non_sisa.Checked;
            strct.single_3d = this.h.config_3d.Checked;
            strct.keep_aspect = this.h.config_keep_AR.Checked;
            strct.check_version = this.h.config_check_version.Checked;
            strct.last_model = this.siox_config.last_model;
            strct.short_third = this.siox_config.short_third;
            strct.short_siox = this.siox_config.short_siox;
            strct.weighting = this.siox_config.weighting;
            strct.load_bounds = this.h.config_load_bounds.Checked;
            strct.basepath = this.basepath;
            strct.databasefunction = this.h.config_database.Checked;
            strct.UI_position = this.h.f.Position;
            
            for m = 1:length(this.modes)
                if isa(this.modes{m},'FluoMode')
                    strct.fluo_show_wl = this.modes{m}.get_current_wl();
                end
            end

            for i = 1:length(this.modes)
                tmp = this.modes{i}.get_fit_bounds;
                if isempty(tmp)
                    continue
                end
                vals = tmp;
                save(fullfile(fileparts(this.inipath), 'bounds.mat'),'vals');
            end
            
            % last files
            for i = 1:length(this.lastfiles)
                if isfield(this.lastfiles, 'path')
                    strct.("lastfile_"+i) = [this.lastfiles(i).path filesep this.lastfiles(i).name];
                end
            end
            
            
            writeini(this.inipath, strct, false, true);
        end
        
        %% Close
        
        function destroy(this, children_only)
            for i = 1:10
                try
                    this.saveini();
                catch
                    % some problem with the file system?!
                    % doesn't matter all that much, actually; just try
                    % again.
                    continue
                end
                break
            end

            for i = 1:length(this.modes)
                this.modes{i}.destroy(children_only);
            end
    %             this.modes = {};
    %             delete(this.h.tabs)
            
            if ~children_only
                delete(this.h.f);
                delete(this);
            end
        end
    end

    methods (Access = private)
        function resize(this, varargin)
            % resize elements in figure to match window size
            if isfield(this.h, 'f') % workaround for error when a loading a file
                fP = get(this.h.f, 'Position');
                
                tmp = get(this.h.modepanel, 'Position');
                tmp(3) = fP(3)+2;
                tmp(4) = fP(4)-20;
                mP = tmp;
                set(this.h.modepanel, 'Position', tmp);

                bP = get(this.h.bottombar, 'Position');
                bP(3) = mP(3)+3;
                set(this.h.bottombar, 'Position', bP);

                bP = get(this.h.info, 'Position');
                bP(3) = mP(3);
                set(this.h.info, 'Position', bP);
            end
            
            for i = 1:length(this.modes)
                this.modes{i}.resize();
            end
        end
        
        function maximise(this)
            jFrame = handle(this.h.f).JavaFrame;
            jFrame.setMaximized(1);
        end
        
        function m = isMaximised(this)
            jFrame = handle(this.h.f).JavaFrame;
            m = jFrame.isMaximized();
        end
        
        function addToLastfiles(this, filepath, filename)
            max_lastfiles = 5;
            
            if filepath(end) == filesep
                filepath = filepath(1:end-1);
            end
%             tic
            if ~isfield(this.lastfiles(1), 'path')
                newIndex = 1;
            else
                newIndex = length(this.lastfiles)+1;
                
                for i = 1:length(this.lastfiles)
                    if strcmp(this.lastfiles(i).name,filename)
                        this.lastfiles(i) = [];
                        newIndex = newIndex-1;
                        break
                    end
                end                
                reorder = length(this.lastfiles):-1:1;
                this.lastfiles = this.lastfiles(reorder);
            end
            
            this.lastfiles(newIndex).name = filename;
            this.lastfiles(newIndex).path = filepath;
            
            reorder = length(this.lastfiles):-1:1;
            this.lastfiles = this.lastfiles(reorder);
            if length(this.lastfiles) > max_lastfiles
                this.lastfiles = this.lastfiles(1:max_lastfiles);
            end
            
            
            for i = 1:length(this.lastfiles)
                if ~isfield(this.h, "last_file_entry"+i)
                    this.h.("last_file_entry"+i) = uimenu(this.h.last_files,...
                                                    'callback',@this.openLastFile_cb,...
                                                    'tag', num2str(i));
                end
                this.h.("last_file_entry"+i).Text = this.lastfiles(i).name;
            end
%             toc
        end
        
        %% Callbacks
        % callback for opening a new file
        % destroys current figure and creates a new one
        function open_file_cb(this, varargin)
            
            limit2DB = true;
            db_query = 'model_not';
            if strcmp(this.h.config_database_no_DWZ.Checked,'on')
                db_query = 'no_DW_Z';
            end
            
            % get path of file from user
            if this.databasefunction && limit2DB
                db = db_interaction(this.db_config);
                model = '';
                for m = 1:length(this.modes)
                    if isa(this.modes{m},'SiSaMode')
                        model = this.modes{m}.model;
                    end
                end
                if isempty(model)
                    s = sisafit(1);
                    models = s.get_model_info;
                    model = models.model_names{this.siox_config.last_model};
                end
            
                
                switch db_query
                    case 'no_DW_Z'
                        query = ['SELECT dateiinfos.name FROM dateiinfos '...
                                'WHERE dateiinfos.ID NOT IN( '...
                                'SELECT dateiinfos.ID FROM `dateiinfos` JOIN '...
                                'datapointinfos ON datapointinfos.datei = dateiinfos.ID '...
                                'JOIN ergebnisse ON ergebnisse.DS_ID = datapointinfos.ID '...
                                'JOIN modell ON ergebnisse.Modell = modell.ID '...
                                'WHERE modell.name = "' model '" '...
                                'AND ergebnisse.DW > 0 '...
                                'GROUP BY dateiinfos.ID)'];
                    case 'model_not'
                        query = ['SELECT dateiinfos.name FROM dateiinfos '...
                                'WHERE dateiinfos.ID NOT IN( '...
                                'SELECT dateiinfos.ID FROM `dateiinfos` JOIN '...
                                'datapointinfos ON datapointinfos.datei = dateiinfos.ID '...
                                'JOIN ergebnisse ON ergebnisse.DS_ID = datapointinfos.ID '...
                                'JOIN modell ON ergebnisse.Modell = modell.ID '...
                                'WHERE modell.name = "' model '" '...
                                'GROUP BY dateiinfos.ID)'];
                    case 'hyper_not'
                        query = ['SELECT dateiinfos.name FROM dateiinfos '...
                                'WHERE dateiinfos.ID NOT IN( '...
                                'SELECT dateiinfos.ID FROM `dateiinfos` JOIN '...
                                'datapointinfos ON datapointinfos.datei = dateiinfos.ID '...
                                'JOIN hyper ON hyper.DS_ID = datapointinfos.ID GROUP BY dateiinfos.ID)'];
                    case 'in_db'
                        query = 'SELECT `name` FROM `dateiinfos` ORDER BY `name` ASC;';
                end
                
                data = db.get(query);
                db.close();
                
                filenames = strjoin(data.name,';');
%                 [name, filepath] = uigetfile({[this.openpath filenames ';*.diff;*.asc;*.state'];[this.openpath filenames '*.h5;*.diff;*.asc;*.state']}, 'Dateien auswählen', 'MultiSelect', 'on');
                [name, filepath] = uigetfile({[filenames '*.diff;*.asc;*.state'], 'DB-Beschränkt'; '*.h5;*.diff;*.asc;*.state', 'alle'}, 'Dateien auswählen', this.openpath, 'MultiSelect', 'on');
           
            else
                [name, filepath] = uigetfile({[this.openpath '*.h5;*.diff;*.asc;*.state']}, 'Dateien auswählen', 'MultiSelect', 'on');
            end
            
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            
            this.addToLastfiles(filepath,name);
            this.openpath = filepath;
            this.saveini();
            this.close_modes();
            this.open_file(filepath, name);
        end
        
        function openLastFile_cb(this,varargin)
            selection = str2double(varargin{1}.Tag);
            filepath = this.lastfiles(selection).path;
            if filepath(end) ~= filesep
                filepath(end+1) = filesep;
            end
            name = this.lastfiles(selection).name;
            this.addToLastfiles(filepath,name);
            this.openpath = filepath;
            this.saveini();
            this.close_modes();
            this.open_file(filepath, name);
        end
        
        function open_folder_cb(this, varargin)
%             this.loadini();
            % get path of file from user
            names  = uipickfiles('FilterSpec', this.openpath, 'REFilter', '\.h5$|\.diff$|\.state$', 'output', 'str');
            
            if ~isstruct(names) || isempty(names) % no file selected
                return
            end
            
            m = this.isMaximised();
            pos = get(this.h.f, 'position');
            
            filepath = [fileparts(names(1).name) '\'];
            this.openpath = filepath;
            this.saveini();
            set(this.h.f, 'visible', 'off');
            global debug_u
            if debug_u == true
                debug_u = UI(filepath, names, pos, m);
            else
                UI(filepath, names, pos, m);
            end
            close(this.h.f);
            delete(this);
            
%             %% add to PATH
%             addpath(genpath([get_executable_dir '\..\3rd-party']));
%             addpath([get_executable_dir '\..\src']);
        end
        
        function open_db_cb(this, varargin)
%             this.loadini();
            % get path of file from user
            [name, filepath] = uigetfile({[this.dbpath '*.db']}, 'Dateien auswählen', 'MultiSelect', 'on');
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            this.dbpath = filepath;
            this.saveini();
            
            dbviewer = DB_Viewer([filepath name], 'DB-Anzeige', this);
        end
        
        
        function open_nsTAS(this)
            name = this.fileinfo.name;
            if iscell(name)
                for i = 1:length(name)
                    this.fileinfo.size = [length(name), 1, 1];
                    d = dlmread([this.fileinfo.path name{i}]);
                    if i > 1
                        if length(d) > size(data, 5)
                            d = d(1:size(data, 5));
                            this.update_infos(['    |    Länge der Daten ungleich in ' name{i}]);
                        elseif length(d) < size(data, 5)
                            d = [d; zeros(size(data, 5) - length(d),1)];
                        end
                    end
                    data(i, 1, 1, 1,:) = d;
                end
                this.fileinfo.np = length(name);
            elseif isstruct(name)
                this.fileinfo.name = cell(length(name),1);
                for i = 1:length(name)
                    if name(i).isdir
                        files = dir([name(i).name '\*.diff']);
                        for j = 1:length(files)
                            d = dlmread([name(i).name '\' files(j).name]);
                            if i == 1 && j == 1
                                data = zeros(length(name),length(files),1,1,length(d));
                            end
                            this.fileinfo.name{i,j} = files(j).name;
                            data(i, j, 1, 1,:) = d;
                        end
                    end
                end
            end
            this.data_read = true;
            
            tmp = size(data);
            this.fileinfo.size = tmp(1:4);
            
            for i = 1:length(name)
                if mod(i, round(length(name)/10)) == 0
                    this.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
            end
            
            reader = this.read_meta();
            this.modes{1} = SiSaMode(this, double(data),reader, 1, this.siox_config);
        end
        
        
        function open_nsTAS_cb(this,varargin)
%             this.loadini();
            [name, filepath] = uigetfile({[this.open_nsTAS_path '*.txt;*.diff']}, 'Dateien auswählen', 'MultiSelect', 'on');
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            
            this.open_nsTAS_path = filepath;
            this.saveini();
            
            if ~iscell(name)
                name = {name};
            end
            
            for i = 1:length(name)
                this.fileinfo.size = [length(name), 1, 1];
                d = import_nsTAS([filepath '\' name{i}],1);
                %                     d(:,1) = data(:,1)*10^6;
                %                     d = dlmread([this.fileinfo.path name{i}]);
                if i > 1
                    if length(d) > size(data, 5)
                        d = d(1:size(data, 5));
                        this.update_infos(['    |    Länge der Daten ungleich in ' name{i}]);
                    elseif length(d) < size(data, 5)
                        d = [d; zeros(size(data, 5) - length(d),1)];
                    end
                end
                data(i, 1, 1, 1,:) = d(:,2);
                x_data(i, 1, 1, 1,:) = d(:,1)*10^6;
                err(i, 1, 1, 1,:) = d(:,3);
            end
            this.fileinfo.np = length(name);
            
            
            this.modes{end+1} = nsTASMode(this,data,x_data,err);
            
        end
        
        % punt to current mode to handle everything
        function save_fig_cb(this, varargin)
            if ~isempty(this.modes)
                tmp = this.current_mode;
                if ischar(tmp)
                    tmp = str2double(tmp);
                end
                this.modes{tmp}.save_fig();
            end
        end
        
        function mode_change_cb(this, varargin)
            this.current_mode = varargin{2}.NewValue.Tag;
        end
                    
        function save_global_state_cb(this, varargin)
            [name, path] = uiputfile('*.state', 'State speichern', [this.savepath this.genericname '.state']);
            if name == 0
                return
            end
            this.set_savepath(path);
            
            this_new = this;
            save([path name], 'this_new');
        end
        
        function config_read_fluo_cb(this,varargin)
            if strcmp(this.h.config_read_fluo.Checked,'on')
                this.h.config_read_fluo.Checked = 'off';
            else
                this.h.config_read_fluo.Checked = 'on';
            end
            this.saveini();            
        end
        
        function config_read_all_fluo_cb(this,varargin)
            if strcmp(this.h.config_read_all_fluo.Checked,'on')
                this.h.config_read_all_fluo.Checked = 'off';
            else
                this.h.config_read_all_fluo.Checked = 'on';
            end
            this.saveini();            
        end
        
        function config_database_cb(this,varargin)
            if strcmp(this.h.config_database.Checked,'on')
                this.h.config_database.Checked = 'off';
                this.databasefunction = false;
            else
                this.h.config_database.Checked = 'on';
                this.databasefunction = true;
            end
            this.saveini();            
        end
        
        function config_database_noDWZ_cb(this,varargin)
            if strcmp(this.h.config_database_no_DWZ.Checked,'on')
                this.h.config_database_no_DWZ.Checked = 'off';
%                 this.databasefunction = false;
            else
                this.h.config_database_no_DWZ.Checked = 'on';
%                 this.databasefunction = true;
            end
%             this.saveini();            
        end
        
        function config_remove_non_sisa_cb(this,varargin)
            if strcmp(this.h.config_remove_non_sisa.Checked,'on')
                this.h.config_remove_non_sisa.Checked = 'off';
            else
                this.h.config_remove_non_sisa.Checked = 'on';
            end
            this.saveini();            
        end        
        
        function config_3d_cb(this,varargin)
            if strcmp(this.h.config_3d.Checked,'on')
                this.h.config_3d.Checked = 'off';
            else
                this.h.config_3d.Checked = 'on';
            end
            this.saveini();            
        end
        
        function config_load_bounds_cb(this,varargin)
            if strcmp(this.h.config_load_bounds.Checked,'on')
                this.h.config_load_bounds.Checked = 'off';
            else
                this.h.config_load_bounds.Checked = 'on';
            end
            this.saveini();            
        end
        
        function config_check_version_cb(this,varargin)
            if strcmp(this.h.config_check_version.Checked,'on')
                this.h.config_check_version.Checked = 'off';
            else
                this.h.config_check_version.Checked = 'on';
            end
            this.saveini();            
        end
        
        
        function config_keep_AR_cb(this,varargin)
            if strcmp(this.h.config_keep_AR.Checked,'on')
                this.h.config_keep_AR.Checked = 'off';
            else
                this.h.config_keep_AR.Checked = 'on';
            end
            this.resize();  % ToDo checken warum das nicht funktioniert
            this.saveini();
        end
        
        function destroy_cb(this, varargin)
            this.destroy(false);
            
%             %% clean up PATH            
%             rmpath(genpath([get_executable_dir '\..\3rd-party']));
%             rmpath(([get_executable_dir '\..\src']));
        end
        
        function destroy_children_cb(this, varargin)
            this.destroy(true);
        end
        
        function open_versioninfo_cb(this, varargin)
            f = figure('units', 'pixels',...
                       'numbertitle', 'off',...
                       'menubar', 'none',...
                       'name', 'SISA Scan Versioninfo',...
                       'resize', 'off',...
                       'Color', [.95, .95, .95]);
                   
            fP = f.Position;
            fP(3:4) = [500 230];
            f.Position = fP;
            uicontrol(f, 'style', 'text',...
                          'position', [20 190 480 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 15,...
                          'string', 'SiSa-Scan Auswerte-Software');
            
            uicontrol(f, 'style', 'text',...
                          'position', [20 160 480 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 11,...
                          'string', 'Autor: Sebastian Pfitzner, pfitzseb@physik');
                      
            
                      
            try
                server_ver = webread(this.online_ver);
            catch
                server_ver = 'keine Internet-Verbindung!';
            end
            
            if ~strcmp(server_ver,this.version)
                uicontrol(f, 'style', 'pushbutton',...
                          'position', [150 132 200 23],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 11,...
                          'string', 'Try Update',...
                          'callback',@this.check_version);
            end
                      
            
            str = ['Aktuelle Version: lokal ' num2str(this.version) '  -  online ' server_ver];

            uicontrol(f, 'style', 'text',...
                          'position', [20 105 460 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 10,...
                          'string', str);
                          
            str = {['Die aktuellsten Versionen finden sich immer auf dem Git-Server'...'
                   ' unter www.git.daten.tk. Dort gibt es sowohl die Binary-Releases als '...
                   'auch den Source-Code und die Readme.'], ['Alternativ sind die '...
                   'Binaries auch auf dem Share im Software-Ordner zu finden.']};
            uicontrol(f, 'style', 'text',...
                          'position', [20 20 470 80],...
                          'FontSize', 10,...
                          'HorizontalAlignment', 'left',...
                          'string', str);
              
        end
    end

    methods (Static=true)
        function ver2isnewer = compare_versions(ver1, ver2)
            ver1_parts = str2double(strsplit(ver1, '.'));
            ver2_parts = str2double(strsplit(ver2, '.'));
            l1 = length(ver2_parts);
            l2 = length(ver1_parts);
            max_length = l1;
            if l1 < l2
                ver1_parts = padarray(ver1_parts, l2-l1, 0, 'post');
                max_length = l2;
            elseif l2 > l1
                ver2_parts = padarray(ver2_parts, l1-l2, 0, 'post');
            end
            
            ver2isnewer = false;
            for i = 1:max_length
                if ver1_parts(i) < ver2_parts(i)
                    ver2isnewer = true;
                    break
                elseif ver1_parts(i) > ver2_parts(i)
                    ver2isnewer = false;
                    break
                end
            end
        end
    end
end
