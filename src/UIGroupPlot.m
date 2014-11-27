classdef UIGroupPlot
    %UIGROUPPLOT
    
    properties
        ui
        x_pos
        y_pos
        x_size
        y_size
        data
        h = struct()           % handles
    end
    
    methods
        function gplt = UIGroupPlot(ui)
            gplt.ui = ui;
            [gplt.x_pos, gplt.y_pos] = find(ui.selection1); % size of the selection
            gplt.x_pos = gplt.x_pos - min(gplt.x_pos) + 1;
            gplt.y_pos = gplt.y_pos - min(gplt.y_pos) + 1;
            gplt.x_size = max(gplt.x_pos) - min(gplt.x_pos) + 1;
            gplt.y_size = max(gplt.y_pos) - min(gplt.y_pos) + 1;
            
            gplt.data = squeeze(ui.data(:, :, ui.current_z, ui.current_sa, :));
            
            gplt.h.f = figure();          
            
            set(gplt.h.f, 'units', 'pixels',...
                          'position', [500 200 1000 710],...
                          'numbertitle', 'off',...
                          'resize', 'on',...
                          'name', 'Auswahl 1');
            gplt.plot_selection();
        end
        
        function plot_selection(gplt)
            [indx, indy] = find(gplt.ui.selection1);
            pltdata = gplt.data(indx, indy, :);
            maxy = max(max(max(pltdata(:, :, (gplt.ui.t_zero+gplt.ui.t_offset):end))))*1.2;
            for i = 1:length(indx)
                subplot(gplt.y_size, gplt.x_size,sub2ind([gplt.x_size, gplt.y_size],...
                        gplt.x_pos(i), 1+gplt.y_size-gplt.y_pos(i)));
                plot(gplt.ui.x_data(gplt.ui.t_zero:end), squeeze(gplt.data(indx(i),...
                           indy(i), gplt.ui.t_zero:end)),'.');
                xlim([0 max(gplt.ui.x_data)])
                ylim([0 maxy])
            end
        end
    end
    
end

