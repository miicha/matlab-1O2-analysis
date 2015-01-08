classdef UIPlot < handle
    %UIPLOT
    
    properties
        ui;
        cp;                     % current point
        data;
        x_data;
        res;
        n_param;
        est_params;             % estimated parameters
        fit_params;             % fitted parameters
        fit_params_err;         % ertimated errors of fitted parameters
        chisq;                  % chisquared
        fitted = false;
        cfit;
        model;
        model_str;
        t_offset;
        t_zero;
        channel_width;
        
        models;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(cp, ui)
            %% get data from main UI
            plt.ui = ui;                % keep refs to the memory in which
                                        % the UI object is saved
            plt.models = ui.models;
            if ui.model
                plt.model = plt.models(ui.model);
            end
            plt.cp = [cp ui.current_z ui.current_sa];
            if ~isnan(ui.fit_chisq(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4)))
                plt.fitted = true;
            end
            plt.getdata(ui);
            tmp = ui.models(ui.model);
            plt.n_param = length(tmp{2});
            plt.t_offset = ui.t_offset;
            plt.t_zero = ui.t_zero;

            plt.channel_width = ui.channel_width;
            
            plt.est_params = squeeze(ui.est_params(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));

            plt.model_str = ui.model;

            %% initialize UI objects
            
            plt.h.f = figure();
            
            plt.h.axes = axes();
            plt.h.res = axes();
            
            plt.h.fitpanel = uipanel();
                plt.h.drpd = uicontrol(plt.h.fitpanel);
                plt.h.pb = uicontrol(plt.h.fitpanel);
                plt.h.pb_glob = uicontrol(plt.h.fitpanel);
                plt.h.gof = uicontrol(plt.h.fitpanel);
                plt.h.param = uipanel(plt.h.fitpanel);

            
            %% figure
            if iscell(ui.fileinfo.name)
                name = ui.fileinfo.name{plt.cp(1)};
            else
                name = [ui.fileinfo.name ' - ' num2str(plt.cp)];
            end
            
            set(plt.h.f, 'units', 'pixels',...
                         'position', [500 200 1000 710],...
                         'numbertitle', 'off',...
                         'resize', 'on',...
                         'name',  ['SISA Scan - ' name],...
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
                            'value', find(strcmp(keys(plt.models), plt.model_str)),...
                            'position', [10 5 200 27],...
                            'FontSize', 9,...
                            'callback', @plt.set_model);
                        
            set(plt.h.pb, 'units', 'pixels',...
                          'position', [10 35 98 28],...
                          'string', 'Fitten',...
                          'FontSize', 9,...
                          'BackgroundColor', [.8 .8 .8],...
                          'callback', @plt.fit);
                      
            set(plt.h.pb_glob, 'units', 'pixels',...
                          'position', [112 35 98 28],...
                          'string', 'globalisieren',...
                          'FontSize', 9,...
                          'BackgroundColor', [.8 .8 .8],...
                          'callback', @plt.globalize)
                      
            set(plt.h.gof, 'units', 'pixels',...
                           'style', 'text',...
                           'FontSize', 9,...
                           'string', {'Chi^2/DoF:', num2str(plt.chisq)},...
                           'position', [223 10 62 45]);
                       
            set(plt.h.param, 'units', 'pixels',...
                             'position', [300 10 600 55]);
                         
            plt.h.pe = cell(1, 1);
            plt.h.pd = cell(1, 1);
            plt.h.pc = cell(1, 1);
                      
            %% draw plot
            plt.generate_param();      
            plt.plotdata();
        end
        
        function getdata(plt, ui)
            plt.chisq = 0;
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                           '/' num2str(plt.cp(3)-1) '/sisa/' num2str(ui.current_sa)];
                plt.data(1, :) = h5read(ui.fileinfo.path, dataset);
            else
                plt.data = squeeze(ui.data(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :));
                plt.x_data = ui.x_data;
                if plt.fitted
                    plt.chisq =  squeeze(ui.fit_chisq(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :));
                    plt.fit_params = squeeze(ui.fit_params(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));
                    plt.fit_params_err = squeeze(ui.fit_params_err(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));
                end
            end
        end
        
        function plotdata(plt, realtime)
            if nargin < 2
                realtime = false;
            end
            datal = plt.data;
            realmax = max(datal)*1.5;
            m = max(datal((plt.t_offset+plt.t_zero):end));
            m = m*1.1;
            
            axes(plt.h.axes);
            cla
            hold on
            plot(plt.x_data(1:(plt.t_offset+plt.t_zero)), datal(1:(plt.t_offset+plt.t_zero)), '.', 'Color', [.8 .8 1]);
            plot(plt.x_data((plt.t_offset+plt.t_zero):end), datal((plt.t_offset+plt.t_zero):end), '.b');
            
            plt.h.zeroline = line([0 0], [0 realmax], 'Color', [0 1 0],... 
                      'ButtonDownFcn', @plt.plot_click, 'LineWidth', 1.5, 'LineStyle', '--');
            plt.h.offsetline = line([plt.t_offset plt.t_offset]*plt.channel_width,...
                [0 realmax], 'Color', [0 1 1], 'ButtonDownFcn', @plt.plot_click, 'LineWidth', 1.5,...
                'LineStyle', '-.');
            hold off
            
            xlim([min(plt.x_data)-1 max(plt.x_data)+1]);
            if ~realtime
                ylim([0 m]);
                if plt.fitted
                    plt.plotfit();
                end
            end
        end
        
        function plotfit(plt)
            p = num2cell(plt.fit_params);
            fitdata = plt.model{1}(p{:}, plt.x_data);
            
            axes(plt.h.axes);
            hold on
            plot(plt.x_data,  fitdata, 'r', 'LineWidth', 2, 'HitTest', 'off');
            hold off
            
            axes(plt.h.res);
            residues = (plt.data((plt.t_offset+plt.t_zero):end)-...
                 fitdata((plt.t_offset+plt.t_zero):end))./sqrt(1+plt.data((plt.t_offset+plt.t_zero):end));
            plot(plt.x_data((plt.t_offset+plt.t_zero):end), residues, 'b.');
            hold on
            plot(plt.x_data(1:(plt.t_offset+plt.t_zero)),...
                 (plt.data(1:(plt.t_offset+plt.t_zero))-...
                 fitdata(1:(plt.t_offset+plt.t_zero)))./...
                 sqrt(1+plt.data(1:(plt.t_offset+plt.t_zero))), '.', 'Color', [.8 .8 1]);
            line([min(plt.x_data)-1 max(plt.x_data)+1], [0 0], 'Color', 'r', 'LineWidth', 2);
            xlim([min(plt.x_data)-1 max(plt.x_data)+1]);
            m = max([abs(max(residues)) abs(min(residues))]);
            ylim([-m m]);
            hold off
            
            % update UI
            for i = 1:plt.n_param
                str = sprintf('%1.2f', plt.fit_params(i));
                set(plt.h.pe{i}, 'string', str);
                if plt.fit_params_err(i) < plt.fit_params(i)
                    str = sprintf('+-%1.2f', plt.fit_params_err(i));   
                else 
                    str = '+-NaN';   
                end
                set(plt.h.pd{i}, 'string', str);
            end
            tmp = get(plt.h.gof, 'string');
            tmp{2} = sprintf('%1.2f', plt.chisq);
            set(plt.h.gof, 'string', tmp);
        end
        
        function fit(plt, varargin)
            x = plt.x_data((plt.t_zero+plt.t_offset):end);
            y = plt.data((plt.t_zero+plt.t_offset):end);
            w = sqrt(y);
            w(w == 0) = 1;
%             plt.set_model();
            ind  = 0;
            fix = {};
            start = zeros(plt.n_param, 1);
            for i = 1:plt.n_param
                start(i) = str2double(get(plt.h.pe{i}, 'string'));
                if get(plt.h.pc{i}, 'value')
                    ind = ind + 1;
                    fix{ind} = plt.model{4}{i};
                end
            end
            
            if ind == plt.n_param
                msgbox('Kann ohne freie Parameter nicht fitten.', 'Fehler','modal');
                return;
            end
            
            [p, p_err, chi] = fitdata(plt.model, x, y, w, start, fix);
            
            plt.fit_params = p;
            plt.fit_params_err = p_err;
            plt.chisq = chi;
            plt.fitted = true;
            plt.plotdata();
            plt.plotfit();
        end
        
        function set_model(plt, varargin)
            m = keys(plt.models);
            n = m{get(plt.h.drpd, 'value')};
            tmp = plt.models(n);
            plt.fitted = false;
            plt.n_param = length(tmp{2});
            plt.model = plt.models(n);
            plt.model_str = n;
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
                                                      'position', [55+(i-1)*100 22 40 20]); 
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
            t = plt.t_zero + round(cpoint/plt.channel_width);
            x = ((1:length(plt.data))-t)'*plt.channel_width;
            if t <= 0
                t = 1;
                x = ((1:length(plt.data))-t)'*plt.channel_width;
            end
            plt.t_zero = t;
            plt.x_data = x;
            plt.plotdata(true)
        end
        
        function plot_drag_offs(plt, varargin)
            cpoint = get(plt.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            if cpoint/plt.channel_width < 0.01
                cpoint = 0.01;
            else
            end
            plt.t_offset = round(cpoint/plt.channel_width);
            plt.plotdata(true)
        end
        
        function stop_dragging(plt, varargin)
            set(plt.h.f, 'WindowButtonMotionFcn', '');
            plt.plotdata();
        end
        
        function globalize(plt, varargin)
            plt.ui.t_offset = plt.t_offset;
            plt.ui.t_zero = plt.t_zero;
            plt.ui.x_data = plt.x_data;
            plt.ui.set_model(plt.model_str);
        end
        
        function save_fig(ui, varargin)
            pix_scale = 1000/d;

            x_pix = x*pix_scale;
            y_pix = y*pix_scale;
            
            tmp = get(ui.h.axes, 'position');
            
            ui.generate_export_fig();

            % save the plot and close the figure
            set(ui.h.plot_pre, 'PaperUnits', 'points');
            set(ui.h.plot_pre, 'PaperSize', [x_pix+80 y_pix+80]/1.5);
            set(ui.h.plot_pre, 'PaperPosition', [tmp(1)*0.5 tmp(2)*0.5 x_pix*1.1 y_pix*1.1]/1.5);
            print(ui.h.plot_pre, '-dpdf', '-r600', [ui.fileinfo.name '_arrayplot.pdf']);
            close(ui.h.plot_pre)
        end

        function generate_export_fig(ui, varargin)
            if ~isempty(varargin) && isvalid(varargin{1})
                vis = 'on';
            else
                vis = 'off';
            end
                        
            tmp = get(ui.h.axes, 'position');
            if isfield(ui.h, 'plot_pre') && ishandle(ui.h.plot_pre)
                figure(ui.h.plot_pre);
                clf();
                windowpos = get(ui.h.plot_pre, 'position');
            else
                ui.h.plot_pre = figure('visible', vis);
                screensize = get(0, 'ScreenSize');
                windowpos = [screensize(3)-(x_pix+100) screensize(4)-(y_pix+150)  x_pix+80 y_pix+100];
            end
            set(plt.h.plot_pre, 'units', 'pixels',...
                   'position', windowpos,...
                   'numbertitle', 'off',...
                   'menubar', 'none',...
                   'name', 'SISA Scan Vorschau',...
                   'resize', 'off',...
                   'Color', [.95, .95, .95]);

            ax = copyobj(plt.h.axes, plt.h.plot_pre);
            ax_res = copyobj(plt.h.res, plt.h.plot_pre);

            set(ax, 'position', [tmp(1) tmp(2) x_pix y_pix],...
                    'XColor', 'black',...
                    'YColor', 'black');
            xlabel('X [mm]')
            ylabel('Y [mm]')
            set(ax, 'xtick', 0:x, 'ytick', 0:y,...
                    'xticklabel', num2cell((0:x)*ui.scale(1)),...
                    'yticklabel', num2cell((0:y)*ui.scale(2)));
            colormap(ui.cmap);
            colorbar();
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