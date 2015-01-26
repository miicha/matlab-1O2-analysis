classdef UIGroupPlot
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
                          'resize', 'on',...
                          'name', 'Auswahl 1');
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
    end
    
end

