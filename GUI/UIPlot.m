classdef UIPlot < handle
    %UIPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cp;
        data;
        model;
        h = struct(); 
    end
    
    methods
        function plt = UIPlot(cp, ui)
            plt.cp = [cp ui.current_z];
            
            plt.h.f = figure();
            plt.h.axes = axes();
            
            
            set(plt.h.f, 'units', 'pixels',...
                        'position', [200 200 1000 500],...
                        'menubar', 'none',...
                        'numbertitle', 'off',...
                        'name',  ['SISA Scan - ' ui.fileinfo.name ' - ' num2str(plt.cp)],...
                        'resize', 'on');
                    
            set(ui.h.axes, 'units', 'pixels',...
                           'position', [40 80 400 400]);
                       
                       
            plt.getdata(ui);
            axis(plt.h.axes);
            plot(plt.data);
        end
        
        function getdata(plt, ui)
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                                            '/' num2str(plt.cp(3)-1) '/sisa/1'];
                plt.data = h5read(ui.fileinfo.path, dataset);
            else
                % something's missing here :)
            end
        end
    end
    
end

