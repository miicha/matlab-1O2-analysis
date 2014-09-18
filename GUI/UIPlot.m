classdef UIPlot < handle
    %UIPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cp;
        data;
        fitted = false;
        fitparams;
        model = 1;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(cp, ui)
            if ui.fitted
                plt.fitted = true;
            end
            if ui.model
                plt.model = ui.model;
            end
            plt.cp = [cp ui.current_z];
            
            plt.h.f = figure();
            
            plt.h.axes = axes();
            
            plt.h.pb = uicontrol();
            plt.h.drpd = uicontrol();
            
            
            set(plt.h.f, 'units', 'pixels',...
                        'position', [500 200 1000 500],...
                        'numbertitle', 'off',...
                        'name',  ['SISA Scan - ' ui.fileinfo.name ' - ' num2str(plt.cp)],...
                        'resize', 'on');
                    

            set(plt.h.axes, 'units', 'pixels',...
                           'position', [50 70 900 400]);
                       
            set(plt.h.pb, 'units', 'pixels',...
                         'position', [50 15 100 30],...
                         'string', 'Fit')

            set(plt.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', keys(ui.models),...
                           'value', plt.model,...
                           'position', [170 10 200 30],...
                           'callback', @plt.set_model);
                       
            plt.plotdata(ui);
        end
        
        function getdata(plt, ui)
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                           '/' num2str(plt.cp(3)-1) '/sisa/' num2str(ui.current_sa)];
                plt.data = h5read(ui.fileinfo.path, dataset);
            else
                plt.data = squeeze(ui.data(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :));
            end
%             if ui.fitted
%                 plt.model = ui.model;
%                 plt.fitparams = ui.params(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :);
%             end
        end
        
        function plotdata(plt, ui)
            plt.getdata(ui);
            axis(plt.h.axes);
            datal = plt.data;
            x = 0:(length(datal)-1);
            x = x*ui.channel_width;
            [~, pulse] = max(datal);
            m = max(datal((pulse + 30):end));
            m = m*1.1;
            if ~plt.fitted
                plot(x, datal, '.');
                ylim([0 m]);
                xlim([0 length(datal)+1]);
            else
                subplot(3, 1, 1:2) % Daten und Fit
                plot(x, datal, '.');
                ylim([0 m]);
                xlim([0 length(datal)+1]);
                
                subplot(3, 1, 3) % Residuen
                line([0 max(x)], [0 0]);
                xlim([0 length(datal)+1]);
            end


        end
        
        function plotfit(plt)
            plt.model(x, plt.fitparams);
        end
        
        function set_model(plt, varargin)
            plt.model = get(plt.h.drpd, 'value');
        end
        
    end
    
end

