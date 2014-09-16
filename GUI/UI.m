classdef UI < handle % subclass of handle is fucking important...
    
    %UI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fileinfo = struct('path', '', 'x', 0,...
                          'y', 0, 'z', 0); % fileinfo (dims, path, ...)
        data;
        analyzed = false;
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

            % further defs:
            set(ui.h.f, 'units', 'pixels',...
                        'position', [200 200 500 500],...
                        'menubar', 'none',...
                        'numbertitle', 'off',...
                        'name', 'SISA Scan',...
                        'resize', 'off');
                      
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
                           'XTick', [], 'YTick', []);
        end
        
        % open HDF5 file and get infos
        function openHDF5(ui, varargin)
            % get path of file from user
            [name, path] = uigetfile('*.h5', 'HDF5-Datei auswählen');
            if ~ischar(name) || ~ischar(path) % no file selected
                return
            end
            ui.fileinfo.path = [path name];
            
            % get dimensions of scan, determine if scan finished
            dims = h5readatt(ui.filepath, '/PATH/DATA', 'GRID DIMENSIONS');
            dims = strsplit(dims{:}, '/');
            % offset of 1 should be fixed in labview scan software
            ui.fileinfo.x = str2double(dims{1})+1;
            ui.fileinfo.y = str2double(dims{2})+1;
            ui.fileinfo.z = str2double(dims{3})+1;
            fin = h5readatt(ui.filepath, '/PATH/DATA', 'LAST POINT');
            if  strcmp(fin{:}, 'CHECKPOINT')
                ui.fileinfo.finished = true;
            else
                ui.fileinfo.finished = false;
            end
            
            % UI stuff
            set(ui.h.text, 'string', ui.filepath);
            set(ui.h.f, 'name', ['SISA Scan - ' name]);
            set(ui.h.pb, 'string', 'analyze', 'callback', @ui.analyze);
            set(ui.h.axes, 'xlim', [0 ui.fileinfo.x], 'ylim', [0 ui.fileinfo.y]);
        end
        
        function analyze(ui, varargin)
            ui.analyzed = true;
        end
    end
    
end

