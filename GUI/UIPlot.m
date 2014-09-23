classdef UIPlot < handle
    %UIPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cp;                     % current point
        data;
        res;
        sp;                     % starting point for fit
        n_param;
        params;
        fitted = false;
        cfit;
        model;
        t_offset;
        channel_width;
        
        models;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(cp, ui)
            %% get data from main UI
            plt.models = ui.models;
            if ui.fitted
                plt.fitted = true;
            end
            if ui.model
                plt.model = plt.models(ui.model);
            end
            plt.cp = [cp ui.current_z ui.current_sa];
            plt.getdata(ui);
            tmp = ui.models(ui.model);
            plt.n_param = length(tmp{2});
            plt.t_offset = ui.t_offset;
            plt.channel_width = ui.channel_width;
            
            plt.params = ui.params(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :);

            %% initialize UI objects
            
            plt.h.f = figure();
            
            plt.h.axes = axes();
            plt.h.res = axes();
            
            plt.h.fitpanel = uipanel();
                plt.h.drpd = uicontrol(plt.h.fitpanel);
                plt.h.pb = uicontrol(plt.h.fitpanel);
                plt.h.param = uipanel(plt.h.fitpanel);

            
            %% figure
            
            set(plt.h.f, 'units', 'pixels',...
                         'position', [500 200 1000 710],...
                         'numbertitle', 'off',...
                         'name',  ['SISA Scan - ' ui.fileinfo.name ' - ' num2str(plt.cp)],...
                         'resize', 'on',...
                         'ResizeFcn', @plt.resize);
                  
            %% plot

            set(plt.h.axes, 'units', 'pixels',...
                            'position', [50 260 900 400]);
                        
            set(plt.h.res, 'units', 'pixels',...
                            'position', [50 110 900 130]);
            
            %% fitoptions
            set(plt.h.fitpanel, 'units', 'pixels',...
                                'position', [50 10 900 75]);
            
            set(plt.h.drpd, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', keys(ui.models),...
                            'value', 1,...
                            'position', [10 5 200 27],...
                            'FontSize', 9,...
                            'callback', @plt.set_model);
                        
            set(plt.h.pb, 'units', 'pixels',...
                          'position', [10 35 100 30],...
                          'string', 'Fit',...
                          'FontSize', 9,...
                          'callback', @plt.fit);
                        
            set(plt.h.param, 'units', 'pixels',...
                             'position', [250 10 600 55]);
                         
            plt.h.pe = cell(1, 1);
            plt.h.pd = cell(1, 1);
            plt.h.pc = cell(1, 1);
                      
            %% draw plot
            plt.plotdata();
            plt.generate_param();
        end
        
        function getdata(plt, ui)
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                           '/' num2str(plt.cp(3)-1) '/sisa/' num2str(ui.current_sa)];
                plt.data(1, :) = h5read(ui.fileinfo.path, dataset);
            else
                plt.data(1, :) = squeeze(ui.data(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :));
            end
%             if ui.fitted
%                 plt.model = ui.model;
%                 plt.fitparams = ui.params(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :);
%             end
            x = 0:(length(plt.data(1, :))-1);
            plt.data(2, :) = x*ui.channel_width;
        end
        
        function plotdata(plt)
            datal = plt.data(1, :);
            x = plt.data(2, :);
            [~, pulse] = max(datal);
            m = max(datal((pulse + 30):end));
            m = m*1.1;
            axes(plt.h.axes);
            plot(x, datal, '.');
            ylim([0 m]);
            xlim([0 max(x)]);
            if plt.fitted
                plt.plotfit();
            end
        end
        
        function plotfit(plt)
            x = plt.data(2, :);
            p = num2cell(plt.params);
            fitdata = plt.model{1}(p{:}, x);
            
            axes(plt.h.axes);
            hold on
            plot(x,  fitdata, 'r');
            hold off
            axes(plt.h.res);
            plot(x, (plt.data(1,:)-fitdata)./sqrt(plt.data(1,:)), 'b.');
            hold on
            line([0 max(x)], [0 0], 'Color', 'r');
            xlim([0 max(x)]);
            ylim([-20 20]);
            hold off
        end
        
        function fit(plt, varargin)
            x = plt.data(2, :)';
            y = plt.data(1, :)';
            x = x(10:end)+15*plt.channel_width;
            y = y(10:end);
            w = sqrt(y)+1;
%             plt.set_model();
            
            [p] = fitdata(plt.model, x, y, w, plt.params);
            
            plt.params = p;
%             plt.res = res;
            plt.fitted = true;
            plt.plotdata();
            plt.plotfit();
            for i = 1:plt.n_param
                str = sprintf('%1.2f', p(i));
                set(plt.h.pe{i}, 'string', str);
            end
        end
        
        function set_model(plt, varargin)
            m = keys(plt.models);
            n = m{get(plt.h.drpd, 'value')};
            tmp = plt.models(n);
            plt.n_param = length(tmp{2});
            plt.model = plt.models(n);
            plt.params = UI.estimate_parameters_p(plt.data(1, :), n, plt.t_offset, plt.channel_width);
            plt.generate_param();
        end
        
        function resize(plt, varargin)
            fP = get(plt.h.f, 'position');
            
            aP = get(plt.h.axes, 'position');
            aP(3:4) = fP(3:4) - aP(1:2) - 50;
            set(plt.h.axes, 'position', aP);
            
            aP = get(plt.h.res, 'position');
            aP(3) = fP(3) - aP(1) - 50;
            set(plt.h.res, 'position', aP);
            
            fpP = get(plt.h.fitpanel, 'position');
            fpP(3) = fP(3) - fpP(1) - 50;
            set(plt.h.fitpanel, 'position', fpP);
        end
        
        function generate_param(plt)
            for i = 1:length(plt.h.pe)
                delete(plt.h.pe{i});
                set(plt.h.pd{i}, 'visible', 'off');
                delete(plt.h.pd{i});
                delete(plt.h.pc{i});
                clear('plt.h.pe', 'plt.h.pd', 'plt.h.pc');
            end           
            plt.h.pe = cell(plt.n_param, 1);
            plt.h.pd = cell(plt.n_param, 1);
            plt.h.pc = cell(plt.n_param, 1);
            for i = 1:plt.n_param
                 plt.h.pe{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'edit',...
                                                      'string', sprintf('%1.2f', plt.params(i)),...
                                                      'position', [10+(i-1)*100 25 45 20]);
                 plt.h.pd{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', '+-',...
                                                      'HorizontalAlignment', 'left',...
                                                      'position', [55+(i-1)*100 25 30 20]); 
                 plt.h.pc{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'checkbox',...
                                                      'string', 'fix',...
                                                      'position', [10+(i-1)*100 5 50 15]); 
            end
            if plt.n_param == 0
                set(plt.h.param, 'visible', 'off');
            else
                set(plt.h.param, 'visible', 'on');
                pP = get(plt.h.param, 'position');
                pP(3) = 45+(plt.n_param-1)*100+45+10;
                set(plt.h.param, 'position', pP);
            end
            plt.n_param = plt.n_param;
        end
    end
    
end

