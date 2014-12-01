classdef UI < handle % subclass of handle is fucking important...
    %UI 
    
    properties
        %%%%%%% for debugging
        gplt
        plt
        %%%%%%%        
        
        % fileinfo (dims, path, ...)
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0); 
        data;       % source data from HDF5
        x_data;          % time data
        fit_params;     % fit params, size(params) = [x y z length(fitparams)]
        fit_params_err;
        fit_chisq;
        est_params;     % estimated parameters
        fit_selection;
        selection1;
        cancel_f = false;
        model = '1. A*(exp(-t/t1)-exp(-t/t2))+offset';      % fit model, should be global  
        
        channel_width = 20/1000;   % should be determined from file
                                   % needs UI element
        t_offset = 25;   % excitation is over after t_offset channels after 
                         % maximum counts were reached - needs UI element
        t_zero = 0;      % channel in which the maximum of the excitation was reached
           
        file_opened = 0;
        current_z = 1;
        current_sa = 1;
        current_param = 1;
        disp_fit_params = 0;
        overlay = 0;
        points;
        data_read = false;
        fitted = false;
        
        models = containers.Map(...
                 {'1. A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  '3.'},...
                 {...
                    % function, lower bounds, upper bounds, names of arguments
                    {@(A, t1, t2, offset, t) A*(exp(-t/t1)-exp(-t/t2))+offset, [1 0.1 0.1 1], [500 20 10 50], {'A', 't1', 't2', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset, [1 0.1 0.1 1 1], [500 20 10 300 50], {'A', 't1', 't2', 'B', 'offset'} }...
                    {}...
                 })
                    
        h = struct();        % handles
    end

    
    methods
        % create new instance with basic controls
        function ui = UI(path)
            %% initialize all UI objects:
            ui.h.f = figure();
            ui.h.menu = uimenu();

            ui.h.plotpanel = uipanel();
                ui.h.axes = axes('parent', ui.h.plotpanel);
                ui.h.legend = axes('parent', ui.h.plotpanel);
                ui.h.tick_min = uicontrol(ui.h.plotpanel);
                ui.h.tick_max = uicontrol(ui.h.plotpanel);
                ui.h.plttxt = uicontrol(ui.h.plotpanel);
                ui.h.zslider = uicontrol(ui.h.plotpanel);
                ui.h.zbox = uicontrol(ui.h.plotpanel);
                ui.h.saslider = uicontrol(ui.h.plotpanel);
                ui.h.sabox = uicontrol(ui.h.plotpanel);
                ui.h.param = uicontrol(ui.h.plotpanel);
                ui.h.fit_est = uibuttongroup(ui.h.plotpanel);
                    ui.h.fit_par = uicontrol();
                    ui.h.est_par = uicontrol();

            ui.h.bottombar = uipanel();
                ui.h.info = uicontrol(ui.h.bottombar);
                       
            ui.h.tabs = uitabgroup();
                ui.h.fit_tab = uitab(ui.h.tabs);
                    ui.h.fitpanel = uipanel(ui.h.fit_tab);
                        ui.h.fittxt = uicontrol(ui.h.fitpanel);
                        ui.h.drpd = uicontrol(ui.h.fitpanel);
                        ui.h.bounds = uipanel(ui.h.fitpanel);
                            ui.h.bounds_txt1 = uicontrol(ui.h.bounds);
                            ui.h.bounds_txt2 = uicontrol(ui.h.bounds);
                    ui.h.fit = uicontrol(ui.h.fit_tab);
                    ui.h.ov_controls = uipanel(ui.h.fit_tab);
                        ui.h.ov_switch = uicontrol(ui.h.ov_controls);
                        ui.h.ov_drpd = uicontrol(ui.h.ov_controls);
                        ui.h.ov_rel = uicontrol(ui.h.ov_controls);
                        ui.h.ov_val = uicontrol(ui.h.ov_controls);
                    
                ui.h.sel_tab = uitab(ui.h.tabs);
                        ui.h.sel_controls = uipanel(ui.h.sel_tab);
                        ui.h.sel_switch = uicontrol(ui.h.sel_controls);
                        ui.h.sel_btn_plot = uicontrol(ui.h.sel_controls);
                        ui.h.sel_btn_exp = uicontrol(ui.h.sel_controls);
            

            %% Figure, menu, bottombar
            set(ui.h.f, 'units', 'pixels',...
                        'position', [200 200 1000 600],...
                        'numbertitle', 'off',...
                        'menubar', 'none',...
                        'name', 'SISA Scan',...
                        'resize', 'on',...
                        'Color', [.95, .95, .95],...
                        'ResizeFcn', @ui.resize);
                    
            set(ui.h.menu, 'Label', 'Datei');
            uimenu(ui.h.menu, 'label', 'Datei öffnen...',...
                              'callback', @ui.open_file);
            
            set(ui.h.bottombar, 'units', 'pixels',...
                                'position', [-1 0 1000 18],...
                                'BorderType', 'EtchedOut');
                            
            set(ui.h.info, 'units', 'pixels',...
                           'style', 'text',...
                           'string', ui.fileinfo.path,...
                           'HorizontalAlignment', 'left',...
                           'BackgroundColor', get(ui.h.f, 'Color'),...
                           'ForegroundColor', [.3 .3 .3],...
                           'FontSize', 9,...
                           'position', [0 0 1000 15]);
            
            %% Plot
            set(ui.h.plotpanel, 'units', 'pixels',...
                                'position', [270 28 500 500],...
                                'BackgroundColor', [.85 .85 .85]);
            
            set(ui.h.axes, 'units', 'pixels',...
                           'position', [50 50 400 400],...
                           'xtick', [], 'ytick', [],...
                           'Color', get(ui.h.plotpanel, 'BackgroundColor'),...
                           'XColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                           'YColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                           'ButtonDownFcn', @ui.aplot_click);
                       
                                 
            set(ui.h.legend, 'units', 'pixels',...
                             'position', [50 22 400 20],...
                             'xtick', [], 'ytick', [],...
                             'XColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                             'YColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                             'visible', 'off');
                                     
            set(ui.h.plttxt, 'units', 'pixels',...
                             'style', 'text',...
                             'string', 'Parameter:',...
                             'position', [50 452 100 20],...
                             'HorizontalAlignment', 'left',...
                             'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                             'FontSize', 9,...
                             'visible', 'off');
                                                       
            set(ui.h.zslider, 'units', 'pixels',...
                              'style', 'slider',...
                              'position', [460 50 20 370],...
                              'value', 1,...
                              'visible', 'off',...
                              'callback', @ui.update_plot);
                           
            set(ui.h.zbox, 'units', 'pixels',...
                           'style', 'edit',...
                           'string', '1',...
                           'position', [460 430 20, 20],...
                           'callback', @ui.update_plot,...
                           'visible', 'off',...
                           'BackgroundColor', [1 1 1]);
            
            set(ui.h.saslider, 'units', 'pixels',...
                               'style', 'slider',...
                               'position', [20 50 20 370],... 
                               'value', 1,...
                               'visible', 'off',...
                               'callback', @ui.update_plot);

            set(ui.h.sabox, 'units', 'pixels',...
                            'style', 'edit',...
                            'string', '1',...
                            'position', [20 460 20 20],...
                            'callback', @ui.update_plot,...
                            'visible', 'off',...
                            'BackgroundColor', [1 1 1]);

            set(ui.h.param, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', {},...
                            'position', [120 470 80 20],...
                            'FontSize', 9,...
                            'visible', 'off',...
                            'callback', @ui.update_plot,...
                            'BackgroundColor', [1 1 1]);
                        
            set(ui.h.tick_min, 'units', 'pixels',...
                               'style', 'text',...
                               'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                               'visible', 'off',...
                               'FontSize', 9,...
                               'string', '1',...
                               'horizontalAlignment', 'right',...
                               'position', [12 22 35 17]);
                           
            set(ui.h.tick_max, 'units', 'pixels',...
                               'style', 'text',...
                               'visible', 'off',...
                               'FontSize', 9,...
                               'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                               'string', '100',...
                               'horizontalAlignment', 'left',...
                               'position', [460 22 35 17]);  
                           
            set(ui.h.est_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                              'string', 'abgeschätzt',...
                              'horizontalAlignment', 'left',...
                              'position', [10 1 100 17],...
                              'parent', ui.h.fit_est);
                           
            set(ui.h.fit_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                              'string', 'gefittet',...
                              'horizontalAlignment', 'left',...
                              'position', [115 1 60 17],...
                              'parent', ui.h.fit_est,...
                              'visible', 'off');
                          
            set(ui.h.fit_est, 'units', 'pixels',...
                              'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                              'BorderType', 'none',...
                              'SelectionChangeFcn', @ui.change_par_source,...
                              'position', [220 445 200 21],...
                              'visible', 'off');          
                      
            %% tabs for switching selection modes
            set(ui.h.tabs, 'units', 'pixels',...
                               'position', [10 28 250 550],...
                               'visible', 'off');
                           
            %% Fitten
            set(ui.h.fit_tab, 'Title', 'Fitten');
            
            set(ui.h.fit,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 2 80 28],...
                           'string', 'global Fitten',...
                           'BackgroundColor', [.8 .8 .8],...
                           'callback', @ui.fit_all);
                       
            %% overlay control
            set(ui.h.ov_controls, 'units', 'pixels',...
                                  'position', [2 360 243 100]);

            set(ui.h.ov_switch, 'units', 'pixels',...
                                'style', 'checkbox',...
                                'position', [15 50 60 30],...
                                'string', 'Overlay',...
                                'callback', @ui.toggle_overlay);
                         
            set(ui.h.ov_drpd, 'units', 'pixels',...
                             'style', 'popupmenu',...
                             'position', [35 25 60 30],...
                             'string', {''},...
                             'callback', @ui.change_overlay_cond,...
                             'BackgroundColor', [1 1 1]);
                         
            set(ui.h.ov_rel, 'units', 'pixels',...
                             'style', 'popupmenu',...
                             'position', [96 25 30 30],...
                             'string', {'<', '>'},...
                             'callback', @ui.change_overlay_cond,...
                             'BackgroundColor', [1 1 1]);
            
            set(ui.h.ov_val, 'units', 'pixels',...
                             'style', 'edit',...
                             'position', [127 33 60 22],...
                             'string', '',...
                             'callback', @ui.change_overlay_cond,...
                             'BackgroundColor', [1 1 1]); 
                         
            %% Fit-Panel:
            set(ui.h.fitpanel, 'units', 'pixels',...
                               'position', [2 35 243 260],...
                               'title', 'Fit-Optionen',...
                               'FontSize', 9);

            % select fit model
            set(ui.h.fittxt, 'units', 'pixels',...
                             'style', 'text',...
                             'position', [15 220 50 15],...
                             'HorizontalAlignment', 'left',...
                             'string', 'Fitmodell:');

            set(ui.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', keys(ui.models),...
                           'value', 1,...
                           'position', [15 205 220 15],...
                           'callback', @ui.set_model,...
                           'BackgroundColor', [1 1 1]);
                       
            set(ui.h.bounds, 'units', 'pixels',...
                             'position', [15 10 185 180],...
                             'title', 'Grenzen',...
                             'FontSize', 9);
                          
            set(ui.h.bounds_txt1, 'units', 'pixels',...
                                  'position', [55 145 50 15],...
                                  'style', 'text',...
                                  'string', 'untere',...
                                  'horizontalAlignment', 'left',...
                                  'FontSize', 9);
                              
            set(ui.h.bounds_txt2, 'units', 'pixels',...
                                  'position', [115 145 50 15],...
                                  'style', 'text',...
                                  'string', 'obere',...
                                  'horizontalAlignment', 'left',...
                                  'FontSize', 9);
            ui.h.lb = cell(1, 1);
            ui.h.ub = cell(1, 1);
            ui.h.n = cell(1, 1);

            %% interpretation
            set(ui.h.sel_tab, 'Title', 'Auswertung');
            
            set(ui.h.sel_controls, 'units', 'pixels',...
                                   'position', [2 360 243 100])
        
            set(ui.h.sel_switch, 'units', 'pixels',...
                             'style', 'checkbox',...
                             'position', [15 50 100 30],...
                             'string', 'Auswahl 1',...
                             'callback', @ui.toggle_overlay);
                         
             set(ui.h.sel_btn_plot, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 15 50 20],...
                             'string', 'Plotten',...
                             'callback', @ui.plot_selection);
             
             set(ui.h.sel_btn_exp, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [65 15 70 20],...
                             'string', 'Exportieren');
                         
            %% init
            
            ui.resize();
            ui.set_model();
            
            if nargin == 1
                pause(.1);
                ui.openHDF5(path);
            end
        end
        
        function open_file(ui, varargin)
            if ischar(varargin{1})
                r = regexp(varargin{1}, '[/|\\]\w*\.h5');
                if ~isempty(r)
                    path = varargin{1}(1:r(end));
                    name = varargin{1}((r(end)+1):end);
                end
            else
                % get path of file from user
                [name, path] = uigetfile({'*.h5;*.diff'}, 'HDF5-Datei auswählen', 'MultiSelect', 'on');
                if (~ischar(name) && ~iscell(name)) || ~ischar(path) % no file selected
                    return
                end
            end
            
            ui.reset_instance();

            if ~iscell(name) && regexp(name, '*?.h5')
                ui.fileinfo.name = name;
                ui.fileinfo.path = [path name];
                ui.openHDF5();
            else
                ui.fileinfo.name = name;
                ui.fileinfo.path = path;
                ui.openDIFF();
            end
                
        end
        
        function openHDF5(ui)
            % get dimensions of scan, determine if scan finished
            dims = h5readatt(ui.fileinfo.path, '/PATH/DATA', 'GRID DIMENSIONS');
            dims = strsplit(dims{:}, '/');
            
                    % offset of 1 should be fixed in labview scan software
            offset = 1;
            if str2double(dims{3}) < 0
                offset = abs(str2double(dims{3}))+1;
            end
            ui.fileinfo.size = [str2double(dims{1})+1 str2double(dims{2})+1 str2double(dims{3})+offset];
                    % end of fix
            % get max number of samples per point (should be at /0/0/0/sisa)
            info = h5info(ui.fileinfo.path, '/0/0/0/sisa');
            ui.fileinfo.size(4) = length(info.Datasets);
            
            % read Channel Width
            try
                chanWidth=h5readatt(ui.fileinfo.path, '/META/SISA', 'Channel Width (ns)');
                ui.channel_width=single(chanWidth)/1000;
            end
            
            % get attributes from file
            fin = h5readatt(ui.fileinfo.path, '/PATH/DATA', 'LAST POINT');
            if  strcmp(fin{:}, 'CHECKPOINT')
                ui.fileinfo.finished = true;
            else
                ui.fileinfo.finished = false;
            end
            
            % get scanned points
            tmp = h5read(ui.fileinfo.path, '/PATH/DATA');
            tmp = tmp.Name;
            % create map between string and position in data
                % Performance problem here. Not using a map and computing
                % the position in the vector from the string on the fly is
                % almost as slow (-.1s). Might try to only save a matrix of
                % indices and compute the string from that.
            ui.points = containers.Map;
            for i = 1:length(tmp) - 1
                vec = str2double(strsplit(tmp{i}, '/'))+[1 1 offset];
                ui.points(tmp{i}) = vec;
                if mod(i, round((length(tmp) - 1)/10)) == 0
                    ui.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
                if strcmp(tmp{i}, fin)
                    break
                end
            end

            % get number of scanned points
            ui.fileinfo.np = ui.points.Count;
            
            % UI stuff
            set(ui.h.f, 'name', ['SISA Scan - ' ui.fileinfo.name]);
            
            ui.update_sliders();
            ui.readHDF5();
        end

        function openDIFF(ui)
            time_zero = 0;
            name = ui.fileinfo.name;
            if iscell(name)
                for i = 1:length(name)
                    ui.fileinfo.size = [length(name), 1, 1];
                    d = dlmread([ui.fileinfo.path name{i}]);
                    [~, t] = max(d(1:end));
                    time_zero = (time_zero + t)/2;
                    ui.data(i, 1, 1, 1,:) = d;
                end
                ui.fileinfo.np = length(name);
            end
            ui.t_zero = round(time_zero);
            ui.x_data = ((1:length(ui.data(1, 1, 1, 1, :)))-ui.t_zero)'*ui.channel_width;
            ui.data_read = true;
            
            tmp = size(ui.data);
            ui.fileinfo.size = tmp(1:4);
            
            ui.points = containers.Map;
            for i = 1:length(name)
                vec = [i 1 1];
                ui.points(num2str(vec)) = vec;
                if mod(i, round(length(name)/10)) == 0
                    ui.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
            end
            
            ui.fit_selection = ones(tmp(1), tmp(2), tmp(3), tmp(4));
            
            % UI stuff
            t = keys(ui.models);
            t = ui.models(t{get(ui.h.drpd, 'value')});
             
            set(ui.h.plttxt, 'visible', 'on');
            set(ui.h.fit_est, 'visible', 'on');
            set(ui.h.param, 'visible', 'on',...
                            'string', t{4});
            set(ui.h.ov_drpd, 'string', t{4});
            set(ui.h.tabs, 'visible', 'on')
            ui.update_infos();
            ui.update_sliders();
            ui.set_model();
            ui.plot_array();
        end
        
        function readHDF5(ui, varargin)
            time_zero = 0;
            k = keys(ui.points);
            for i = 1:ui.fileinfo.np
                ind = ui.points(k{i});
                % every point should have exactly as many samples
                % as the first point, except for the last one
%                 if i == ui.fileinfo.np % get number of samples for last point
                    info = h5info(ui.fileinfo.path, ['/' k{i} '/sisa']);
                    samples = length(info.Datasets); 
%                 else % take number of samples of first point
%                     samples = ui.fileinfo.size(4);
%                 end
                for j = 1:samples % iterate over all samples
                    d = h5read(ui.fileinfo.path, ['/' k{i} '/sisa/' num2str(j)]);
                    ui.data(ind(1), ind(2), ind(3), j, :) = d;
                    [~, t] = max(d(1:end));
                    time_zero = (time_zero + t)/2;
                end
                if mod(i, round(ui.fileinfo.np/20)) == 0
                    ui.update_infos(['   |   Daten einlesen ' num2str(i) '/' num2str(ui.fileinfo.np) '.']);
                end
            end
            
            ui.t_zero = round(time_zero);
            ui.x_data = ((1:length(ui.data(1, 1, 1, 1, :)))-ui.t_zero)'*ui.channel_width;
            ui.data_read = true;
            tmp = size(ui.data);
            ui.fileinfo.size = tmp(1:4);
            
            ui.fit_selection = ones(tmp(1), tmp(2), tmp(3), tmp(4));
            ui.selection1 = zeros(tmp(1), tmp(2), tmp(3), tmp(4));
            
            % UI stuff
            t = keys(ui.models);
            t = ui.models(t{get(ui.h.drpd, 'value')});
             
            set(ui.h.plttxt, 'visible', 'on');
            set(ui.h.fit_est, 'visible', 'on');
            set(ui.h.param, 'visible', 'on',...
                            'string', t{4});
            set(ui.h.ov_drpd, 'string', t{4});
            set(ui.h.tabs, 'visible', 'on');
            
            ui.update_infos();
            ui.update_sliders();
            ui.set_model();
            ui.change_overlay_cond();
            ui.plot_array();
        end

        function update_plot(ui, varargin)
            switch varargin{1}
                case ui.h.zslider
                    z = round(get(ui.h.zslider, 'value'));
                    sample = ui.current_sa;
                    p = ui.current_param;
                    
                case ui.h.zbox
                    z = round(str2double(get(ui.h.zbox, 'string')));
                    if z > ui.fileinfo.size(3)
                        z = ui.fileinfo.size(3);
                    elseif z <= 0
                        z = 1;
                    end
                    sample = ui.current_sa;
                    p = ui.current_param;
                    
                case ui.h.saslider
                    sample = round(get(ui.h.saslider, 'value'));
                    z = ui.current_z;
                    p = ui.current_param;
                    
                case ui.h.sabox
                    sample = round(str2double(get(ui.h.sabox, 'string')));
                    if sample > ui.fileinfo.size(4)
                        sample = ui.fileinfo.size(4);
                    elseif sample <= 0
                        sample = 1;
                    end
                    z = ui.current_z;
                    p = ui.current_param;
                    
                case ui.h.param
                    p = get(ui.h.param, 'value');
                    z = ui.current_z;
                    sample = ui.current_sa;
                otherwise
            end
            if z > ui.fileinfo.size(3)
                z = ui.fileinfo.size(3);
            end
            if z > ui.fileinfo.size(4)
                sample = ui.fileinfo.size(4);
            end
            
            set(ui.h.zslider, 'value', z);
            set(ui.h.zbox, 'string', num2str(z));
            set(ui.h.saslider, 'value', sample);
            set(ui.h.sabox, 'string', num2str(sample));
            set(ui.h.param, 'value', p);
            ui.current_z = z;
            ui.current_sa = sample;
            ui.current_param = p;
            ui.plot_array();
        end

        function update_sliders(ui)
            set(ui.h.axes, 'xlim', [.5 ui.fileinfo.size(1)+.5], 'ylim', [.5 ui.fileinfo.size(2)+.5]);
            % handle z-scans
            if ui.fileinfo.size(3) > 1 
                set(ui.h.zslider, 'min', 1, 'max', ui.fileinfo.size(3),...
                                  'visible', 'on',...
                                  'SliderStep', [1 5]/(ui.fileinfo.size(3)-1));
                set(ui.h.zbox, 'visible', 'on');
            else 
                set(ui.h.zbox, 'visible', 'off');
                set(ui.h.zslider, 'visible', 'off');
            end
            % handle multiple samples
            if ui.fileinfo.size(4) > 1 
                set(ui.h.saslider, 'min', 1, 'max', ui.fileinfo.size(4),...
                                  'visible', 'on',...
                                  'SliderStep', [1 5]/(ui.fileinfo.size(4)-1));
                set(ui.h.sabox, 'visible', 'on');
            else 
                set(ui.h.sabox, 'visible', 'off');
                set(ui.h.saslider, 'visible', 'off');
            end
        end
        
        function update_infos(ui, text)
            pause(.0001);                    
            if nargin < 2
                text = '';
            end
            str = [ui.fileinfo.path '  |   Dimensionen: ' num2str(ui.fileinfo.size)];
            if ui.fitted
                str = [str '   |   Daten global gefittet.'];
            elseif ui.data_read
                str = [str '   |    Daten eingelesen.'];
            end
            set(ui.h.info, 'string', [str text]);
        end

        function plot_array(ui, varargin)
            z = ui.current_z;
            sample = ui.current_sa;
            param = ui.current_param;
            if ui.disp_fit_params
                if param > length(ui.est_params(1, 1, 1, 1, :))
                    plot_data = ui.fit_chisq;
                else
                    plot_data = ui.fit_params(:, :, z, sample, param);
                end
            else
                if param > length(ui.est_params(1, 1, 1, 1, :))
                    param = 1;
                end
                plot_data = ui.est_params(:, :, z, sample, param);
            end
            % plotting:
            % Memo to self: Don't try using HeatMaps... seriously.
            if gcf == ui.h.f  % don't plot when figure is in background
                set(ui.h.f, 'CurrentAxes', ui.h.axes); 
                cla
                hold on
                hmap(squeeze(plot_data(:, :))');
                if ui.overlay
                    switch ui.overlay
                        case 'fit'
                            plot_overlay(squeeze(ui.fit_selection(:, :, z, sample))');
                        case '1'
                            plot_overlay(squeeze(ui.selection1(:, :, z, sample))');
                    end
                end
                hold off

                if min(min(plot_data(~isnan(plot_data)))) < max(max(plot_data(~isnan(plot_data))))
                    set(ui.h.f, 'CurrentAxes', ui.h.legend);
                    l_data = min(min(plot_data)):(max(max(plot_data))-min(min(plot_data)))/20:max(max(plot_data));
                    cla
                    hold on
                    hmap(l_data);
                    hold off
                    xlim([.5 length(l_data)+.5])
                    set(ui.h.legend, 'visible', 'on');
                    set(ui.h.tick_min, 'visible', 'on', 'string', num2str(l_data(1),4));
                    set(ui.h.tick_max, 'visible', 'on', 'string', num2str(l_data(end),4));
                end
            end
        end
        
        function estimate_parameters(ui)
            n = ui.models(ui.model);
            ui.est_params = zeros(ui.fileinfo.size(1), ui.fileinfo.size(2),...
                              ui.fileinfo.size(3), ui.fileinfo.size(4), length(n{2}));
            ub = zeros(length(n{2}), 1);
            lb = ones(length(n{2}), 1)*100;
            p = values(ui.points);
            for i = 1:ui.fileinfo.np
                for j = 1:ui.fileinfo.size(4)
                    d = ui.data(p{i}(1), p{i}(2), p{i}(3), j, :);
                    ps = UI.estimate_parameters_p(d, ui.model, ui.t_zero, ui.t_offset, ui.channel_width);
                    ui.est_params(p{i}(1), p{i}(2), p{i}(3), j, :) = ps;
                    if mod(i, round(ui.fileinfo.np/20)) == 0
                        ui.update_infos(['   |   Parameter abschätzen ' num2str(i) '/' num2str(ui.fileinfo.np) '.']);
                    end
                    for k = 1:length(ps) % find biggest and smallest params
                        if ps(k) > ub(k)
                            ub(k) = ps(k);
                        end
                        if ps(k) < lb(k) && ps(k) ~= 0
                            lb(k) = ps(k);
                        end
                    end
                end
            end
            ui.fitted = false;
            ui.fit_chisq = nan(ui.fileinfo.size(1), ui.fileinfo.size(2),...
                                 ui.fileinfo.size(3), ui.fileinfo.size(4));
                             
            % set bounds from estimated parameters
            tmp = ui.models(ui.model);
            tmp{3} = ub*1.5;
            tmp{2} = lb*0.5;
            ui.models(ui.model) = tmp;
            ui.generate_bounds();
            
            ui.update_infos();
            set(ui.h.ov_val, 'string', mean(mean(mean(mean(squeeze(ui.est_params(:, :, :, :, 1)))))));
        end
        
        function fit_all(ui, varargin)
            if get(ui.h.ov_switch, 'value')
                ma = length(find(ui.fit_selection));
            else
                ma = prod(ui.fileinfo.size);
            end
            t = keys(ui.models);
            t = ui.models(t{get(ui.h.drpd, 'value')});
            set(ui.h.param, 'visible', 'on',...
                            'string', {t{4}{:}, 'Chi^2'});
            
            ov = get(ui.h.ov_switch, 'value');      
            
            % set cancel button:
            set(ui.h.fit, 'string', 'Abbrechen', 'callback', @ui.cancel_fit);

            ui.fit_params = zeros(size(ui.est_params));
            ui.fit_params_err = zeros(size(ui.est_params));
            n = 0;
            for i = 1:ui.fileinfo.size(1)
                for j = 1:ui.fileinfo.size(2)
                    for k = 1:ui.fileinfo.size(3)
                        for l = 1:ui.fileinfo.size(4)
                            if ui.fit_selection(i, j, k, l) || ~ov
                                n = n + 1;
                                y = squeeze(ui.data(i, j, k, l, (ui.t_offset+ui.t_zero):end));
                                x = ui.x_data((ui.t_zero + ui.t_offset):end);
                                w = sqrt(y);
                                w(w == 0) = 1;
                                [p, p_err, chi] = fitdata(ui.models(ui.model), x, y, w, ui.est_params(i, j, k, l, :)); 
                                ui.fit_params(i, j, k, l, :) = p;
                                ui.fit_params_err(i, j, k, l, :) = p_err;
                                ui.fit_chisq(i, j, k, l) = chi;
                                ui.update_infos(['   |   Fitte ' num2str(n) '/' num2str(ma) '.'])
                            end
                            if n == 1
                                set(ui.h.fit_par, 'visible', 'on');
                            end
                            if ui.disp_fit_params
                                ui.plot_array();
                            end
                            if ui.cancel_f
                                ui.cancel_f = false;
                                return
                            end
                        end
                    end
                end
            end
            
            set(ui.h.fit, 'string', 'Fit', 'callback', @ui.fit_all);
            ui.fitted = true;
            ui.update_infos();
        end
        
        function set_model(ui, varargin)
            t = keys(ui.models);
            if isKey(ui.models, varargin)
                str = varargin{:};
                set(ui.h.drpd, 'value', find(strcmp(t, str)));
            else
                str = t{get(ui.h.drpd, 'value')};
            end
            t = ui.models(str);
            ui.fit_params = nan(ui.fileinfo.size(1), ui.fileinfo.size(2),...
                                ui.fileinfo.size(3), ui.fileinfo.size(4), length(t{4}));
            ui.model = str;
            ui.generate_bounds();
            if ui.data_read
                ui.estimate_parameters();
                set(ui.h.plttxt, 'visible', 'on');
                set(ui.h.param, 'visible', 'on',...
                                'string', t{4});
                ui.plot_array();
            end
            set(ui.h.ov_drpd, 'string', t{4});
        end
    end
    
    methods (Access = private)
        function aplot_click(ui, varargin)
            switch get(ui.h.f, 'SelectionType')
                case 'normal'
                    if ~strcmp(ui.fileinfo.path, '')
                        cp = get(ui.h.axes, 'CurrentPoint');
                        cp = round(cp(1, 1:2));
                        if sum(ui.data(cp(1), cp(2), ui.current_z, ui.current_sa, :))
                            ui.plt = UIPlot(cp, ui);
                        end
                    end
                case 'alt'
                    if ~strcmp(ui.fileinfo.path, '')
                        cp = get(ui.h.axes, 'CurrentPoint');
                        cp = round(cp(1, 1:2));
                        if sum(ui.data(cp(1), cp(2), ui.current_z, ui.current_sa, :))
                            switch ui.overlay
                                case 'fit'
                                    ui.fit_selection(cp(1), cp(2), ui.current_z, ui.current_sa) = ...
                                       ~ui.fit_selection(cp(1), cp(2), ui.current_z, ui.current_sa);
                                case '1'
                                    ui.selection1(cp(1), cp(2), ui.current_z, ui.current_sa) = ...
                                       ~ui.selection1(cp(1), cp(2), ui.current_z, ui.current_sa);
                            end
                        end
                    end
                    ui.plot_array();
            end
        end
        
        function change_par_source(ui, varargin)
            ov = get(varargin{2}.OldValue, 'String');
            nv = get(varargin{2}.NewValue, 'String');
            if ~strcmp(ov, nv)
                if strcmp(nv, get(ui.h.fit_par, 'string'))
                    ui.disp_fit_params = true;
                else
                    ui.disp_fit_params = false;
                end
                ui.plot_array();
            end
        end
        
        function reset_instance(ui)
            if ui.file_opened
                clear('ui.data', 'ui.points');
                ui.fileinfo = struct('path', '', 'size', [0 0 0],...
                                     'name', '', 'np', 0); 
                ui.file_opened = 0;
                ui.current_z = 1;
                ui.current_sa = 1;
                ui.current_param = 1;
                ui.data_read = false;
                ui.fitted = false;  
                ui.model = 1;      % fit model, should be global  
                ui.channel_width = 1;   % should be determines from file
                set(ui.h.legend, 'visible', 'off');
                delete(allchild(ui.h.legend));
            end
            ui.file_opened = 1;
        end
                
        function set_bounds(ui, varargin)
            m = ui.models(ui.model);
            for i = 1:length(m{4});
                m{2}(i) = str2double(get(ui.h.lb{i}, 'string'));
                m{3}(i) = str2double(get(ui.h.ub{i}, 'string'));
            end
            ui.models(ui.model) = m;
        end
        
        function resize(ui, varargin)
            % resize elements in figure to match window size
            fP = get(ui.h.f, 'Position');
            
            pP = get(ui.h.plotpanel, 'Position');
            pP(3:4) = [(fP(3)-pP(1))-10 (fP(4)-pP(2))-10];
            set(ui.h.plotpanel, 'Position', pP);
            
            aP = get(ui.h.axes, 'Position');
            aP(3:4) = [(pP(3)-aP(1))-50 (pP(4)-aP(2))-50];
            set(ui.h.axes, 'Position', aP);
            
            tmp = get(ui.h.legend, 'position');
            tmp(3) = aP(3);
            set(ui.h.legend, 'position', tmp);
            
            tmp = get(ui.h.tick_max, 'position');
            tmp(1) = aP(3) + aP(1) + 2;
            set(ui.h.tick_max, 'position', tmp);
            
            tmp = get(ui.h.plttxt, 'position');
            tmp(2) = aP(2)+aP(4)+2;
            set(ui.h.plttxt, 'position', tmp);
            
            tmp = get(ui.h.param, 'position');
            tmp(2) = aP(2)+aP(4)+6;
            set(ui.h.param, 'position', tmp);
            
            tmp = get(ui.h.fit_est, 'position');
            tmp(2) = aP(2)+aP(4)+6;
            set(ui.h.fit_est, 'position', tmp);
            
            tmp = get(ui.h.zslider, 'position');
            tmp(1) = aP(1) + aP(3) + 10;
            tmp(4) = aP(4) - 30;
            set(ui.h.zslider, 'position', tmp);
            
            tmp = get(ui.h.zbox, 'position');
            tmp(1) = aP(1) + aP(3) + 10;
            tmp(2) = aP(1) + aP(4) - 20;
            set(ui.h.zbox, 'position', tmp);
            
            tmp = get(ui.h.saslider, 'position');
            tmp(4) = aP(4) - 30;
            set(ui.h.saslider, 'position', tmp);
            
            tmp = get(ui.h.sabox, 'position');
            tmp(2) = aP(1) + aP(4) - 20;
            set(ui.h.sabox, 'position', tmp);
                        
            bP = get(ui.h.bottombar, 'Position');
            bP(3) = fP(3)+3;
            set(ui.h.bottombar, 'Position', bP);
            
            bP = get(ui.h.info, 'Position');
            bP(3) = fP(3);
            set(ui.h.info, 'Position', bP);
            
            tP = get(ui.h.tabs, 'Position');
            tP(4) = pP(4);
            set(ui.h.tabs, 'Position', tP);
            
            tmp = get(ui.h.ov_controls, 'Position');
            tmp(2) = tP(4) - tmp(4) - 40;
            set(ui.h.ov_controls, 'Position', tmp);
            set(ui.h.sel_controls, 'Position', tmp);
        end
        
        function toggle_overlay(ui, varargin)
            switch varargin{1} 
                case ui.h.ov_switch
                    ov = 'fit';
                    set(ui.h.sel_switch, 'Value', 0);
                case ui.h.sel_switch
                    ov = '1';
                    set(ui.h.ov_switch, 'Value', 0);
            end
            if ui.overlay == ov
                ui.overlay = false;
            else
                ui.overlay = ov;
            end
            
            ui.plot_array();
        end
        
        function change_overlay_cond(ui, varargin)
            switch get(ui.h.ov_rel, 'value')
                case 1
                    for i = 1:ui.fileinfo.size(1)
                        for j = 1:ui.fileinfo.size(2)
                            for k = 1:ui.fileinfo.size(3)
                                for l = 1:ui.fileinfo.size(4)
                                    if ui.est_params(i, j, k, l, get(ui.h.ov_drpd, 'value')) < str2double(get(ui.h.ov_val, 'string'))
                                        ui.fit_selection(i, j, k, l) = 0;
                                    else
                                        ui.fit_selection(i, j, k, l) = 1;
                                    end
                                end
                            end
                        end
                    end
                case 2
                    for i = 1:ui.fileinfo.size(1)
                        for j = 1:ui.fileinfo.size(2)
                            for k = 1:ui.fileinfo.size(3)
                                for l = 1:ui.fileinfo.size(4)
                                    if ui.est_params(i, j, k, l, get(ui.h.ov_drpd, 'value')) > str2double(get(ui.h.ov_val, 'string'))
                                        ui.fit_selection(i, j, k, l) = 0;
                                    else
                                        ui.fit_selection(i, j, k, l) = 1;
                                    end
                                end
                            end
                        end
                    end
            end
            ui.plot_array();
        end
        
        function generate_bounds(ui)
            m = ui.models(ui.model);
            n = length(m{4});

            for i = 1:length(ui.h.lb)
                delete(ui.h.lb{i});
                delete(ui.h.ub{i});
                delete(ui.h.n{i});
            end 
            ui.h.lb = cell(n, 1);
            ui.h.ub = cell(n, 1);
            ui.h.n = cell(n, 1);
            for i = 1:n
                ui.h.lb{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', m{2}(i)),...
                                                    'position', [55 155-i*23-10 45 20],...
                                                    'callback', @ui.set_bounds,...
                                                    'BackgroundColor', [1 1 1]);
                ui.h.ub{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', m{3}(i)),...
                                                    'position', [115 155-i*23-10 45 20],...
                                                    'callback', @ui.set_bounds,...
                                                    'BackgroundColor', [1 1 1]);
                ui.h.n{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', m{4}{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [15 155-i*23-14 40 20]);
            end
        end
        
        function cancel_fit(ui, varargin)
            ui.cancel_f = true;
            
            set(ui.h.fit, 'string', 'Fit', 'callback', @ui.fit_all);
        end
        
        function plot_selection(ui, varargin)
            ui.gplt = UIGroupPlot(ui);
        end
    end
    
    methods (Static=true)
        function [param] = estimate_parameters_p(d, model, t_zero, t_offset, cw)
            switch model
                case '1. A*(exp(-t/t1)-exp(-t/t2))+offset'
                    [A, t1] = max(d((t_zero + t_offset):end)); % Amplitude, first time
                    param(1) = A;
                    param(3) = t1*cw;
                    param(4) = mean(d(end-100:end));
                    d = d-param(4);
                    A = A-param(4);
                    t2 = find(abs(d <= round(A/2.7)));
                    t2 = t2(t2 > t1);
                    param(2) = (t2(1) - t1)*cw;
                case '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'
                    [A, t1] = max(d((t_zero + t_offset):end)); % Amplitude, first time
                    param(1) = A;
                    param(3) = t1*cw;
                    param(4) = A/4;
                    param(5) = mean(d(end-100:end));
                    d = d-param(5);
                    A = A-param(5);
                    t2 = find(abs(d <= round(A/2.7)));
                    t2 = t2(t2 > t1);
                    param(2) = (t2(1) - t1)*cw;
            end
        end
    end
    
end

function plot_overlay(data)
    opengl software;
    [m, n] = size(data);
    image = ones(m, n, 3);
    image(:, :, 1) = (image(:, :, 1) - data);
    for i = 2:3
        image(:, :, i) = (image(:, :, i) - data)*0.2;
    end
    im = imagesc(image);
    set(im, 'HitTest', 'off',...
            'AlphaData', image(:,:,1)*.4);
end

function hmap(data, grid, cmap)
    if nargin < 3
        cmap = 'summer';
        if nargin < 2
            grid = false;
        end
    end
    im = imagesc(data);
    set(im, 'HitTest', 'off');
    colormap(cmap);
    if grid
        [max_x, max_y] = size(data');
        hold on
        for i = 1:max_x-1
            for j = 1:max_y-1
                line([0 max_x]+.5,[j j]+.5, 'color', [.6 .6 .6], 'HitTest', 'off');
                line([i i]+.5, [0 max_y]+.5, 'color', [.6 .6 .6], 'HitTest', 'off');
            end
        end
        hold off
    end
end
