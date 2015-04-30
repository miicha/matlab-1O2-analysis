classdef UI < handle
    %UI 

    properties
        gplt = {};
        plt = {};
        
        reorder = [3 4 1 2];
        
        version = '0.3.5';
        online_ver = 'http://www.daten.tk/webhook/tags.php?owner=sebastian.pfitzner&project=sisa-scan-auswertung';
        
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0); 

        scale = [5 5 5];          % distance between the centers of two pixels in mm

        par_size = 16;  % when doing parallel processing: how many "tasks" should be sent to all threads?

        file_opened = 0;
        
        dimnames = {'x', 'y', 'z', 's'};

        disp_fit_params = 0;
        l_min; % maximum of the current parameter over all data points
        l_max; % minimum of the current parameter over all data points
        use_user_legend = false;
        user_l_min;
        user_l_max;
        
        genericname;
        openpath; % persistent, in ini
        savepath; % persistent, in ini

        points;
        data_read = false;
        fitted = false;
        cmap = 'summer';
        
        fix = {};
        gstart = [0 0 0 0];
        use_gstart = [0 0 0 0]';
        models = containers.Map(...
                 {'1. A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  '3. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'...
                  '4. A*(exp(-t/t1)+B*exp(-t/t2)+offset'...
                 },...
                 {...
                    % function, lower bounds, upper bounds, names of arguments
                    {@(A, t1, t2, offset, t) A*(exp(-t/t1)-exp(-t/t2))+offset, [0 0 0 0], [inf inf inf inf], {'A', 't1', 't2', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*exp(-t/t1)+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                  })
                    
        models_latex = containers.Map(...
                 {'1. A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  '3. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'...
                  '4. A*(exp(-t/t1)+B*exp(-t/t2)+offset'...
                 },...
                 {...
                 { '$$f(t) = A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - \exp \left(\frac{t}{\tau_2}\right) \right] + o$$', {'A', '\tau_1', '\tau_2', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts'} }...
                 { '$$f(t) = A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - \exp \left(\frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(\frac{t}{\tau_2}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 { '$$f(t) = A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - \exp \left(\frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(\frac{t}{\tau_1}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 { '$$f(t) = A\cdot \exp \left(\frac{t}{\tau_1}\right) + B\cdot \exp \left(\frac{t}{\tau_2}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 })
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
                
            %% Figure, menu, bottombar
            set(this.h.f, 'units', 'pixels',...
                        'position', [200 200 1010 700],...
                        'numbertitle', 'off',...
                        'menubar', 'none',...
                        'name', 'SISA Scan',...
                        'resize', 'on',...
                        'Color', [.95, .95, .95],...
                        'ResizeFcn', @this.resize,...
                        'DeleteFcn', @this.destroy_cb);
     
            set(this.h.menu, 'Label', 'Datei');
            uimenu(this.h.menu, 'label', 'Datei �ffnen...',...
                              'callback', @this.open_file_cb);
            uimenu(this.h.menu, 'label', 'Plot speichern',...
                              'callback', @this.save_fig);
            uimenu(this.h.menu, 'label', 'State speichern (experimentell!)',...
                              'callback', @this.save_global_state_cb);
            set(this.h.helpmenu, 'Label', '?');
            uimenu(this.h.helpmenu, 'label', '�ber',...
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
                                  'position', [0 18 1000 680]);
                             
            %% check version (only if called as a binary)
            this.check_version();
                                 
            %% limit size with java
            unsafe_limit_size(this.h.f, [900 680]);
            
            %% get numbers of cores and set par_size accordingly
            this.par_size = feature('numCores')*6;
            
            %% init
            this.resize();
%             this.set_model('1. A*(exp(-t/t1)-exp(-t/t2))+offset');
%             
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
                end
                [~, n] = fileparts(name);
            end
            

            this.genericname = n;
            
%             tmp = size(this.data);
%             this.fileinfo.size = tmp(1:4);
%             
%             this.overlays{1} = ones(tmp(1), tmp(2), tmp(3), tmp(4));
%             this.overlays{2} = zeros(tmp(1), tmp(2), tmp(3), tmp(4));
            
            this.saveini();
            
            
%             % UI stuff
%             t = keys(this.models);
%             t = this.models(t{get(this.h.drpd, 'value')});
%              
%             set(this.h.plttxt, 'visible', 'on');
%             set(this.h.fit_est, 'visible', 'on');
%             set(this.h.param, 'visible', 'on', 'string', [t{4}, 'Summe']);
%             set(this.h.ov_drpd, 'string', [t{4}, 'Summe']);
%             set(this.h.tabs, 'visible', 'on');
%             
%             this.update_infos();
%             this.set_model('1. A*(exp(-t/t1)-exp(-t/t2))+offset');
%             this.change_overlay_cond_cb();
%             this.update_sliders();
%             this.plot_array();
%             
%             this.set_scale(this.scale);
%             this.generate_overlay();
%             
%             % initialise here, so we can check whether a point is fitted or not
%             s = num2cell(size(this.est_params));
%             this.fit_chisq = nan(s{1:4});
        end
        
        function openHDF5(this)
            filepath = [this.fileinfo.path this.fileinfo.name{1}];
            % get dimensions of scan, determine if scan finished
            try
                x_step = h5readatt(filepath, '/PATH/DATA','X Step Size mm');
                y_step = h5readatt(filepath, '/PATH/DATA','Y Step Size mm');
                z_step = h5readatt(filepath, '/PATH/DATA','Z Step Size mm');
                this.scale = [x_step y_step z_step];
            catch
                % nothing. just an old file.
            end
            try
                dims = h5readatt(filepath, '/PATH/DATA', 'GRID DIMENSIONS');
                if strcmp(dims{:}, '')
                    dims = {'0/0/0'};
                end
                dims = strsplit(dims{:}, '/');

                        % offset of 1 should be fixed in labview scan software
                offset = 1;
                if str2double(dims{3}) < 0
                    offset = abs(str2double(dims{3}))+1;
                end
                this.fileinfo.size = [str2double(dims{1})+1 str2double(dims{2})+1 str2double(dims{3})+offset];
                        % end of fix

                % get attributes from file
                fin = h5readatt(filepath, '/PATH/DATA', 'LAST POINT');

                % get scanned points
                tmp = h5read(filepath, '/PATH/DATA');
                tmp = tmp.Name;
                
                if  strcmp(fin{:}, 'CHECKPOINT')
                    this.fileinfo.finished = true;
                    num_of_points = length(tmp) - 1;
                else
                    this.fileinfo.finished = false;
                    num_of_points = length(tmp);
                end
            catch exception
                % really ugly... and doesn't really work.
                display(exception);
                offset=1;
                [tmp,dims]=estimate_path(filepath);
                this.fileinfo.finished = true;
                this.fileinfo.size = [dims{1} dims{2} dims{3}];
                fin=tmp{end};
                if strcmp(fin, 'CHECKPOINT')
                    tmp = tmp(1:end-1);
                    fin = tmp{end};
                end
                num_of_points = length(tmp);
            end
            
            % read Channel Width
            try
                chanWidth=h5readatt(filepath, '/META/SISA', 'Channel Width (ns)');
                this.channel_width=single(chanWidth)/1000;
            catch
                % nothing. just an old file.
            end
            
            % get max number of samples per point (should be at /0/0/0/sisa)
            info = h5info(filepath, '/0/0/0/sisa');
            this.fileinfo.size(4) = length(info.Datasets);
            
            % create map between string and position in data
                % now reasonably fast(about 10 times faster then before), 
                % approx factor 2 possible with:
                % vec = cellfun(@(x) textscan(x,'%d/%d/%d', 'CollectOutput', 1),tmp);
                % but vec is the complete matrix and I don't know how to 
                % put this matrix into this.points()
            this.points = containers.Map;
            for i = 1:num_of_points
                vec = cell2mat(textscan(tmp{i},'%n/%n/%n')) + [1 1 offset];
                this.points(tmp{i}) = vec;
                if mod(i, 15) == 0
                    this.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
                if strcmp(tmp{i}, fin)
                    break
                end
            end

            % get number of scanned points
            this.fileinfo.np = this.points.Count;
            
            % UI stuff
            set(this.h.f, 'name', ['SISA Scan - ' this.fileinfo.name{1}]);
            
            this.readHDF5();
        end

        function readHDF5(this, varargin)
            filepath = [this.fileinfo.path this.fileinfo.name{1}];
            k = keys(this.points);
            fid = H5F.open(filepath);

            for i = 1:this.fileinfo.np
                index = this.points(k{i});
                % every point should have exactly as many samples
                % as the first point, except for the last one
%                 if i == this.fileinfo.np % get number of samples for last point
                    dataset_group= sprintf('/%s/sisa',k{i});
                    gid = H5G.open(fid,dataset_group);
                    info = H5G.get_info(gid);
%                 else % take number of samples of first point
%                     samples = this.fileinfo.size(4);
%                 end
                for j = 1:info.nlinks % iterate over all samples
                    dset_id = H5D.open(gid,sprintf('%d',j));
                    d = H5D.read(dset_id);
                    H5D.close(dset_id);
                    data(index(1), index(2), index(3), j, :) = d;
                end
                H5G.close(gid);
                if mod(i, 15) == 0
                    this.update_infos(['   |   Daten einlesen ' num2str(i) '/' num2str(this.fileinfo.np) '.']);
                end
            end
            H5F.close(fid);
            
            %% open a SiSa-tab
            SiSaMode(this, double(data));
            
            this.data_read = true;
        end
        
        function openDIFF(this)
            time_zero = 0;
            name = this.fileinfo.name;
            if iscell(name)
                for i = 1:length(name)
                    this.fileinfo.size = [length(name), 1, 1];
                    d = dlmread([this.fileinfo.path name{i}]);
                    [~, t] = max(d(1:end));
                    time_zero = (time_zero + t)/2;
                    this.data(i, 1, 1, 1,:) = d;
                end
                this.fileinfo.np = length(name);
            end
            this.t_zero = round(time_zero);
            this.x_data = ((1:length(this.data(1, 1, 1, 1, :)))-this.t_zero)'*this.channel_width;
            this.data_read = true;
            
            tmp = size(this.data);
            this.fileinfo.size = tmp(1:4);
            
            this.points = containers.Map;
            for i = 1:length(name)
                vec = [i 1 1];
                this.points(num2str(vec)) = vec;
                if mod(i, round(length(name)/10)) == 0
                    this.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
            end
        end
        
        function load_global_state(this, file)
            load(file, '-mat');
            v = str2double(strsplit(this.version));
            nv = str2double(strsplit(this_new.version));
            if sum(nv > v) > 0
                wh = warndlg({['Version des geladenen Files (' num2str(this_new.version)...
                              ') entspricht nicht der Version des aktuellen Programms'...
                              ' (' this.version '). Dies wird zu unerwartetem '...
                              'Verhalten (bspw. fehlender Funktionalit�t) f�hren!'], ...
                              ['Zum Umgehen dieses Problems sollten die zugrundeliegenden '...
                              'Daten erneut ge�ffnet und gefittet werden']}, 'Warnung', 'modal');
                pos = wh.Position;
                wh.Position = [pos(1) pos(2) pos(3)+20 pos(4)];
                wh.Children(3).Children.FontSize = 9;
                
            end
            this_new.destroy(true);
            unsafe_limit_size(this_new.h.f, [900 680]);
            close(this.h.f);
            delete(this);
        end
        
    % functions for updating the GUI
        function update_infos(this, text)
            str = [[this.fileinfo.path this.fileinfo.name{1}] '  |   Dimensionen: ' num2str(this.fileinfo.size)];

            if nargin < 2
                text = '';
                if this.fitted
                    str = [str '   |   Daten global gefittet.'];
                elseif this.data_read
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
                    wh = warndlg({['Es ist eine neue Version der Software verf�gbar ('...
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
            
            if ~isempty(this.plt)
                for i = 1:length(this.plt)
                    if isvalid(this.plt{i}) && isa(this.plt{i}, 'UIPlot')
                        delete(this.plt{i}.h.f);
                        delete(this.plt{i});
                    end
                end
            end
            if ~isempty(this.gplt)
                for i = 1:length(this.gplt)
                    if isvalid(this.gplt{i}) && isa(this.gplt{i}, 'UIGroupPlot')
                        delete(this.gplt{i}.h.f);
                        delete(this.gplt{i});
                    end
                end
            end
            if ~children_only
                delete(this.h.f);
                delete(this);
            end
        end

        function name = get_parname(this, index)
            m = this.models(this.model);
            fitpars = m{4};
            if index > length(fitpars)
                if this.disp_fit_params
                    name = 'Chi';
                else
                    name = 'Summe';
                end
                return
            end
            name = fitpars{index};
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
        end
        
        %% Callbacks
        % callback for opening a new file
        % destroys current figure and creates a new one
        function open_file_cb(this, varargin)
            this.loadini();
            % get path of file from user
            [name, filepath] = uigetfile({[this.openpath '*.h5;*.diff;*.state']}, 'Dateien ausw�hlen', 'MultiSelect', 'on');
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
                end
            end
        end
    end
end
