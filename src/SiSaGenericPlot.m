classdef SiSaGenericPlot < handle
    %GENERICPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data;
        x_data;
        smode;
        models;
        model;
        fitted = false;
        chisq;              % chisquared
        n_param;
        t_offset;
        t_zero;
        t_end;
        channel_width;
        est_params;         % estimated parameters
        model_str;
        h = struct();       % handles
        fit_params;         % fitted parameters
        fit_params_err;     % ertimated errors of fitted parameters
        cp;
        fit_info = true;
        diff_data;
        data_backup;
        plot_limits;
    end
    
    properties (Access = private)
        current_draggable;
    end
    
    methods
        function this = SiSaGenericPlot(smode)            
            %% get data from main UI
            this.smode = smode;                % keep refs to the memory in which
                                        % the UI object is saved
            this.models = smode.models;
            if smode.model
                this.model = this.models(smode.model);
            end


            
            this.x_data = this.smode.x_data;
            
            tmp = smode.models(smode.model);
            this.n_param = length(tmp{2});
            this.t_offset = smode.t_offset;
            this.t_zero = smode.t_zero;
            this.t_end = smode.t_end;

            this.channel_width = smode.channel_width;
            
            this.est_params = rand(length(tmp{2}),1);

            this.model_str = smode.model;
            
            %% initialize UI objects
            
            this.h.f = figure();
            minSize = [850 650];
            
            this.h.toolbar=findall( this.h.f,'type','uitoolbar');
            this.h.xy_zoom = uitoggletool(this.h.toolbar,'cdata',rand(16,16,3), ...
                'tooltip','XY-Zoom', 'OnCallback',@this.xy_zoom, 'OffCallback',@this.reset_zoom);
            this.h.x_zoom = uitoggletool(this.h.toolbar,'cdata',rand(16,16,3), ...
                'tooltip','X-Zoom', 'OnCallback',@this.x_zoom, 'OffCallback',@this.reset_zoom);
            
            this.h.axes = axes();
            this.h.res = axes();
            
            this.h.tabs = uitabgroup();
            this.h.fit_tab = uitab(this.h.tabs);
                this.h.drpd = uicontrol(this.h.fit_tab);
                this.h.pb = uicontrol(this.h.fit_tab);
                this.h.pb_glob = uicontrol(this.h.fit_tab);
                this.h.pb_set_quant = uicontrol(this.h.fit_tab);
                this.h.gof = uicontrol(this.h.fit_tab);
                this.h.quant = uicontrol(this.h.fit_tab);
                this.h.param = uipanel(this.h.fit_tab);
                
            this.h.exp_tab = uitab(this.h.tabs);
                this.h.prev_fig = uicontrol(this.h.exp_tab);
                this.h.save_fig = uicontrol(this.h.exp_tab);
                this.h.save_data = uicontrol(this.h.exp_tab);
                this.h.save_data_temp = uicontrol(this.h.exp_tab);
                
            this.h.imp_tab = uitab(this.h.tabs);
                this.h.import_diff_data = uicontrol(this.h.imp_tab);
                this.h.faktor_slider = uicontrol(this.h.imp_tab);
                this.h.faktor_edit = uicontrol(this.h.imp_tab);

            %% figure
           
            scsize = get(0,'screensize');
            
            figuresize = {1000, 710};
            
            set(this.h.f, 'units', 'pixels',...
                         'position', [scsize(3)-1050 scsize(4)-820 figuresize{:}],...
                         'numbertitle', 'off',...
                         'resize', 'on',...
                         'menubar', 'none',...
                         'toolbar', 'figure',...
                         'ResizeFcn', @this.resize);
                     
            toolbar_pushtools = findall(this.h.toolbar, 'Type', 'uipushtool');
            toolbar_toggletools = findall(this.h.toolbar, 'Type', 'uitoggletool');
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
                          'position', [10 35 50 28],...
                          'string', 'Fitten',...
                          'FontSize', 9,...
                          'callback', @this.fit);
                      
            set(this.h.pb_glob, 'units', 'pixels',...
                          'position', [62 35 98 28],...
                          'string', 'globalisieren',...
                          'FontSize', 9,...
                          'callback', @this.globalize)
                      
            set(this.h.pb_set_quant, 'units', 'pixels',...
                          'position', [162 35 50 28],...
                          'string', 'Phi',...
                          'FontSize', 9,...
                          'callback', @this.set_as_reference)
                      
            set(this.h.gof, 'units', 'pixels',...
                           'style', 'text',...
                           'FontSize', 9,...
                           'string', {'Chi^2/DoF:', num2str(this.chisq)},...
                           'position', [223 20 62 45]);
            
            set(this.h.quant, 'units', 'pixels',...
                           'style', 'text',...
                           'FontSize', 9,...
                           'position', [223 10 80 15]);
                       
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
                      
            set(this.h.save_data, 'units', 'pixels',...
                          'position', [120 5 120 28],...
                          'string', 'Daten speichern',...
                          'FontSize', 9,...
                          'callback', @this.save_data_cb);
            
            set(this.h.save_data_temp, 'units', 'pixels',...
                          'position', [120 40 120 28],...
                          'string', 'Daten übergeben',...
                          'FontSize', 9,...
                          'callback', @this.save_data_temp_cb);
                      
             %% import
            set(this.h.imp_tab, 'units', 'pixels',...
                               'Title', 'Import');
                           
            set(this.h.import_diff_data, 'units', 'pixels',...
                          'position', [10 40 98 28],...
                          'string', 'Load Diff Data',...
                          'FontSize', 9,...
                          'callback', @this.load_diff_data_cb);
                      
            set(this.h.faktor_slider, 'units', 'pixels',...
                            'style', 'slider',...
                            'position', [400 40 300 20],...
                            'min', 0, 'max', 3.5,...
                            'SliderStep', [0.01 0.1],...
                            'value', 0.6,...
                            'callback', @this.change_faktor_cb,...
                            'BackgroundColor', [1 1 1]);
                        
            set(this.h.faktor_edit, 'units', 'pixels',...
                            'style', 'edit',...
                            'string', '0.6',...
                            'position', [200 40 50 20],...
                            'callback', @this.change_faktor_cb);

            %% limit size with java
            drawnow;
            jFrame = get(handle(this.h.f), 'JavaFrame');
            jWindow = jFrame.fHG2Client.getWindow;
            tmp = java.awt.Dimension(minSize(1), minSize(2));
            jWindow.setMinimumSize(tmp);
            
            %% draw plot
            this.generate_param();
        end
        
        function set_window_name(this,name)
            set(this.h.f, 'name',  ['SISA Scan - ' name]);
        end
        
        function plotdata(this, realtime)
            if nargin < 2
                realtime = false;
            end
            datal = this.data;
            realmax = max(datal)*1.5;
            m = max(datal((this.t_offset+this.t_zero):end));
            m = m*1.1;
            mini = min(datal((this.t_offset+this.t_zero):end))*0.95;
            
            if this.t_end == 0
                this.t_end = length(this.x_data) - this.t_zero - 1;
            end
            
            set(this.h.f,'CurrentAxes',this.h.axes)
            cla
            hold on
            
            plot(this.x_data(1:(this.t_offset+this.t_zero)), datal(1:(this.t_offset+this.t_zero)),...
                                                                   '.-', 'Color', [.8 .8 1]);
            this.h.data_line = plot(this.x_data(this.t_zero+(this.t_offset:this.t_end)), datal(this.t_zero+(this.t_offset:this.t_end)),...
                                   'Marker', '.', 'Color', [.8 .8 1], 'MarkerEdgeColor', 'blue');
            plot(this.x_data(this.t_zero+this.t_end:end), datal(this.t_zero+this.t_end:end),...
                                   '.-', 'Color', [.8 .8 1]);
            
            this.h.zeroline = line([0 0], [0 realmax], 'Color', [.7 0 .5],... 
                      'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2, 'LineStyle', '--',...
                      'Tag', 'line');
            this.h.offsetline = line([this.t_offset this.t_offset]*this.channel_width,...
                [0 realmax], 'Color', [0 .6 .5], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2,...
                'LineStyle', '-.', 'Tag', 'line');
            this.h.endline = line([this.t_end this.t_end]*this.channel_width,...
                [0 realmax], 'Color', [0 .8 .8], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2,...
                'LineStyle', '-.', 'Tag', 'line');
            hold off
            

            if ~realtime             
                ylim([mini m]);
                xlim([min(this.x_data)-1 max(this.x_data)+1]);
                if this.fitted
                    this.plotfit();
                end
            end
        end
        
        function plot_raw_data(this, data, add, varargin)
            if nargin < 3
                add = false;
            end
            
            set(this.h.f,'CurrentAxes',this.h.axes);
            if add
                hold all
            else
                cla();
            end
            
            if ischar(add)
                if nargin > 4 && mod(nargin - 3, 2) == 0
                    plot(data(:, 1), data(:, 2), add, varargin{:})
                else
                    plot(data(:, 1), data(:, 2), add)
                end
            else
                if nargin > 4 && mod(nargin - 3, 2) == 0
                    plot(data(:, 1), data(:, 2), varargin{:})
                else
                    plot(data(:, 1), data(:, 2))
                end
            end
                        
            if add
                hold off
            end
            
        end
        
        function plotfit(this)
            p = num2cell(this.fit_params);
            fitdata = this.model{1}(p{:}, this.x_data);

            set(this.h.f,'CurrentAxes',this.h.axes)
            
            % extrahierte SiSa-Daten Plotten
            if get(this.h.drpd, 'value') == 1 || get(this.h.drpd, 'value') == 2
                sisamodel = this.models('A*(exp(-t/t1)-exp(-t/t2))+offset');
                sisadata = sisamodel{1}(p{1}, p{2}, p{3}, p{5}, this.x_data);
                hold on
                plot(this.x_data,  sisadata, 'color', [1 0.6 0.2], 'LineWidth', 1.5, 'HitTest', 'off');
                hold off
            end
            hold on
            this.h.fit_line = plot(this.x_data,  fitdata, 'r', 'LineWidth', 1.5, 'HitTest', 'off');
            hold off
            
            
            % Residuen plotten
            set(this.h.f,'CurrentAxes',this.h.res);
            
            % im fitbereich
            residues = this.data - fitdata;
            tmp = this.data; 
            tmp(tmp <= 0) = 1;
            residues = residues./sqrt(tmp);
            
            plot(this.x_data(this.t_zero+(this.t_offset:this.t_end)),...
                 residues(this.t_zero+(this.t_offset:this.t_end)), 'b.');
            
            hold on
            % vor fitbereich
            plot(this.x_data(1:(this.t_offset+this.t_zero)),...
                 residues(1:(this.t_offset+this.t_zero)), '.', 'Color', [.8 .8 1]);
            % nach fitbereich
            plot(this.x_data((this.t_zero+this.t_end):end),...
                 residues((this.t_zero+this.t_end):end), '.', 'Color', [.8 .8 1]);
            % nulllinie
            line([min(this.x_data)-1 max(this.x_data)+1], [0 0], 'Color', 'r', 'LineWidth', 1.5);
            xlim([min(this.x_data)-1 max(this.x_data)+1]);
            m = max([abs(max(residues(this.t_zero+(this.t_offset:this.t_end)))),...
                     abs(min(residues(this.t_zero+(this.t_offset:this.t_end))))]);
            ylim([-m m]);
            hold off
            
            % update UI
            for i = 1:this.n_param
                str = sprintf('%1.2f', this.fit_params(i));
                
                if abs(this.fit_params(i) - this.model{2}(i)) < 1e-4 || abs(this.fit_params(i) - this.model{3}(i)) < 1e-4
                    this.h.pe{i}.BackgroundColor = [0.8 0.4 0.4];
                else
                    this.h.pe{i}.BackgroundColor = [0.9400 0.9400 0.9400];
                end
                    
                
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
            this.read_and_calc_quant();
        end
        
        function fit(this, varargin)
            x = this.x_data(this.t_zero+(this.t_offset:this.t_end));
            y = this.data(this.t_zero+(this.t_offset:this.t_end));
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
        end
        
        function xy_zoom(this, varargin)            
            this.y_zoom()
            this.x_zoom()
        end
        
        function y_zoom(this, varargin)            
            y_max = max(this.data);
            this.plot_limits.Y = this.h.axes.YLim;
            this.h.axes.YLim = [0 y_max];
        end
        
        function x_zoom(this, varargin)
            x_min = this.t_zero*this.channel_width;
            x_max = 5*this.t_zero*this.channel_width;  
            this.plot_limits.X = this.h.axes.XLim;
            this.h.axes.XLim = [-x_min x_max];
        end
        
        function reset_zoom(this, varargin)            
            this.h.axes.XLim = this.plot_limits.X;
            if isfield(this.plot_limits, 'Y')
                this.h.axes.YLim = this.plot_limits.Y;
            end
        end
        
        function read_and_calc_quant(this, varargin)
            
            path = tempdir;
            name = 'amplitude_phi.txt';
            A = this.smode.corrected_amplitude(this.fit_params,1);
            
            try
                quantum_yield = dlmread([path name]);
                quantum_yield = round(A/quantum_yield*1000)/1000;
                quantum_yield = ['Phi: ' num2str(quantum_yield)];
                set(this.h.quant,'string', quantum_yield);
            end
        end
        
        function set_as_reference(this, varargin)
            phi = inputdlg('Quantenausbeute der Referenz');
            
            if ~isempty(phi)
                phi = str2double(strrep(phi,',','.'));

                amplitude_phi = this.smode.corrected_amplitude(this.fit_params,phi);

                path = tempdir;
                name = 'amplitude_phi.txt';
                dlmwrite([path name], amplitude_phi);
            end
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
                    set(this.h.f, 'WindowButtonUpFcn', @this.stop_dragging);
                case this.h.offsetline
                    set(this.h.f, 'WindowButtonMotionFcn', @this.plot_drag_offs);
                    set(this.h.f, 'WindowButtonUpFcn', @this.stop_dragging);
                case this.h.endline
                    set(this.h.f, 'WindowButtonMotionFcn', @this.plot_drag_end);
                    set(this.h.f, 'WindowButtonUpFcn', @this.stop_dragging);
            end
        end
        
        function plot_drag_zero(this, varargin)
            this.current_draggable = 'zero';
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);

            this.h.zeroline.XData = [cpoint cpoint];
        end
        
        function plot_drag_offs(this, varargin)
            this.current_draggable = 'offs';
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
        
        function plot_drag_end(this, varargin)
            this.current_draggable = 'end';
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            if cpoint > this.x_data(end)
                cpoint = this.x_data(end);
            elseif cpoint < (this.t_offset)*this.channel_width
                cpoint = (this.t_offset + 1)*this.channel_width;
            end
            this.t_end = round(cpoint/this.channel_width);
            this.plotdata(true)
        end
        
        function stop_dragging(this, varargin)
            if strcmp(this.current_draggable, 'zero')
                cpoint = get(this.h.axes, 'CurrentPoint');
                cpoint = cpoint(1, 1);
                t = this.t_zero + round(cpoint/this.channel_width);
                n = length(this.data);

                if t <= 0
                    t = 1;
                elseif t + this.t_offset >= n - 1
                    t = n - this.t_offset - 2;
                elseif t + this.t_end >= n
                    this.t_end = n - t;
                end
                % end line sticks to the end
                if this.t_end == n - this.t_zero
                    this.t_end = n - t;
                end
                this.t_zero = t;
                this.x_data = ((1:n)-t)'*this.channel_width;
            end
            this.current_draggable = 'none';
            set(this.h.f, 'WindowButtonMotionFcn', '');
            set(this.h.f, 'WindowButtonUpFcn', '');
            this.plotdata();
        end
        
        function globalize(this, varargin)
            if ~strcmp(this.model_str, this.smode.model)
                this.smode.set_model(this.model_str);
            end
            if this.fitted
                par = this.fit_params;
            else
                par = this.est_params;
            end
            this.smode.set_gstart(par);
            this.smode.t_offset = this.t_offset;
            this.smode.t_zero = this.t_zero;
            this.smode.x_data = this.x_data;
            this.smode.t_end = this.t_end;
        end
        
        %% Export
        
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
        
        function save_data_cb(this, varargin)
            [name, path] = uiputfile('*.txt', 'Plot als PDF speichern', this.generate_filepath());
            if name == 0
                return
            end
            this.save_data([path name]);
        end
        
        function save_data_temp_cb(this, varargin)
            path = tempdir;
            name = 'sisa_temp.txt';
            this.save_data([path name]);
        end
        
        function save_data(this, path)
            fid = fopen(path, 'w');
            
            sx = size(this.x_data);
            sy = size(this.data);
            
            % only one set of x values
            if sx(1) == 1 || sx(2) == 1
                if sx(1) < sx(2)
                    x = this.x_data';
                else
                    x = this.x_data;
                end
                
                % only one set of y values
                if sy(1) == 1 || sy(2) == 1
                    if sy(1) < sy(2)
                        y = this.data';
                    else
                        y = this.data;
                    end
                    fprintf(fid, 'x,y\n');
                    fclose(fid);
                    dlmwrite(path, [x y], '-append');

                else % multiple sets of y values
                    fprintf(fid, 'x,');
                    for i = 1:sy(2)
                        if i == sy(2)
                            fprintf(fid, 'y%d\n', i);
                        else
                            fprintf(fid, 'y%d,', i);
                        end
                        
                    end
                    fclose(fid);
                    dlmwrite(path, [x this.ydata], '-append');
                end
            else % multiple sets of x values
                warndlg('Cannot currently export plot-data with more than one x-axis');
            end
            
        end
        
        function path = generate_filepath(this)
            %ToDo checken warum genericname und savepath leer sind
            point = regexprep(num2str(this.cp), '\s+', '_');
            name = [this.smode.p.genericname '_p_' point];
            path = fullfile(this.smode.p.savepath, name);
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
        
        %% Import
        
        function load_diff_data_cb(this, varargin)
            this.data_backup = this.data;
            
            path = tempdir();
            name = 'sisa_temp.txt';
            this.diff_data = dlmread([path name],',',1,0);
            
            plotdata = this.diff_data;
            plotdata(:,2) = plotdata(:,2)*0.8;
            
            this.plot_raw_data(plotdata,true)
        end
        
        function change_faktor_cb(this,caller, varargin)
            
            if strcmp(caller.Style,'slider')
                this.h.faktor_edit.String = caller.Value;
            elseif strcmp(caller.Style,'edit')
                tmp = strrep(caller.String,',','.');
                this.h.faktor_slider.Value = str2double(tmp);
            end

            plotdata = this.diff_data;
            plotdata = plotdata(:,2)*this.h.faktor_slider.Value;
            
            this.data = this.data_backup-plotdata+50;
            
            
            
            this.plotdata();
            this.plot_raw_data([this.x_data plotdata],true)
            
            
            
            
            this.plot_raw_data([this.x_data this.data_backup], true)
            
            offset = mean(this.data(end-400:end));
            this.plot_raw_data([this.x_data(1) offset;this.x_data(end) offset], 'k', 'linewidth',1.5)
            
            
            uistack(this.h.data_line,'top')
            if this.fitted
                uistack(this.h.fit_line,'top')
            end
            
            
            
        end
    end
    
    methods (Access = protected)
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

