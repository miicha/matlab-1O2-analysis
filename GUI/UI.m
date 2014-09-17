classdef UI < handle % subclass of handle is fucking important...
    
    %UI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % fileinfo (dims, path, ...)
        fileinfo = struct('path', '', 'size', [0 0 0],...
                          'name', '', 'np', 0); 
        data;       % source data from HDF5
        params;     % fit params
        model;      % fit model
        current_z = 1;
        data_read = false;
        h = struct();                      % handles
    end

    
    methods
        % create new instance with basic controls
        function ui = UI()
            %init:
            ui.h.f = figure();
            
            ui.h.pb = uicontrol();
            ui.h.menu = uimenu();
            ui.h.axes = axes();
            ui.h.text = uicontrol();
            ui.h.zslider = uicontrol();
            ui.h.zbox = uicontrol();
            ui.h.param = uicontrol();
            
            ui.h.fitpanel = uipanel();
            ui.h.drpd = uicontrol(ui.h.fitpanel);

            % further defs:
            set(ui.h.f, 'units', 'pixels',...
                        'position', [200 200 1000 500],...
                        'menubar', 'none',...
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
                          'position', [10 10 70 30],...
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
                               'visible', 'off',...
                               'callback', @ui.update_plot);
                           
            set(ui.h.zbox, 'units', 'pixels',...
                           'style', 'edit',...
                           'position', [450 460 20, 20],...
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
            ui.fileinfo.name = name;
            ui.fileinfo.path = [path name];
            
            % get dimensions of scan, determine if scan finished
            dims = h5readatt(ui.fileinfo.path, '/PATH/DATA', 'GRID DIMENSIONS');
            dims = strsplit(dims{:}, '/');
            % offset of 1 should be fixed in labview scan software
            ui.fileinfo.size = [str2double(dims{1})+1 str2double(dims{2})+1 str2double(dims{3})+1];
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
            % get number of scanned points
            ui.fileinfo.np = length(tmp) - 1;
            ui.fileinfo.points = tmp(1:end - 1);

            
            % UI stuff
            set(ui.h.text, 'string', ui.fileinfo.path);
            set(ui.h.f, 'name', ['SISA Scan - ' name]);
            set(ui.h.pb, 'string', 'Einlesen', 'callback', @ui.readHDF5);
            set(ui.h.axes, 'xlim', [.5 ui.fileinfo.size(1)+.5], 'ylim', [.5 ui.fileinfo.size(2)+.5]);
            if ui.fileinfo.size(3) > 1 
                set(ui.h.zslider, 'min', 1, 'max', ui.fileinfo.size(3),...
                                  'value', 1, 'visible', 'on',...
                                  'SliderStep', [1 1]/(ui.fileinfo.size(3)-1));
                set(ui.h.zbox, 'visible', 'on', 'string', '0');
            else 
                set(ui.h.zbox, 'visible', 'off');
                set(ui.h.zslider, 'visible', 'off');
            end
            ui.plot_array(1, 1);
        end
        
        function readHDF5(ui, varargin)
            ui.data = 1;
        end
        
        function plot_array(ui, z, param ,varargin)
            axis(ui.h.axes);
            if ~ui.data_read
                plot_data = zeros(ui.fileinfo.size(1), ui.fileinfo.size(2), ui.fileinfo.size(3));
                % if the poin has been measured, set to 1; else to 0
                % doesn't work yet: PATH contains all points, but those after
                % LAST POINT weren't measured
                for i = 1:ui.fileinfo.np
                    tmp = str2double(strsplit(ui.fileinfo.points{i}, '/'))+1;
                    plot_data(tmp(1), tmp(2), tmp(3)) = 1;
                end
                % Memo to self: Don't try using HeatMaps... seriously.
                % debug
%                 plot_data(1, 1, z) = 0;
%                 plot_data(end, end, z) = 2;
%                 plot_data(end, 1, z) = 3;
                % debug         
            else
                plot_data = ui.data(:, :, z, param);
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
                case ui.h.zbox
                    z = round(str2double(get(ui.h.zbox, 'string')));
                    if z > ui.fileinfo.size(3)
                        z = ui.fileinfo.size(3);
                    elseif z < 0
                        z = 0;
                    end
                otherwise
                    0;
            end
            set(ui.h.zslider, 'value', z);
            set(ui.h.zbox, 'string', num2str(z));
            ui.current_z = z;
            plot_array(ui, z); % needs input from ui.h.param
        end
        
        function aplot_click(ui, varargin)
            if ~strcmp(ui.fileinfo.path, '')
                cp = get(ui.h.axes, 'CurrentPoint');
                cp = round(cp(1, 1:2));
                plt = UIPlot(cp, ui);
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

