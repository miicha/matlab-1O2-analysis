classdef UIPlot < handle
    %UIPLOT
    
    properties
        smode;
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
        function this = UIPlot(point, smode)
            %% get data from main UI
            this.smode = smode;                % keep refs to the memory in which
                                        % the UI object is saved
            this.models = smode.models;
            if smode.model
                this.model = this.models(smode.model);
            end
            this.cp = point;
            if ~isnan(smode.fit_chisq(this.cp(1), this.cp(2), this.cp(3), this.cp(4)))
                this.fitted = true;
            end
            this.getdata(smode);
            tmp = smode.models(smode.model);
            this.n_param = length(tmp{2});
            this.t_offset = smode.t_offset;
            this.t_zero = smode.t_zero;

            this.channel_width = smode.channel_width;
            
            this.est_params = squeeze(smode.est_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));

            this.model_str = smode.model;
            
            %% initialize UI objects
            
            this.h.f = figure();
            minSize = [850 650];
            
%             this.h.menu = uimenu(this.h.f);
            
            this.h.axes = axes();
            this.h.res = axes();
            
            this.h.tabs = uitabgroup();
            this.h.fit_tab = uitab(this.h.tabs);
                this.h.drpd = uicontrol(this.h.fit_tab);
                this.h.pb = uicontrol(this.h.fit_tab);
                this.h.pb_glob = uicontrol(this.h.fit_tab);
                this.h.gof = uicontrol(this.h.fit_tab);
                this.h.param = uipanel(this.h.fit_tab);
                
            this.h.exp_tab = uitab(this.h.tabs);
                this.h.prev_fig = uicontrol(this.h.exp_tab);
                this.h.save_fig = uicontrol(this.h.exp_tab);

            %% figure
            if length(smode.p.fileinfo.name) > 1
                name = smode.p.fileinfo.name{this.cp(1)};
            else
                name = [smode.p.fileinfo.name{1} ' - ' num2str(this.cp)];
            end
            
            set(this.h.f, 'units', 'pixels',...
                         'position', [500 200 1000 710],...
                         'numbertitle', 'off',...
                         'resize', 'on',...
                         'menubar', 'none',...
                         'toolbar', 'figure',...
                         'name',  ['SISA Scan - ' name],...
                         'ResizeFcn', @this.resize,...
                         'WindowButtonUpFcn', @this.stop_dragging);
                     
            toolbar_pushtools = findall(findall(this.h.f, 'Type', 'uitoolbar'),...
                                                         'Type', 'uipushtool');
            toolbar_toggletools = findall(findall(this.h.f, 'Type', 'uitoolbar'),...
                                                    'Type', 'uitoggletool');

            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOn'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOff'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.PrintFigure'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.FileOpen'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.NewFigure'), 'visible', 'off');
            
            set(findall(toolbar_pushtools, 'Tag', 'Standard.SaveFigure'),...
                                                  'clickedcallback', @this.save_fig_selloc_cb);
            
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

            set(this.h.axes, 'units', 'pixels',...
                            'position', [50 305 900 400],...
                            'box', 'on');
                        
            set(this.h.res, 'units', 'pixels',...
                           'position', [50 145 900 130],...
                           'box', 'on');
            
            set(this.h.tabs, 'units', 'pixels',...
                            'position', [50 10 900 105]);
                        
            %% fitoptions
            set(this.h.fit_tab, 'units', 'pixels',...
                               'Title', 'Fitten');
            
            set(this.h.drpd, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', keys(this.models),...
                            'value', find(strcmp(keys(this.models), this.model_str)),...
                            'position', [10 5 200 27],...
                            'FontSize', 9,...
                            'callback', @this.set_model);
                        
            set(this.h.pb, 'units', 'pixels',...
                          'position', [10 35 98 28],...
                          'string', 'Fitten',...
                          'FontSize', 9,...
                          'callback', @this.fit);
                      
            set(this.h.pb_glob, 'units', 'pixels',...
                          'position', [112 35 98 28],...
                          'string', 'globalisieren',...
                          'FontSize', 9,...
                          'callback', @this.globalize)
                      
            set(this.h.gof, 'units', 'pixels',...
                           'style', 'text',...
                           'FontSize', 9,...
                           'string', {'Chi^2/DoF:', num2str(this.chisq)},...
                           'position', [223 10 62 45]);
                       
            set(this.h.param, 'units', 'pixels',...
                             'position', [300 5 620 65]);
                         
            this.h.pe = cell(1, 1);
            this.h.pd = cell(1, 1);
            this.h.pc = cell(1, 1);
            this.h.pt = cell(1, 1);
            
            %% export
            set(this.h.exp_tab, 'units', 'pixels',...
                               'Title', 'Export');
                           
            set(this.h.prev_fig, 'units', 'pixels',...
                          'position', [10 40 98 28],...
                          'string', 'Vorschau',...
                          'FontSize', 9,...
                          'callback', @this.generate_export_fig_cb);
                      
            set(this.h.save_fig, 'units', 'pixels',...
                          'position', [10 5 98 28],...
                          'string', 'Speichern',...
                          'FontSize', 9,...
                          'callback', @this.save_fig_cb);

            %% limit size with java
            drawnow;
            jFrame = get(handle(this.h.f), 'JavaFrame');
            jWindow = jFrame.fHG2Client.getWindow;
            tmp = java.awt.Dimension(minSize(1), minSize(2));
            jWindow.setMinimumSize(tmp);
            
            %% draw plot
            this.generate_param();      
            this.plotdata();
        end
        
        function getdata(this, smode)
            this.chisq = 0;
            if ~smode.p.data_read
                dataset = ['/' num2str(this.cp(1)-1) '/' num2str(this.cp(2)-1)...
                           '/' num2str(this.cp(3)-1) '/sisa/' num2str(this.cp(4)-1)];
                this.data(1, :) = h5read(smode.p.fileinfo.path, dataset);
            else
                this.data = squeeze(smode.data(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                this.x_data = smode.x_data;
                if this.fitted
                    this.chisq =  squeeze(smode.fit_chisq(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                    this.fit_params = squeeze(smode.fit_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                    this.fit_params_err = squeeze(smode.fit_params_err(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                end
            end
        end
        
        function plotdata(this, realtime)
            if nargin < 2
                realtime = false;
            end
            datal = this.data;
            realmax = max(datal)*1.5;
            m = max(datal((this.t_offset+this.t_zero):end));
            m = m*1.1;
            
            axes(this.h.axes);
            cla
            hold on
            plot(this.x_data(1:(this.t_offset+this.t_zero)), datal(1:(this.t_offset+this.t_zero)),...
                                                                   '.-', 'Color', [.8 .8 1]);
            plot(this.x_data((this.t_offset+this.t_zero):end), datal((this.t_offset+this.t_zero):end),...
                                   'Marker', '.', 'Color', [.8 .8 1], 'MarkerEdgeColor', 'blue');
            
            this.h.zeroline = line([0 0], [0 realmax], 'Color', [.7 0 .5],... 
                      'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2, 'LineStyle', '--',...
                      'Tag', 'line');
            this.h.offsetline = line([this.t_offset this.t_offset]*this.channel_width,...
                [0 realmax], 'Color', [0 .6 .5], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2,...
                'LineStyle', '-.', 'Tag', 'line');
            hold off
            xlim([min(this.x_data)-1 max(this.x_data)+1]);

            if ~realtime             
                ylim([0 m]);
                if this.fitted
                    this.plotfit();
                end
            end
        end
        
        function plotfit(this)
            p = num2cell(this.fit_params);
            fitdata = this.model{1}(p{:}, this.x_data);
            
            axes(this.h.axes);
            hold on
            plot(this.x_data,  fitdata, 'r', 'LineWidth', 1.5, 'HitTest', 'off');
            hold off
            
            axes(this.h.res);
            residues = (this.data((this.t_offset+this.t_zero):end)-...
                 fitdata((this.t_offset+this.t_zero):end))./sqrt(1+this.data((this.t_offset+this.t_zero):end));
            plot(this.x_data((this.t_offset+this.t_zero):end), residues, 'b.');
            hold on
            plot(this.x_data(1:(this.t_offset+this.t_zero)),...
                 (this.data(1:(this.t_offset+this.t_zero))-...
                 fitdata(1:(this.t_offset+this.t_zero)))./...
                 sqrt(1+this.data(1:(this.t_offset+this.t_zero))), '.', 'Color', [.8 .8 1]);
            line([min(this.x_data)-1 max(this.x_data)+1], [0 0], 'Color', 'r', 'LineWidth', 1.5);
            xlim([min(this.x_data)-1 max(this.x_data)+1]);
            m = max([abs(max(residues)) abs(min(residues))]);
            ylim([-m m]);
            hold off
            
            % update UI
            for i = 1:this.n_param
                str = sprintf('%1.2f', this.fit_params(i));
                set(this.h.pe{i}, 'string', str);
                if this.fit_params_err(i) < this.fit_params(i)
                    str = sprintf('+-%1.2f', this.fit_params_err(i));   
                else 
                    str = '+-NaN';   
                end
                set(this.h.pd{i}, 'string', str);
            end
            tmp = get(this.h.gof, 'string');
            tmp{2} = sprintf('%1.2f', this.chisq);
            set(this.h.gof, 'string', tmp);
        end
        
        function fit(this, varargin)
            x = this.x_data((this.t_zero+this.t_offset):end);
            y = this.data((this.t_zero+this.t_offset):end);
            w = sqrt(y);
            w(w == 0) = 1;

            ind  = 0;
            fix = {};
            start = zeros(this.n_param, 1);
            for i = 1:this.n_param
                start(i) = str2double(get(this.h.pe{i}, 'string'));
                if get(this.h.pc{i}, 'value')
                    ind = ind + 1;
                    fix{ind} = this.model{4}{i};
                end
            end
            
            if ind == this.n_param
                msgbox('Kann ohne freie Parameter nicht fitten.', 'Fehler','modal');
                return;
            end
            
            tmp = this.smode.models(this.model_str);
            this.model{2} = tmp{2};
            this.model{3} = tmp{3};

            [p, p_err, chi] = fitdata(this.model, x, y, w, start, fix);
            
            this.fit_params = p;
            this.fit_params_err = p_err;
            this.chisq = chi;
            this.fitted = true;
            this.plotdata();
            this.plotfit();
        end
        
        function set_model(this, varargin)
            m = keys(this.models);
            n = m{get(this.h.drpd, 'value')};
            tmp = this.models(n);
            this.fitted = false;
            this.n_param = length(tmp{2});
            this.model = this.models(n);
            this.model_str = n;
            this.est_params = SiSaMode.estimate_parameters_p(this.data, n, this.t_zero, this.t_offset, this.channel_width);
            this.generate_param();
        end
        
        function generate_param(this)
            if this.fitted
                par = this.fit_params;
            else
                par = this.est_params;
            end
            for i = 1:length(this.h.pe)
                delete(this.h.pe{i});
                set(this.h.pd{i}, 'visible', 'off');
                delete(this.h.pd{i});
                delete(this.h.pc{i});
                delete(this.h.pt{i});
            end           
            clear('this.h.pe', 'this.h.pd', 'this.h.pc', 'this.h.pt');

            this.h.pt = cell(this.n_param, 1);
            this.h.pe = cell(this.n_param, 1);
            this.h.pd = cell(this.n_param, 1);
            this.h.pc = cell(this.n_param, 1);
            for i = 1:this.n_param
                 this.h.pt{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', this.model{4}{i},...
                                                      'HorizontalAlignment', 'left',...
                                                      'FontSize', 9,...
                                                      'position', [10+(i-1)*100 40 41 20]);
                 this.h.pe{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'edit',...
                                                      'string', sprintf('%1.2f', par(i)),...
                                                      'position', [10+(i-1)*100 25 45 20]);
                 this.h.pd{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', '+-',...
                                                      'HorizontalAlignment', 'left',...
                                                      'position', [55+(i-1)*100 22 40 20]); 
                 this.h.pc{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'checkbox',...
                                                      'string', 'fix',...
                                                      'position', [10+(i-1)*100 5 50 15]); 
            end
            if this.n_param == 0
                set(this.h.param, 'visible', 'off');
            else
                set(this.h.param, 'visible', 'on');
                pP = get(this.h.param, 'position');
                pP(3) = 45+(this.n_param-1)*100+45+10;
                set(this.h.param, 'position', pP);
            end
        end
        
        function plot_click(this, varargin)
            switch varargin{1}
                case this.h.zeroline
                    set(this.h.f, 'WindowButtonMotionFcn', @this.plot_drag_zero);
                case this.h.offsetline
                    set(this.h.f, 'WindowButtonMotionFcn', @this.plot_drag_offs);
            end
        end
        
        function plot_drag_zero(this, varargin)
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            t = this.t_zero + round(cpoint/this.channel_width);
            n = length(this.data);
            x = ((1:n)-t)'*this.channel_width;
            if t <= 0
                t = 1;
                x = ((1:n)-t)'*this.channel_width;
            elseif t + this.t_offset >= n
                t = length(this.x_data)-this.t_offset-1;
                x = ((1:n)-t)'*this.channel_width;
            end
            this.t_zero = t;
            this.x_data = x;
            this.plotdata(true)
        end
        
        function plot_drag_offs(this, varargin)
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            if cpoint/this.channel_width < 0.01
                cpoint = 0.01;
            elseif this.t_zero+cpoint/this.channel_width >= length(this.x_data)-10
                cpoint = (length(this.x_data)-this.t_zero-1)*this.channel_width;
            end
            this.t_offset = round(cpoint/this.channel_width);
            this.plotdata(true)
        end
        
        function stop_dragging(this, varargin)
            set(this.h.f, 'WindowButtonMotionFcn', '');
%             this.plotdata();
        end
        
        function globalize(this, varargin)
            this.smode.t_offset = this.t_offset;
            this.smode.t_zero = this.t_zero;
            this.smode.x_data = this.x_data;
            this.smode.set_model(this.model_str);
            if this.fitted
                par = this.fit_params;
            else
                par = this.est_params;
            end
            this.smode.set_gstart(par);
        end
        
        function save_fig_selloc_cb(this, varargin)
            [name, path] = uiputfile('*.pdf', 'Plot als PDF speichern', this.generate_filepath());
            if name == 0
                return
            end
            this.save_fig([path name]);
        end
        
        function save_fig_cb(this, varargin)
            this.save_fig_selloc_cb();
        end
        
        function path = generate_filepath(this)
            point = regexprep(num2str(this.cp), '\s+', '_');
            name = [this.smode.genericname '_p_' point];
            path = fullfile(this.smode.savepath, name);
        end
        
        function save_fig(this, path)
            this.generate_export_fig('off');
            
            tmp = get(this.h.plot_pre, 'position');
            x_pix = tmp(3);
            y_pix = tmp(4);
            
            % save the plot and close the figure
            set(this.h.plot_pre, 'PaperUnits', 'points');
            set(this.h.plot_pre, 'PaperSize', [x_pix+80 y_pix+80]/1.5);
            set(this.h.plot_pre, 'PaperPosition', [10 0 x_pix+80 y_pix+80]/1.5);
            print(this.h.plot_pre, '-dpdf', '-r600', path);
            close(this.h.plot_pre)
        end

        function generate_export_fig(this, vis)    
            if isfield(this.h, 'plot_pre') && ishandle(this.h.plot_pre)
                figure(this.h.plot_pre);
                clf();
            else
                this.h.plot_pre = figure('visible', vis);
            end
            set(this.h.plot_pre, 'units', 'pixels',...
                   'numbertitle', 'off',...
                   'menubar', 'none',...
                   'position', [100 100 1100 750],...
                   'name', 'SISA Scan Vorschau',...
                   'resize', 'off',...
                   'Color', [.95, .95, .95]);

            ax = copyobj(this.h.axes, this.h.plot_pre);
            xlabel(ax, 'Zeit [µs]')
            ylabel(ax, 'Counts');

            if this.fitted
                ax_res = copyobj(this.h.res, this.h.plot_pre);
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
            
            if this.fitted && this.fit_info
                this.generate_fit_info_ov();
            end
        end
        
        function generate_fit_info_ov(this)
            ax = this.h.plot_pre.Children(2);
            axes(ax);
            latex_model = this.smode.models_latex(this.model_str);
            m_names = latex_model{2};
            m_units = latex_model{3};
            func = latex_model{1};
            str{1} = func;
            for i = 1:length(this.fit_params)
                err = roundsig(this.fit_params_err(i), 2);
                par = roundsig(this.fit_params(i), floor(log10(this.fit_params(i)/this.fit_params_err(i))) + 1);
                
                str{i+2} = ['$$ ' m_names{i} ' = (' num2str(par) '\pm' num2str(err) ')$$ ' m_units{i}];
            end
            str{end+2} = ['$$ \chi^2 =$$ ' num2str(roundsig(this.chisq, 4))];
            m = text(.92, .94, str, 'Interpreter', 'latex',...
                                    'units', 'normalized',...
                                    'HorizontalAlignment', 'right',...
                                    'VerticalAlignment', 'top');
        end
        
        function generate_export_fig_cb(this, varargin)
            this.generate_export_fig('on');
        end
    end
    
    methods (Access = private)
        function resize(this, varargin)
            if isfield(this.h, 'f')
                fP = get(this.h.f, 'position');

                aP = get(this.h.axes, 'position');
                aP(3) = fP(3) - aP(1) - 50;
                aP(4) = fP(4) - aP(2) - 10;
                set(this.h.axes, 'position', aP);

                aP = get(this.h.res, 'position');
                aP(3) = fP(3) - aP(1) - 50;
                set(this.h.res, 'position', aP);

                fpP = get(this.h.tabs, 'position');
                fpP(3) = fP(3) - fpP(1) - 50;
                set(this.h.tabs, 'position', fpP);
            end
        end
    end
    
end