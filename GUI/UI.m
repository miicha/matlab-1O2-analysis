classdef UI < handle % subclass of handle is fucking important...
    
    %UI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % fileinfo (dims, path, ...)
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0); 
        data;       % source data from HDF5
        params;     % fit params, size(params) = [x y z length(fitparams)]
        model;      % fit model, should be global
        
        file_opened = 0;
        current_z = 1;
        current_sa = 1;
        points;
        data_read = false;
        fitted = false;
        
        h = struct();                      % handles
    end

    
    methods
        % create new instance with basic controls
        function ui = UI()
            %init:
            ui.h.f = figure();
            
            ui.h.axes = axes();
            
            ui.h.pb = uicontrol();
            ui.h.menu = uimenu();
            ui.h.text = uicontrol();
            
            ui.h.zslider = uicontrol();
            ui.h.zbox = uicontrol();
            
            ui.h.saslider = uicontrol();
            ui.h.sabox = uicontrol();
            
            ui.h.param = uicontrol();
            
            ui.h.fitpanel = uipanel();
            ui.h.drpd = uicontrol(ui.h.fitpanel);

            % further defs:
            set(ui.h.f, 'units', 'pixels',...
                        'position', [200 200 1000 500],...
                        'numbertitle', 'off',...
                        'name', 'SISA Scan',...
                        'resize', 'on');
                    
            set(ui.h.text, 'units', 'pixels',...
                           'style', 'text',...
                           'string', ui.fileinfo.path,...
                           'position', [100 10 200 30]);
    
            % open HDF5 file
            set(ui.h.pb,  'units', 'pixels',...
                          'style', 'push',...
                          'position', [10 20 70 30],...
                          'string', 'open',...
                          'callback', @ui.openHDF5);

            set(ui.h.menu, 'Label', 'Datei');
            uimenu(ui.h.menu, 'label', 'Datei öffnen...',...
                              'callback', @ui.openHDF5);

            set(ui.h.axes, 'units', 'pixels',...
                           'position', [40 80 400 400],...
                           'xtick', [], 'ytick', [],...
                           'ButtonDownFcn', @ui.aplot_click);
                       
            set(ui.h.zslider, 'units', 'pixels',...
                               'style', 'slider',...
                               'position', [450 80 20 370],...
                               'value', 1,...
                               'visible', 'off',...
                               'callback', @ui.update_plot);
                           
            set(ui.h.zbox, 'units', 'pixels',...
                           'style', 'edit',...
                           'string', '1',...
                           'position', [450 460 20, 20],...
                           'callback', @ui.update_plot,...
                           'visible', 'off');
            
            set(ui.h.saslider, 'units', 'pixels',...
                               'style', 'slider',...
                               'position', [15 80 20 370],... 
                               'value', 1,...
                               'visible', 'off',...
                               'callback', @ui.update_plot);
                           
            set(ui.h.sabox, 'units', 'pixels',...
                           'style', 'edit',...
                           'string', '1',...
                           'position', [15 460 20, 20],...
                           'callback', @ui.update_plot,...
                           'visible', 'off');
                       
                       
            set(ui.h.param, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', {'bl', 'bli', 'blu'},...
                           'position', [40 60 100 15],...
                           'visible', 'off',...
                           'callback', @ui.update_plot);
            
            % Fit-Panel:
            set(ui.h.fitpanel, 'units', 'pixels',...
                               'position', [480 100 300 300],...
                               'title', 'Fit-Optionen')

            % select fit model
            set(ui.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', {'bl', 'bli', 'blu'},...
                           'position', [40 250 100 15]);
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
            ui.points = containers.Map;
            for i = 1:length(tmp) - 1
                vec = str2double(strsplit(tmp{i}, '/'))+[1 1 offset];
                if strcmp(tmp{i}, fin) && ui.fileinfo.size(4) == 1
                    break;
                else
                    ui.points(tmp{i}) = vec;
                end
            end

            % get number of scanned points
            ui.fileinfo.np = length(ui.points);
            
            % UI stuff
            set(ui.h.text, 'string', ui.fileinfo.path);
            set(ui.h.f, 'name', ['SISA Scan - ' name]);
            set(ui.h.pb, 'string', 'Einlesen', 'callback', @ui.readHDF5);
            set(ui.h.axes, 'xlim', [.5 ui.fileinfo.size(1)+.5], 'ylim', [.5 ui.fileinfo.size(2)+.5]);
            % handle z-scans
            if ui.fileinfo.size(3) > 1 
                set(ui.h.zslider, 'min', 1, 'max', ui.fileinfo.size(3),...
                                  'visible', 'on',...
                                  'SliderStep', [1 1]/(ui.fileinfo.size(3)-1));
                set(ui.h.zbox, 'visible', 'on');
            else 
                set(ui.h.zbox, 'visible', 'off');
                set(ui.h.zslider, 'visible', 'off');
            end
            % handle multiple samples
            if ui.fileinfo.size(4) > 1 
                set(ui.h.saslider, 'min', 1, 'max', ui.fileinfo.size(4),...
                                  'visible', 'on',...
                                  'SliderStep', [1 1]/(ui.fileinfo.size(4)-1));
                set(ui.h.sabox, 'visible', 'on');
            else 
                set(ui.h.sabox, 'visible', 'off');
                set(ui.h.saslider, 'visible', 'off');
            end
            
            ui.plot_array(1);
        end
        
        function readHDF5(ui, varargin)
            k = keys(ui.points);
            for i = 1:ui.fileinfo.np
                ind = ui.points(k{i});
                if ui.fileinfo.size(4) > 1
                    info = h5info(ui.fileinfo.path, ['/' k{i} '/sisa']);
                    samples = length(info.Datasets);
                else 
                    samples = 1;
                end
                for j = 1:samples
                    ui.data(ind(1), ind(2), ind(3), j, :) = h5read(ui.fileinfo.path, ['/' k{i} '/sisa/' num2str(j)]);
                end
            end
        end
        
        function plot_array(ui, z, sample, param ,varargin)
            axis(ui.h.axes);
            if ~ui.data_read
%                 plot_data = zeros(ui.fileinfo.size(1), ui.fileinfo.size(2),...
%                                   ui.fileinfo.size(3),  ui.fileinfo.size(4));
                
                % if the poin has been measured, set to 1; else to 0
                vals = values(ui.points);
                for i = 1:ui.fileinfo.np
                    tmp = vals{i};
                    plot_data(tmp(1), tmp(2), tmp(3)) = 1;
                end
                % Memo to self: Don't try using HeatMaps... seriously.        
            else
                plot_data = ui.data(:, :, z, sample, param);
            end
            
            % plot
            hold on
            hmap(plot_data(:,:)');
            hold off
        end
        
        function update_plot(ui, varargin)
            switch varargin{1}
                case ui.h.zslider
                    z = get(ui.h.zslider, 'value');
                    
                    sample = ui.current_sa;
                    
                case ui.h.zbox
                    z = round(str2double(get(ui.h.zbox, 'string')));
                    if z > ui.fileinfo.size(3)
                        z = ui.fileinfo.size(3);
                    elseif z <= 0
                        z = 1;
                    end
                    sample = ui.current_sa;
                    
                case ui.h.saslider
                    sample = get(ui.h.saslider, 'value');
                    z = ui.current_z;
                    
                case ui.h.sabox
                    sample = round(str2double(get(ui.h.sabox, 'string')));
                    if sample > ui.fileinfo.size(4)
                        sample = ui.fileinfo.size(4);
                    elseif sample <= 0
                        sample = 1;
                    end
                    z = ui.current_z;
                    
                otherwise
                    0;
            end
            set(ui.h.zslider, 'value', z);
            set(ui.h.zbox, 'string', num2str(z));
            set(ui.h.saslider, 'value', sample);
            set(ui.h.sabox, 'string', num2str(sample));
            ui.current_z = z;
            ui.current_sa = sample;
            plot_array(ui, z, sample); % needs input from ui.h.param
        end
        
        function aplot_click(ui, varargin)
            if ~strcmp(ui.fileinfo.path, '')
                cp = get(ui.h.axes, 'CurrentPoint');
                cp = round(cp(1, 1:2));
                if isKey(ui.points, [num2str(cp(1)-1) '/' num2str(cp(2)-1) '/' num2str(ui.current_z-1) ])
                    plt = UIPlot(cp, ui);
                end
            end
        end
        
    end
    
    methods (Access = private)
        function reset_instance(ui)
            if ui.file_opened
                clear('ui.data', 'ui.params', 'ui.model');
                ui.fileinfo = struct('path', '', 'size', [0 0 0],...
                                     'name', '', 'np', 0); 
                ui.file_opened = 0;
                ui.current_z = 1;
                ui.data_read = false;
                ui.fitted = false;  
                ui.file_opened = 1;
                ui.points = containers.Map;
            end
        end
    end
    
end

function hmap(data, cmap)
    if nargin < 2
        cmap = 'summer';
    end
    im = imagesc(data);
    set(im, 'HitTest', 'off');
    colormap(cmap);
    [max_x, max_y] = size(data');
    hold on
    for i = 1:max_x-1
        for j = 1:max_y-1
            line([0 max_x]+.5,[j j]+.5, 'color', [.7 .7 .7]);
            line([i i]+.5, [0 max_y]+.5, 'color', [.7 .7 .7]);
        end
    end
    hold off
end

