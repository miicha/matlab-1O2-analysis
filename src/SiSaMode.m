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
        fit_dw;
        fit_z;
        sisa_esti;
        sisa_esti_err;
        fluo_val;
            
        est_params;
        last_fitted;
        int_time = 5;
        
        sum_number = 1;
        
        overlays = {};  % 1 is always the automatically generated overlay,
                        % additional overlays can be added
        overlay_num2name = {'', 'Overlay 1'};
        multi_select = {}
        current_ov = 1;
        overlay_data;
        disp_ov = false;
        selection_props;
        
        cancel_f = false;
        hold_f = false;

        current_param = 1;
        
        disp_fit_params = 0;
        
        sisa_data_size;
        
        d_name;
        
        fitted = false;
        cmap = 'summer';
        model;
        model_number = 1;
        
        channel_width = 20/1000;   % needs UI element
        t_offset = 25;   % excitation is over after t_offset channels after 
                         % maximum counts were reached - needs UI element
        t_zero = 1;      % channel in which the maximum of the excitation was reached

        t_end;
        
        sisa_fit = sisafit(1);
        sisa_fit_info;
        
        export_fit_info = true;
        export_res = true;
        
        fix = {};
        gstart = [0 0 0 0];
        use_gstart = [0 0 0 0]';
        reader;
        dbResults;
    end
    
    methods
        function this = SiSaMode(parent, data, reader, tag, config)
            if nargin < 4
                tag = 1;
            end
            if nargin < 3
                reader = struct();
                reader.meta.sisa.int_time = 1;
            end
            
            this.reader = reader;
            this.p = parent;
            if isfield(reader.meta, 'sisa') && isfield(reader.meta.sisa, 'int_time')
                this.int_time = double(reader.meta.sisa.int_time);
            else
                this.int_time = this.p.scale(4)*ones(size(data(:, :, :, :, 1)));
            end
            
            %% create elements
            this.p = parent;
            this.data = data;
            
            this.sisa_fit_info = this.sisa_fit.get_model_info();
            
            this.h.parent = parent.h.modepanel;
            
            if isfield(reader.meta, 'sisaScale')
                this.scale = reader.meta.sisaScale;
            else
                this.scale = this.p.scale;
            end
            this.units = this.p.units;
            this.scale(end) = mean(this.int_time(:));
            this.d_name = {'x', 'y', 'z', 'sa'};
            
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
                        this.h.short_siox = uicontrol(this.h.fitpanel);
                        this.h.short_third = uicontrol(this.h.fitpanel);
                        this.h.weighting = uicontrol(this.h.fitpanel);
                        this.h.bounds = uipanel(this.h.fitpanel);
                            this.h.bounds_txt1 = uicontrol(this.h.bounds);
                            this.h.bounds_txt2 = uicontrol(this.h.bounds);
                            this.h.gstart_text = uicontrol(this.h.bounds);
                            this.h.fix_text = uicontrol(this.h.bounds);
                            this.h.glob_text = uicontrol(this.h.bounds);
                    this.h.parallel = uicontrol(this.h.fit_tab);
                    this.h.fit = uicontrol(this.h.fit_tab);
                    this.h.hold = uicontrol(this.h.fit_tab);
                    this.h.ov_controls = uipanel(this.h.fit_tab);
                        this.h.ov_disp = uicontrol(this.h.ov_controls);
                        this.h.ov_sum_disp = uicontrol(this.h.ov_controls);
                        this.h.export_slice_disp = uicontrol(this.h.ov_controls);
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
                        this.h.histo_btn = uicontrol(this.h.sel_controls);
                        this.h.hyper_btn = uicontrol(this.h.sel_controls);
                        this.h.ML_btn = uicontrol(this.h.sel_controls);
                        
                        this.h.load_bounds_btn = uicontrol(this.h.sel_controls);
                        
                    this.h.db_btns = uipanel(this.h.sel_tab);
                        this.h.dbinsert_btn = uicontrol(this.h.db_btns);
                        this.h.dbDWUpdate_btn = uicontrol(this.h.db_btns);
                        this.h.dbcheck_btn = uicontrol(this.h.db_btns);
                        this.h.dbupdPoints_btn = uicontrol(this.h.db_btns);
                    
                    this.h.sel_values = uipanel(this.h.sel_tab);

                this.h.pres_tab = uitab(this.h.tabs);
                    this.h.savefig = uicontrol(this.h.pres_tab);
                    this.h.prevfig = uicontrol(this.h.pres_tab);
                    this.h.ch_width = uicontrol(this.h.pres_tab);
                    this.h.ch_width_label = uicontrol(this.h.pres_tab);
                    this.h.d_name_header = uicontrol(this.h.pres_tab);
                    this.h.d_scale_header = uicontrol(this.h.pres_tab);
                    this.h.d_unit_header = uicontrol(this.h.pres_tab);
                    
                    this.h.meta_controls = uipanel(this.h.pres_tab);
                        this.h.d_exwl_header = uicontrol(this.h.meta_controls);
                        this.h.d_exwl = uicontrol(this.h.meta_controls);
                        this.h.d_swl_header = uicontrol(this.h.meta_controls);
                        this.h.d_swl = uicontrol(this.h.meta_controls);
                        this.h.d_ps_header = uicontrol(this.h.meta_controls);
                        this.h.d_ps = uicontrol(this.h.meta_controls);
                        this.h.d_probe_header = uicontrol(this.h.meta_controls);
                        this.h.d_probe = uicontrol(this.h.meta_controls);
                        this.h.d_inttime = uicontrol(this.h.meta_controls);
                        
                        this.h.d_fileRating_header = uicontrol(this.h.meta_controls);
                        this.h.d_fileRating = uicontrol(this.h.meta_controls);
                        this.h.d_fitResultRating_header = uicontrol(this.h.meta_controls);
                        this.h.d_fitResultRating = uicontrol(this.h.meta_controls);
                        
                        this.h.d_comm_header = uicontrol(this.h.meta_controls);
                        this.h.d_comm = uicontrol(this.h.meta_controls);
                        this.h.d_note_header = uicontrol(this.h.meta_controls);
                        this.h.d_note = uicontrol(this.h.meta_controls);
                        this.h.d_bpth_header = uicontrol(this.h.meta_controls);
                        this.h.d_bpth = uicontrol(this.h.meta_controls);
                    
                        
            
            dims = size(data);
            
            %% format elements
                                
            set(this.h.sisamode, 'title', 'SiSa-Lumineszenz',...
                                 'tag', num2str(tag),...
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
                              'string', 'Estimates',...
                              'horizontalAlignment', 'left',...
                              'position', [10 1 100 17],...
                              'parent', this.h.fit_est);
                            
            set(this.h.fit_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                              'string', 'Fitted',...
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
            set(this.h.fit_tab, 'Title', 'Fit');
            
            set(this.h.fit,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 2 80 28],...
                           'string', 'Fit all',...
                           'callback', @this.fit_all_cb);
                       
            set(this.h.hold, 'units', 'pixels',...
                           'style', 'push',...
                           'position', [250-80-5 2 80 28],...
                           'string', 'Pause fit',...
                           'visible', 'off',...
                           'callback', @this.hold_fit_cb);
                       
            set(this.h.parallel, 'units', 'pixels',...
                            'style', 'checkbox',...
                            'string', 'Parallel Fit? (not interactive!)',...
                            'tooltipString', 'Dauert am Anfang ein bisschen. Keine Fortschrittsanzeige!',...
                            'position', [2 35 200 15]);
                        
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
                              'position', [15 175 100 20],...
                              'string', 'Overlay',...
                              'callback', @this.disp_ov_cb);
                          
            set(this.h.ov_sum_disp, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [80 175 65 20],...
                              'string', 'Over Sum',...
                              'callback', @this.disp_ov_sum_cb);
                          
            set(this.h.export_slice_disp, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [160 175 75 20],...
                              'string', 'Slice export',...
                              'callback', @this.export_slice_data_cb);
                          
                              
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
                               'title', 'Fit-Options',...
                               'bordertype', 'line',...
                               'highlightcolor', [.7 .7 .7],...
                               'FontSize', 9);

            %% select fit model
            set(this.h.fittxt, 'units', 'pixels',...
                             'style', 'text',...
                             'position', [15 240 50 15],...
                             'HorizontalAlignment', 'left',...
                             'string', 'Fitmodell:');

            set(this.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', this.sisa_fit_info.model_names,...
                           'value', 1,...
                           'position', [15 225 220 15],...
                           'callback', @this.set_model_cb,...
                           'BackgroundColor', [1 1 1],...
                           'FontSize', 9);
                       
           set(this.h.short_siox, 'units', 'pixels',...
                             'style', 'checkbox',...
                             'position', [15 134 105 15],...
                             'HorizontalAlignment', 'left',...
                             'string', 'Short SiOx',...
                             'callback', @this.update_config,...
                             'Value', config.short_siox);
                         
           set(this.h.short_third, 'units', 'pixels',...
                             'style', 'checkbox',...
                             'position', [80 134 105 15],...
                             'HorizontalAlignment', 'left',...
                             'callback', @this.update_config,...
                             'string', 'Short Third',...
                             'Value', config.short_third);
                         
           set(this.h.weighting, 'units', 'pixels',...
                             'style', 'checkbox',...
                             'position', [120 134 105 15],...
                             'HorizontalAlignment', 'left',...
                             'callback', @this.set_weighting_cb,...
                             'string', 'weighting',...
                             'Value', config.weighting);
                       
            set(this.h.bounds, 'units', 'pixels',...
                             'position', [2 2 239 180],...
                             'title', 'Fitparameter',...
                             'bordertype', 'line',...
                             'highlightcolor', [.7 .7 .7],...
                             'FontSize', 9);
                          
            set(this.h.bounds_txt1, 'units', 'pixels',...
                                  'position', [40 145 50 15],...
                                  'style', 'text',...
                                  'string', 'Lower',...
                                  'horizontalAlignment', 'left');
                              
            set(this.h.bounds_txt2, 'units', 'pixels',...
                                  'position', [95 145 50 15],...
                                  'style', 'text',...
                                  'string', 'Upper',...
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
                                   'position', [3 360 243 100])
                               
            set(this.h.histo_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 5 65 20],...
                             'string', 'Histogramm',...
                             'callback', @this.plot_histo);
                         
            set(this.h.hyper_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [85 5 60 20],...
                             'string', 'Hyper',...
                             'callback', @this.plot_hyper);
                         
            set(this.h.ML_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [150 5 60 20],...
                             'string', 'ML',...
                             'callback', @this.plot_ML);
                        
            set(this.h.load_bounds_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 70 120 20],...
                             'string', 'load bounds',...
                             'callback', @this.load_bounds);
                         
            set(this.h.export_fit_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [85 30 50 20],...
                             'string', 'Export Fit',...
                             'callback', @this.export_fit_cb);
                     
            set(this.h.sel_btn_plot, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 30 50 20],...
                             'string', 'Plotten',...
                             'callback', @this.plot_group);
            
            %% DB Buttons
            set(this.h.db_btns, 'units', 'pixels',...
                                   'position', [3 305 243 100])
                         
            set(this.h.dbinsert_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 5 60 20],...
                             'string', 'DB insert',...
                             'callback', @this.DBinsert);
                         
            set(this.h.dbDWUpdate_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [130 5 100 20],...
                             'string', 'DW-Z update',...
                             'callback', @this.DWUpdate);
                         
            set(this.h.dbupdPoints_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [130 30 100 20],...
                             'string', 'DB upd_points',...
                             'callback', @this.DBupdatePoints);
                         
            set(this.h.dbcheck_btn, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 70 60 20],...
                             'string', 'DB check',...
                             'callback', @this.DBcheck);
                         
            %% info about the selected data
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
                              'string', 'Preview',...
                              'callback', @this.generate_export_fig_cb);
                          
            set(this.h.ch_width_label, 'units', 'pixels',...
                                       'style', 'text',...
                                       'position', [10 40 170 28],...
                                       'horizontalAlignment', 'left',...
                                       'string', 'Channel Width [ns]:');
                          
            set(this.h.ch_width, 'units', 'pixels',...
                              'style', 'popupmenu',...
                              'position', [185 44 55 28],...
                              'String', {'13.33','20','40', '50', '80'},...
                              'callback', @this.change_channel_width);

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
                                  
            % -------------------------------------------------------------
                                  
            set(this.h.meta_controls, 'units', 'pixels',...
                                    'position', [2 260 243 350],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7]);
                                  
            set(this.h.d_exwl_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [10, 20, 35, 20],...
                                      'string', 'Exc.');
                                  
            set(this.h.d_exwl, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [10, 5, 35, 20],...
                                      'callback', @this.update_config);
            try
                this.h.d_exwl.String = num2str(this.reader.meta.exWL);
            end
                                  
            set(this.h.d_swl_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [50, 20, 40, 20],...
                                      'string', 'Emis.');
                                  
            set(this.h.d_swl, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [50, 5, 40, 20],...
                                      'callback', @this.update_config);
            try
                this.h.d_swl.String = num2str(this.reader.meta.sisa.wl);
            end
                                  
            set(this.h.d_ps_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [95, 20, 50, 20],...
                                      'string', 'PS');
                                  
            set(this.h.d_ps, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [95, 5, 50, 20],...
                                      'callback', @this.update_config);
                                  
            try
                this.h.d_ps.String = this.reader.meta.sample.ps;
            end
                                  
            set(this.h.d_probe_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [150, 20, 60, 20],...
                                      'string', 'Probe');
                                  
            set(this.h.d_probe, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [150, 5, 80, 20],...
                                      'string', 'Cam (IV)',...
                                      'callback', @this.update_config);
                                  
            set(this.h.d_inttime, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [10, 45, 75, 20],...
                                      'string', ['Int. Time: ' num2str(this.int_time) ' s'],... 
                                      'callback', @this.update_config);
                                  
            set(this.h.d_fileRating, 'units', 'pixels',...
                              'style', 'popupmenu',...
                              'position', [95 45 55 20],...
                              'String', {'1','2','3', '4', '5'});
            set(this.h.d_fileRating_header, 'units', 'pixels',...
                              'style', 'text',...
                              'position', [95 60 55 20],...
                              'String', 'FileRating');
                          
            set(this.h.d_fitResultRating, 'units', 'pixels',...
                              'style', 'popupmenu',...
                              'position', [160 45 55 20],...
                              'String', {'1','2','3', '4', '5'});
            set(this.h.d_fitResultRating_header, 'units', 'pixels',...
                              'style', 'text',...
                              'position', [160 60 55 20],...
                              'String', 'Fit Rating');
                                  
            set(this.h.d_comm_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [10, 130, 225, 20],...
                                      'string', 'Comment');
                                  
            set(this.h.d_comm, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [10, 85, 225, 50],...
                                      'max', 2,...
                                      'HorizontalAlignment','left',...
                                      'callback', @this.update_config);
          try
              this.h.d_comm.String = this.reader.meta.sample.description;
          end
                                  
            set(this.h.d_note_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [10, 205, 225, 20],...
                                      'string', 'Fit Result Note');
                                  
            set(this.h.d_note, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [10, 155, 225, 50],...
                                      'max', 2,...
                                      'HorizontalAlignment','left',...
                                      'callback', @this.update_config);
                                  
            set(this.h.d_bpth_header, 'units', 'pixels',...
                                      'style', 'text',...
                                      'position', [10, 275, 225, 20],...
                                      'string', 'Basepath');
                                  
            set(this.h.d_bpth, 'units', 'pixels',...
                                      'style', 'edit',...
                                      'position', [10, 240, 225, 40],...
                                      'max', 2,...
                                      'callback', @this.update_config);
            try
                this.h.d_bpth.String = this.p.basepath;
            end
            % init          
            %% get Metadata
            
            this.read_channel_width();
            
            search_start = 1;
            if this.channel_width == 0.02
                search_start = 15;
            end
            
            % find mean of t_0
            tmp = size(this.data);
            this.sisa_data_size = tmp(1:4);
            
            this.overlays{1} = ones(tmp(1), tmp(2), tmp(3), tmp(4));
            this.overlays{2} = zeros(tmp(1), tmp(2), tmp(3), tmp(4));     
            
            [max_anf, I] = max(this.data(:,:,:,:,search_start:round(size(this.data, 5)/4)), [], 5);
            
            
%             tmp = diff(this.data, 1, 5);
%             tmp2 = find(tmp>1000)
%             test = ind2sub(size(this.data),tmp2)
%             size(tmp)
%             figure(123)
%             plot(squeeze(tmp(1,1,1,1:500)))
            
            
            I = squeeze(I(:,:,1));
            I = I(:);
            [N,pos] = hist(I,1:max(I));
            [~,t_0] = max(N);
            t_0 = t_0 + search_start-1;
            
            [max_end, I] = max(this.data(:,:,:,:,round(size(this.data, 5)/4*3):end), [], 5);           
            I = squeeze(I(:,:,1));
            I = I(:);
            [N,pos] = hist(I,1:max(I));
            [~,end_ch] = max(N);

            if mean(max_anf) < mean(max_end)
                end_ch = end_ch + round(length(this.data)/4*3)-55;
            else
                end_ch = length(this.data(1,1,1,1,:));
            end
            
            this.sisa_fit.update('t0',t_0, 'offset',t_0+25, 'end_chan', end_ch, 'weighting', this.h.weighting.Value);

            % UI stuff
            
            set(this.h.plttxt, 'visible', 'on');
            set(this.h.fit_est, 'visible', 'on');
            set(this.h.tabs, 'visible', 'on');
            
            
            this.h.load_substract = uimenu(this.p.h.menu, 'Label', 'Load data and substract from current dataset',...
                                  'callback', @this.load_ext_data_cb);
  
            this.p.update_infos();
            
            this.set_model(config.last_model);
            
            this.x_data = this.sisa_fit.get_x_axis();
            
            this.change_overlay_cond_cb();
            this.plot_array();
            
            this.generate_overlay();
            
            % initialise here, so we can check whether a point is fitted or not
            s = num2cell(size(this.est_params));
            this.fit_chisq = nan(s{1:4});
            this.fit_dw = this.fit_chisq;
            this.fit_z = this.fit_chisq;
            this.sisa_esti = nan(s{1:4});
            this.sisa_esti_err = nan(s{1:4});
            this.fluo_val = this.fit_chisq;
            
            this.set_fit_bounds(config.vals);
            
            %% Hintergrundfarbe abh�ngig von Detektionswellenl�nge
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
        
        function change_channel_width(this, varargin)
            try
                this.channel_width = str2double(this.h.ch_width.String{this.h.ch_width.Value})/1000;
            catch
                this.channel_width = 0.02;
            end
            this.sisa_fit.update('c',this.channel_width);
        end
        
        function read_channel_width(this)
            % read Channel Width
            this.channel_width = this.reader.meta.sisa.Kanalbreite;
            % select channel width in dropdown
            tmp = str2double(this.h.ch_width.String);
            this.h.ch_width.Value = find(tmp == this.channel_width*1000);
            this.change_channel_width();
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
            
            this.fit_params = nan(this.sisa_data_size(1), this.sisa_data_size(2),...
                                this.sisa_data_size(3), this.sisa_data_size(4), par_num);
            this.l_max = nan(par_num + 1, 1);
            this.l_min = nan(par_num + 1, 1);
            this.model = str;
            this.estimate_parameters();
            set(this.h.plttxt, 'visible', 'on');
            
            set(this.h.ov_drpd, 'string', [par_names,'Chi^2', 'Summe','1O2 est']);
            set(this.h.param, 'visible', 'on',...
                            'string', [par_names, 'Summe']);
            this.plot_array();
            this.set_param_fix_cb();
            this.DBcheck();
        end
    
        function set_scale(this, scl)
            this.p.scale = scl;
            set(this.h.scale_x, 'string', this.p.scale(1));
            set(this.h.scale_y, 'string', this.p.scale(2));
        end
        
        function set_gstart(this, gst)
            this.gstart = gst;
            for i = 1:length(this.gstart)
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
               
        function name = get_parname(this)
            name = this.h.param.String{this.h.param.Value};
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
                    if isvalid(this.plt{i}) && isa(this.plt{i}, 'SiSaPointPlot')
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
                delete(this.h.load_substract)
                delete(this.h.sisamode)
                delete(this);
            end
        end
        
        function ind = get_current_slice(this)
            ind = this.plotpanel.get_slice();
        end
        
        function fig = get_figure(this)
            fig = this.p.get_figure();
        end
        
        function [plot_data, param] = get_data(this,varargin)
            if nargin == 2 && ~isempty(varargin{1})
                param = varargin{1}{1};
                param = cell2mat(param);
            else
                param = this.current_param;
            end

            if this.disp_fit_params
                switch param
                    case length(this.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = this.fit_chisq;
                    case length(this.est_params(1, 1, 1, 1, :)) + 2
                        plot_data = this.fit_dw;
                    case length(this.est_params(1, 1, 1, 1, :)) + 3
                        plot_data = this.fit_z;
                    case length(this.est_params(1, 1, 1, 1, :)) + 4
%                         plot_data = this.corrected_amplitude(this.fit_params);
                        plot_data = this.sisa_esti;
                    case length(this.est_params(1, 1, 1, 1, :)) + 5
                        plot_data = this.fluo_val;
                    case length(this.est_params(1, 1, 1, 1, :)) + 6
                        plot_data = this.fluo_val./this.sisa_esti;
                    otherwise
                        plot_data = this.fit_params(:, :, :, :, param);
                end
            else
                switch param
                    case length(this.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = this.data_sum;
                    otherwise
                        if param > length(this.est_params(1, 1, 1, 1, :))
                            param = length(this.est_params(1, 1, 1, 1, :));
                        end
                        plot_data = this.est_params(:, :, :, :, param);
                end
            end
        end
        
        function [plot_data, param] = get_errs(this,varargin)
            if nargin == 2 && ~isempty(varargin{1})
                param = varargin{1}{1};
                param = cell2mat(param);
            else
                param = this.current_param;
            end
            
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
                            switch par
                                case no_pars +1
                                    this.overlays{1} = this.fit_chisq < val;
                            end
                        end
                    case 2
                        if par <= no_pars
                            this.overlays{1} = this.fit_params(:, :, :, :, par) > val;
                        else
                            switch par
                                case no_pars +1
                                    this.overlays{1} = this.fit_chisq > val;
                            end
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
            sf = this.sisa_fit;
            num_par = this.sisa_fit_info.par_num{sf.curr_fitfun};
            
            this.est_params = zeros(this.sisa_data_size(1), this.sisa_data_size(2),...
                              this.sisa_data_size(3), this.sisa_data_size(4), num_par);
            ub = zeros(num_par, 1);
            lb = ones(num_par, 1)*100;
            curr_p = 0;
            short_siox = this.h.short_siox.Value;
            short_third = this.h.short_third.Value;
            for n = 1:prod(this.sisa_data_size)
                [i,j,k,l] = ind2sub(this.sisa_data_size, n);
                d = squeeze(this.data(i, j, k, l, :));
                if sum(d) == 0
                    continue
                end
                curr_p = curr_p + 1;
%                 sf.update('t0', this.t_zero, 'offset_t', this.t_zero + this.t_offset);
                ps = sf.estimate(d,short_siox,short_third);
                this.est_params(i, j, k, l, :) = ps;
                if mod(curr_p, round(this.p.fileinfo.np/20)) == 0
                    this.p.update_infos(['   |   Parameter absch�tzen ' num2str(curr_p) '/' num2str(this.p.fileinfo.np) '.']);
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
            this.data_sum = sum(this.data(:, :, :, :, (this.sisa_fit.t_0+this.sisa_fit.offset_time):end), 5);
%             this.sisa_fit.t_0+this.sisa_fit.offset_time
            this.fitted = false;
            
            
            this.gstart = (ub+lb)./2;
            if sf.curr_fitfun == 16
                lb(end) = 0;
                ub(end) = 1/2;
                this.gstart(end) = 0.8;
            end
            ub = ub*3;
            lb = lb*0.3;

            offset_index = find(strcmp(this.sisa_fit_info.par_names{this.sisa_fit.curr_fitfun},'offset'));
            lb(offset_index) = this.int_time/2-0.7;
            ub(offset_index) = this.int_time/2+0.7;
            
            % set bounds from estimated parameters            
            this.sisa_fit.update('upper', ub, 'lower', lb);
            
            
            
            this.update_fit_options_field();
            this.p.update_infos();
            set(this.h.ov_val, 'string', mean(mean(mean(mean(squeeze(this.est_params(:, :, :, :, 1)))))));
        end

        function fit_all(this, start)
            outertime = tic();
            if this.disp_ov
                ma = length(find(this.overlays{this.current_ov}));
            else
                ma = prod(this.sisa_data_size);
            end
            % set cancel button:
            set(this.h.fit, 'string', 'Abbrechen', 'callback', @this.cancel_fit_cb);
            set(this.h.hold, 'visible', 'on');
            set(this.h.fit_par, 'visible', 'on');
            
            s = num2cell(size(this.est_params));
            if start == 1
                this.fit_params = nan(s{:});
                this.fit_params_err = nan(s{:});
            end
            
            g_par = find(this.use_gstart);
            
            lt = 0;
            m = 1;
            n_pixel = prod(this.sisa_data_size);

            % configure sisa-fit-tools
            sf = this.sisa_fit;
            sf.update('fixed',this.fix,'start',this.gstart);%, 't0', this.t_zero, 'offset_t', this.t_zero + this.t_offset);
            
            for n = start:n_pixel
                [i,j,k,l] = ind2sub(this.sisa_data_size, n);               
                if ~this.disp_ov || this.overlays{this.current_ov}(i, j, k, l)
                    innertime = tic();
                    y = squeeze(this.data(i, j, k, l, :));
                
                    if sum(y) == 0
                        continue
                    end
                    
                    start = squeeze(this.est_params(i, j, k, l, :));
                    if ~isempty(g_par) % any parameter global startpoint?
                        start(g_par) = this.gstart(g_par);
                    end
                    sf.set_start(start);
                    [par, p_err, chi] = sf.fit(y);
                        
                    m = m + 1;
                    this.fit_params(i, j, k, l, :) = par;
                    this.fit_params_err(i, j, k, l, :) = p_err;
                    this.fit_chisq(i, j, k, l) = chi;
                    this.last_fitted = n;
                    [this.sisa_esti(i, j, k, l), this.sisa_esti_err(i, j, k, l)] = sf.get_sisa_estimate();
                    
                    lt = lt + toc(innertime);
                    
                    this.p.update_infos(['   |   Fitting ' num2str(m) '/' num2str(ma) ' (sequentiell): '...
                                    format_time(lt/m*(ma-m)) ' remaining.'])
                end
                
                if this.disp_fit_params
                    this.plot_array();
                end
                if this.hold_f
                    set(this.h.hold, 'string', 'Resume',...
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
            set(this.h.fit, 'string', 'Fit all', 'callback', @this.fit_all_cb);
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
            
            n_pixel = prod(this.sisa_data_size);
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
            e_pars = reshape(this.est_params, prod(this.sisa_data_size), 1, parcount);
            f_pars = reshape(this.fit_params, prod(this.sisa_data_size), parcount);
            f_pars_e = reshape(this.fit_params_err, prod(this.sisa_data_size), parcount);
            f_chisq = reshape(this.fit_chisq, prod(this.sisa_data_size), 1);
            f_s_est = f_chisq;
            f_s_est_err = f_chisq;
            fluo = f_chisq;
            f_dw = f_chisq;
            f_z = f_chisq;

            g_par = find(this.use_gstart);
            global_start = this.gstart;

            
            rest = mod(n_pixel - start + 1, this.p.par_size);
            inner_upper = this.p.par_size-1;

            lt = 0;
            sf = this.sisa_fit;
            sf.update('fixed',this.fix,'start',this.gstart);%, 't0', this.t_zero, 'offset_t', this.t_zero + this.t_offset);
            
            for n = start:this.p.par_size:n_pixel
                if n == start
                    this.p.update_infos(['   |   Fitte ' num2str(start) '/' num2str(prod(this.sisa_data_size)) ' (parallel).'])
                end
                if n == n_pixel - rest + 1
                    inner_upper = rest - 1;
                end
                
                innertime = tic();
                parfor i = 0:inner_upper
                    if (ov(n+i) || ~d_ov)
                        y = squeeze(d(n+i, :))';
                        if all(isnan(y)) || sum(y) == 0
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
                        [f_s_est(n+i), f_s_est_err(n+i)] = sf.get_sisa_estimate();
                        f_pars(n+i, :) = par;
                        f_pars_e(n+i, :) = p_err;
                        f_chisq(n+i) = chi;
                        f_dw(n+i) = sf.dw_test;
                        f_z(n+i) = sf.runstest;
                    end
                end
                lt = lt + toc(innertime);
                
                this.p.update_infos(['   |   Fitte ' num2str(n+inner_upper) '/' num2str(prod(this.sisa_data_size)) ' (parallel): '...
                   format_time(lt/(n+inner_upper-start)*(n_pixel-(n+inner_upper))) ' verbleibend.'])

                this.last_fitted = n;
                if this.disp_fit_params
                    this.fit_params = reshape(f_pars, [this.sisa_data_size size(f_pars, 2)]);
                    this.fit_params_err = reshape(f_pars_e, [this.sisa_data_size size(f_pars, 2)]);
                    this.fit_chisq = reshape(f_chisq, this.sisa_data_size);
                    this.fit_dw = reshape(f_dw, this.sisa_data_size);
                    this.fit_z = reshape(f_z, this.sisa_data_size);
                    this.sisa_esti = reshape(f_s_est, this.sisa_data_size);
                    this.sisa_esti_err = reshape(f_s_est_err, this.sisa_data_size);
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
            this.fit_params = reshape(f_pars, [this.sisa_data_size size(f_pars, 2)]);
            this.fit_params_err = reshape(f_pars_e, [this.sisa_data_size size(f_pars, 2)]);
            this.fit_chisq = reshape(f_chisq, this.sisa_data_size);
            this.fit_dw = reshape(f_dw, this.sisa_data_size);
            this.fit_z = reshape(f_z, this.sisa_data_size);
            this.sisa_esti = reshape(f_s_est, this.sisa_data_size);
            this.sisa_esti_err = reshape(f_s_est_err, this.sisa_data_size);

            for m = 1:length(this.p.modes)
                if isa(this.p.modes{m},'FluoMode')
                    n_pixel = prod(this.sisa_data_size);
                    for n = 1:n_pixel
                        [i,j,k,l] = ind2sub(this.sisa_data_size, n);
                        pointname = squeeze(this.reader.data.sisa_point_name(i, j, k, l, :));
                        this.fluo_val(i,j,k,l) = this.p.modes{m}.get_mean_value(pointname,720);
                    end
                end
            end
            this.plot_array();
        end
        
        function update_fit_options_field(this)
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
            
            
            
            % update positions and sizes
            
            fit_options_height = n*23 + 118;
            
            set(this.h.fitpanel, 'position', [2 55 243 fit_options_height]);
            
            set(this.h.fittxt, 'position', [15 n*23+85 50 15]); % 'Fitmodell'

            set(this.h.drpd, 'position', [15 n*23+70 220 15]);
            
            this.h.short_siox.Position = [15 n*23+42 105 15];
            this.h.short_third.Position = [90 n*23+42 105 15];
            this.h.weighting.Position = [170 n*23+42 105 15];
            
            fit_param_height = n*23 + 35;
                       
            set(this.h.bounds, 'position', [2 2 239 fit_param_height]);  % 'Fitparameter'
                          
            
            set(this.h.bounds_txt1, 'position', [40 fit_param_height-32 50 15]);
                              
            set(this.h.bounds_txt2, 'position', [95 fit_param_height-32 50 15]);
                              
            set(this.h.gstart_text, 'position', [150 fit_param_height-32 50 15]);
                            
            set(this.h.fix_text, 'position', [201 fit_param_height-32 20 15]);
                            
            set(this.h.glob_text, 'position', [218 fit_param_height-32 20 15]);
            
            
            fit_param_height = fit_param_height -20 ;

            for i = 1:n
                this.h.n{i} = uicontrol(this.h.bounds,  'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', par_names{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [5 fit_param_height-i*23-14 35 20]);
                                                
                this.h.lb{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', lb(i)),...
                                                    'position', [40 fit_param_height-i*23-10 45 20],...
                                                    'callback', @this.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                this.h.ub{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f',ub(i)),...
                                                    'position', [95 fit_param_height-i*23-10 45 20],...
                                                    'callback', @this.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);

                this.h.st{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', this.gstart(i)),...
                                                    'position', [150 fit_param_height-i*23-10 45 20],...
                                                    'callback', @this.set_gstart_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                this.h.fix{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                     'style', 'checkbox',...
                                                     'value', ismember(par_names(i), this.fix),...
                                                     'position', [198 fit_param_height-i*23-10 40 20],...
                                                     'callback', @this.set_param_fix_cb);
                                                 
                this.h.gst{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                     'style', 'checkbox',...
                                                     'value', this.use_gstart(i),...
                                                     'position', [215 fit_param_height-i*23-10 40 20],...
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
                                          '_SiSa_par=' this.get_parname()...
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
        function click_on_axes_cb(this, index, button, shift, ctrl, alt)
            if ~strcmp(this.p.fileinfo.path, '')
                if button == 1 % left
%                     if sum(this.data(index{:}, :))
                    if ~isnan(this.data(index{:}))
                        i = length(this.plt);
                        this.sum_number = 1;
                        this.plt{i+1} = SiSaPointPlot([index{:}], this);
                    end
                elseif button == 3 % right
                    if ~this.disp_ov
                        this.set_disp_ov(true);
                    end
                    if all(~isnan(this.data(index{:})))
                        if shift || ~isempty(this.multi_select) % switch rectangle
                            if ~isempty(this.multi_select)
                                indrange = {};
                                for i = 1:length(index)
                                    i1 = this.multi_select{i};
                                    i2 = index{i};
                                    if i1 > i2
                                        indrange{i} = i2:i1;
                                    else
                                        indrange{i} = i1:i2;
                                    end
                                end
                                
                                this.overlays{this.current_ov}(indrange{:}) = ...
                                  ~this.overlays{this.current_ov}(indrange{:});
                                
                                this.multi_select = {};
                            else
                                this.multi_select = index;
                            end
                        else % point
                            this.overlays{this.current_ov}(index{:}) = ...
                              ~this.overlays{this.current_ov}(index{:});
                        end
                    end
                    this.plot_array();
                end
            end
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
            
            tmp = this.h.sel_controls.Position;
            tmp(2) = tP(4) - tmp(4) - 40;
            
            set(this.h.sel_controls, 'Position', tmp);
            tmp(2) = tmp(2) - 105;
            this.h.db_btns.Position = tmp;
        end
        
        function vals = get_fit_bounds(this, varargin)
            par_num = this.sisa_fit_info.par_num{this.sisa_fit.curr_fitfun};
            vals = nan(par_num,3);
            for i = 1:par_num
                    vals(i,1) = str2double(strrep(get(this.h.lb{i}, 'string'),',','.'));
                    vals(i,2) = str2double(strrep(get(this.h.ub{i}, 'string'),',','.'));
                    vals(i,3) = str2double(strrep(get(this.h.st{i}, 'string'),',','.'));
            end
        end
        
        function set_fit_bounds(this, vals)
            par_num = this.sisa_fit_info.par_num{this.sisa_fit.curr_fitfun}-1;
            if par_num > size(vals,1)
                par_num = size(vals,1);
            end
            for i = 1:par_num
                this.h.lb{i}.String = num2str(vals(i,1));
                this.h.ub{i}.String = num2str(vals(i,2));
                this.h.st{i}.String = num2str(vals(i,3));
            end
            this.set_bounds_cb();
        end
    end
    
    methods (Access = private)       
        %% Callbacks:
        function load_ext_data_cb(this, varargin)
            [name, filepath] = uigetfile({[this.p.openpath '*.fit']}, 'Dateien ausw�hlen');
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            
            single = questdlg('Einzeln (bei gleichen Datensätzen) oder den Mittelwert abziehen?',...
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
        
        function plot_histo(this, varargin)
            params = this.get_overlay_selection_data(this.fit_params);
            ParameterHistogram(params, this.sisa_fit.parnames);
        end
        
        function plot_hyper(this, varargin)
            this.reader.meta.sample.measure_time - this.reader.meta.sample.prep_time
            t = datetime(this.reader.meta.sample.prep_time,'ConvertFrom','posixtime') 
            hy = hyper([this.p.openpath this.p.genericname '.h5'],...
                       [this.sisa_fit.offset_time this.sisa_fit.t_0],...
                        this.reader,...
                        this.p.db_config,...
                        this.collect_fileinfo(), this.p);
                    
%             this.reader.meta.pointinfo.point_time
        end
        
        function plot_ML(this, varargin)
            m = ML([this.p.openpath this.p.genericname '.h5'],...
                       [this.sisa_fit.offset_time this.sisa_fit.t_0],...
                        this.reader,...
                        this.p.db_config,...
                        this.collect_fileinfo(), this.p);
                    
%             this.reader.meta.pointinfo.point_time
        end
        
        function fileinfo = collect_fileinfo(this)
            fileinfo.basepath = this.h.d_bpth.String;
            fileinfo.filename = [strrep(this.p.openpath, fileinfo.basepath, '') this.p.genericname '.h5'];
            fileinfo.ps = this.h.d_ps.String;
            fileinfo.pw = double(this.reader.meta.sisa.Pulsbreite);
            fileinfo.cw = this.reader.meta.sisa.Kanalbreite*1000;
            fileinfo.t_0 = this.sisa_fit.t_0;
            fileinfo.rating = this.h.d_fileRating.Value;
            
            fileinfo.probe = this.h.d_probe.String;
            fileinfo.exWL = str2double(this.h.d_exwl.String);
            fileinfo.sWL = str2double(this.h.d_swl.String);    % aus Textfeld und config
            fileinfo.note = 'irgendwas'; %this.h.d_note.String;    % aus Textfeld und eventuell config
            fileinfo.description = this.h.d_comm.String;  % aus Datei
        end
        
        function DBinsert(this, varargin)
            db = db_interaction(this.p.db_config);
            db.set_progress_cb(@(x) this.p.update_infos(x));
            
            fileinfo = this.collect_fileinfo();
            [pointinfo, result] = this.collectPointInfoResults;

            num_results_inserted = db.insert(fileinfo, pointinfo, result);
            sprintf('Es wurden %i Ergebnisse von insegsamt %i in die Datenbank eingetragen.', num_results_inserted, length(result))
            
            db.close();
        end
        
        function DWUpdate(this, varargin)
            db = db_interaction(this.p.db_config);
            db.set_progress_cb(@(x) this.p.update_infos(x));
            
            fileinfo = this.collect_fileinfo();
            [pointinfo, result] = this.collectPointInfoResults;
            
            num_results_inserted = db.addDWZ(fileinfo, pointinfo, result, this.dbResults);
            sprintf('Es wurden %i Ergebnisse von insegsamt %i in der Datenbank aktualisiert.', num_results_inserted, length(result))
            
            db.close();
        end
        
        function [pointinfo, result] = collectPointInfoResults(this)
            if this.disp_ov
                num_points = length(find(this.overlays{this.current_ov}));
            else
                num_points = prod(this.sisa_data_size);
            end
            s = prod(this.sisa_data_size);
            ii = 0;
%             pointinfo = repmat( struct( 'name', 1 ), num_points, 1 );
%             result = repmat( struct( 'ort', 1 ), num_points, 1 );
            
            g_par = find(this.use_gstart);
            
            short_siox = this.h.short_siox.Value;
            weighting = this.h.weighting.Value;
            for n = 1:s
                [i,j,k,l] = ind2sub(this.sisa_data_size, n);               
                if all(~isnan(this.data(i, j, k, l))) && (~this.disp_ov || this.overlays{this.current_ov}(i, j, k, l))
                    ii = ii+1;                    
                    pointinfo(ii).ort = 'undefined';
                    pointinfo(ii).int_time = this.int_time;
                    pointinfo(ii).note = '';
                    
                    [~,indx]=ismember(this.reader.meta.pointinfo.point_names,[i-1,j-1,k-1],'rows');                    
                    try
                        pointinfo(ii).messzeit = round(this.reader.meta.pointinfo.point_time(indx == 1));
                    catch
                        pointinfo(ii).messzeit = 0;
                    end
                    pointinfo(ii).ink = (this.reader.meta.sample.measure_time - this.reader.meta.sample.prep_time) + pointinfo(ii).messzeit; % in seconds
                    
                    try
                        name = sprintf('%i/%i/%i/%i',squeeze(this.reader.data.sisa_point_name(i, j, k, l, :))-1);
                    catch
                        name = sprintf('%i/%i/%i/%i',i-1,j-1,k-1,l-1);
                    end
                    pointinfo(ii).name = name;
                    
                    pointinfo(ii).sisa_intens = squeeze(this.sisa_esti(i,j,k,l,:));
                    pointinfo(ii).sisa_intens_err = squeeze(this.sisa_esti_err(i,j,k,l,:));
                    pointinfo(ii).fluo_val = squeeze(this.fluo_val(i,j,k,l,:));
                    
                    result(ii).chisq = squeeze(this.fit_chisq(i,j,k,l,:));
                    result(ii).DW = squeeze(this.fit_dw(i,j,k,l,:));
                    result(ii).Z = squeeze(this.fit_z(i,j,k,l,:));
                    
                    result(ii).fitmodel = this.sisa_fit.name;

                    result(ii).t_zero = this.sisa_fit.t_0;
                    result(ii).fit_start = this.sisa_fit.offset_time;
                    result(ii).fit_end = this.sisa_fit.end_channel;
                    
                    result(ii).params = squeeze(this.fit_params(i,j,k,l,:));
                    result(ii).parnames = this.sisa_fit.parnames;
                    
                    result(ii).errors = squeeze(this.fit_params_err(i,j,k,l,:));
                    
                    start = squeeze(this.est_params(i, j, k, l, :));
                    if ~isempty(g_par) % any parameter global startpoint?
                        start(g_par) = this.gstart(g_par);
                    end                    
                    result(ii).start = start;
                    
                    result(ii).lower = this.sisa_fit.lower_bounds;
                    result(ii).upper = this.sisa_fit.upper_bounds;
                    result(ii).shortSiox = short_siox;
                    result(ii).weighting = weighting;
                    
                    result(ii).rating = this.h.d_fitResultRating.Value;
                    result(ii).kommentar = this.h.d_note.String;
                    
                end
            end
        end
  
        function DBcheck(this, varargin)
            if ~this.p.databasefunction
                return
            end
            basepath = this.h.d_bpth.String;
            filename = [strrep(this.p.openpath, basepath, '') this.p.genericname '.h5'];
            db = db_interaction(this.p.db_config);
            [points_in_db,anzahl_in_db] = db.check_file_exists(basepath, filename, this.model);
            anz = {'Points in DB', 'Points in File', 'Results';points_in_db,prod(this.sisa_data_size),anzahl_in_db};
            disp(anz)
            
            if strcmp(this.p.h.config_database_no_DWZ.Checked,'on')
                result = db.getNoDWZ(basepath, filename, this.model);
                this.dbResults = result;
                if ~isempty(result)
                    save([tempdir 'result_table.mat'],'result');
                    lb = zeros(length(this.sisa_fit.parnames),1);
                    ub = lb;
                    parnames = cell(length(this.sisa_fit.parnames),1);
                    parnames_start = parnames;
                    for i = 1:length(this.sisa_fit.parnames)
                        switch this.sisa_fit.parnames{i}
                            case 'A'
                                parname = 'A1';
                            case 'B'
                                parname = 'A2';
                            case 'tD'
                                parname = 't1';
                            case 'tT'
                                parname = 't2';
                            otherwise
                                parname = this.sisa_fit.parnames{i};
                        end
                        parnames{i} = parname;
                        parnames_start{i} = [parname '_start'];
                        low_name = [parname '_lo'];
                        up_name = [parname '_up'];
                        lb(i,1) = min(result.(low_name));
                        ub(i,1) = max(result.(up_name));
                    end
                    
                    t_0 = mean(result.t_zero);
                    fit_start = mean(result.fit_start);
                    
                    this.sisa_fit.update('upper', ub, 'lower', lb,'t0',t_0, 'offset',fit_start);
                    
                    this.update_fit_options_field();
                    % Fitergebnis aus DB als Startwerte setzen
                    for n = 1:prod(this.sisa_data_size)
                        [i,j,k,l] = ind2sub(this.sisa_data_size, n);
                        name = squeeze(this.reader.data.sisa_point_name(i, j, k, l, :))-1;
                        try
                            pointname = join(string(name),'/');
                            startwert = table2array(result(pointname,parnames_start));
                            this.est_params(i, j, k, l, :) = startwert;
                        catch
                            [pointname ' wurde nicht in DB gefunden']
                        end
                    end
                    
                    for i = 1:length(parnames)
                        if std(result.(parnames{i}))< 1e-10
                            ['Achtung, ' parnames{i} ' fixieren']
                            mean(result.(parnames{i}))
                        end
                    end
                    
                    figure
                    subplot(1,2,1)
                    boxplot(result.chisq)
                    subplot(1,2,2)
                    histogram(result.chisq)
                end
            end
            db.close();
            if anzahl_in_db > 1
                this.h.sisamode.BackgroundColor = [0.3 .8 .5];
            else
                this.h.sisamode.BackgroundColor = [0.9400 0.9400 0.9400];
            end
        end
        
        function DBupdatePoints(this, varargin)
            type = 'correct_pointname';
            
            db = db_interaction(this.p.db_config);
            db.set_progress_cb(@(x) this.p.update_infos(x));
            fileinfo = this.collect_fileinfo();
            
            switch type
                case 'add_dw_z'
                    
                case 'correct_pointname'
                    if this.disp_ov
                        num_points = length(find(this.overlays{this.current_ov}));
                    else
                        num_points = prod(this.sisa_data_size);
                    end
                    s = prod(this.sisa_data_size);
                    ii = 0;
                    pointinfo = repmat( struct( 'name', 1 ), num_points, 1 );
                    jj = 0;
                    for n = 1:s
                        [i,j,k,l] = ind2sub(this.sisa_data_size, n);
                        if ~isnan(squeeze(this.sisa_esti(i,j,k,l,:)))
                            jj = jj+1;
                        end
                        if ~this.disp_ov || this.overlays{this.current_ov}(i, j, k, l)
                            ii = ii+1;                    
                            pointinfo(ii).ort = 'undefined';
                            pointinfo(ii).int_time = this.int_time;
                            pointinfo(ii).note = '';

                            [~,indx]=ismember(this.reader.meta.pointinfo.point_names,[i-1,j-1,k-1],'rows');                    
                            try
                                pointinfo(ii).messzeit = round(this.reader.meta.pointinfo.point_time(indx == 1));
                            catch
                                pointinfo(ii).messzeit = 0;
                            end
                            pointinfo(ii).ink = (this.reader.meta.sample.measure_time - this.reader.meta.sample.prep_time) + pointinfo(ii).messzeit; % in seconds
                            
                            pointinfo(ii).name = sprintf('%i/%i/%i/%i',i-1,j-1,k-1,l-1);
                            pointinfo(ii).realname = sprintf('%i/%i/%i/%i',squeeze(this.reader.data.sisa_point_name(i, j, k, l, :))-1);
                            
                            pointinfo(ii).sisa_intens = squeeze(this.sisa_esti(i,j,k,l,:));
                            pointinfo(ii).sisa_intens_err = squeeze(this.sisa_esti_err(i,j,k,l,:));
                            pointinfo(ii).fluo_val = squeeze(this.fluo_val(i,j,k,l,:));
                        end
                    end
                    jj
                    num_results_updated = db.updatePointInfo(fileinfo, pointinfo);
                    
                    sprintf('Es wurden %i Punkte von insegsamt %i in der Tabelle datapointinfos aktualisiert.', num_results_updated, ii)
            end
            db.close();
        end
        
        function load_bounds(this, varargin)
            p = get_executable_dir();
            [FILENAME, PATHNAME] = uigetfile([p filesep() '*.mat'], 'irgendwas');
            if ~FILENAME
                return
            end
            file = [PATHNAME FILENAME];
            vals = load(file);
            try
                this.set_fit_bounds(vals.vals);
            end
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
            data = this.get_overlay_selection_data(this.data);
            this.sum_number = size(data,1);
            data = sum(data,1)';
            SiSaDataPlot(data,this);
        end
        
        function data = get_overlay_selection_data(this,data,varargin)
            if this.disp_ov
                dimensionen = size(data);
                n = dimensionen(end);
                anzahl = sum(this.overlays{this.current_ov}(:));
                auswahl = repmat(this.overlays{this.current_ov},[1 1 1 1 n]);
                data = reshape(data(logical(auswahl)),anzahl,n);
            else
                data = reshape(data,[],size(data,5));
            end
        end
        
        function export_slice_data_cb(this, varargin)
%             this.get_current_slice()
            num_params = size(this.fit_params,5)+2;
            
            for i = 1:num_params
                [~, plot_vec, plot_vec_err] = this.plotpanel.slices{end}.get_slice_data(i);
                slice_data(i,:) = plot_vec;
                slice_error_data(i,:) = plot_vec_err;
            end
            export_data{1} = this.sisa_fit.parnames;
            export_data{2} = slice_data;
            export_data{3} = slice_error_data;

%             this.p.savepath
            [FILENAME, PATHNAME] = uiputfile([this.p.savepath '.mat']);
            
            if FILENAME > 0
                save([PATHNAME FILENAME], 'export_data');
            end
%             export_data
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
                    params = [par_names, 'Chi^2','DW','Z','SiSa_esti', 'Fluo', 'Fluo/SiSa'];
                else
                    this.disp_fit_params = false;
                    params = [par_names, 'Summe'];
                end

                set(this.h.param, 'visible', 'on',...
                                  'string', params);
                if length(params) < this.h.param.Value
                    this.h.param.Value = length(params);
                end
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
            this.use_gstart = tmp;
            for i = 1:par_num
                this.use_gstart(i) = this.h.gst{i}.Value;
                tmp(i) = str2double(strrep(get(this.h.st{i}, 'string'),',','.'));
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
            this.set_model(this.h.drpd.Value);
            this.update_config();
        end 
        
        function set_weighting_cb(this, varargin)
            this.sisa_fit.update('weighting', this.h.weighting.Value);
            this.update_config();
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
                lb(i) = str2double(strrep(get(this.h.lb{i}, 'string'),',','.'));
                ub(i) = str2double(strrep(get(this.h.ub{i}, 'string'),',','.'));
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
            
            figure
            subplot(1,2,1)
            boxplot(this.fit_chisq(:))
            ylabel('\chi^2')

            subplot(1,2,2)
            histogram(this.fit_chisq(:))
            title('\chi^2 Verteilung aus Fit')
            xlabel('\chi^2')
            
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
        
        function update_config(this, varargin)
            this.p.siox_config.short_siox = this.h.short_siox.Value;
            this.p.siox_config.short_third = this.h.short_third.Value;
            this.p.siox_config.weighting = this.h.weighting.Value;
            this.p.siox_config.last_model = this.h.drpd.Value;
            this.p.basepath = this.h.d_bpth.String;
            this.p.saveini();
        end
    end
    
    methods (Static = true)
       
    end
end