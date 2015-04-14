classdef UIGroupPlot < handle
    %UIGROUPPLOT
    
    properties
        ui
        x_pos
        y_pos
        x_data
        y_data
        x_size
        y_size
        data
        params
        model_fun
        h = struct()           % handles
    end
    
    methods
        function gplt = UIGroupPlot(ui)
            gplt.ui = ui;
            [gplt.x_pos, gplt.y_pos] = find(ui.overlay_data); % size of the selection
            if ui.curr_dims(1) < ui.curr_dims(2)
                gplt.x_data = gplt.x_pos;
                gplt.y_data = gplt.y_pos;
            else
                gplt.y_data = gplt.x_pos;
                gplt.x_data = gplt.y_pos;
            end
            
            gplt.x_pos = gplt.x_pos - min(gplt.x_pos) + 1;
            gplt.y_pos = gplt.y_pos - min(gplt.y_pos) + 1;
            gplt.x_size = max(gplt.x_pos) - min(gplt.x_pos) + 1;
            gplt.y_size = max(gplt.y_pos) - min(gplt.y_pos) + 1;
            
            gplt.data = squeeze(ui.data(ui.ind{:}, :));
            gplt.params = squeeze(ui.fit_params(ui.ind{:}, :));
            tmp = gplt.ui.models(gplt.ui.model);
            gplt.model_fun =  tmp{1};
            
            
            gplt.h.f = figure(); 
            gplt.h.s = {};
            set(gplt.h.f, 'units', 'pixels',...
                          'position', [500 200 1000 710],...
                          'numbertitle', 'off',...
                          'menubar', 'none',...
                          'toolbar', 'figure',...
                          'resize', 'on',...
                          'name', 'Auswahl 1');
                      
            toolbar_pushtools = findall(findall(gplt.h.f, 'Type', 'uitoolbar'),...
                                                         'Type', 'uipushtool');
            toolbar_toggletools = findall(findall(gplt.h.f, 'Type', 'uitoolbar'),...
                                                    'Type', 'uitoggletool');

            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOn'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOff'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.PrintFigure'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.FileOpen'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.NewFigure'), 'visible', 'off');
            
            set(findall(toolbar_pushtools, 'Tag', 'Standard.SaveFigure'),...
                                                  'clickedcallback', @gplt.save_fig_cb);
            
            set(findall(toolbar_toggletools, 'Tag', 'Annotation.InsertLegend'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Annotation.InsertColorbar'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'DataManager.Linking'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Exploration.Rotate'), 'visible', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Standard.EditPlot'), 'visible', 'off',...
                                                                          'Separator', 'off');
                      
            gplt.plot_selection();
        end
        
        function plot_selection(gplt)
            indx = gplt.x_data;
            indy = gplt.y_data;
%             size(gplt.data)
            pltdata = gplt.data(indx, indy, :);
 
            maxy = max(max(max(pltdata(:, :, (gplt.ui.t_zero+gplt.ui.t_offset):end))))*1.2;
            for i = 1:length(indx)
                if ndims(gplt.params)==3
                    p = num2cell(squeeze(gplt.params(indx(i), indy(i), :)));
                else
                    p = num2cell(squeeze(gplt.params(indx(i), :)));
                end
                fitdata = gplt.model_fun(p{:}, gplt.ui.x_data(gplt.ui.t_zero:end));
                
                gplt.h.s{i} = subplot(gplt.y_size, gplt.x_size,sub2ind([gplt.x_size, gplt.y_size],...
                        gplt.x_pos(i), 1+gplt.y_size-gplt.y_pos(i)));
                plot(gplt.ui.x_data(gplt.ui.t_zero:end), squeeze(gplt.data(indx(i),...
                           indy(i), gplt.ui.t_zero:end)),'.');
                       
                set(gplt.h.s{i}, 'xtick', [], 'ytick', [], 'ButtonDownFcn', @gplt.click_cb, 'Tag', num2str(i));
                
                hold on
                plot(gplt.ui.x_data(gplt.ui.t_zero:end), fitdata, 'r-');
                hold off
                xlim([0 max(gplt.ui.x_data)])
                ylim([0 maxy])
            end
        end
        
        function save_fig_cb(gplt, varargin)
            [name, path] = uiputfile('*.pdf', 'Plot als PDF speichern', fullfile(gplt.ui.savepath, gplt.ui.genericname));
            if name == 0
                return
            end
            gplt.ui.set_savepath(path);
            path = fullfile(path, name);
            set(gplt.h.f, 'toolbar', 'none');
            tmp = get(gplt.h.f, 'position');
            x_pix = tmp(3);
            y_pix = tmp(4);
            
            set(gplt.h.f, 'PaperUnits', 'points');
            set(gplt.h.f, 'PaperSize', [x_pix+80 y_pix+80]/1.5);
            set(gplt.h.f, 'PaperPosition', [0 0 x_pix+80 y_pix+80]/1.5);
            print(gplt.h.f, '-dpdf', '-r600', path);
            set(gplt.h.f, 'toolbar', 'figure');
        end
        
        function click_cb(gplt, varargin)
            t = str2double(varargin{1}.Tag);
            gplt.x_data(t);
            
            index{gplt.ui.curr_dims(1)} = gplt.x_data(t); % x ->
            index{gplt.ui.curr_dims(2)} = gplt.y_data(t); % y ^
            index{gplt.ui.curr_dims(3)} = gplt.ui.ind{gplt.ui.curr_dims(3)};
            index{gplt.ui.curr_dims(4)} = gplt.ui.ind{gplt.ui.curr_dims(4)};

            for i = 1:4
                if index{i} > gplt.ui.fileinfo.size(i)
                    index{i} = gplt.ui.fileinfo.size(i);
                elseif index{i} <= 0
                     index{i} = 1;
                end
            end
            
            i = length(gplt.ui.plt);
            gplt.ui.plt{i+1} = UIPlot([index{:}], gplt.ui);
        end % mouseclick on plot
    end
    
end

