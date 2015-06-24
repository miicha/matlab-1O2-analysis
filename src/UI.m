classdef UI < handle
    %UI 
    properties (SetAccess = private)
        modes; % started modes
        current_mode = 1;
        online_ver = 'http://www.daten.tk/webhook/tags.php?owner=sebastian.pfitzner&project=sisa-scan-auswertung';
    end
    
    properties
        version = '0.4.2';
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0); 
                      
        scale = [5 5 5 3];          % distance between the centers of two pixels in units
        units = {'mm', 'mm', 'mm', 's'};
        
        par_size = 16;  % when doing parallel processing: how many "tasks" should be sent to all threads?
        file_opened = 0;
        data_read = false;
        
        genericname;
        openpath; % persistent, in ini
        savepath; % persistent, in ini

        h = struct();        % handles
    end

    methods
    % create new instance with basic controls
        function this = UI(path, name, pos)
            %% initialize all UI objects:
            this.h.f = figure();
            
            this.h.menu = uimenu(this.h.f);
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
     
            set(this.h.menu, 'Label', 'Datei');
            uimenu(this.h.menu, 'label', 'Datei öffnen...',...
                              'callback', @this.open_file_cb);
            uimenu(this.h.menu, 'label', 'Plot speichern',...
                              'callback', @this.save_fig_cb);
            uimenu(this.h.menu, 'label', 'State speichern (experimentell!)',...
                              'callback', @this.save_global_state_cb);
            set(this.h.helpmenu, 'Label', '?');
            uimenu(this.h.helpmenu, 'label', 'Über',...
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
                             
            %% check version (only if called as a binary)
            this.check_version();
                                 
            %% limit size with java
            unsafe_limit_size(this.h.f, [900 680]);
            
            %% get numbers of cores and set par_size accordingly
            this.par_size = feature('numCores')*6;
            
            %% init
            this.resize();

            if nargin > 1
                if nargin == 3
                    set(this.h.f, 'position', pos);
                end
                pause(.1);
                this.open_file(path, name);
            end
                        
        end
        
    % functions for opening and reading various files:
        function open_file(this, path, name)
            %% add to PATH
            addpath(genpath([get_executable_dir '\..\3rd-party']));
            addpath([get_executable_dir '\..\src']);
            %%
            this.loadini();
            this.fileinfo.path = path;
            this.openpath = path;
            filepath = path;
            if iscell(name)
                % multiple selection
                % TODO: check if all files end with *.diff
                this.fileinfo.name = name;
                this.openDIFF();
                [~, n] = fileparts(name{1});
            else
                % single selection
                [~, ~, ext] = fileparts(name);
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
                end
                [~, n] = fileparts(name);
            end
            

            this.genericname = n;
            
            this.saveini();
        end
        
        function openHDF5(this)
            filepath = fullfile(this.fileinfo.path, this.fileinfo.name{1});
            
            % File-Version und Typ auslesen (geht nur bei neuen Dateien)
            try                
                f_id = H5F.open(filepath);
                attr_id = H5A.open(f_id,'Version');
                info = H5A.read(attr_id);
                H5A.close(attr_id);
                H5F.close(f_id);
                FileType = info.Typ{1};
            catch
                FileType = 'scanning';
            end
            
            switch FileType
                case 'scanning'
                    reader = scanning_reader(filepath);
                    fn = fieldnames(reader.meta.fileinfo);
                    for i = 1:length(fn)
                        this.fileinfo.(fn{i}) = reader.meta.fileinfo.(fn{i});
                    end
                    
                    if isfield(reader.data, 'sisa')
                        % open a SiSa tab
                        this.modes{1} = SiSaMode(this, double(reader.data.sisa));
                    end
                    if isfield(reader.data, 'fluo')
                        % open a fluorescence tab
%                         this.modes{2} = FluoMode(this, double(reader.data.fluo),...
%                                                        reader.meta.fluo.x_achse,...
%                                                        reader.meta.fluo.int_time);
                    end
                    if isfield(reader.data, 'temp')
                        % open a temperature tab
                        this.modes{3} = TempMode(this, double(reader.data.temp));
                    end
                    
                case 'in-vivo'
                    reader = invivo_reader(filepath, this);
                    tmp = size(reader.data.sisa.data);
                    this.fileinfo.size = tmp(1:4);
                    
                    if isfield(reader.data, 'sisa')
                        % open a SiSa tab
                        this.modes{1} = InvivoMode(this, double(reader.data.sisa.data),...
                                                         reader.data.sisa.verlauf,...
                                                         reader.meta.sisa.int_time, reader);
                    end
                    if isfield(reader.data, 'fluo')
                        % open a fluorescence tab
                        this.modes{2} = FluoMode(this, double(reader.data.fluo.data),...
                                                       reader.meta.fluo.x_achse,...
                                                       reader.meta.fluo.int_time);
                    end
                    if isfield(reader.data, 'temp')
                        % open a temperature tab
                        this.modes{3} = TempMode(this, double(reader.data.temp));
                    end
            end

            this.data_read = true;
        end
        
        function openDIFF(this)
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
            end
            this.data_read = true;
            
            tmp = size(data);
            this.fileinfo.size = tmp(1:4);
            
            for i = 1:length(name)
                if mod(i, round(length(name)/10)) == 0
                    this.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
            end
            
            this.modes{1} = SiSaMode(this, double(data));
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
            this_new.destroy(true);
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

        function check_version(this)
            try
                nv_str = urlread(this.online_ver);
                
                if UI.compare_versions(this.version, nv_str)
                    wh = warndlg({['Es ist eine neue Version der Software verfügbar ('...
                                   num2str(nv_str) ').'], ['Aktuelle Version: '...
                                   num2str(this.version) '.'],... 
                                   'Download unter: https://git.daten.tk/ oder auf dem Share.'}, 'Warnung', 'modal');
                    pos = wh.Position;
                    wh.Position = [pos(1) pos(2) pos(3)+20 pos(4)];
                    wh.Children(3).Children.FontSize = 9;
                end
            catch
                 % no internet connection.
            end
        end
        
        function loadini(this)
            p = get_executable_dir();
            if exist(fullfile(p, 'config.ini'), 'file')
                conf = readini('config.ini');
                if isfield(conf, 'openpath')
                    this.openpath = conf.openpath;
                else
                    this.openpath = [p filesep()];
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
            else
                this.openpath = [p filesep()];
                this.savepath = [p filesep()];
            end
        end
        
        function saveini(this)
            p = get_executable_dir();
            strct.version = this.version;
            strct.openpath = this.openpath;
            strct.savepath = this.savepath;

            writeini([p filesep() 'config.ini'], strct);
        end
        
        function destroy(this, children_only)
            for i = 1:10
                try
                    this.saveini();
                catch
                    % some problem with the file system?!
                    % doesn't matter all that much, actually; just try
                    % again.
                    continue;
                end
                break;
            end
            for i = 1:length(this.modes)
                this.modes{i}.destroy(children_only);
            end
            
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
        
        %% Callbacks
        % callback for opening a new file
        % destroys current figure and creates a new one
        function open_file_cb(this, varargin)
            this.loadini();
            % get path of file from user
            [name, filepath] = uigetfile({[this.openpath '*.h5;*.diff;*.state']}, 'Dateien auswählen', 'MultiSelect', 'on');
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            this.openpath = filepath;
            this.saveini();
            set(this.h.f, 'visible', 'off');
            global debug_u
            if debug_u == true
                debug_u = UI(filepath, name, get(this.h.f, 'position'));
            else
                UI(filepath, name, get(this.h.f, 'position'));
            end
            close(this.h.f);
            delete(this);
            
%             %% add to PATH
%             addpath(genpath([get_executable_dir '\..\3rd-party']));
%             addpath([get_executable_dir '\..\src']);
        end
        
        % punt to current mode to handle everything
        function save_fig_cb(this, varargin)
            if ~isempty(this.modes)
                this.modes{this.current_mode}.save_fig();
            end
        end
        
        function mode_change_cb(this, varargin)
            this.current_mode = str2double(varargin{2}.NewValue.Tag);
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
        
        function destroy_cb(this, varargin)
            this.destroy(false);
            
%             %% clean up PATH            
%             rmpath(genpath([get_executable_dir '\..\3rd-party']));
%             rmpath(([get_executable_dir '\..\src']));
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
                server_ver = urlread(this.online_ver);
            catch
                server_ver = 'keine Internet-Verbindung!';
            end
            
            str = ['Aktuelle Version: lokal ' num2str(this.version) '  -  online ' server_ver];

            uicontrol(f, 'style', 'text',...
                          'position', [20 120 460 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 10,...
                          'string', str);
                          
            str = {['Die aktuellsten Versionen finden sich immer auf dem Git-Server'...'
                   ' unter git.daten.tk. Dort gibt es sowohl die Binary-Releases als '...
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
