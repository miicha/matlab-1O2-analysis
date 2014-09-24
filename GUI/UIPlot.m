classdef UIPlot < handle
    %UIPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cp;                     % current point
        data;
        x_data;
        res;
        n_param;
        est_params;             % estimated parameters
        fit_params;             % fitted parameters
        fitted = false;
        cfit;
        model;
        t_offset;
        t_zero;
        channel_width;
        
        models;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(cp, ui)
            %% get data from main UI
            plt.models = ui.models;
            if ui.model
                plt.model = plt.models(ui.model);
            end
            plt.cp = [cp ui.current_z ui.current_sa];
            plt.getdata(ui);
            tmp = ui.models(ui.model);
            plt.n_param = length(tmp{2});
            plt.t_offset = ui.t_offset;
            plt.t_zero = ui.t_zero;

            plt.channel_width = ui.channel_width;
            
            plt.est_params = squeeze(ui.est_params(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));
            plt.fit_params = squeeze(ui.fit_params(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));
            
            if ~isnan(plt.fit_params)
                plt.fitted = true;
            end
            model_sel = ui.model;


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
                         'ResizeFcn', @plt.resize,...
                         'WindowButtonUpFcn', @plt.stop_dragging);
                  
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
                            'string', keys(plt.models),...
                            'value', find(strcmp(keys(plt.models), model_sel)),...
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
                plt.data = squeeze(ui.data(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :));
                plt.x_data = ui.x_data;
            end
        end
        
        function plotdata(plt, realtime)
            if nargin < 2
                realtime = false;
            end
            datal = plt.data;
            m = max(datal((plt.t_offset+plt.t_zero):end));
            m = m*1.1;
            
            axes(plt.h.axes);
            cla
            hold on
            plot(plt.x_data(1:(plt.t_offset+plt.t_zero)), datal(1:(plt.t_offset+plt.t_zero)), '.r');
            plot(plt.x_data((plt.t_offset+plt.t_zero):end), datal((plt.t_offset+plt.t_zero):end), '.b');
            
            plt.h.zeroline = line([0 0], [0 m], 'Color', [0 1 0], 'ButtonDownFcn', @plt.plot_click);
            plt.h.offsetline = line([plt.t_offset plt.t_offset]*plt.channel_width, [0 m], 'Color', [0 1 1], 'ButtonDownFcn', @plt.plot_click);
            hold off
            
            ylim([0 m]);
            xlim([min(plt.x_data)-1 max(plt.x_data)+1]);
            if plt.fitted && ~realtime
                plt.plotfit();
            end
        end
        
        function plotfit(plt)
            p = num2cell(plt.fit_params);
            fitdata = plt.model{1}(p{:}, plt.x_data);
            
            axes(plt.h.axes);
            hold on
            plot(plt.x_data,  fitdata, 'r');
            hold off
            
            axes(plt.h.res);
            residues = (plt.data((plt.t_offset+plt.t_zero):end)-...
                 fitdata((plt.t_offset+plt.t_zero):end))./sqrt(1+plt.data((plt.t_offset+plt.t_zero):end));
            plot(plt.x_data((plt.t_offset+plt.t_zero):end), residues, 'b.');
            hold on
            plot(plt.x_data(1:(plt.t_offset+plt.t_zero)),...
                 (plt.data(1:(plt.t_offset+plt.t_zero))-...
                 fitdata(1:(plt.t_offset+plt.t_zero)))./sqrt(1+plt.data(1:(plt.t_offset+plt.t_zero))), 'r.');
            line([min(plt.x_data)-1 max(plt.x_data)+1], [0 0], 'Color', 'r');
            xlim([min(plt.x_data)-1 max(plt.x_data)+1]);
            m = max([abs(max(residues)) abs(min(residues))]);
            ylim([-m m]);
            hold off
        end
        
        function fit(plt, varargin)
            x = plt.x_data((plt.t_zero+plt.t_offset):end);
            y = plt.data((plt.t_zero+plt.t_offset):end);
            w = sqrt(y+1);
%             plt.set_model();
            ind  = 0;
            fix = {};
            for i = 1:plt.n_param
                start(i) = str2double(get(plt.h.pe{i}, 'string'));
                if get(plt.h.pc{i}, 'value')
                    ind = ind + 1;
                    fix{ind} = plt.model{4}{i};
                end
            end
            
            if ind == plt.n_param
                error('kann ohne params nich fitten...');
            end
            
            [p] = fitdata(plt.model, x, y, w, start, fix);
            
            plt.fit_params = p;
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
            plt.fitted = false;
            plt.n_param = length(tmp{2});
            plt.model = plt.models(n);
            plt.est_params = UI.estimate_parameters_p(plt.data, n, plt.t_zero, plt.t_offset, plt.channel_width);
            plt.generate_param();
        end
        
        function generate_param(plt)
            if plt.fitted
                par = plt.fit_params;
            else
                par = plt.est_params;
            end
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
                                                      'string', sprintf('%1.2f', par(i)),...
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
        end
        
        function plot_click(plt, varargin)
            switch varargin{1}
                case plt.h.zeroline
                    set(plt.h.f, 'WindowButtonMotionFcn', @plt.plot_drag_zero);
                case plt.h.offsetline
                    set(plt.h.f, 'WindowButtonMotionFcn', @plt.plot_drag_offs);
            end
        end
        
        function plot_drag_zero(plt, varargin)
            cpoint = get(plt.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            plt.t_zero = plt.t_zero + round(cpoint/plt.channel_width);
            plt.x_data = ((1:length(plt.data))-plt.t_zero)'*plt.channel_width;
            plt.plotdata(true)
        end
        
        function plot_drag_offs(plt, varargin)
            cpoint = get(plt.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            plt.t_offset = round(cpoint/plt.channel_width);
            plt.plotdata(true)
        end
        
        function stop_dragging(plt, varargin)
            set(plt.h.f, 'WindowButtonMotionFcn', '');
            plt.plotdata();
        end
    end
    
    methods (Access = private)
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

    end
    
end