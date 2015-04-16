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
        fit_info = true; % should probably be false?
        
        models;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(point, ui)
            %% get data from main UI
            plt.ui = ui;                % keep refs to the memory in which
                                        % the UI object is saved
            plt.models = ui.models;
            if ui.model
                plt.model = plt.models(ui.model);
            end
            plt.cp = point;
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
            minSize = [850 650];
            
%             plt.h.menu = uimenu(plt.h.f);
            
            plt.h.axes = axes();
            plt.h.res = axes();
            
            plt.h.tabs = uitabgroup();
            plt.h.fit_tab = uitab(plt.h.tabs);
                plt.h.drpd = uicontrol(plt.h.fit_tab);
                plt.h.pb = uicontrol(plt.h.fit_tab);
                plt.h.pb_glob = uicontrol(plt.h.fit_tab);
                plt.h.gof = uicontrol(plt.h.fit_tab);
                plt.h.param = uipanel(plt.h.fit_tab);
                
            plt.h.exp_tab = uitab(plt.h.tabs);
                plt.h.prev_fig = uicontrol(plt.h.exp_tab);
                plt.h.save_fig = uicontrol(plt.h.exp_tab);

            %% figure
            if length(ui.fileinfo.name) > 1
                name = ui.fileinfo.name{plt.cp(1)};
            else
                name = [ui.fileinfo.name{1} ' - ' num2str(plt.cp)];
            end
            
            set(plt.h.f, 'units', 'pixels',...
                         'position', [500 200 1000 710],...
                         'numbertitle', 'off',...
                         'resize', 'on',...
                         'menubar', 'none',...
                         'toolbar', 'figure',...
                         'name',  ['SISA Scan - ' name],...
                         'ResizeFcn', @plt.resize,...
                         'WindowButtonUpFcn', @plt.stop_dragging);
                     
            toolbar_pushtools = findall(findall(plt.h.f, 'Type', 'uitoolbar'),...
                                                         'Type', 'uipushtool');
            toolbar_toggletools = findall(findall(plt.h.f, 'Type', 'uitoolbar'),...
                                                    'Type', 'uitoggletool');

            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOn'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOff'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.PrintFigure'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.FileOpen'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.NewFigure'), 'visible', 'off');
            
            set(findall(toolbar_pushtools, 'Tag', 'Standard.SaveFigure'),...
                                                  'clickedcallback', @plt.save_fig_selloc_cb);
            
            set(findall(toolbar_toggletools, 'Tag', 'Annotation.InsertLegend'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Annotation.InsertColorbar'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'DataManager.Linking'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Exploration.Rotate'), 'visible', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Standard.EditPlot'), 'visible', 'off',...
                                                                          'Separator', 'off');

            %% plot

            set(plt.h.axes, 'units', 'pixels',...
                            'position', [50 305 900 400],...
                            'box', 'on');
                        
            set(plt.h.res, 'units', 'pixels',...
                           'position', [50 145 900 130],...
                           'box', 'on');
            
            set(plt.h.tabs, 'units', 'pixels',...
                            'position', [50 10 900 105]);
                        
            %% fitoptions
            set(plt.h.fit_tab, 'units', 'pixels',...
                               'Title', 'Fitten');
            
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
                          'callback', @plt.fit);
                      
            set(plt.h.pb_glob, 'units', 'pixels',...
                          'position', [112 35 98 28],...
                          'string', 'globalisieren',...
                          'FontSize', 9,...
                          'callback', @plt.globalize)
                      
            set(plt.h.gof, 'units', 'pixels',...
                           'style', 'text',...
                           'FontSize', 9,...
                           'string', {'Chi^2/DoF:', num2str(plt.chisq)},...
                           'position', [223 10 62 45]);
                       
            set(plt.h.param, 'units', 'pixels',...
                             'position', [300 5 620 65]);
                         
            plt.h.pe = cell(1, 1);
            plt.h.pd = cell(1, 1);
            plt.h.pc = cell(1, 1);
            plt.h.pt = cell(1, 1);
            
            %% export
            set(plt.h.exp_tab, 'units', 'pixels',...
                               'Title', 'Export');
                           
            set(plt.h.prev_fig, 'units', 'pixels',...
                          'position', [10 40 98 28],...
                          'string', 'Vorschau',...
                          'FontSize', 9,...
                          'callback', @plt.generate_export_fig_cb);
                      
            set(plt.h.save_fig, 'units', 'pixels',...
                          'position', [10 5 98 28],...
                          'string', 'Speichern',...
                          'FontSize', 9,...
                          'callback', @plt.save_fig_cb);

            %% limit size with java
            drawnow;
            jFrame = get(handle(plt.h.f), 'JavaFrame');
            jWindow = jFrame.fHG2Client.getWindow;
            tmp = java.awt.Dimension(minSize(1), minSize(2));
            jWindow.setMinimumSize(tmp);
            
            %% draw plot
            plt.generate_param();      
            plt.plotdata();
        end
        
        function getdata(plt, ui)
            plt.chisq = 0;
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                           '/' num2str(plt.cp(3)-1) '/sisa/' num2str(plt.cp(4)-1)];
                plt.data(1, :) = h5read(ui.fileinfo.path, dataset);
            else
                plt.data = squeeze(ui.data(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));
                plt.x_data = ui.x_data;
                if plt.fitted
                    plt.chisq =  squeeze(ui.fit_chisq(plt.cp(1), plt.cp(2), plt.cp(3), plt.cp(4), :));
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
            plot(plt.x_data(1:(plt.t_offset+plt.t_zero)), datal(1:(plt.t_offset+plt.t_zero)),...
                                                                   '.-', 'Color', [.8 .8 1]);
            plot(plt.x_data((plt.t_offset+plt.t_zero):end), datal((plt.t_offset+plt.t_zero):end),...
                                   'Marker', '.', 'Color', [.8 .8 1], 'MarkerEdgeColor', 'blue');
            
            plt.h.zeroline = line([0 0], [0 realmax], 'Color', [.7 0 .5],... 
                      'ButtonDownFcn', @plt.plot_click, 'LineWidth', 1.2, 'LineStyle', '--',...
                      'Tag', 'line');
            plt.h.offsetline = line([plt.t_offset plt.t_offset]*plt.channel_width,...
                [0 realmax], 'Color', [0 .6 .5], 'ButtonDownFcn', @plt.plot_click, 'LineWidth', 1.2,...
                'LineStyle', '-.', 'Tag', 'line');
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
            plot(plt.x_data,  fitdata, 'r', 'LineWidth', 1.5, 'HitTest', 'off');
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
            line([min(plt.x_data)-1 max(plt.x_data)+1], [0 0], 'Color', 'r', 'LineWidth', 1.5);
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
                delete(plt.h.pt{i});
            end           
            clear('plt.h.pe', 'plt.h.pd', 'plt.h.pc', 'plt.h.pt');

            plt.h.pt = cell(plt.n_param, 1);
            plt.h.pe = cell(plt.n_param, 1);
            plt.h.pd = cell(plt.n_param, 1);
            plt.h.pc = cell(plt.n_param, 1);
            for i = 1:plt.n_param
                 plt.h.pt{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', plt.model{4}{i},...
                                                      'HorizontalAlignment', 'left',...
                                                      'FontSize', 9,...
                                                      'position', [10+(i-1)*100 40 41 20]);
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
            n = length(plt.data);
            x = ((1:n)-t)'*plt.channel_width;
            if t <= 0
                t = 1;
                x = ((1:n)-t)'*plt.channel_width;
            elseif t + plt.t_offset >= n
                t = length(plt.x_data)-plt.t_offset-1;
                x = ((1:n)-t)'*plt.channel_width;
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
            elseif plt.t_zero+cpoint/plt.channel_width >= length(plt.x_data)-10
                cpoint = (length(plt.x_data)-plt.t_zero-1)*plt.channel_width;
            end
            plt.t_offset = round(cpoint/plt.channel_width);
            plt.plotdata(true)
        end
        
        function stop_dragging(plt, varargin)
            set(plt.h.f, 'WindowButtonMotionFcn', '');
%             plt.plotdata();
        end
        
        function globalize(plt, varargin)
            plt.ui.t_offset = plt.t_offset;
            plt.ui.t_zero = plt.t_zero;
            plt.ui.x_data = plt.x_data;
            plt.ui.set_model(plt.model_str);
            if plt.fitted
                par = plt.fit_params;
            else
                par = plt.est_params;
            end
            plt.ui.set_gstart(par);
        end
        
        function save_fig_selloc_cb(plt, varargin)
            [name, path] = uiputfile('*.pdf', 'Plot als PDF speichern', plt.generate_filepath());
            if name == 0
                return
            end
            plt.save_fig([path name]);
        end
        
        function save_fig_cb(plt, varargin)
            plt.save_fig_selloc_cb();
        end
        
        function path = generate_filepath(plt)
            point = regexprep(num2str(plt.cp), '\s+', '_');
            name = [plt.ui.genericname '_p_' point];
            path = fullfile(plt.ui.savepath, name);
        end
        
        function save_fig(plt, path)
            plt.generate_export_fig('off');
            
            tmp = get(plt.h.plot_pre, 'position');
            x_pix = tmp(3);
            y_pix = tmp(4);
            
            % save the plot and close the figure
            set(plt.h.plot_pre, 'PaperUnits', 'points');
            set(plt.h.plot_pre, 'PaperSize', [x_pix+80 y_pix+80]/1.5);
            set(plt.h.plot_pre, 'PaperPosition', [10 0 x_pix+80 y_pix+80]/1.5);
            print(plt.h.plot_pre, '-dpdf', '-r600', path);
            close(plt.h.plot_pre)
        end

        function generate_export_fig(plt, vis)    
            if isfield(plt.h, 'plot_pre') && ishandle(plt.h.plot_pre)
                figure(plt.h.plot_pre);
                clf();
            else
                plt.h.plot_pre = figure('visible', vis);
            end
            set(plt.h.plot_pre, 'units', 'pixels',...
                   'numbertitle', 'off',...
                   'menubar', 'none',...
                   'position', [100 100 1100 750],...
                   'name', 'SISA Scan Vorschau',...
                   'resize', 'off',...
                   'Color', [.95, .95, .95]);

            ax = copyobj(plt.h.axes, plt.h.plot_pre);
            xlabel(ax, 'Zeit [µs]')
            ylabel(ax, 'Counts');

            if plt.fitted
                ax_res = copyobj(plt.h.res, plt.h.plot_pre);
                xlabel(ax_res, 'Zeit [µs]')
                ylabel(ax_res, 'norm. Residuen [Counts]')
                set(ax_res, 'position', [50, 50, 1000, 150]);
                set(ax, 'position', [50 250 1000 450]);
            else
                set(ax, 'position', [50 50 1000 650]);
            end
            
            plotobjs = ax.Children;
            for i = 1:length(plotobjs)
                if strcmp(plotobjs(i).Tag, 'line')
                    set(plotobjs(i), 'visible', 'off')
                end
            end
            
            if plt.fitted && plt.fit_info
                plt.generate_fit_info_ov();
            end
        end
        
        function generate_fit_info_ov(plt)
            ax = plt.h.plot_pre.Children(2);
            axes(ax);

            m_names = {'A', '\tau_1', '\tau_2', 'B', 'o'};
            m_units = {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'};
            m_str = ['$$A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - '...
                   '\exp \left(\frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(\frac{t}{\tau_2}\right) + o$$'];
               
            str{1} = m_str;
               
            for i = 1:length(plt.fit_params)
                str{i+1} = ['$$ ' m_names{i} ' = (' num2str(plt.fit_params(i)) '\pm' num2str(plt.fit_params_err(i)) ')$$ ' m_units{i}];
            end
            m = text(.92, .94, str, 'Interpreter', 'latex',...
                                    'units', 'normalized',...
                                    'HorizontalAlignment', 'right',...
                                    'VerticalAlignment', 'top');
        end
        
        function generate_export_fig_cb(plt, varargin)
            plt.generate_export_fig('on');
        end
    end
    
    methods (Access = private)
        function resize(plt, varargin)
            if isfield(plt.h, 'f')
                fP = get(plt.h.f, 'position');

                aP = get(plt.h.axes, 'position');
                aP(3) = fP(3) - aP(1) - 50;
                aP(4) = fP(4) - aP(2) - 10;
                set(plt.h.axes, 'position', aP);

                aP = get(plt.h.res, 'position');
                aP(3) = fP(3) - aP(1) - 50;
                set(plt.h.res, 'position', aP);

                fpP = get(plt.h.tabs, 'position');
                fpP(3) = fP(3) - fpP(1) - 50;
                set(plt.h.tabs, 'position', fpP);
            end
        end
    end
    
end