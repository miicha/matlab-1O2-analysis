classdef UIGroupPlot < handle
    %UIGROUPPLOT
    
    properties
        ui
        x_pos
        y_pos
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
            [gplt.x_pos, gplt.y_pos] = find(ui.overlays{ui.current_ov}); % size of the selection
            gplt.x_pos = gplt.x_pos - min(gplt.x_pos) + 1;
            gplt.y_pos = gplt.y_pos - min(gplt.y_pos) + 1;
            gplt.x_size = max(gplt.x_pos) - min(gplt.x_pos) + 1;
            gplt.y_size = max(gplt.y_pos) - min(gplt.y_pos) + 1;
            
            gplt.data = squeeze(ui.data(:, :, ui.current_z, ui.current_sa, :));
            gplt.params = squeeze(ui.fit_params(:, :, ui.current_z, ui.current_sa, :));
            tmp = gplt.ui.models(gplt.ui.model);
            gplt.model_fun =  tmp{1};
            
            
            
            gplt.h.f = figure(); 
            
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
            [indx, indy] = find(gplt.ui.overlays{gplt.ui.current_ov});
            pltdata = gplt.data(indx, indy, :);
 
            maxy = max(max(max(pltdata(:, :, (gplt.ui.t_zero+gplt.ui.t_offset):end))))*1.2;
            for i = 1:length(indx)
                if ndims(gplt.params)==3
                    p = num2cell(squeeze(gplt.params(indx(i), indy(i), :)));
                else
                    p = num2cell(squeeze(gplt.params(indx(i), :)));
                end
                fitdata = gplt.model_fun(p{:}, gplt.ui.x_data(gplt.ui.t_zero:end));
                
                subplot(gplt.y_size, gplt.x_size,sub2ind([gplt.x_size, gplt.y_size],...
                        gplt.x_pos(i), 1+gplt.y_size-gplt.y_pos(i)));
                plot(gplt.ui.x_data(gplt.ui.t_zero:end), squeeze(gplt.data(indx(i),...
                           indy(i), gplt.ui.t_zero:end)),'.');
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
    end
    
end

