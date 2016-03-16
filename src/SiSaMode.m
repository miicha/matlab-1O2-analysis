classdef SiSaMode < GenericMode
    %SISAMODE
    
    properties
        gplt = {};
        plt = {};
              
        data_sum;
        x_data;         % time data
        fit_params;
        fit_params_err;
        fit_chisq;
        est_params;
        last_fitted;
        int_time = 5;
        
        overlays = {};  % 1 is always the automatically generated overlay,
                        % additional overlays can be added
        overlay_num2name = {'', 'Overlay 1'};
        current_ov = 1;
        overlay_data;
        disp_ov = false;
        selection_props;
        
        cancel_f = false;
        hold_f = false;

        current_param = 1;
        
        disp_fit_params = 0;
        
        d_name;
        
        fitted = false;
        cmap = 'summer';
        
%         sisafit;
        
        % deprecated:
        model = '1. A*(exp(-t/t1)-exp(-t/t2))+offset';      % fit model, should be global  
        model_number = 1;
        
        channel_width = 20/1000;   % needs UI element
        t_offset = 25;   % excitation is over after t_offset channels after 
                         % maximum counts were reached - needs UI element
        t_zero = 1;      % channel in which the maximum of the excitation was reached

        t_end;
        
        sisa_fit = sisafit(1);
        sisa_fit_info;
        
        fix = {};
        gstart = [0 0 0 0];
        use_gstart = [0 0 0 0]';
        models = containers.Map(...
                 {'A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  'A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  'A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'...
                  'A*exp(-t/t1)+B*exp(-t/t2)+offset'...
                 },...
                 {...
                    % function, lower bounds, upper bounds, names of arguments
                    {@(A, t1, t2, offset, t) A*(exp(-t/t1)-exp(-t/t2))+offset, [0 0 0 0], [inf inf inf inf], {'A', 't1', 't2', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*exp(-t/t1)+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                  })
                    
        models_latex = containers.Map(...
                 {'A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  'A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  'A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'...
                  'A*(exp(-t/t1)+B*exp(-t/t2)+offset'...
                 },...
                 {...
                 { '$$f(t) = A\cdot \left[\exp \left(- \frac{t}{\tau_1}\right) - \exp \left(- \frac{t}{\tau_2}\right) \right] + o$$', {'A', '\tau_1', '\tau_2', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts'} }...
                 { '$$f(t) = A\cdot \left[\exp \left(- \frac{t}{\tau_1}\right) - \exp \left(- \frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(- \frac{t}{\tau_2}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 { '$$f(t) = A\cdot \left[\exp \left(- \frac{t}{\tau_1}\right) - \exp \left(- \frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(- \frac{t}{\tau_1}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 { '$$f(t) = A\cdot \exp \left(- \frac{t}{\tau_1}\right) + B\cdot \exp \left(- \frac{t}{\tau_2}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 })
             
%          genericname;
%          savepath;
        reader;
    end
    
    methods
        function this = SiSaMode(parent, data, reader)
            
            if nargin < 3
                reader = struct();
            end
            
            this.reader = reader;
            this.p = parent;
            
            if isfield(reader, 'meta.sisa') && isfield(reader.meta.sisa, 'int_time')
                this.int_time = reader.meta.sisa.int_time/1000;
            else
                this.int_time = this.p.scale(4)*ones(size(data(:, :, :, :, 1)));
            end
            
            this.p = parent;
            this.data = data;
            
            this.sisa_fit_info = this.sisa_fit.get_model_info();
            
            this.h.parent = parent.h.modepanel;
            
            this.scale = this.p.scale;
            this.units = this.p.units;
            this.scale(end) = mean(mean(mean(mean(this.int_time))));
            this.d_name = {'x', 'y', 'z', 'sa'};
            
            this.read_channel_width();
            
            this.h.sisamode = uitab(this.h.parent);
            
            this.h.plotpanel = uipanel(this.h.sisamode);
                this.h.plttxt = uicontrol(this.h.plotpanel);
                this.h.param = uicontrol(this.h.plotpanel);
                this.h.fit_est = uibuttongroup(this.h.plotpanel);
                    this.h.fit_par = uicontrol();
                    this.h.est_par = uicontrol();

            this.h.tabs = uitabgroup(this.h.sisamode);
                this.h.fit_tab = uitab(this.h.tabs);
                    this.h.fitpanel = uipanel(this.h.fit_tab);
                        this.h.fittxt = uicontrol(this.h.fitpanel);
                        this.h.drpd = uicontrol(this.h.fitpanel);
                        this.h.bounds = uipanel(this.h.fitpanel);
                            this.h.bounds_txt1 = uicontrol(this.h.bounds);
                            this.h.bounds_txt2 = uicontrol(this.h.bounds);
                            this.h.gstart_text = uicontrol(this.h.bounds);
                            this.h.fix_text = uicontrol(this.h.bounds);
                            this.h.glob_text = uicontrol(this.h.bounds);
                    this.h.load_data = uicontrol(this.h.fit_tab);
                    this.h.parallel = uicontrol(this.h.fit_tab);
                    this.h.fit = uicontrol(this.h.fit_tab);
                    this.h.hold = uicontrol(this.h.fit_tab);
                    this.h.ov_controls = uipanel(this.h.fit_tab);
                        this.h.ov_disp = uicontrol(this.h.ov_controls);
                        this.h.ov_sum_disp = uicontrol(this.h.ov_controls);
                        this.h.ov_buttongroup = uibuttongroup(this.h.ov_controls);
                            this.h.ov_radiobtns = {uicontrol(this.h.ov_buttongroup)};
                            this.h.ov_drpd = uicontrol(this.h.ov_controls);
                            this.h.ov_rel = uicontrol(this.h.ov_controls);
                            this.h.ov_val = uicontrol(this.h.ov_controls);
                            this.h.ov_add_from_auto = uicontrol(this.h.ov_controls);
                            this.h.add_overlay = {};

                this.h.sel_tab = uitab(this.h.tabs);
                    this.h.sel_controls = uipanel(this.h.sel_tab);
                        this.h.sel_btn_plot = uicontrol(this.h.sel_controls);
                        this.h.export_fit_btn = uicontrol(this.h.sel_controls);

                    this.h.sel_values = uipanel(this.h.sel_tab);

                this.h.pres_tab = uitab(this.h.tabs);
                    this.h.savefig = uicontrol(this.h.pres_tab);
                    this.h.prevfig = uicontrol(this.h.pres_tab);    
                    this.h.d_name_header = uicontrol(this.h.pres_tab);
                    this.h.d_scale_header = uicontrol(this.h.pres_tab);
                    this.h.d_unit_header = uicontrol(this.h.pres_tab);
                        
            
            dims = size(data);
                                
            set(this.h.sisamode, 'title', 'SiSa-Lumineszenz',...
                                 'tag', '1',...
                                 'SizeChangedFcn', @this.resize);
                %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [270 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
                            
            this.plotpanel = PlotPanel(this, dims(1:4), {'x', 'y', 'z', 's'}, this.h.plotpanel);

            set(this.h.plttxt, 'units', 'pixels',...
                             'style', 'text',...
                             'string', 'Parameter:',...
                             'position', [50 452 100 20],...
                             'HorizontalAlignment', 'left',...
                             'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                             'FontSize', 9,...
                             'visible', 'off');

            set(this.h.param, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', {},...
                            'position', [120 470 80 20],...
                            'FontSize', 9,...
                            'visible', 'off',...
                            'callback', @this.set_param_cb,...
                            'BackgroundColor', [1 1 1]);
                            
            set(this.h.est_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                              'string', 'abgeschätzt',...
                              'horizontalAlignment', 'left',...
                              'position', [10 1 100 17],...
                              'parent', this.h.fit_est);
                            
            set(this.h.fit_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                              'string', 'gefittet',...
                              'horizontalAlignment', 'left',...
                              'position', [115 1 60 17],...
                              'parent', this.h.fit_est,...
                              'visible', 'off');
                          
            set(this.h.fit_est, 'units', 'pixels',...
                              'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                              'BorderType', 'none',...
                              'SelectionChangeFcn', @this.change_par_source_cb,...
                              'position', [220 445 200 21],...
                              'visible', 'off');          
                            
            %% tabs for switching selection modes
            set(this.h.tabs, 'units', 'pixels',...
                             'position', [10 5 250 550],...
                             'visible', 'off');
                           
            %% Fitten
            set(this.h.fit_tab, 'Title', 'Fitten');
            
            set(this.h.fit,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 2 80 28],...
                           'string', 'global Fitten',...
                           'callback', @this.fit_all_cb);
                       
            set(this.h.hold, 'units', 'pixels',...
                           'style', 'push',...
                           'position', [250-80-5 2 80 28],...
                           'string', 'Fit anhalten',...
                           'visible', 'off',...
                           'callback', @this.hold_fit_cb);
                       
            set(this.h.parallel, 'units', 'pixels',...
                            'style', 'checkbox',...
                            'string', 'parallel Fitten? (keine Interaktivität!)',...
                            'tooltipString', 'Dauert am Anfang ein bisschen. Keine Fortschrittsanzeige!',...
                            'position', [2 35 200 15]);
                        
            set(this.h.load_data,  'units', 'pixels',...
                                   'style', 'push',...
                                   'position', [2 320 220 28],...
                                   'string', 'Daten laden und abziehen',...
                                   'callback', @this.load_ext_data_cb);
                        
            if isdeployed()
                set(this.h.parallel, 'visible', 'off');
            end
                        
            %% overlay control
            set(this.h.ov_controls, 'units', 'pixels',...
                                    'position', [2 260 243 200],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7]);
                              
            set(this.h.ov_buttongroup, 'units', 'pixels',...
                                       'bordertype', 'none',...
                                       'position', [2 2 237 170]);

            set(this.h.ov_disp, 'units', 'pixels',...
                              'style', 'checkbox',...
                              'position', [15 175 150 20],...
                              'string', 'Overlay anzeigen',...
                              'callback', @this.disp_ov_cb);
                          
            set(this.h.ov_sum_disp, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [120 175 115 20],...
                              'string', 'Overlay Daten Summe',...
                              'callback', @this.disp_ov_sum_cb);
                              
            set(this.h.ov_buttongroup, 'SelectionChangedFcn', @this.set_current_ov_cb);
            
            set(this.h.ov_radiobtns{1}, 'units', 'pixels',...
                                   'style', 'radiobutton',...
                                   'tag', '1',...
                                   'position', [15 135 15 15]);
                               
            set(this.h.ov_add_from_auto, 'units', 'pixels',...
                                       'style', 'pushbutton',...
                                       'string', '+',...
                                       'position', [190 134 20 20],...
                                       'callback', {@this.add_ov_cb, 1});
                                           
            set(this.h.ov_drpd, 'units', 'pixels',...
                              'style', 'popupmenu',...
                              'position', [35 125 60 30],...
                              'string', {''},...
                              'callback', @this.change_overlay_cond_cb,...
                              'BackgroundColor', [1 1 1]);
                         
            set(this.h.ov_rel, 'units', 'pixels',...
                             'style', 'popupmenu',...
                             'position', [96 125 30 30],...
                             'string', {'<', '>'},...
                             'value', 2,...
                             'callback', @this.change_overlay_cond_cb,...
                             'BackgroundColor', [1 1 1]);
            
            set(this.h.ov_val, 'units', 'pixels',...
                             'style', 'edit',...
                             'position', [127 133 60 22],...
                             'string', '',...
                             'callback', @this.change_overlay_cond_cb,...
                             'BackgroundColor', [1 1 1]); 
                         
            %% Fit-Panel:
            set(this.h.fitpanel, 'units', 'pixels',...
                               'position', [2 55 243 260],...
                               'title', 'Fit-Optionen',...
                               'bordertype', 'line',...
                               'highlightcolor', [.7 .7 .7],...
                               'FontSize', 9);

            % select fit model
            set(this.h.fittxt, 'units', 'pixels',...
                             'style', 'text',...
                             'position', [15 220 50 15],...
                             'HorizontalAlignment', 'left',...
                             'string', 'Fitmodell:');

            set(this.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', this.sisa_fit_info.model_names,...
                           'value', 1,...
                           'position', [15 205 220 15],...
                           'callback', @this.set_model_cb,...
                           'BackgroundColor', [1 1 1],...
                           'FontSize', 9);
                       
            set(this.h.bounds, 'units', 'pixels',...
                             'position', [2 10 237 180],...
                             'title', 'Fitparameter',...
                             'bordertype', 'line',...
                             'highlightcolor', [.7 .7 .7],...
                             'FontSize', 9);
                          
            set(this.h.bounds_txt1, 'units', 'pixels',...
                                  'position', [40 145 50 15],...
                                  'style', 'text',...
                                  'string', 'untere',...
                                  'horizontalAlignment', 'left');
                              
            set(this.h.bounds_txt2, 'units', 'pixels',...
                                  'position', [95 145 50 15],...
                                  'style', 'text',...
                                  'string', 'obere',...
                                  'horizontalAlignment', 'left');
                              
            set(this.h.gstart_text, 'units', 'pixels',...
                             'position', [150 145 50 15],...
                             'style', 'text',...
                             'string', 'Start',...
                             'tooltipString', 'globale Startwerte',...
                             'horizontalAlignment', 'left');
                            
            set(this.h.fix_text, 'units', 'pixels',...
                               'position', [201 145 20 15],...
                               'style', 'text',...
                               'string', 'f',...
                               'tooltipString', 'Parameter fixieren',...
                               'horizontalAlignment', 'left');
                            
            set(this.h.glob_text, 'units', 'pixels',...
                               'position', [218 145 20 15],...
                               'style', 'text',...
                               'string', 'g',...
                               'tooltipString', 'Startwerte globalisieren',...
                               'horizontalAlignment', 'left');
                            
            this.h.lb = cell(1, 1);
            this.h.ub = cell(1, 1);
            this.h.st = cell(1, 1);
            this.h.fix = cell(1, 1);
            this.h.n = cell(1, 1);
            this.h.gst = cell(1, 1);

            %% interpretation
            set(this.h.sel_tab, 'Title', 'Auswertung');
            
            set(this.h.sel_controls, 'units', 'pixels',...
                                   'position', [2 360 243 100])
      
            set(this.h.sel_btn_plot, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 50 50 20],...
                             'string', 'Plotten',...
                             'callback', @this.plot_group);
                         
            set(this.h.export_fit_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [85 50 50 20],...
                             'string', 'Export Fit',...
                             'callback', @this.export_fit_cb);
                         
            % info about the selected data
            set(this.h.sel_values, 'units', 'pixels',...
                                   'bordertype', 'line',...
                                   'highlightcolor', [.7 .7 .7],...
                                   'position', [2 100 243 250])  
            
            this.h.mean = cell(1, 1);
            this.h.var = cell(1, 1);
            this.h.par = cell(1, 1);
            
            %% meta
            set(this.h.pres_tab, 'Title', 'Meta');
                               
            set(this.h.savefig, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [2 2 80 28],...
                              'string', 'Plot speichern',...
                              'callback', @this.save_fig);
                          
            set(this.h.prevfig, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [92 2 80 28],...
                              'string', 'Vorschau',...
                              'callback', @this.generate_export_fig_cb);

            set(this.h.d_name_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [10, 220, 60, 20],...
                                      'string', 'Name');
                                  
            set(this.h.d_scale_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [80, 220, 60, 20],...
                                      'string', 'Skalierung');
                                 
            set(this.h.d_unit_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [150, 220, 60, 20],...
                                      'string', 'Einheit');
            
            % init
            tmp = size(this.data);
            
            this.overlays{1} = ones(tmp(1), tmp(2), tmp(3), tmp(4));
            this.overlays{2} = zeros(tmp(1), tmp(2), tmp(3), tmp(4));
            
            % find mean of t_0
            [~, I] = max(this.data, [], 5);
            t_0 = ceil(mean(mean(mean(mean(I)))));
            end_ch = length(this.data(1,1,1,1,:));
            
            this.sisa_fit.update('t0',t_0, 'offset',t_0+25, 'end_chan', end_ch);
            
            this.x_data = this.sisa_fit.get_x_axis();
            
            % UI stuff
            % folgende 3 Zeilen wahrscheinlich unnütz...
            par_names = this.sisa_fit_info.par_names{this.model_number};
            set(this.h.param, 'visible', 'on', 'string', [par_names, 'A_korr', 'Summe']);
            set(this.h.ov_drpd, 'string', [par_names, 'Summe']);
            
            set(this.h.plttxt, 'visible', 'on');
            set(this.h.fit_est, 'visible', 'on');
            set(this.h.tabs, 'visible', 'on');
            
            this.p.update_infos();
            
            
            this.set_model(1);
            
            this.x_data = this.sisa_fit.get_x_axis();
            
            this.change_overlay_cond_cb();
            this.plot_array();
            
            this.generate_overlay();
            
            % initialise here, so we can check whether a point is fitted or not
            s = num2cell(size(this.est_params));
            this.fit_chisq = nan(s{1:4});
            
            %% Hintergrundfarbe abhängig von DetektionswellenlÃ¤nge
            if isfield(reader, 'meta') && isfield(reader.meta, 'sisa') && isfield(reader.meta.sisa, 'Optik')
                if reader.meta.sisa.Optik == 1270
                    set(this.h.sisamode, 'background', [0.8 0.2 0.2]);
                else
                    set(this.h.sisamode, 'background', [0.2 0.2 0.8]);
                end
            end

        end
        
        function plot_array(this, varargin)
            this.generate_mean();
            [plot_data, param] = this.get_data();
            mparam = sprintf('m%d', param);
            if this.disp_ov
                this.plotpanel.plot_array(plot_data, mparam, this.overlays{this.current_ov});
            else 
                this.plotpanel.plot_array(plot_data, mparam);
            end
        end
        
        function read_channel_width(this)
            % read Channel Width
            try
                chanWidth=h5readatt(fullfile(this.p.fileinfo.path, this.p.fileinfo.name{1}), '/META/SISA', 'Channel Width (ns)');
                this.channel_width=single(chanWidth)/1000;
            catch
                % nothing. just an old file.
            end
        end
        
        function set_model(this, number)
            tmp = sisafit(number);
            tmp.copy_data(this.sisa_fit);
            this.sisa_fit = tmp;
            
            this.h.drpd.Value = number;
            
            this.model_number = number;
            str = this.sisa_fit_info.model_names{number};
            par_num = this.sisa_fit_info.par_num{number};
            par_names = this.sisa_fit_info.par_names{number};
            
            this.fit_params = nan(this.p.fileinfo.size(1), this.p.fileinfo.size(2),...
                                this.p.fileinfo.size(3), this.p.fileinfo.size(4), par_num);
            this.l_max = nan(par_num + 1, 1);
            this.l_min = nan(par_num + 1, 1);
            this.model = str;
            this.estimate_parameters();
            set(this.h.plttxt, 'visible', 'on');
            set(this.h.param, 'visible', 'on',...
                            'string', [par_names, 'A_korr', 'Summe']);
            this.plot_array();
        end
    
        function set_scale(this, scl)
            this.p.scale = scl;
            set(this.h.scale_x, 'string', this.p.scale(1));
            set(this.h.scale_y, 'string', this.p.scale(2));
        end
        
        function set_gstart(this, gst)
            this.gstart = gst;
            for i = 1:length(this.gstart);
                set(this.h.st{i}, 'string', gst(i));
            end
        end
        
        function set_param_glob(this, glob)
            if length(glob) == length(this.gstart)
                this.use_gstart = glob;
                for i = 1:length(glob)
                    set(this.h.gst{i}, 'value', glob(i))
                end
            end
        end
               
        function name = get_parname(this, index)
            fitpars = this.sisa_fit_info.par_names{this.model_number};
            if index == length(fitpars + 1)
                name = 'A_korr';
                return
            elseif index > length(fitpars)
                if this.disp_fit_params
                    name = 'Chi';
                else
                    name = 'Summe';
                end
                return
            end
            name = fitpars{index};
        end

        function generate_sel_vals(this)
            par_names = this.sisa_fit_info.par_names{this.model_number};
            
            n = length(par_names);
            for i = 1:length(this.h.mean)
                delete(this.h.mean{i});
                delete(this.h.var{i});
                delete(this.h.par{i});
            end 
            this.h.mean = cell(n, 1);
            this.h.var = cell(n, 1);
            this.h.par = cell(n, 1);
            for i = 1:n
                this.h.mean{i} = uicontrol(this.h.sel_values, 'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', sprintf('%1.2f', this.selection_props.mean(i)),...
                                                    'position', [55 155-i*23-10 45 20],...
                                                    'BackgroundColor', [1 1 1]);
                this.h.var{i} = uicontrol(this.h.sel_values, 'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', sprintf('%1.2f', this.selection_props.var(i)),...
                                                    'position', [115 155-i*23-10 45 20],...
                                                    'BackgroundColor', [1 1 1]);
                this.h.par{i} = uicontrol(this.h.sel_values,  'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string',par_names{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [15 155-i*23-14 40 20]);
            end
        end % mean, std, etc.

        function add_ov(this, init, name)
            new_ov_number = length(this.overlays)+1;
            if nargin < 3
                name = ['Overlay ' num2str(new_ov_number)];
            end
            this.overlay_num2name{new_ov_number} = name;
            this.overlays{new_ov_number} = init;
            this.generate_overlay();
            this.set_current_ov(new_ov_number);
            this.plot_array();
        end
        
        function del_ov(this, position)
            if position == 1 % cannot delete first overlay
                return
            end
            for i = position:length(this.overlay_num2name)-1
                this.overlay_num2name{i} = this.overlay_num2name{i+1};
            end
            this.overlay_num2name{end} = [];
            this.overlays(position) = [];
            this.generate_overlay();
            this.set_current_ov(this.current_ov-1);
        end
        
        function set_current_ov(this, pos)
            if pos < 1
                pos = 1;
            end
            this.current_ov = pos;
            this.plot_array();
            this.h.ov_radiobtns{pos}.Value = true;
        end
                
        function generate_overlay(this)
            ov_number = length(this.overlays);
            pos_act_r = [15 135 115 20];
            for i = 2:length(this.h.ov_radiobtns)
                delete(this.h.ov_radiobtns{i});
                delete(this.h.del_overlay{i});
                delete(this.h.add_overlay{i});
            end
            
            for i = 2:ov_number
                name = this.overlay_num2name{i};
                pos_act_r = pos_act_r-[0 25 0 0];
                this.h.ov_radiobtns{i} = uicontrol(this.h.ov_buttongroup,...
                                                 'units', 'pixels',...
                                                 'style', 'radiobutton',...
                                                 'Tag', num2str(i),...
                                                 'string', name,...
                                                 'position', pos_act_r);
                this.h.del_overlay{i} = uicontrol(this.h.ov_controls,...
                                                 'units', 'pixels',...
                                                 'style', 'pushbutton',...
                                                 'string', '-',...
                                                 'visible', 'on',...
                                                 'position', [190 pos_act_r(2) 20 20],...
                                                 'callback', {@this.del_ov_cb, i});
                this.h.add_overlay{i} = uicontrol(this.h.ov_controls,...
                                                 'units', 'pixels',...
                                                 'style', 'pushbutton',...
                                                 'string', '+',...
                                                 'visible', 'on',...
                                                 'position', [211 pos_act_r(2) 20 20],...
                                                 'callback', {@this.add_ov_cb, i});
            end
        end
        
        function set_disp_ov(this, val)
            this.disp_ov = val;
            set(this.h.ov_disp, 'Value', val);
            this.plot_array();
        end
                
        function destroy(this, children_only)
            if ~isempty(this.plt)
                for i = 1:length(this.plt)
                    if isvalid(this.plt{i}) && isa(this.plt{i}, 'SiSaPlot')
                        delete(this.plt{i}.h.f);
                        delete(this.plt{i});
                    end
                end
            end
            if ~isempty(this.gplt)
                for i = 1:length(this.gplt)
                    if isvalid(this.gplt{i}) && isa(this.gplt{i}, 'SiSaGroupPlot')
                        delete(this.gplt{i}.h.f);
                        delete(this.gplt{i});
                    end
                end
            end
            
            if ~children_only
                delete(this);
            end
        end
        
        function ind = get_current_slice(this)
            ind = this.plotpanel.get_slice();
        end
        
        function fig = get_figure(this)
            fig = this.p.get_figure();
        end
        
        function [plot_data, param] = get_data(this)
            param = this.current_param;

            if this.disp_fit_params
                switch param
                    case length(this.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = this.corrected_amplitude(this.fit_params);
                    case length(this.est_params(1, 1, 1, 1, :)) + 2
                        plot_data = this.fit_chisq;
                    otherwise
                        plot_data = this.fit_params(:, :, :, :, param);
                end
            else
                switch param
                    case length(this.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = this.corrected_amplitude(this.est_params);
                    case length(this.est_params(1, 1, 1, 1, :)) + 2
                        plot_data = this.data_sum;
                    otherwise
                        plot_data = this.est_params(:, :, :, :, param);
                end
            end
        end
        
        function [plot_data, param] = get_errs(this)
            param = this.current_param;
            
            if this.disp_fit_params
                if param <= length(this.est_params(1, 1, 1, 1, :))
                    plot_data = this.fit_params_err(:, :, :, :, param);
                else
                    plot_data = nan(size(this.fit_params_err(:, :, :, :, 1)));
                end
            else
                plot_data = nan(size(this.fit_params_err(:, :, :, :, 1)));
            end
        end
        
    % functions that actually compute something
        function compute_ov(this)
             if this.disp_fit_params
                val = str2double(get(this.h.ov_val, 'string'));
                par = get(this.h.ov_drpd, 'value');
                no_pars = size(this.fit_params, 5);
                switch get(this.h.ov_rel, 'value')
                    case 1
                        if par <= no_pars
                            this.overlays{1} = this.fit_params(:, :, :, :, par) < val;
                        else
                            this.overlays{1} = this.fit_chisq < val;
                        end
                    case 2
                        if par <= no_pars
                            this.overlays{1} = this.fit_params(:, :, :, :, par) > val;
                        else
                            this.overlays{1} = this.fit_chisq > val;
                        end
                end
            else
                val = str2double(get(this.h.ov_val, 'string'));
                par = get(this.h.ov_drpd, 'value');
                no_pars = size(this.est_params, 5);
                switch get(this.h.ov_rel, 'value')
                    case 1
                        if par <= no_pars
                            this.overlays{1} = this.est_params(:, :, :, :, par) < val;
                        else
                            this.overlays{1} = this.data_sum < val;
                        end
                    case 2
                        if par <= no_pars
                            this.overlays{1} = this.est_params(:, :, :, :, par) > val;
                        else
                            this.overlays{1} = this.data_sum > val;
                        end
                end
            end
        end

        function estimate_parameters(this)
            % ToDo in fit-tools auslagern
            sf = this.sisa_fit;
            num_par = this.sisa_fit_info.par_num{sf.curr_fitfun};
            
            this.est_params = zeros(this.p.fileinfo.size(1), this.p.fileinfo.size(2),...
                              this.p.fileinfo.size(3), this.p.fileinfo.size(4), num_par);
            ub = zeros(num_par, 1);
            lb = ones(num_par, 1)*100;
            curr_p = 0;
            for n = 1:prod(this.p.fileinfo.size)
                [i,j,k,l] = ind2sub(this.p.fileinfo.size, n);
                d = squeeze(this.data(i, j, k, l, :));
                if sum(d) == 0
                    continue
                end
                curr_p = curr_p + 1;
%                 sf.update('t0', this.t_zero, 'offset_t', this.t_zero + this.t_offset);
                ps = sf.estimate(d);
                this.est_params(i, j, k, l, :) = ps;
                if mod(curr_p, round(this.p.fileinfo.np/20)) == 0
                    this.p.update_infos(['   |   Parameter abschÃ¤tzen ' num2str(curr_p) '/' num2str(this.p.fileinfo.np) '.']);
                end
                for m = 1:length(ps) % find biggest and smallest params
                    if ps(m) > ub(m)
                        ub(m) = ps(m);
                    end
                    if ps(m) < lb(m) && ps(m) ~= 0
                        lb(m) = ps(m);
                    end
                end
            end
            this.data_sum = sum(this.data(:, :, :, :, (this.t_zero+this.t_offset):end), 5);
            this.fitted = false;
                          
            % set bounds from estimated parameters            
            this.sisa_fit.update('upper', ub*1.5, 'lower', lb*0.5);
            
            this.gstart = (ub+lb)./2;
            
            this.generate_bounds();
            this.p.update_infos();
            set(this.h.ov_val, 'string', mean(mean(mean(mean(squeeze(this.est_params(:, :, :, :, 1)))))));
        end

        function fit_all(this, start)
            outertime = tic();
            if this.disp_ov
                ma = length(find(this.overlays{this.current_ov}));
            else
                ma = prod(this.p.fileinfo.size);
            end
            % set cancel button:
            set(this.h.fit, 'string', 'Abbrechen', 'callback', @this.cancel_fit_cb);
            set(this.h.hold, 'visible', 'on');
            
            s = num2cell(size(this.est_params));
            if start == 1
                this.fit_params = nan(s{:});
                this.fit_params_err = nan(s{:});
            end
            
            g_par = find(this.use_gstart);
            
            lt = 0;
            m = 1;
            n_pixel = prod(this.p.fileinfo.size);

            % configure sisa-fit-tools
            sf = this.sisa_fit;
            sf.update('fixed',this.fix,'start',this.gstart);%, 't0', this.t_zero, 'offset_t', this.t_zero + this.t_offset);
            
            for n = start:n_pixel
                [i,j,k,l] = ind2sub(this.p.fileinfo.size, n);               
                if this.overlays{this.current_ov}(i, j, k, l) || ~this.disp_ov
                    innertime = tic();
                    y = squeeze(this.data(i, j, k, l, :));
                    
                    if n == 1
                        set(this.h.fit_par, 'visible', 'on');
                    end
                
                    if sum(y) == 0
                        continue
                    end
                    if ~isempty(g_par) % any parameter global startpoint?
                        start = squeeze(this.est_params(i, j, k, l, :));
                        start(g_par) = this.gstart(g_par);
                        sf.set_start(start);
                        [par, p_err, chi] = sf.fit(y);
                    else
                        start = squeeze(this.est_params(i, j, k, l, :)); 
                        sf.set_start(start);
                        [par, p_err, chi] = sf.fit(y);
                    end
                    m = m + 1;
                    this.fit_params(i, j, k, l, :) = par;
                    this.fit_params_err(i, j, k, l, :) = p_err;
                    this.fit_chisq(i, j, k, l) = chi;
                    this.last_fitted = n;
                    
                    lt = lt + toc(innertime);
                    
                    this.p.update_infos(['   |   Fitte ' num2str(m) '/' num2str(ma) ' (sequentiell): '...
                                    format_time(lt/m*(ma-m)) ' verbleibend.'])
                end
                
                if this.disp_fit_params
                    this.plot_array();
                end
                if this.hold_f
                    set(this.h.hold, 'string', 'Fortsetzen',...
                                   'callback', @this.resume_fit_cb);
                    return
                end
                if this.cancel_f
                    this.p.update_infos();
                    return
                end
            end
            
            t = toc(outertime);
            this.p.update_infos(['   |   Daten global gefittet (' format_time(t) ').'])
            set(this.h.hold, 'visible', 'off');
            set(this.h.fit, 'string', 'global Fitten', 'callback', @this.fit_all_cb);
            this.fitted = true;
            
            this.fit_params(i, j, k, l, :) = par;
            this.fit_params_err(i, j, k, l, :) = p_err;
            this.fit_chisq(i, j, k, l) = chi;
            this.plot_array();
        end
        
        function fit_all_parallel(this, start)
            outertime = tic();
            this.p.update_infos('   |   Starte Parallel-Pool.')
            set(this.h.fit_par, 'visible', 'on');
            % set cancel button:
            set(this.h.fit, 'string', 'Abbrechen', 'callback', @this.cancel_fit_cb);
            set(this.h.hold, 'visible', 'on');
            
            gcp(); % get or start parallel pool
            
            n_pixel = prod(this.p.fileinfo.size);
            s = num2cell(size(this.est_params));
            if start == 1
                this.fit_params = nan(s{:});
                this.fit_params_err = nan(s{:});
                this.fit_chisq = nan(s{1:end-1});
            end
            
            % initialize the local, linearily indexed arrays
            ov = reshape(this.overlays{this.current_ov}, numel(this.overlays{this.current_ov}), 1);
            d_ov = this.disp_ov;
            t_length = size(this.data, 5);
            d = reshape(this.data, n_pixel, 1, t_length);
           
            parcount = this.sisa_fit_info.par_num{this.sisa_fit.curr_fitfun};
            e_pars = reshape(this.est_params, prod(this.p.fileinfo.size), 1, parcount);
            f_pars = reshape(this.fit_params, prod(this.p.fileinfo.size), parcount);
            f_pars_e = reshape(this.fit_params_err, prod(this.p.fileinfo.size), parcount);
            f_chisq = reshape(this.fit_chisq, prod(this.p.fileinfo.size), 1);

            g_par = find(this.use_gstart);
            global_start = this.gstart;

            
            rest = mod(n_pixel - start + 1, this.p.par_size);
            inner_upper = this.p.par_size-1;

            lt = 0;
            sf = this.sisa_fit;
            sf.update('fixed',this.fix,'start',this.gstart);%, 't0', this.t_zero, 'offset_t', this.t_zero + this.t_offset);
            
            for n = start:this.p.par_size:n_pixel
                if n == start
                    this.p.update_infos(['   |   Fitte ' num2str(start) '/' num2str(prod(this.p.fileinfo.size)) ' (parallel).'])
                end
                if n == n_pixel - rest + 1
                    inner_upper = rest - 2;
                end
                
                innertime = tic();
                parfor i = 0:inner_upper
                    if (ov(n+i) || ~d_ov)
                        y = squeeze(d(n+i, :))';
                        if sum(y) == 0
                            continue;
                        end
                        if ~isempty(g_par)
                            tmp = e_pars(n+i, :);
                            tmp(g_par) = global_start(g_par);
                            sf.set_start(tmp);
                            [par, p_err, chi] = sf.fit(y);
                        else
                            sf.set_start(e_pars(n+i, :));
                            [par, p_err, chi] = sf.fit(y);
                        end
                        f_pars(n+i, :) = par;
                        f_pars_e(n+i, :) = p_err;
                        f_chisq(n+i) = chi;
                    end
                end
                lt = lt + toc(innertime);
                
                this.p.update_infos(['   |   Fitte ' num2str(n+inner_upper) '/' num2str(prod(this.p.fileinfo.size)) ' (parallel): '...
                   format_time(lt/(n+inner_upper-start)*(n_pixel-(n+inner_upper))) ' verbleibend.'])
                
                this.last_fitted = n;
                if this.disp_fit_params
                    this.fit_params = reshape(f_pars, [this.p.fileinfo.size size(f_pars, 2)]);
                    this.fit_params_err = reshape(f_pars_e, [this.p.fileinfo.size size(f_pars, 2)]);
                    this.fit_chisq = reshape(f_chisq, this.p.fileinfo.size);
                    this.plot_array();
                end
                
                if this.hold_f
                    set(this.h.hold, 'string', 'Fortsetzen',...
                                   'callback', @this.resume_fit_cb);
                    return
                end
                if this.cancel_f
                    this.p.update_infos();
                    return
                end
            end
            t = toc(outertime);
            this.p.update_infos(['   |   Daten global gefittet (' format_time(t) ').'])
            set(this.h.hold, 'visible', 'off');
            set(this.h.fit, 'string', 'global Fitten', 'callback', @this.fit_all_cb);
            
            % write back to the 'global' arrays
            this.fitted = true;
            this.fit_params = reshape(f_pars, [this.p.fileinfo.size size(f_pars, 2)]);
            this.fit_params_err = reshape(f_pars_e, [this.p.fileinfo.size size(f_pars, 2)]);
            this.fit_chisq = reshape(f_chisq, this.p.fileinfo.size);
            this.plot_array();
        end
        
        function generate_bounds(this)
            lb = this.sisa_fit.lower_bounds;
            ub = this.sisa_fit.upper_bounds;
            par_names = this.sisa_fit_info.par_names{this.sisa_fit.curr_fitfun};
            n = length(par_names);

            
            if  length(this.gstart) < n
                this.gstart = (m{2}(:)+m{3}(:))./2;
            end
            if length(this.use_gstart) < n
                this.use_gstart = [this.use_gstart; zeros(n - length(this.use_gstart), 1)];
            end
            
            for i = 1:length(this.h.lb)
                delete(this.h.lb{i});
                delete(this.h.ub{i});
                delete(this.h.n{i});
                delete(this.h.st{i});
                delete(this.h.fix{i});
                delete(this.h.gst{i});
            end 
            this.h.lb = cell(n, 1);
            this.h.ub = cell(n, 1);
            this.h.n = cell(n, 1);
            this.h.st = cell(n, 1);
            this.h.fix = cell(n, 1);
            this.h.gst = cell(n, 1);

            for i = 1:n
                this.h.n{i} = uicontrol(this.h.bounds,  'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', par_names{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [5 155-i*23-14 35 20]);
                                                
                this.h.lb{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', lb(i)),...
                                                    'position', [40 155-i*23-10 45 20],...
                                                    'callback', @this.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                this.h.ub{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f',ub(i)),...
                                                    'position', [95 155-i*23-10 45 20],...
                                                    'callback', @this.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);

                this.h.st{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', this.gstart(i)),...
                                                    'position', [150 155-i*23-10 45 20],...
                                                    'callback', @this.set_gstart_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                this.h.fix{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                     'style', 'checkbox',...
                                                     'value', ismember(par_names(i), this.fix),...
                                                     'position', [198 155-i*23-10 40 20],...
                                                     'callback', @this.set_param_fix_cb);
                                                 
                this.h.gst{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                     'style', 'checkbox',...
                                                     'value', this.use_gstart(i),...
                                                     'position', [215 155-i*23-10 40 20],...
                                                     'callback', @this.set_param_glob_cb);
            end
        end

        function generate_mean(this)
            s = size(this.fit_params);
            sel = find(this.overlays{this.current_ov});
            for i = 1:s(end)
                if this.fitted && this.disp_fit_params
                    fp = squeeze(this.fit_params(:, :, :, :, i));
                else
                    fp = squeeze(this.est_params(:, :, :, :, i));
                end
                this.selection_props.mean(i) = mean(fp(sel));
                this.selection_props.var(i) = std(fp(sel));
            end
            this.generate_sel_vals();
        end
        
        function save_fig(this, varargin)
            if this.disp_fit_params
                tmp = 'gefittet';
            else
                tmp = 'geschaetzt';
            end
            np = this.plotpanel.save_fig([this.p.savepath filesep() this.p.genericname...
                                          '_SiSa_par=' this.get_parname(this.current_param)...
                                          '_' tmp '.pdf']);
            this.p.set_savepath(np);
        end
        
        function A = corrected_amplitude(this, fit_params, phi)
            if nargin < 3
                phi = 1;
            end
            if ndims(fit_params) == 5
                A = fit_params(:, :, :, :, 1).*(1 - fit_params(:, :, :, :, 3)./fit_params(:, :, :, :, 2));
            else
                A = fit_params(1)*(1-fit_params(3)/fit_params(2));
            end
            A = abs(A/phi);
        end
        
        % mouseclicks
        function left_click_on_axes(this, index)
            if ~strcmp(this.p.fileinfo.path, '')
                if sum(this.data(index{:}, :))
                    i = length(this.plt);
                    this.plt{i+1} = SiSaPointPlot([index{:}], this);
                end
            end
        end
        
        function right_click_on_axes(this, index)
            if ~this.disp_ov
                this.set_disp_ov(true);
            end
            if ~strcmp(this.p.fileinfo.path, '')
                if sum(this.data(index{:}, :))
                    this.overlays{this.current_ov}(index{:}) = ...
                    ~this.overlays{this.current_ov}(index{:});
                end
            end
            this.plot_array();
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'Position');

            mP(4) = mP(4)-25;
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);

            tmp = get(this.h.plttxt, 'position');
            tmp(2) = pP(4)-10-tmp(4)-5;
            set(this.h.plttxt, 'position', tmp);

            tmp = get(this.h.param, 'position');
            tmp(2) = pP(4)-10-tmp(4);
            set(this.h.param, 'position', tmp);

            tmp = get(this.h.fit_est, 'position');
            tmp(2) = pP(4)-10-tmp(4);
            set(this.h.fit_est, 'position', tmp);

            tP = get(this.h.tabs, 'Position');
            tP(4) = pP(4);
            set(this.h.tabs, 'Position', tP);

            tmp = get(this.h.ov_controls, 'Position');
            tmp(2) = tP(4) - tmp(4) - 40;
            set(this.h.ov_controls, 'Position', tmp);
            set(this.h.sel_controls, 'Position', tmp);
        end
    end
    
    methods (Access = private)       
        %% Callbacks:
        function load_ext_data_cb(this, varargin)
            [name, filepath] = uigetfile({[this.p.openpath '*.fit']}, 'Dateien auswÃ¤hlen');
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            
            single = questdlg('Einzeln (bei gleichen DatensÃ¤tzen) oder den Mittelwert abziehen?',...
                              '', 'erste', 'einzeln', 'mittelwert', 'einzeln');
            this.p.openpath = filepath;
            loaded = load([filepath name], '-mat');
            this.t_zero = loaded.fit.t_zero;  
            this.t_end = length(this.x_data)-this.t_zero;
            switch single 
                case 'erste'
                    pars = num2cell(squeeze(loaded.fit.params(1,1,1,1,:)));
                    bg = loaded.fit.model(pars{:}, this.x_data(this.t_zero:end));
                    [s1, s2, s3, s4] = size(this.est_params(:, :, :, :, 1));

                    for i = 1:s1
                        for j = 1:s2
                            for k = 1:s3
                                for l = 1:s4
                                    this.data(i, j, k, l, this.t_zero:end) = squeeze(this.data(i, j, k, l, this.t_zero:end)) - bg;
                                end
                            end
                        end
                    end
                case 'mittel'
                    pars = num2cell(squeeze(mean(mean(mean(mean(loaded.fit.params, 1), 2), 3), 4)));
                    bg = loaded.fit.model(pars{:}, this.x_data(this.t_zero:end));
                    [s1, s2, s3, s4] = size(this.est_params(:, :, :, :, 1));
                    for i = 1:s1
                        for j = 1:s2
                            for k = 1:s3
                                for l = 1:s4
                                    this.data(i, j, k, l, this.t_zero:end) = squeeze(this.data(i, j, k, l, this.t_zero:end)) - bg;
                                end
                            end
                        end
                    end
                case 'einzeln'
                    [s1, s2, s3, s4] = size(loaded.fit.params(:, :, :, :, 1));
                    for i = 1:s1
                        for j = 1:s2
                            for k = 1:s3
                                for l = 1:s4
                                    pars = num2cell(squeeze(loaded.fit.params(i, j, k, l, :)));
                                    this.data(i, j, k, l, this.t_zero:end) = squeeze(this.data(i, j, k, l, this.t_zero:end)) - loaded.fit.model(pars{:}, this.x_data(this.t_zero:end));
                                end
                            end
                        end
                    end
            end
            this.data(this.data<0) = 0;
        end
        
        function export_fit_cb(this, varargin)
            if this.fitted
                [file, path] = uiputfile([this.p.savepath filesep() this.p.genericname...
                                         '.fit']);
                                     
                if ~ischar(file) || ~ischar(path) % no file selected
                    return
                end
                this.p.set_savepath(path);
                fit.params = this.fit_params;
                fit.params_err = this.fit_params_err;
                fit.chisq = this.fit_chisq;
                fit.model = this.sisa_fit_info.model_names{this.sisa_fit.curr_fitfun};
                fit.t_zero = this.t_zero;
                save([path file], 'fit');
            end
        end
        
        function change_overlay_cond_cb(this, varargin)
            this.compute_ov();
            this.plot_array();
        end
        
        function plot_group(this, varargin)
            i = length(this.gplt);
            this.gplt{i+1} = SiSaGroupPlot(this);
            this.generate_sel_vals();
        end
        
        function add_ov_cb(this, varargin)
            if varargin{1} == this.h.ov_add_from_auto
                name = [this.h.ov_drpd.String{this.h.ov_drpd.Value} ' '...
                        this.h.ov_rel.String{this.h.ov_rel.Value} ' '...
                        this.h.ov_val.String];
                this.add_ov(this.overlays{varargin{1}.Callback{2}}, name);
            else
                ov_ind = varargin{1}.Callback{2};
                this.add_ov(this.overlays{ov_ind}, [this.overlay_num2name{ov_ind} ' *']);
            end
        end
        
        function del_ov_cb(this, varargin)
            this.del_ov(varargin{1}.Callback{2});
        end
        
        function disp_ov_cb(this, varargin)
            this.set_disp_ov(varargin{1}.Value);
        end
        
        function disp_ov_sum_cb(this, varargin)
            dimensionen = size(this.data);
            n = dimensionen(end);
            auswahl = find(this.overlays{this.current_ov});
            anzahl = length(auswahl);

            auswahl = repmat(this.overlays{this.current_ov},[1 1 1 1 n]);
            
            tmp = this.data(auswahl);
            data = zeros(n,anzahl);
            
            for i = 1:anzahl
                data(:,i) =tmp(i:anzahl:n*anzahl);
            end
           
            data = sum(data,2);
            
            SiSaDataPlot(data,this);
            
        end
        
        function set_current_ov_cb(this, varargin)
            dat = varargin{2};
            this.set_current_ov(str2double(dat.NewValue.Tag));
        end
        
        function change_par_source_cb(this, varargin)
            par_names = this.sisa_fit_info.par_names{this.sisa_fit.curr_fitfun};
            ov = get(varargin{2}.OldValue, 'String');
            nv = get(varargin{2}.NewValue, 'String');
            if ~strcmp(ov, nv)
                if strcmp(nv, get(this.h.fit_par, 'string'))
                    this.disp_fit_params = true;
                    params = [par_names, 'A_korr', 'Chi^2'];
                else
                    this.disp_fit_params = false;
                    params = [par_names, 'A_korr', 'Summe'];
                end
                set(this.h.param, 'visible', 'on',...
                                  'string', params);
                
                this.generate_mean();
                if (this.fitted || this.hold_f || this.cancel_f)
                    this.compute_ov();
                end
                this.plot_array();
            end
        end
        
        function generate_export_fig_cb(this, varargin)
            this.plotpanel.generate_export_fig('on');
        end
        
        % change global start point
        function set_gstart_cb(this, varargin)
            par_num = this.sisa_fit_info.par_num{this.sisa_fit.curr_fitfun};
            ub = this.sisa_fit.upper_bounds;
            lb = this.sisa_fit.lower_bounds;
            
            tmp = zeros(par_num,1);
            for i = 1:par_num;
                tmp(i) = str2double(get(this.h.st{i}, 'string'));
                if tmp(i) < lb(i)
                    tmp(i) = lb(i);
                end
                if tmp(i) > ub(i)
                    tmp(i) = ub(i);
                end
                set(this.h.st{i}, 'string', tmp(i))
            end
            this.gstart = tmp;
        end 
                
        % fix parameter checkbox
        function set_param_fix_cb(this, varargin)
            par_names = this.sisa_fit_info.par_names{this.sisa_fit.curr_fitfun};
            n = length(par_names);
            index = 0;
            this.fix = {};
            for i = 1:n
                if get(this.h.fix{i}, 'value') == 1
                    index = index + 1;
                    if this.use_gstart(i) ~= 1
                        set(this.h.gst{i}, 'value', 1);
                        this.use_gstart(i) = 1;
                    end
                    if index == n
                        msgbox('Kann ohne freie Parameter nicht fitten.', 'Fehler', 'modal');
                        set(this.h.fix{i}, 'value', 0);
                        return;
                    end
                    this.fix{index} = par_names{i};
                end
            end
            this.set_gstart_cb();
        end
        
        % global SP checkbox
        function set_param_glob_cb(this, varargin)
            n = this.sisa_fit_info.par_num{this.sisa_fit.curr_fitfun};
            g = zeros(n,1);
            for i = 1:n
                if get(this.h.gst{i}, 'value') == 1
                    g(i) = 1;
                end
            end
            this.set_param_glob(g);
        end
       
        % fitmodel from dropdown
        function set_model_cb(this, varargin)            
            this.set_model(get(this.h.drpd, 'value'));
        end 
        
        % colormap
        function set_cmap_cb(this, varargin)
            cmaps = get(this.h.colormap_drpd, 'string'); 
            this.cmap = cmaps{get(this.h.colormap_drpd, 'value')};
            this.plot_array();
        end 
        
        % update bounds
        function set_bounds_cb(this, varargin)
            num_par = this.sisa_fit_info.par_num{this.sisa_fit.curr_fitfun};
            lb = zeros(num_par,1);
            ub = lb;
            for i = 1:num_par
                lb(i) = str2double(get(this.h.lb{i}, 'string'));
                ub(i) = str2double(get(this.h.ub{i}, 'string'));
            end
            this.sisa_fit.update('upper', ub, 'lower', lb);
        end 
        
        function set_param_cb(this, varargin)
            this.current_param = get(this.h.param, 'value');
            this.plot_array();
        end
        
        function hold_fit_cb(this, varargin)
            this.hold_f = true;
        end
        
        function fit_all_cb(this, varargin)
            this.hold_f = false;
            this.cancel_f = false;
            if get(this.h.parallel, 'value')
                this.fit_all_parallel(1);
            else
                this.fit_all(1);
            end
        end
        
        function resume_fit_cb(this, varargin)
            this.hold_f = false;
            set(this.h.hold, 'string', 'Fit anhalten', 'callback', @this.hold_fit_cb);
            if get(this.h.parallel, 'value')
                this.fit_all_parallel(this.last_fitted + this.p.par_size);
            else
                this.fit_all(this.last_fitted);
            end
        end
        
        function cancel_fit_cb(this, varargin)
            this.cancel_f = true;
            set(this.h.fit, 'string', 'global Fitten', 'callback', @this.fit_all_cb);
            set(this.h.hold, 'visible', 'off');
        end
    end
    
    methods (Static = true)
       
    end
end