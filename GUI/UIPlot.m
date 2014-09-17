classdef UIPlot < handle
    %UIPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cp;
        data;
        fitparams;
        model;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(cp, ui)
            plt.cp = [cp ui.current_z];
            
            plt.h.f = figure();
            plt.h.axes = axes();
            
            
            set(plt.h.f, 'units', 'pixels',...
                        'position', [500 200 1000 500],...
                        'numbertitle', 'off',...
                        'name',  ['SISA Scan - ' ui.fileinfo.name ' - ' num2str(plt.cp)],...
                        'resize', 'on');
                    
            set(ui.h.axes, 'units', 'pixels',...
                           'position', [40 80 400 400]);
                       
                       
            plt.plotdata(ui);
        end
        
        function getdata(plt, ui)
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                           '/' num2str(plt.cp(3)-1) '/sisa/' num2str(ui.current_sa)];
                plt.data = h5read(ui.fileinfo.path, dataset);
            else
                plt.data = ui.data(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa);
            end
            if ui.fitted
                plt.model = ui.model;
                plt.fitparams = ui.params(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :);
            end
        end
        
        function plotdata(plt, ui)
            plt.getdata(ui);
            axis(plt.h.axes);
            plot(plt.data);
        end
        
        function plotfit(plt)
            plt.model(x, plt.fitparams);
        end
        
    end
    
end

