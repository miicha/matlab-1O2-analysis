classdef SiSaGenericPlot < handle
    %GENERICPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data;
        smode;
        fitted = false;
        chisq;              % chisquared
        est_params;         % estimated parameters
        h = struct();       % handles
        fit_params;         % fitted parameters
        fit_params_err;     % ertimated errors of fitted parameters
        cp;
        diff_data;
        data_backup;
        plot_limits;
        plot_limits_default;
        sisa_fit;
        sisa_fit_info;
        export_fit_info = true;
        export_res = true;
        res;
        ub                  % upper bounds (different from parent due to sum)
        start
    end
    
    properties (Access = private)
        current_draggable;
    end
    
    methods
        function this = SiSaGenericPlot(smode)            
            %% get data from main UI
            this.smode = smode;                % keep refs to the memory in which
                                               % the UI object is saved

            this.sisa_fit_info = this.smode.sisa_fit_info;
            this.sisa_fit = this.smode.sisa_fit.copy;
            
            this.export_fit_info = smode.export_fit_info;
            this.export_res = smode.export_res;
            
            this.ub = this.smode.sisa_fit.upper_bounds;
            
            this.est_params = rand(this.sisa_fit.par_num,1);
            
            %% initialize UI objects
            
            this.h.f = figure();
            minSize = [850 650];
            
            this.h.toolbar = findall(this.h.f,'type','uitoolbar');
            this.h.xy_zoom = uitoggletool(this.h.toolbar, 'cdata', lrudarrow(),...
                                          'tooltip', 'XY-Zoom', 'OnCallback', @this.xy_zoom_cb,...
                                          'OffCallback', @this.reset_zoom_cb);
            this.h.x_zoom = uitoggletool(this.h.toolbar, 'cdata', lrarrow(),...
                                         'tooltip','X-Zoom', 'OnCallback', @this.x_zoom_cb,...
                                         'OffCallback', @this.reset_zoom_cb);

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
                this.h.res_toggle = uicontrol(this.h.exp_tab);
                this.h.info_toggle = uicontrol(this.h.exp_tab);
                this.h.save_to_db = uicontrol(this.h.exp_tab);
                
                this.h.comm_header = uicontrol(this.h.exp_tab);
                this.h.comm = uicontrol(this.h.exp_tab);
                
            this.h.imp_tab = uitab(this.h.tabs);
                this.h.import_diff_data = uicontrol(this.h.imp_tab);
                this.h.faktor_slider = uicontrol(this.h.imp_tab);
                this.h.faktor_edit = uicontrol(this.h.imp_tab);
                this.h.faktor_edit_desc = uicontrol(this.h.imp_tab,'Style','text',...
                    'String','Scaling Factor:','Position',[180 37 75 20]);

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
                            'position', [10 10 970 105]);
                        
            %% fitoptions
            set(this.h.fit_tab, 'units', 'pixels',...
                               'Title', 'Fitten');
            
            set(this.h.drpd, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', this.sisa_fit_info.model_names,...
                            'value', this.smode.model_number,...
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
                          'string', 'Globalize',...
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
                           'string', {'Chi:', num2str(this.chisq)},...
                           'position', [300 20 62 45]);
            
            set(this.h.quant, 'units', 'pixels',...
                           'style', 'text',...
                           'FontSize', 9,...
                           'position', [300 10 80 15]);
                       
            set(this.h.param, 'units', 'pixels',...
                             'position', [355 5 620 65]);
                         
            this.h.pe = cell(1, 1);
            this.h.pd = cell(1, 1);
            this.h.pc = cell(1, 1);
            this.h.pt = cell(1, 1);
            
            %% export
            set(this.h.exp_tab, 'units', 'pixels',...
                               'Title', 'Export');
                           
            set(this.h.prev_fig, 'units', 'pixels',...
                          'position', [10 40 98 28],...
                          'string', 'Preview',...
                          'FontSize', 9,...
                          'callback', @this.generate_export_fig_cb);
                      
            set(this.h.save_fig, 'units', 'pixels',...
                          'position', [10 5 98 28],...
                          'string', 'Save',...
                          'FontSize', 9,...
                          'callback', @this.save_fig_cb);
                      
            set(this.h.save_data, 'units', 'pixels',...
                          'position', [120 5 120 28],...
                          'string', 'Save Data',...
                          'FontSize', 9,...
                          'callback', @this.save_data_cb);
            
            set(this.h.save_data_temp, 'units', 'pixels',...
                          'position', [120 40 120 28],...
                          'string', 'Transfer Data',...
                          'FontSize', 9,...
                          'callback', @this.save_data_temp_cb);
             set(this.h.res_toggle, 'units', 'pixels',...
                          'style', 'checkbox',...
                          'position', [250 5 120 28],...
                          'string', 'Export residues',...
                          'value', this.export_res,...
                          'FontSize', 9,...
                          'callback', @this.toggle_res_cb);
             set(this.h.info_toggle, 'units', 'pixels',...
                          'position', [250 40 120 28],...
                          'style', 'checkbox',...
                          'value', this.export_fit_info,...
                          'string', 'Export fit info',...
                          'FontSize', 9,...
                          'callback', @this.toggle_info_cb);
                      
            set(this.h.save_to_db, 'units', 'pixels',...
                          'position', [470 5 120 28],...
                          'string', 'Save in DB',...
                          'FontSize', 9,...
                          'callback', @this.save_data_db_cb);
                      
            set(this.h.comm_header, 'units', 'pixels',...
                          'style', 'text',...
                          'position', [407 35 60 28],...
                          'string', 'Comment:',...
                          'FontSize', 9);
                  
            set(this.h.comm, 'units', 'pixels',...
                          'style', 'edit',...
                          'max', 2,...
                          'HorizontalAlignment','left',...
                          'position', [470 35 300 40],...
                          'FontSize', 9);
                      
                      
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
                            'position', [320 40 300 20],...
                            'min', 0, 'max', 3.5,...
                            'SliderStep', [0.01 0.1],...
                            'value', 0.6,...
                            'callback', @this.change_faktor_cb,...
                            'BackgroundColor', [1 1 1]);
                        
            set(this.h.faktor_edit, 'units', 'pixels',...
                            'style', 'edit',...
                            'string', '0.6',...
                            'position', [260 40 50 20],...
                            'callback', @this.change_faktor_cb);

            %% limit size with java
            drawnow;
            jFrame = get(handle(this.h.f), 'JavaFrame');
            jWindow = jFrame.fHG2Client.getWindow;
            tmp = java.awt.Dimension(minSize(1), minSize(2));
            jWindow.setMinimumSize(tmp);
            
            %% draw plot
%             this.generate_param();
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
            m = max(datal(this.sisa_fit.offset_time:this.sisa_fit.end_channel));
            m = m*1.1;
            mini = min(datal(this.sisa_fit.offset_time:end))*0.95;
           
            set(this.h.f,'CurrentAxes',this.h.axes)
            cla
            hold on
            
            
            
            x_ges = this.sisa_fit.get_x_axis();
            x_before = x_ges(1:this.sisa_fit.offset_time);
            y_before = datal(1:this.sisa_fit.offset_time);
            
            x_fit = x_ges(this.sisa_fit.offset_time:this.sisa_fit.end_channel);
            y_fit = datal(this.sisa_fit.offset_time:this.sisa_fit.end_channel);
            
            x_after = x_ges(this.sisa_fit.end_channel:end);
            y_after = datal(this.sisa_fit.end_channel:end);
            
            plot(this.h.axes, x_before, y_before, '.-', 'Color', [.8 .8 1]);
            this.h.data_line = plot(this.h.axes, x_fit, y_fit, 'Marker', '.', 'Color', [.8 .8 1], 'MarkerEdgeColor', 'blue');
            
            plot(this.h.axes, x_after, y_after, '.-', 'Color', [.8 .8 1]);
            
            this.h.zeroline = line([0 0], [0 realmax], 'Color', [.7 0 .5],... 
                      'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2, 'LineStyle', '--',...
                      'Tag', 'line');

            offset_line = this.sisa_fit.offset_time-this.sisa_fit.t_0;
            this.h.offsetline = line([offset_line offset_line]*this.sisa_fit.cw,...
                [0 realmax], 'Color', [0 .6 .5], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2,...
                'LineStyle', '-.', 'Tag', 'line');
            
            end_line = this.sisa_fit.end_channel-this.sisa_fit.t_0;
            this.h.endline = line([end_line end_line]*this.sisa_fit.cw,...
                [0 realmax], 'Color', [0 .8 .8], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2,...
                'LineStyle', '-.', 'Tag', 'line');
            hold off
            

            if ~realtime             
                ylim([0 m]);
                xlim([min(x_ges)-1 max(x_ges)+1]);
                % before refreshing the plot reset the zoom buttons
                this.h.xy_zoom.State = 'off';
                this.h.x_zoom.State = 'off';
                if this.fitted
                    this.plotfit();
                end
            end
            this.plot_limits_default.Y = [0 m];
            this.plot_limits_default.X = [min(x_ges)-1 max(x_ges)+1];
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
                    plot(this.h.axes, data(:, 1), data(:, 2), add, varargin{:})
                else
                    plot(this.h.axes, data(:, 1), data(:, 2), add)
                end
            else
                if nargin > 4 && mod(nargin - 3, 2) == 0
                    plot(this.h.axes, data(:, 1), data(:, 2), varargin{:})
                else
                    plot(this.h.axes, data(:, 1), data(:, 2))
                end
            end
                        
            if add
                hold off
            end
            
        end
        
        function plotfit(this)
            p = this.fit_params;
            
            if isempty(this.sisa_fit.x_axis)
                this.sisa_fit.estimate(this.data);
            end
            
            x_axis = this.sisa_fit.x_axis;
            fitdata_complete = this.sisa_fit.eval(this.fit_params, x_axis);
            fitdata = fitdata_complete(x_axis>=0);
            x_axis = x_axis(x_axis>=0);

            set(this.h.f,'CurrentAxes',this.h.axes)
            
            % extrahierte SiSa-Daten Plotten
            if get(this.h.drpd, 'value') == 2 || get(this.h.drpd, 'value') == 3
                sisamodel = sisafit(1);
                sisamodel.copy_data(this.sisa_fit);
                switch this.h.drpd.Value
                    case 2
                        sisadata = sisamodel.eval([p(1:3); p(5)], x_axis);
                    case 3
                        sisadata = sisamodel.eval([p(1:3); p(6)], x_axis);
                end
                hold on
                plot(this.h.axes, x_axis,  sisadata, 'color', [1 0.6 0.2], 'LineWidth', 1.5, 'HitTest', 'off');
                hold off
            end
            hold on
            this.h.fit_line = plot(this.h.axes, x_axis,  fitdata, 'r', 'LineWidth', 1.5, 'HitTest', 'off');
            hold off
            
            
            % Residuen plotten
            set(this.h.f,'CurrentAxes',this.h.res);
            
            % im fitbereich
            residues = this.data - fitdata_complete;
            tmp = this.data; 
            tmp(tmp <= 0) = 1;
            residues = residues./sqrt(tmp);
            
            x_ges = this.sisa_fit.get_x_axis();
            x_before = x_ges(1:this.sisa_fit.offset_time);
            y_before = residues(1:this.sisa_fit.offset_time);
            
            x_res = x_ges(this.sisa_fit.offset_time:this.sisa_fit.end_channel);
            y_res = residues(this.sisa_fit.offset_time:this.sisa_fit.end_channel);
            
            x_after = x_ges(this.sisa_fit.end_channel:end);
            y_after = residues(this.sisa_fit.end_channel:end);
            
            plot(this.h.res, x_res,y_res, 'b.');
            
            hold on
            % vor fitbereich
            plot(this.h.res, x_before,y_before, '.', 'Color', [.8 .8 1]);
            % nach fitbereich
            plot(this.h.res, x_after,y_after, '.', 'Color', [.8 .8 1]);
            % nulllinie
            line([min(x_ges)-1 max(x_ges)+1], [0 0], 'Color', 'r', 'LineWidth', 1.5);
            xlim([min(x_ges)-1 max(x_ges)+1]);
            m = mean(abs(y_res))*8;
            ylim([-m m]);
            hold off
            
            % update UI
            for i = 1:this.sisa_fit.par_num
                str = sprintf('%1.2f', this.fit_params(i));
                
                if length(this.smode.sisa_fit.lower_bounds) == this.sisa_fit.par_num && (abs(this.fit_params(i) - this.smode.sisa_fit.lower_bounds(i)) < 1e-4 || abs(this.fit_params(i) - this.ub(i)) < 1e-4)
                    this.h.pe{i}.BackgroundColor = [0.8 0.4 0.4];
                else
                    this.h.pe{i}.BackgroundColor = [0.9400 0.9400 0.9400];
                end

                set(this.h.pe{i}, 'string', str);
                
                str = sprintf('%1.2f', this.fit_params_err(i));   

                set(this.h.pd{i}, 'string', str,'tooltipString', '95% Konfidenz');
            end
            tmp = get(this.h.gof, 'string');
            tmp{2} = sprintf('%1.2f', this.chisq);
            set(this.h.gof, 'string', tmp);
            this.read_and_calc_quant();
        end
        
        function fit(this, varargin)
            n_param = this.sisa_fit.par_num;
            fix = zeros(this.sisa_fit.par_num,1);
            start = fix;
            for i = 1:this.sisa_fit.par_num
                start(i) = str2double(strrep(get(this.h.pe{i}, 'string'),',','.'));
                fix(i) = get(this.h.pc{i}, 'value');
            end            
            this.start = start;
            if sum(fix) == this.sisa_fit.par_num
                msgbox('Kann ohne freie Parameter nicht fitten.', 'Fehler','modal');
                return;
            end
            
            if length(this.smode.sisa_fit.lower_bounds) == length(start)
                
                this.ub = this.smode.sisa_fit.upper_bounds;
                for i = 1:length(this.ub)
                    if this.smode.sisa_fit.parnames{i}(1) ~= 't'
                        this.ub(i) = this.ub(i)*this.smode.sum_number;
                    end
                end
                this.sisa_fit.update('lower,',this.smode.sisa_fit.lower_bounds, 'upper', this.ub);
            end                
            this.sisa_fit.update('start',start,'fixed',fix, 'weighting', this.smode.sisa_fit.weighting);
            
            if length(this.diff_data) > 1
                [p, p_err, chi, this.res] = this.sisa_fit.fit(this.data_backup,this.diff_data(:,2), this.h.faktor_slider.Value);
                if strcmp(this.sisa_fit.name, 'A*(exp(-t/t1)-exp(-t/t2))+offset+B*diff_data')
                    this.data = this.data_backup;
                end
            else
                [p, p_err, chi, this.res] = this.sisa_fit.fit(this.data);
            end
            
            this.fit_params = p;
            this.fit_params_err = p_err;
            this.chisq = chi;
            this.fitted = true;
            this.plotdata();
        end
        
        function xy_zoom_cb(this, varargin)
            this.h.x_zoom.State = 'off';
            this.y_zoom()
            this.x_zoom()
        end
        
        function x_zoom_cb(this, varargin)
            this.h.xy_zoom.State = 'off';
            this.x_zoom();
            this.h.axes.YLim = this.plot_limits_default.Y;
        end
        
        function y_zoom(this)      
            y_max = max(this.data);
            this.plot_limits.Y = this.h.axes.YLim;
            this.h.axes.YLim = [0 y_max];
        end
        
        function x_zoom(this)
            x_min = 100*this.sisa_fit.cw;
            x_max = 100*this.sisa_fit.cw;
            this.plot_limits.X = this.h.axes.XLim;
            this.h.axes.XLim = [-x_min x_max];
        end
        
        function reset_zoom_cb(this, varargin)
            this.h.axes.XLim = this.plot_limits_default.X;
            this.h.axes.YLim = this.plot_limits_default.Y;
        end
        
        function read_and_calc_quant(this, varargin)
            
            path = tempdir;
            name = 'amplitude_phi.txt';
            A = this.smode.corrected_amplitude(this.fit_params, 1);
            
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
            this.fitted = false;
            tmp = sisafit(get(this.h.drpd, 'value'));
            tmp.copy_data(this.sisa_fit);
            this.sisa_fit = tmp;
            
            this.est_params = this.sisa_fit.estimate(this.data);
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
            clear('this.h.pe', 'this.h.pd', 'this.h.pct', 'this.h.pc', 'this.h.pt');

            this.h.pt = cell(this.sisa_fit.par_num, 1);
            this.h.pe = cell(this.sisa_fit.par_num, 1);
            this.h.pd = cell(this.sisa_fit.par_num, 1);
            this.h.pc = cell(this.sisa_fit.par_num, 1);
            this.h.pct = cell(this.sisa_fit.par_num, 1);
            par_names = this.sisa_fit.parnames;
            
            spacing = 80;
            for i = 1:this.sisa_fit.par_num
                 this.h.pt{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', par_names{i},...
                                                      'HorizontalAlignment', 'left',...
                                                      'FontSize', 9,...
                                                      'position', [10+(i-1)*spacing 40 41 20]);
                 this.h.pct{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', 'fix',...
                                                      'position', [43+(i-1)*spacing 40 41 20]);                                
                 this.h.pe{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'edit',...
                                                      'string', sprintf('%1.2f', par(i)),...
                                                      'position', [10+(i-1)*spacing 25 45 20]);
                 this.h.pc{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'checkbox',...
                                                      'position', [57+(i-1)*spacing 29 40 20]); 
                 this.h.pd{i} = uicontrol(this.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', '\pm',...
                                                      'HorizontalAlignment', 'left',...
                                                      'position', [10+(i-1)*spacing 5 50 15]);   
            end
            if this.sisa_fit.par_num == 0
%                 set(this.h.param, 'visible', 'off');
            else
                set(this.h.param, 'visible', 'on');
                pP = get(this.h.param, 'position');
                pP(3) = 45+(this.sisa_fit.par_num-1)*spacing+30+10;
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
            x_axis = this.sisa_fit.get_x_axis;
            if cpoint/this.sisa_fit.cw < 0.01
                cpoint = 0.01;
            elseif this.sisa_fit.t_0+cpoint/this.sisa_fit.cw >= length(x_axis)-10
                cpoint = (length(this.sisa_fit.get_x_axis)-this.t_zero-1)*this.sisa_fit.cw;
            end
            this.sisa_fit.update('offset',round(cpoint/this.sisa_fit.cw+this.sisa_fit.t_0));
            this.plotdata(true)
        end
        
        function plot_drag_end(this, varargin)
            this.current_draggable = 'end';
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            x_axis = this.sisa_fit.get_x_axis();
            if cpoint > x_axis(end)
                cpoint = x_axis(end);
            elseif cpoint < (this.sisa_fit.offset_time-this.sisa_fit.t_0)*this.sisa_fit.cw
                cpoint = (this.sisa_fit.offset_time-this.sisa_fit.t_0 + 1)*this.sisa_fit.cw;
            end
            this.sisa_fit.update('end',round(cpoint/this.sisa_fit.cw + this.sisa_fit.t_0));
            this.plotdata(true)
        end
        
        function stop_dragging(this, varargin)
            if strcmp(this.current_draggable, 'zero')
                cpoint = get(this.h.axes, 'CurrentPoint');
                cpoint = cpoint(1, 1);
                t = this.sisa_fit.t_0 + round(cpoint/this.sisa_fit.cw);
                n = length(this.data);

                
                t_offset = this.sisa_fit.offset_time - this.sisa_fit.t_0;
                t_end = this.sisa_fit.end_channel - this.sisa_fit.t_0;
                
                
                if t <= 0 % t_0 muss mindestens im ersten kanal sein
                    t = 1;
                elseif t + t_offset >= n - 1 % t_0 darf maximal 2 kanäle vor ende - offset sein
                    t = n - t_offset - 2;
                elseif t + t_end >= n        % 
                    t_end = n - t;
                end
                % end line sticks to the end
                if t_end == n - this.sisa_fit.t_0
                    t_end = n - t;
                end
                t_offset = t + t_offset;
                t_end = t + t_end;
                
                this.sisa_fit.update('t0', t, 'offset',t_offset, 'end', t_end);
            end
            this.current_draggable = 'none';
            set(this.h.f, 'WindowButtonMotionFcn', '');
            set(this.h.f, 'WindowButtonUpFcn', '');
            this.plotdata();
        end
        
        function globalize(this, varargin)  
            if this.sisa_fit.curr_fitfun ~= this.smode.sisa_fit.curr_fitfun || ...
                    this.smode.sisa_fit.t_0 ~= this.sisa_fit.t_0
                this.smode.sisa_fit.t_0 = this.sisa_fit.t_0;
                this.smode.set_model(this.sisa_fit.curr_fitfun);
            end
            if this.fitted
                par = this.fit_params;
            else
                par = this.est_params;
            end
            this.smode.set_gstart(par);
            this.smode.sisa_fit.copy_data(this.sisa_fit);
        end
        
        %% Export
        
        function save_fig_selloc_cb(this, varargin)
            [name, path] = uiputfile({'*.pdf'; '*.png'}, 'Plot speichern', this.generate_filepath());
            if name == 0
                return
            end
            this.save_fig([path name]);
            this.smode.p.set_savepath(path)
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
            this.smode.p.set_savepath(path)
        end
        
        function save_data_temp_cb(this, varargin)
            path = tempdir;
            name = 'sisa_temp.txt';
            this.save_data([path name]);
        end
        
        
        function save_data_db_cb(this, varargin)
            
            if this.fitted
                db = db_interaction('messdaten2', 'messdaten', 'testtest', 'localhost');

                fileinfo.basepath = this.smode.h.d_bpth.String;
                fileinfo.filename = [strrep(this.smode.p.openpath, fileinfo.basepath, '') this.smode.p.genericname '.h5'];
                fileinfo.ps = this.smode.h.d_ps.String;
                fileinfo.pw = double(this.smode.reader.meta.sisa.Pulsbreite);
                fileinfo.cw = this.smode.reader.meta.sisa.Kanalbreite*1000;

                fileinfo.t_0 = this.sisa_fit.t_0;

                fileinfo.probe = this.smode.h.d_probe.String;
                fileinfo.exWL = str2double(this.smode.h.d_exwl.String);
                fileinfo.sWL = str2double(this.smode.h.d_swl.String);    % aus Textfeld und config
                fileinfo.note = this.smode.h.d_note.String;    % aus Textfeld und eventuell config
                fileinfo.description = this.smode.h.d_comm.String;  % aus Datei

                pointinfo.ort = 'undefined';
                pointinfo.int_time = 7;
                pointinfo.bewertung = 0;
                pointinfo.note = '';
                pointinfo.ink = 0;
                pointinfo.messzeit = 0;

                pointinfo.name = sprintf('%i/%i/%i/%i',this.cp-1);
                pointinfo.name
                result.chisq = this.chisq;
                result.fitmodel = this.sisa_fit.name;

                result.t_zero = this.sisa_fit.t_0;
                result.fit_start = this.sisa_fit.offset_time;
                result.fit_end = this.sisa_fit.end_channel;

                result.params = this.fit_params;
                result.errors = this.fit_params_err;
                
                result.start = this.start;
                
                result.shortSiox = this.smode.h.short_siox.Value;
                
                result.parnames = this.sisa_fit.parnames;

                result.kommentar = this.h.comm.String;
                
                result.lower = this.sisa_fit.lower_bounds;
                result.upper = this.sisa_fit.upper_bounds;

                num_results_inserted = db.insert(fileinfo, pointinfo, result)
                

                db.close();
            end
        end
        
        function save_data(this, path)
            fid = fopen(path, 'w');
            
            sx = size(this.sisa_fit.get_x_axis);
            sy = size(this.data);
            
            % only one set of x values
            if sx(1) == 1 || sx(2) == 1
                if sx(1) < sx(2)
                    x = this.sisa_fit.get_x_axis';
                else
                    x = this.sisa_fit.get_x_axis;
                end
                
                % only one set of y values
                if sy(1) == 1 || sy(2) == 1
                    if sy(1) < sy(2)
                        y = this.data';
                    else
                        y = this.data;
                    end
                    if isempty(this.sisa_fit.last_params)
                        fprintf(fid, 'x,y\n');
                        fitdata = nan;
                        res = nan;
                    else
                        fprintf(fid, 'x, y, fit, x_res, res\n');
                        fitdata = this.sisa_fit.eval(this.fit_params, this.sisa_fit.x_axis);

                        res = nan(length(x),2);
                        tmp = this.sisa_fit.x_axis_fit;
                        res(end-length(tmp)+1:end,1) = tmp; 
                        tmp = this.sisa_fit.get_res;
                        res(end-length(tmp)+1:end,2) = tmp;
                    end
                    fclose(fid);
                    if isnan(fitdata)
                        dlmwrite(path, [x y], '-append');
                    else
                        dlmwrite(path, [x y fitdata res], '-append');
                    end

                else % multiple sets of y values
                    fprintf(fid, 'x,');
                    for i = 1:sy(2)
                        if i == sy(2)
                            fprintf(fid, 'y%d\n', i);
                        else
                            fprintf(fid, 'y%d, ', i);
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
            [~, ~, ext] = fileparts(path);
            ext = ext(2:end);
            already_open = false;
            if ~isfield(this.h, 'plot_pre') || (isfield(this.h, 'plot_pre') && ~ishandle(this.h.plot_pre))
                this.generate_export_fig('off');
                already_open = true;
            end
            
            save2pdf(path, 'format', ext, 'tick', 9, 'figure', this.h.plot_pre, 'width', .8)
            
            if ~already_open
                close(this.h.plot_pre)
            end
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
                   'position', [100 100 1150 780],...
                   'name', 'SISA Scan Vorschau',...
                   'Color', [.95, .95, .95],...
                   'resize', 'off');
%                    'menubar', 'none',...
%                    'resize', 'off',);
               

            ax = copyobj(this.h.axes, this.h.plot_pre);
            xlabel(ax, 'Time [$$\mu$$s]', 'interpreter', 'latex');
            ylabel(ax, 'Counts', 'interpreter', 'latex');
            
            tmp = gca;
            tmp = tmp.Children;
            for i=1:length(tmp)
                if i ==1
                    tmp(i).DisplayName = 'fit';
                elseif i ==length(tmp)-1
                    tmp(i).DisplayName = 'data';
                elseif (length(tmp) == 8 && i ==2)
                    tmp(i).DisplayName = 'estimated ^1O_2-signal';
                else
                    tmp(i).HandleVisibility = 'off';
                end
            end
               
            
            if this.fitted && this.export_res
                ax_res = copyobj(this.h.res, this.h.plot_pre);
                xlabel(ax_res, 'Time [$$\mu$$s]', 'interpreter', 'latex');
                ylabel(ax_res, 'norm. residues', 'interpreter', 'latex');
                set(ax_res, 'position', [130, 90, 1000, 120]);
                set(ax, 'position', [130, 290, 1000, 450]);
                ax_res.TickLabelInterpreter='latex';
            else
                set(ax, 'position', [130 90 1000 650]);
            end
            ax.TickLabelInterpreter='latex';
            
            plotobjs = ax.Children;
            for i = 1:length(plotobjs)
                if strcmp(plotobjs(i).Tag, 'line')
                    set(plotobjs(i), 'visible', 'off')
                end
            end
                        
            if this.fitted && this.export_fit_info
                this.generate_fit_info_ov(ax);
            else
                if this.fitted
                    h = legend('Data', 'Fit');
                else
                    h = legend('Data');
                end
                set(h, 'interpreter', 'latex');
            end
        end
        
        function toggle_info_cb(this, caller, varargin)
            this.export_fit_info = caller.Value;
            this.smode.export_fit_info = this.export_fit_info;
        end
        
        function toggle_res_cb(this, caller, varargin)
            this.export_res = caller.Value;
            this.smode.export_res = this.export_res;
        end
        
        function generate_fit_info_ov(this, ax)
            axes(ax);
            m_names = this.sisa_fit.tex_parnames;
            m_units = this.sisa_fit.tex_units;  
            func = this.sisa_fit.tex_func;
            str{1} = func;
            
            for i = 1:length(this.fit_params)
                err = roundsig(this.fit_params_err(i), 2);
                par = roundsig(this.fit_params(i), floor(log10(this.fit_params(i)/this.fit_params_err(i))) + 1);
                
                str{i+2} = ['$$ ' m_names{i} ' = (' num2str(par) '\pm ' num2str(err) ')$$ ' m_units{i}];
            end
            str{end+2} = ['$$ \chi^2 =$$ ' num2str(roundsig(this.chisq, 4))];
            m = text(.96, .90, str, 'Interpreter', 'latex',...
                                    'units', 'normalized',...
                                    'HorizontalAlignment', 'right',...
                                    'VerticalAlignment', 'top',...
                                    'FontSize', 8);
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
            x = this.sisa_fit.get_x_axis;
            
            if strcmp(caller.Style,'slider')
                this.h.faktor_edit.String = caller.Value;
            elseif strcmp(caller.Style,'edit')
                tmp = strrep(caller.String,',','.');
                this.h.faktor_slider.Value = str2double(tmp);
            end

            plotdata = this.diff_data;
            plotdata = plotdata(:,2)*this.h.faktor_slider.Value;
            this.data = this.data_backup-plotdata;
            
            this.plotdata();
            this.plot_raw_data([x plotdata],true)

            this.plot_raw_data([x this.data_backup], true)
            
            offset = mean(this.data(end-400:end));
            this.plot_raw_data([x(1) offset;x(end) offset], 'k', 'linewidth',1.5)
            
            
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

function img = lrarrow()
    img = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
           1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
           0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0
           0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0
           0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0
           0 1 1 0 1 1 1 1 1 1 1 1 0 1 1 0
           0 1 0 1 1 1 1 1 1 1 1 1 1 0 1 0
           0 0 1 1 1 1 1 1 1 1 1 1 1 1 0 0
           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
           0 0 1 1 1 1 1 1 1 1 1 1 1 1 0 0
           0 1 0 1 1 1 1 1 1 1 1 1 1 0 1 0
           0 1 1 0 1 1 1 1 1 1 1 1 0 1 1 0
           0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0
           0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0
           1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
           1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
    img(img == 1) = 0.95;
    img = repmat(img, 1, 1, 3);
end

function img = lrudarrow()
    img = [1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 1
           1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1
           1 1 1 1 1 0 1 0 1 0 1 1 1 1 1 1
           1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1
           1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1
           0 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0
           0 1 0 1 1 1 1 0 1 1 1 1 1 0 1 0
           0 0 1 1 1 1 1 0 1 1 1 1 1 1 0 0
           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
           0 0 1 1 1 1 1 0 1 1 1 1 1 1 0 0
           0 1 0 1 1 1 1 0 1 1 1 1 1 0 1 0
           0 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0
           1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1
           1 1 1 1 1 0 1 0 1 0 1 1 1 1 1 1
           1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1
           1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 1];
    img(img == 1) = 0.95;
    img = repmat(img, 1, 1, 3);
end
