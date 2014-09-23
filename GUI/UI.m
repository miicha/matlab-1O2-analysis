classdef UI < handle % subclass of handle is fucking important...
    %UI 
    
    properties
        % fileinfo (dims, path, ...)
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0); 
        data;       % source data from HDF5
        params;     % fit params, size(params) = [x y z length(fitparams)]
        fit_selection;
        model = '1. A*(exp(-t/t1)-exp(-t/t2))+offset';      % fit model, should be global  
        
        channel_width = 20/1000;   % should be determined from file
                                   % needs UI element
        t_offset = 15;   % excitation is over after t_offset channels after 
                         % maximum counts were reached - needs UI element
           
        file_opened = 0;
        current_z = 1;
        current_sa = 1;
        current_param = 1;
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
                    {@(A, t1, t2, offset, t) A*(exp(-t/t1)-exp(-t/t2))+offset, [0 0 0 0], [1000 10 10 500], {'A', 't1', 't2', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {}...
                 })
                    
        h = struct();        % handles
    end

    
    methods
        % create new instance with basic controls
        function ui = UI()
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

            ui.h.bottombar = uipanel();
                ui.h.info = uicontrol(ui.h.bottombar);
            
            ui.h.pb = uicontrol();
            
            ui.h.ov_controls = uipanel();
                ui.h.ov_box = uicontrol(ui.h.ov_controls);
                ui.h.ov_drpd = uicontrol(ui.h.ov_controls);
                ui.h.ov_rel = uicontrol(ui.h.ov_controls);
                ui.h.ov_val = uicontrol(ui.h.ov_controls);
            
            ui.h.fitpanel = uipanel();
                ui.h.fittxt = uicontrol(ui.h.fitpanel);
                ui.h.drpd = uicontrol(ui.h.fitpanel);

            %% Figure, menu, bottombar
            set(ui.h.f, 'units', 'pixels',...
                        'position', [200 200 1000 600],...
                        'numbertitle', 'off',...
                        'menubar', 'none',...
                        'name', 'SISA Scan',...
                        'resize', 'on',...
                        'ResizeFcn', @ui.resize);
                    
            set(ui.h.menu, 'Label', 'Datei');
            uimenu(ui.h.menu, 'label', 'Datei öffnen...',...
                              'callback', @ui.openHDF5);
            
            set(ui.h.bottombar, 'units', 'pixels',...
                                'position', [0 0 1000 18],...
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
                             'string', 'Parameter',...
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
                           'visible', 'off');
            
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
                            'visible', 'off');

            set(ui.h.param, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', {},...
                            'position', [120 470 80 20],...
                            'FontSize', 9,...
                            'visible', 'off',...
                            'callback', @ui.update_plot);
                        
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

            %% pushbutton
            set(ui.h.pb,  'units', 'pixels',...
                          'style', 'push',...
                          'position', [10 20 70 30],...
                          'string', 'open',...
                          'callback', @ui.openHDF5);
            
            %% overlay control
            set(ui.h.ov_controls, 'units', 'pixels',...
                                  'position', [10 360 250 200]);
        
            set(ui.h.ov_box, 'units', 'pixels',...
                             'style', 'checkbox',...
                             'position', [15 100 60 30],...
                             'string', 'Overlay',...
                             'callback', @ui.toggle_overlay);
                         
            set(ui.h.ov_drpd, 'units', 'pixels',...
                             'style', 'popupmenu',...
                             'position', [35 75 60 30],...
                             'string', {''},...
                             'callback', @ui.change_overlay_cond);
                         
            set(ui.h.ov_rel, 'units', 'pixels',...
                             'style', 'popupmenu',...
                             'position', [96 75 30 30],...
                             'string', {'<', '>'},...
                             'callback', @ui.change_overlay_cond);
            
            set(ui.h.ov_val, 'units', 'pixels',...
                             'style', 'edit',...
                             'position', [127 83 60 22],...
                             'string', '123',...
                             'callback', @ui.change_overlay_cond); 
                         
        
            %% Fit-Panel:
            set(ui.h.fitpanel, 'units', 'pixels',...
                               'position', [10 50 250 300],...
                               'title', 'Fit-Optionen',...
                               'FontSize', 9);

            % select fit model
            set(ui.h.fittxt, 'units', 'pixels',...
                             'style', 'text',...
                             'position', [15 260 50 15],...
                             'HorizontalAlignment', 'left',...
                             'string', 'Fitmodell:');

            set(ui.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', keys(ui.models),...
                           'value', 1,...
                           'position', [15 245 220 15],...
                           'callback', @ui.set_model);
                   
                       
                       
            ui.resize();
        end
        
        % open HDF5 file and get infos
        function openHDF5(ui, varargin)
            % get path of file from user
            [name, path] = uigetfile('*.h5', 'HDF5-Datei auswählen');
            if ~ischar(name) || ~ischar(path) % no file selected
                return
            end
            % reset instance
            ui.reset_instance();
            
            disp('metadaten einlesen');
            
            ui.fileinfo.name = name;
            ui.fileinfo.path = [path name];
            
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
                % indices and compute the strring from that.
            ui.points = containers.Map;
            for i = 1:length(tmp) - 1
                vec = str2double(strsplit(tmp{i}, '/'))+[1 1 offset];
                ui.points(tmp{i}) = vec;
                if strcmp(tmp{i}, fin)
                    break
                end
            end
            % get number of scanned points
            ui.fileinfo.np = ui.points.Count;
            
            
            % UI stuff
            set(ui.h.f, 'name', ['SISA Scan - ' name]);
            
            ui.update_sliders();
            ui.readHDF5();
        end

        function readHDF5(ui, varargin)
            disp('daten einlesen');
            
            k = keys(ui.points);
            for i = 1:ui.fileinfo.np
                ind = ui.points(k{i});
                if ui.fileinfo.size(4) > 1 % multiple samples per point
                    % every point should have exactly as many samples
                    % as the first point, except for the last one
                    if i == ui.fileinfo.np % get number of samples for last point
                        info = h5info(ui.fileinfo.path, ['/' k{i} '/sisa']);
                        samples = length(info.Datasets); 
                    else % take number of samples of first point
                        samples = ui.fileinfo.size(4);
                    end
                    for j = 1:samples % iterate over all samples
                        ui.data(ind(1), ind(2), ind(3), j, :) = h5read(ui.fileinfo.path, ['/' k{i} '/sisa/' num2str(j)]);
                    end
                else % only one sample anyways
                    ui.data(ind(1), ind(2), ind(3), 1, :) = h5read(ui.fileinfo.path, ['/' k{i} '/sisa/1']);
                end
            end
            ui.data_read = true;
            tmp = size(ui.data);
            ui.fileinfo.size = tmp(1:4);
            ui.fit_selection = zeros(tmp(1), tmp(2), tmp(3), tmp(4));
            % UI stuff
            t = keys(ui.models);
            t = ui.models(t{get(ui.h.drpd, 'value')});
             
            set(ui.h.plttxt, 'visible', 'on');
            set(ui.h.param, 'visible', 'on',...
                            'string', t{4});
            set(ui.h.ov_drpd, 'string', t{4});
            set(ui.h.pb, 'string', 'Fit', 'callback', @ui.fit_all);
            ui.update_infos();
            ui.update_sliders();
            ui.estimate_parameters();
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
                    0;
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
        
        function update_infos(ui)
            str = [ui.fileinfo.path '  |   Dimensionen: ' num2str(ui.fileinfo.size)];
            if ui.fitted
                str = [str '   |   Daten global gefittet.'];
            elseif ui.data_read
                str = [str '   |    Daten eingelesen.'];
            end
            set(ui.h.info, 'string', str);
        end

        function plot_array(ui, varargin)
            z = ui.current_z;
            sample = ui.current_sa;
            param = ui.current_param;
            
            axes(ui.h.axes);
            plot_data = ui.params(:, :, z, sample, param);

            % plot
            % Memo to self: Don't try using HeatMaps... seriously. 
            cla
            hold on
            hmap(squeeze(plot_data(:, :))');
            hold off
            hold on
            if ui.overlay
                plot_overlay(squeeze(ui.fit_selection(:, :, z, sample))');
                hold off
            end
             
            if min(plot_data) < max(plot_data)
                axes(ui.h.legend);
                l_data = min(min(plot_data)):max(max(plot_data))/20:max(max(plot_data));
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

        function aplot_click(ui, varargin)
            switch get(ui.h.f, 'SelectionType')
                case 'normal'
                    if ~strcmp(ui.fileinfo.path, '')
                        cp = get(ui.h.axes, 'CurrentPoint');
                        cp = round(cp(1, 1:2));
                        if isKey(ui.points, [num2str(cp(1)-1) '/' num2str(cp(2)-1) '/' num2str(ui.current_z-1) ])
                            plt = UIPlot(cp, ui);
                        end
                    end
                case 'alt'
                    if ~strcmp(ui.fileinfo.path, '')
                        cp = get(ui.h.axes, 'CurrentPoint');
                        cp = round(cp(1, 1:2));
                        if isKey(ui.points, [num2str(cp(1)-1) '/' num2str(cp(2)-1) '/' num2str(ui.current_z-1) ])
                            if ui.fit_selection(cp(1), cp(2), ui.current_z, ui.current_sa) == 0
                                ui.fit_selection(cp(1), cp(2), ui.current_z, ui.current_sa) = 1;
                            else
                                ui.fit_selection(cp(1), cp(2), ui.current_z, ui.current_sa) = 0;
                            end
                        end
                    end
                    ui.plot_array();
            end
        end
        
        function estimate_parameters(ui)
            disp('parameter abschätzen');
            n = ui.models(ui.model);
            ui.params = zeros(ui.fileinfo.size(1), ui.fileinfo.size(2),...
                              ui.fileinfo.size(3), ui.fileinfo.size(4), length(n{2}));
            p = values(ui.points);
            for i = 1:ui.fileinfo.np
                for j = 1:ui.fileinfo.size(4)
                    d = ui.data(p{i}(1), p{i}(2), p{i}(3), j, :);
                    ps = UI.estimate_parameters_p(d, ui.model, ui.t_offset, ui.channel_width);
                    ui.params(p{i}(1), p{i}(2), p{i}(3), j, :) = ps;
                end
            end
            ui.fitted = false;
        end
        
        function fit_all(ui, varargin)
            max = length(find(ui.fit_selection));
            wb = waitbar(0, 'Fortschritt');
            n = 0;
            for i = 1:ui.fileinfo.size(1)
                for j = 1:ui.fileinfo.size(2)
                    for k = 1:ui.fileinfo.size(3)
                        for l = 1:ui.fileinfo.size(4)
                            if ui.fit_selection(i, j, k, l)
                                n = n + 1;
                                y = squeeze(ui.data(i, j, k, l, :));
                                x = (1:length(ui.data))'*ui.channel_width;
                                w = sqrt(y);
                                p = fitdata(ui.models(ui.model), x(10:end), y(10:end), w(10:end), ui.params(i, j, k, l, :)); 
                                ui.params(i, j, k, l, :) = p;
                                waitbar(n/max, wb, 'Fortschritt');
                            end
                        end
                    end
                end
            end
            close(wb);
            ui.fitted = true;
        end
    end
    
    methods (Access = private)
        function reset_instance(ui)
            if ui.file_opened
                clear('ui.data', 'ui.points', 'ui.params');
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
        
        function read_ini(ui)
            % stuff
        end
        
        function set_model(ui, varargin)
            t = keys(ui.models);
            str = t{get(ui.h.drpd, 'value')};
            t = ui.models(str);
             
            set(ui.h.plttxt, 'visible', 'on');
            set(ui.h.param, 'visible', 'on',...
                            'string', t{4});
            set(ui.h.ov_drpd, 'string', t{4});
            
            ui.model = str;
            ui.estimate_parameters();
        end
        
        function resize(ui, varargin)
            % resize elements in figure to match
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
            bP(3) = fP(3);
            set(ui.h.bottombar, 'Position', bP);
            
            bP = get(ui.h.info, 'Position');
            bP(3) = fP(3);
            set(ui.h.info, 'Position', bP);
        end
        
        function toggle_overlay(ui, varargin)
            ui.overlay = ~ui.overlay;
            ui.plot_array;
        end
        
        function change_overlay_cond(ui, varargin)
            switch get(ui.h.ov_rel, 'value')
                case 1
                    for i = 1:ui.fileinfo.size(1)
                        for j = 1:ui.fileinfo.size(2)
                            for k = 1:ui.fileinfo.size(3)
                                for l = 1:ui.fileinfo.size(4)
                                    if ui.params(i, j, k, l, get(ui.h.ov_drpd, 'value')) < str2double(get(ui.h.ov_val, 'string'))
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
                                    if ui.params(i, j, k, l, get(ui.h.ov_drpd, 'value')) > str2double(get(ui.h.ov_val, 'string'))
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
    end
    
    methods (Static=true)
        function [param] = estimate_parameters_p(d, model, offset, cw)
            switch model
                case '1. A*(exp(-t/t1)-exp(-t/t2))+offset'
                    [~, peak] = max(d);
                    [A, t1] = max(d((peak+offset):end)); % Amplitude, first time
                    param(1) = A;
                    param(3) = t1*cw;
                    param(4) = mean(d(end-100:end));
                    d = d-param(4);
                    A = A-param(4);
                    t2 = find(abs(d < round(A/2.7)));
                    t2 = t2(t2 > t1);
                    param(2) = (t2(1) - t1)*cw;
                case '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'
                    [~, peak] = max(d);
                    [A, t1] = max(d((peak+offset):end)); % Amplitude, first time
                    param(1) = A;
                    param(3) = t1*cw;
                    param(4) = A/4;
                    param(5) = mean(d(end-100:end));
                    d = d-param(5);
                    A = A-param(5);
                    t2 = find(abs(d < round(A/2.7)));
                    t2 = t2(t2 > t1);
                    param(2) = (t2(1) - t1)*cw;
            end
        end
    end
    
end

function plot_overlay(data)
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
