classdef SiSaMode < handle
    %SISAMODE
    
    properties
        gplt = {};
        plt = {};
        
        p;            % parent, generic UI object
        h = struct(); % GUI handles
        
        data;       % source data from HDF5
        data_sum;
        x_data;         % time data
        fit_params;
        fit_params_err;
        fit_chisq;
        est_params;
        last_fitted;
        
        overlays = {};  % 1 is always the automatically generated overlay,
                        % additional overlays can be added
        current_ov = 1;
        overlay_data;
        disp_ov = false;
        selection_props;
        
        cancel_f = false;
        hold_f = false;
        model = '1. A*(exp(-t/t1)-exp(-t/t2))+offset';      % fit model, should be global  
        
        channel_width = 20/1000;   % needs UI element
        t_offset = 25;   % excitation is over after t_offset channels after 
                         % maximum counts were reached - needs UI element
        t_zero = 1;      % channel in which the maximum of the excitation was reached
        
        % slices to be displayed
        curr_dims = [1, 2, 3, 4];
        ind = {':', ':', 1, 1};
        transpose = false;

        current_param = 1;
        
        disp_fit_params = 0;
        l_min; % maximum of the current parameter over all data points
        l_max; % minimum of the current parameter over all data points
        use_user_legend = false;
        user_l_min;
        user_l_max;
        
        fitted = false;
        cmap = 'summer';
        
        fix = {};
        gstart = [0 0 0 0];
        use_gstart = [0 0 0 0]';
        models = containers.Map(...
                 {'1. A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  '3. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'...
                  '4. A*(exp(-t/t1)+B*exp(-t/t2)+offset'...
                 },...
                 {...
                    % function, lower bounds, upper bounds, names of arguments
                    {@(A, t1, t2, offset, t) A*(exp(-t/t1)-exp(-t/t2))+offset, [0 0 0 0], [inf inf inf inf], {'A', 't1', 't2', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*exp(-t/t1)+B*exp(-t/t2)+offset, [0 0 0 0 0], [inf inf inf inf inf], {'A', 't1', 't2', 'B', 'offset'} }...
                  })
                    
        models_latex = containers.Map(...
                 {'1. A*(exp(-t/t1)-exp(-t/t2))+offset'...
                  '2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset'...
                  '3. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'...
                  '4. A*(exp(-t/t1)+B*exp(-t/t2)+offset'...
                 },...
                 {...
                 { '$$f(t) = A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - \exp \left(\frac{t}{\tau_2}\right) \right] + o$$', {'A', '\tau_1', '\tau_2', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts'} }...
                 { '$$f(t) = A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - \exp \left(\frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(\frac{t}{\tau_2}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 { '$$f(t) = A\cdot \left[\exp \left(\frac{t}{\tau_1}\right) - \exp \left(\frac{t}{\tau_2}\right) \right] + B \cdot \exp\left(\frac{t}{\tau_1}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 { '$$f(t) = A\cdot \exp \left(\frac{t}{\tau_1}\right) + B\cdot \exp \left(\frac{t}{\tau_2}\right) + o$$', {'A', '\tau_1', '\tau_2', 'B', 'o'}, {'Counts', '$$\mu$$s', '$$\mu$$s', 'Counts', 'Counts'} }...
                 })
    end
    
    methods
        function this = SiSaMode(parent, data)
            this.p = parent;
            this.data = data;
            this.h.parent = parent.h.modepanel;
            
            this.read_channel_width();
            
            
            this.h.sisamode = uitab(this.h.parent);
            
            this.h.plotpanel = uipanel(this.h.sisamode);
                        this.h.axes = axes('parent', this.h.plotpanel);
                        this.h.legend = axes('parent', this.h.plotpanel);
                        this.h.tick_min = uicontrol(this.h.plotpanel);
                        this.h.tick_max = uicontrol(this.h.plotpanel);
                        this.h.plttxt = uicontrol(this.h.plotpanel);
                        this.h.zslider = uicontrol(this.h.plotpanel);
                        this.h.zbox = uicontrol(this.h.plotpanel);
                        this.h.saslider = uicontrol(this.h.plotpanel);
                        this.h.sabox = uicontrol(this.h.plotpanel);
                        this.h.param = uicontrol(this.h.plotpanel);
                        this.h.fit_est = uibuttongroup(this.h.plotpanel);
                            this.h.fit_par = uicontrol();
                            this.h.est_par = uicontrol();
                        this.h.d1_select = uicontrol(this.h.plotpanel);
                        this.h.d2_select = uicontrol(this.h.plotpanel);
                        this.h.d3_select = uicontrol(this.h.plotpanel);
                        this.h.d4_select = uicontrol(this.h.plotpanel);

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
                            this.h.parallel = uicontrol(this.h.fit_tab);
                            this.h.fit = uicontrol(this.h.fit_tab);
                            this.h.hold = uicontrol(this.h.fit_tab);
                            this.h.ov_controls = uipanel(this.h.fit_tab);
                                this.h.ov_disp = uicontrol(this.h.ov_controls);
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

                            this.h.sel_values = uipanel(this.h.sel_tab);

                        this.h.pres_tab = uitab(this.h.tabs);
                            this.h.savefig = uicontrol(this.h.pres_tab);
                            this.h.prevfig = uicontrol(this.h.pres_tab);
                            this.h.pres_controls = uipanel(this.h.pres_tab);
                                this.h.colormap_drpd_text = uicontrol(this.h.pres_controls);
                                this.h.colormap_drpd = uicontrol(this.h.pres_controls);
                                this.h.scale_x_text = uicontrol(this.h.pres_controls);
                                this.h.scale_x = uicontrol(this.h.pres_controls);
                                this.h.scale_y_text = uicontrol(this.h.pres_controls);
                                this.h.scale_y = uicontrol(this.h.pres_controls);
                                
                                
            set(this.h.sisamode, 'title', 'SiSa',...
                                 'SizeChangedFcn', @this.resize);
                %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [270 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
            
            set(this.h.axes, 'units', 'pixels',...
                           'position', [40 60 380 390],...
                           'Color', get(this.h.plotpanel, 'BackgroundColor'),...
                           'xtick', [], 'ytick', [],...
                           'XColor', get(this.h.plotpanel, 'BackgroundColor'),...
                           'YColor', get(this.h.plotpanel, 'BackgroundColor'),...
                           'ButtonDownFcn', @this.aplot_click_cb);
                       
            set(this.h.legend, 'units', 'pixels',...
                             'position', [40 12 400 20],...
                             'xtick', [], 'ytick', [],...
                             'XColor', get(this.h.plotpanel, 'BackgroundColor'),...
                             'YColor', get(this.h.plotpanel, 'BackgroundColor'),...
                             'visible', 'off');
                                     
            set(this.h.plttxt, 'units', 'pixels',...
                             'style', 'text',...
                             'string', 'Parameter:',...
                             'position', [50 452 100 20],...
                             'HorizontalAlignment', 'left',...
                             'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                             'FontSize', 9,...
                             'visible', 'off');
                                                       
            set(this.h.zslider, 'units', 'pixels',...
                              'style', 'slider',...
                              'position', [460 85 20 340],...
                              'value', 1,...
                              'visible', 'off',...
                              'callback', @this.set_d3_cb,...
                              'BackgroundColor', [1 1 1]);
                           
            set(this.h.zbox, 'units', 'pixels',...
                           'style', 'edit',...
                           'string', '1',...
                           'position', [460 430 20, 20],...
                           'callback', @this.set_d3_cb,...
                           'visible', 'off',...
                           'BackgroundColor', [1 1 1]);
            
            set(this.h.saslider, 'units', 'pixels',...
                               'style', 'slider',...
                               'position', [490 85 20 340],... 
                               'value', 1,...
                               'visible', 'off',...
                               'BackgroundColor', [1 1 1],...
                               'ForegroundColor', [0 0 0],...
                               'callback', @this.set_d4_cb);

            set(this.h.sabox, 'units', 'pixels',...
                            'style', 'edit',...
                            'string', '1',...
                            'position', [490 460 20 20],...
                            'callback', @this.set_d4_cb,...
                            'visible', 'off',...
                            'BackgroundColor', [1 1 1]);

            set(this.h.param, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', {},...
                            'position', [120 470 80 20],...
                            'FontSize', 9,...
                            'visible', 'off',...
                            'callback', @this.set_param_cb,...
                            'BackgroundColor', [1 1 1]);
                        
            set(this.h.tick_min, 'units', 'pixels',...
                               'style', 'edit',...
                               'visible', 'off',...
                               'FontSize', 9,...
                               'string', '1',...
                               'horizontalAlignment', 'left',...
                               'callback', @this.set_tick_cb,...
                               'position', [40 34 65 17]);
                           
            set(this.h.tick_max, 'units', 'pixels',...
                               'style', 'edit',...
                               'visible', 'off',...
                               'FontSize', 9,...
                               'string', '100',...
                               'horizontalAlignment', 'right',...
                               'callback', @this.set_tick_cb,...
                               'position', [405 34 65 17]);  
                           
            set(this.h.est_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(this.h.plotpanel, 'BackgroundColor'),...
                              'string', 'abgesch�tzt',...
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
                          
            set(this.h.d1_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.p.dimnames,...
                                'value', 1,...
                                'tag', '1',...
                                'visible', 'off',...
                                'callback', @this.set_dim_cb,...
                                'position', [385 40 30 17],...
                                'BackgroundColor', [1 1 1]);
                            
            set(this.h.d2_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.p.dimnames,...
                                'value', 2,...
                                'visible', 'off',...
                                'tag', '2',...
                                'callback', @this.set_dim_cb,...
                                'position', [5 300 30 17],...
                                'BackgroundColor', [1 1 1]);


            set(this.h.d3_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.p.dimnames,...
                                'value', 3,...
                                'visible', 'off',...
                                'tag', '3',...
                                'callback', @this.set_dim_cb,...
                                'position', [465 520 30 17],...
                                'BackgroundColor', [1 1 1]);

                            
            set(this.h.d4_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.p.dimnames,...
                                'value', 4,...
                                'visible', 'off',...
                                'tag', '4',...
                                'callback', @this.set_dim_cb,...
                                'position', [505 520 30 17],...
                                'BackgroundColor', [1 1 1]);

                            
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
                            'string', 'parallel Fitten? (keine Interaktivit�t!)',...
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
                              'position', [15 175 150 20],...
                              'string', 'Overlay anzeigen',...
                              'callback', @this.disp_ov_cb);
                              
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
                           'string', keys(this.models),...
                           'value', 1,...
                           'position', [15 205 220 15],...
                           'callback', @this.set_model_cb,...
                           'BackgroundColor', [1 1 1]);
                       
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

            % info about the selected data
            set(this.h.sel_values, 'units', 'pixels',...
                                   'bordertype', 'line',...
                                   'highlightcolor', [.7 .7 .7],...
                                   'position', [2 100 243 250])  
            
            this.h.mean = cell(1, 1);
            this.h.var = cell(1, 1);
            this.h.par = cell(1, 1);
            
            %% presentation
            set(this.h.pres_tab, 'Title', 'Darstellung');
            
            set(this.h.pres_controls, 'units', 'pixels',...
                                    'position', [2 50 243 250])
                               
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
                          
            set(this.h.colormap_drpd_text, 'units', 'pixels',...
                                         'style', 'text',...
                                         'string', 'Colormap:',...
                                         'horizontalAlignment', 'left',...
                                         'position', [10, 142, 50, 25]);
                          
            set(this.h.colormap_drpd, 'units', 'pixels',...
                                    'style', 'popupmenu',...
                                    'position', [70, 160, 80, 10],...
                                    'string', {'parula', 'jet', 'hsv',...
                                               'hot', 'cool', 'spring',...
                                               'summer', 'autumn', 'winter',...
                                               'gray', 'bone', 'copper',...
                                               'pink'},...
                                    'value', 7,...
                                    'callback', @this.set_cmap_cb);
            
            set(this.h.scale_x_text, 'units', 'pixels',...
                                   'style', 'text',...
                                   'string', 'mm/px X:',...
                                   'horizontalAlignment', 'left',...
                                   'position', [10, 112, 80, 25]);
                                     
            set(this.h.scale_x, 'units', 'pixels',...
                              'style', 'edit',...
                              'callback', @this.set_scale_cb,...
                              'position', [70, 120, 80, 20]);
            
            set(this.h.scale_y_text, 'units', 'pixels',...
                                   'style', 'text',...
                                   'string', 'mm/px Y:',...
                                   'horizontalAlignment', 'left',...
                                   'position', [10, 82, 80, 25]);

            set(this.h.scale_y, 'units', 'pixels',...
                              'style', 'edit',...
                              'callback', @this.set_scale_cb,...
                              'position', [70, 90, 80, 20]);          
            
            % init
            tmp = size(this.data);
            
            this.overlays{1} = ones(tmp(1), tmp(2), tmp(3), tmp(4));
            this.overlays{2} = zeros(tmp(1), tmp(2), tmp(3), tmp(4));
                          
            % UI stuff
            t = keys(this.models);
            t = this.models(t{get(this.h.drpd, 'value')});
             
            set(this.h.plttxt, 'visible', 'on');
            set(this.h.fit_est, 'visible', 'on');
            set(this.h.param, 'visible', 'on', 'string', [t{4}, 'Summe']);
            set(this.h.ov_drpd, 'string', [t{4}, 'Summe']);
            set(this.h.tabs, 'visible', 'on');
            
            this.p.update_infos();
            this.set_model('1. A*(exp(-t/t1)-exp(-t/t2))+offset');
            this.estimate_parameters();
            this.change_overlay_cond_cb();
            this.update_sliders();
            this.plot_array();
            
            this.generate_overlay();
            
            % initialise here, so we can check whether a point is fitted or not
            s = num2cell(size(this.est_params));
            this.fit_chisq = nan(s{1:4});
        end
        
        function plot_array(this, varargin)
            this.generate_mean();
            param = this.current_param;

            if this.disp_fit_params
                switch param
                    case length(this.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = this.fit_chisq;
                    otherwise
                        plot_data = this.fit_params(:, :, :, :, param);
                end
            else
                switch param
                    case length(this.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = this.data_sum;
                    otherwise
                        plot_data = this.est_params(:, :, :, :, param);
                end
            end
            
            this.set_transpose();
            
            sx = size(plot_data, this.curr_dims(1));
            sy = size(plot_data, this.curr_dims(2));
            
            plot_data = squeeze(plot_data(this.ind{:}));
            
            % squeeze does strange things: (1x3x1)-array -> (3x1)-array
            
            [sxn, syn] = size(plot_data);
           
            if (sxn ~= sx || syn ~= sy) % breaks for sx == sy...
                this.transpose = ~this.transpose;
                plot_data = plot_data';
                ov_data = squeeze(this.overlays{this.current_ov}(this.ind{:}))';
            elseif sx > 1 && sy > 1 && this.transpose
                plot_data = plot_data';
                ov_data = squeeze(this.overlays{this.current_ov}(this.ind{:}))';
            else
                ov_data = squeeze(this.overlays{this.current_ov}(this.ind{:}));
            end
            
            this.overlay_data = ov_data;
            
            % for legend minimum and maximum
            if ~this.use_user_legend
                this.calculate_legend();
            end
            tickmax = this.l_max(param);
            tickmin = this.l_min(param);
            % plotting:
            % Memo to self: Don't try using HeatMaps... seriously.
            if gcf == this.p.h.f || this.fitted % don't plot when figure is in background
                set(this.p.h.f, 'CurrentAxes', this.h.axes); 
                cla
                hold on
                hmap(plot_data', false, this.cmap);
                if this.disp_ov
                    plot_overlay(ov_data');
                end
                hold off
                s = size(plot_data');
                xlim([.5 s(2)+.5])
                ylim([.5 s(1)+.5])

                if tickmin < tickmax
                    caxis([tickmin tickmax])
                    
                    set(this.p.h.f, 'CurrentAxes', this.h.legend);
                    l_data = tickmin:(tickmax-tickmin)/20:tickmax;
                    cla
                    hold on
                    hmap(l_data, false, this.cmap);
                    hold off
                    xlim([.5 length(l_data)+.5])
                    set(this.h.legend, 'visible', 'on');
                    set(this.h.tick_min, 'visible', 'on', 'string', num2str(l_data(1),4));
                    set(this.h.tick_max, 'visible', 'on', 'string', num2str(l_data(end),4));
                end
            end
            set(this.h.d1_select, 'visible', 'on');
            set(this.h.d2_select, 'visible', 'on');
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
        
        function set_model(this, str)
            t = keys(this.models);
            set(this.h.drpd, 'value', find(strcmp(t, str))); % set the model in the drpd
            
            t = this.models(str);
            this.fit_params = nan(this.p.fileinfo.size(1), this.p.fileinfo.size(2),...
                                this.p.fileinfo.size(3), this.p.fileinfo.size(4), length(t{4}));
            this.l_max = nan(length(t{4}) + 1, 1);
            this.l_min = nan(length(t{4}) + 1, 1);
            this.model = str;
            if this.p.data_read
                this.estimate_parameters();
                set(this.h.plttxt, 'visible', 'on');
                set(this.h.param, 'visible', 'on',...
                                'string', [t{4}, 'Summe']);
                this.plot_array();
            end
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
               
        function generate_sel_vals(this)
            m = this.models(this.model);
            n = length(m{4});

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
                                                    'string', m{4}{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [15 155-i*23-14 40 20]);
            end
        end % mean, std, etc.

        function generate_export_fig(this, ax_in, vis)
            x = size(this.data, this.curr_dims(1));
            y = size(this.data, this.curr_dims(2));

            if x > y
                d = x;
            else
                d = y;
            end

            scale_pix = 800/d;  % max width or height of the axes
            scl = this.p.scale./max(this.p.scale);
            
            x_pix = x*scale_pix*scl(1);
            y_pix = y*scale_pix*scl(2);
            
            tmp = get(ax_in, 'position');
            if isfield(this.h, 'plot_pre') && ishandle(this.h.plot_pre)
                figure(this.h.plot_pre);
                clf();
            else
                this.h.plot_pre = figure('visible', vis);
            end
            screensize = get(0, 'ScreenSize');
            windowpos = [screensize(3)-(x_pix+150) screensize(4)-(y_pix+150)  x_pix+80 y_pix+100];
            set(this.h.plot_pre, 'units', 'pixels',...
                   'position', windowpos,...
                   'numbertitle', 'off',...
                   'name', 'SISA Scan Vorschau',...
                   'menubar', 'none',...
                   'resize', 'off',...
                   'Color', [.95, .95, .95]);

            ax = copyobj(ax_in, this.h.plot_pre);
            set(ax, 'position', [tmp(1) tmp(2) x_pix y_pix],...
                    'XColor', 'black',...
                    'YColor', 'black');
            xlabel([this.p.dimnames{this.curr_dims(1)} ' [mm]'])
            ylabel([this.p.dimnames{this.curr_dims(2)} ' [mm]'])
            
            x_label_res = 1;
            x_tick = 1:x_label_res:x;
            while length(x_tick) > 10
                x_label_res = x_label_res + 1;
                x_tick = 1:x_label_res:x;
            end
            
            y_label_res = 1;
            y_tick = 1:y_label_res:y;
            while length(y_tick) > 10
                y_label_res = y_label_res + 1;
                y_tick = 1:y_label_res:y;
            end
            
            x_tick_label = num2cell((0:x_label_res:x-1)*this.p.scale(1));
            y_tick_label = num2cell((0:y_label_res:y-1)*this.p.scale(2));
            
            set(ax, 'xtick', x_tick, 'ytick', y_tick,...
                    'xticklabel', x_tick_label,...
                    'yticklabel', y_tick_label);

            caxis([this.l_min(this.current_param) this.l_max(this.current_param)]);
            colormap(this.cmap);
            c = colorbar();
            set(c, 'units', 'pixels');
            tmp2 = get(c, 'position');
            tmp2(1) = tmp(1)+x_pix+15;
            set(c, 'position', tmp2);
            if tmp2(1) + tmp2(3) > windowpos(3)
                windowpos(3) = windowpos(3) + tmp2(3) + 20;
                set(this.h.plot_pre, 'position', windowpos);
            end
        end

        function add_ov(this, init)
            new_ov_number = length(this.overlays)+1;
            this.overlays{new_ov_number} = init;
            this.generate_overlay();
            this.set_current_ov(new_ov_number);
            this.plot_array();
        end
        
        function del_ov(this, position)
            if position == 1 % cannot delete first overlay
                return
            end
     
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
        
        function set_savepath(this, path)
            this.savepath = path; 
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
                pos_act_r = pos_act_r-[0 25 0 0];
                this.h.ov_radiobtns{i} = uicontrol(this.h.ov_buttongroup,...
                                                 'units', 'pixels',...
                                                 'style', 'radiobutton',...
                                                 'Tag', num2str(i),...
                                                 'string', ['Overlay ' num2str(i)],...
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
        
        function update_sliders(this)
            [s1, s2, s3, s4, ~] = size(this.est_params);
            s = [s1 s2 s3 s4];

            % handle z-scans
            if s(this.curr_dims(3)) > 1 
                set(this.h.zslider, 'min', 1, 'max', s(this.curr_dims(3)),...
                                  'visible', 'on',...
                                  'value', 1,...
                                  'SliderStep', [1 5]/(s(this.curr_dims(3))-1));
                set(this.h.zbox, 'visible', 'on');
                set(this.h.d3_select, 'visible', 'on');
            else 
                set(this.h.zbox, 'visible', 'off');
                set(this.h.zslider, 'visible', 'off');
                set(this.h.d3_select, 'visible', 'off');
            end
            % handle multiple samples
            if s(this.curr_dims(4)) > 1 
                set(this.h.saslider, 'min', 1, 'max', s(this.curr_dims(4)),...
                                  'visible', 'on',...
                                  'value', 1,...
                                  'SliderStep', [1 5]/(s(this.curr_dims(4))-1));
                set(this.h.sabox, 'visible', 'on');
                set(this.h.d4_select, 'visible', 'on');
            else 
                set(this.h.sabox, 'visible', 'off');
                set(this.h.saslider, 'visible', 'off');
                set(this.h.d4_select, 'visible', 'off');
            end
        end
        
        function set_transpose(this)
            if this.curr_dims(1) > this.curr_dims(2)
                this.transpose = true;
            else 
                this.transpose = false;
            end
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
            % find mean of t_0
            [~, I] = max(this.data, [], 5);
            this.t_zero = round(mean(mean(mean(mean(I)))));
            
            this.x_data = ((1:length(this.data(1, 1, 1, 1, :)))-this.t_zero)'*this.channel_width;
            
            n = this.models(this.model);
            this.est_params = zeros(this.p.fileinfo.size(1), this.p.fileinfo.size(2),...
                              this.p.fileinfo.size(3), this.p.fileinfo.size(4), length(n{2}));
            ub = zeros(length(n{3}), 1);
            lb = ones(length(n{2}), 1)*100;
            po = values(this.p.points);
            for i = 1:this.p.fileinfo.np
                for j = 1:this.p.fileinfo.size(4)
                    d = this.data(po{i}(1), po{i}(2), po{i}(3), j, :);
                    
                    ps = SiSaMode.estimate_parameters_p(squeeze(d), this.model, this.t_zero, this.t_offset, this.channel_width);
                    this.est_params(po{i}(1), po{i}(2), po{i}(3), j, :) = ps;
                    if mod(i, round(this.p.fileinfo.np/20)) == 0
                        this.p.update_infos(['   |   Parameter absch�tzen ' num2str(i) '/' num2str(this.p.fileinfo.np) '.']);
                    end
                    for k = 1:length(ps) % find biggest and smallest params
                        if ps(k) > ub(k)
                            ub(k) = ps(k);
                        end
                        if ps(k) < lb(k) && ps(k) ~= 0
                            lb(k) = ps(k);
                        end
                    end
                end
            end
            this.data_sum = sum(this.data(:, :, :, :, (this.t_zero+this.t_offset):end), 5);
            this.fitted = false;
                          
            % set bounds from estimated parameters
            tmp = this.models(this.model);
            tmp{3} = ub*1.5;
            tmp{2} = lb*0.5;
            this.models(this.model) = tmp;
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
            x = this.x_data((this.t_zero + this.t_offset):end);
            
            lt = 0;
            m = 1;
            n_pixel = prod(this.p.fileinfo.size);
            
            for n = start:n_pixel
                [i,j,k,l] = ind2sub(this.p.fileinfo.size, n);               
                if this.overlays{this.current_ov}(i, j, k, l) || ~this.disp_ov
                    innertime = tic();

                    y = squeeze(this.data(i, j, k, l, (this.t_offset+this.t_zero):end));
                    w = sqrt(y);
                    w(w == 0) = 1;
                    if ~isempty(g_par)
                        start = this.est_params(i, j, k, l, :);
                        start(g_par) = this.gstart(g_par);
                        [par, p_err, chi] = fitdata(this.models(this.model),...
                            x, y, w, start, this.fix);
                    else
                        [par, p_err, chi] = fitdata(this.models(this.model),...
                            x, y, w, this.est_params(i, j, k, l, :), this.fix); 
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
                if n == 1
                    set(this.h.fit_par, 'visible', 'on');
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
        
        function fit_all_par(this, start)
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
            t_length = size(this.data, 5) - (this.t_offset + this.t_zero) + 1;
            d = reshape(this.data(:, :, :, :, (this.t_offset+this.t_zero):end), n_pixel, 1, t_length);
           
            m = this.models(this.model);
            parcount = length(m{2});
            e_pars = reshape(this.est_params, prod(this.p.fileinfo.size), 1, parcount);
            f = this.fix;
            f_pars = reshape(this.fit_params, prod(this.p.fileinfo.size), parcount);
            f_pars_e = reshape(this.fit_params_err, prod(this.p.fileinfo.size), parcount);
            f_chisq = reshape(this.fit_chisq, prod(this.p.fileinfo.size), 1);

            g_par = find(this.use_gstart);
            global_start = this.gstart;

            
            rest = mod(n_pixel - start + 1, this.p.par_size);
            inner_upper = this.p.par_size-1;

            lt = 0;
            
            x = this.x_data((this.t_offset+this.t_zero):end);
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
                        if isnan(y(1))
                            continue;
                        end
                        w = sqrt(y);
                        w(w == 0) = 1;
                        if ~isempty(g_par)
                            tmp = e_pars(n+i, :);
                            tmp(g_par) = global_start(g_par);
                            [par, p_err, chi] = fitdata(m, x, y, w, tmp, f);
                        else
                            [par, p_err, chi] = fitdata(m, x, y, w, e_pars(n+i, :), f); 
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
            m = this.models(this.model);
            n = length(m{4});
            
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
                                                    'string', m{4}{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [5 155-i*23-14 35 20]);
                                                
                this.h.lb{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', m{2}(i)),...
                                                    'position', [40 155-i*23-10 45 20],...
                                                    'callback', @this.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                this.h.ub{i} = uicontrol(this.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', m{3}(i)),...
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
                                                     'value', ismember(m{4}(i), this.fix),...
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
        
        function calculate_legend(this)
            tmp = this.models(this.model);
            for i = 1:length(tmp{2})
                if this.disp_fit_params
                    this.l_max(i) = squeeze(max(max(max(max(this.fit_params(:,:,:,:,i))))));
                    this.l_min(i) = squeeze(min(min(min(min(this.fit_params(:,:,:,:,i))))))-10*eps;
                else
                    this.l_max(i) = squeeze(max(max(max(max(this.est_params(:,:,:,:,i))))));
                    this.l_min(i) = squeeze(min(min(min(min(this.est_params(:,:,:,:,i))))))-10*eps;
                end
            end
            if this.disp_fit_params
                this.l_min(end) = squeeze(min(min(min(min(this.fit_chisq)))))-10*eps;
                this.l_max(end) = squeeze(max(max(max(max(this.fit_chisq)))));
            else
                this.l_min(end) = squeeze(min(min(min(min(this.data_sum)))))-10*eps;
                this.l_max(end) = squeeze(max(max(max(max(this.data_sum)))));
            end
        end
    end
    
    methods (Access = private)
        function resize(this, varargin)
            mP = get(this.h.parent, 'Position');

            mP(4) = mP(4)-25;
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);

            aP = get(this.h.axes, 'Position');
            aP(3:4) = [(pP(3)-aP(1))-80 (pP(4)-aP(2))-50];
            set(this.h.axes, 'Position', aP);

            tmp = get(this.h.d2_select, 'Position');
            tmp(2) = aP(2) + aP(4)/2;
            set(this.h.d2_select, 'Position', tmp);

            tmp = get(this.h.d1_select, 'Position');
            tmp(1) = aP(1) + aP(3)/2;
            set(this.h.d1_select, 'Position', tmp);

            tmp = get(this.h.d3_select, 'Position');
            tmp(1) = aP(1) + aP(3) + 5;
            tmp(2) = aP(2) + aP(4) - 16;
            set(this.h.d3_select, 'Position', tmp);

            tmp(1) = aP(1) + aP(3) + 40;
            set(this.h.d4_select, 'Position', tmp);

            tmp = get(this.h.legend, 'position');
            tmp(3) = aP(3);
            set(this.h.legend, 'position', tmp);

            tmp = get(this.h.tick_max, 'position');
            tmp(1) = aP(3) + aP(1) - tmp(3);
            set(this.h.tick_max, 'position', tmp);

            tmp = get(this.h.plttxt, 'position');
            tmp(2) = aP(2)+aP(4)+2;
            set(this.h.plttxt, 'position', tmp);

            tmp = get(this.h.param, 'position');
            tmp(2) = aP(2)+aP(4)+6;
            set(this.h.param, 'position', tmp);

            tmp = get(this.h.fit_est, 'position');
            tmp(2) = aP(2)+aP(4) + 6;
            set(this.h.fit_est, 'position', tmp);

            tmp = get(this.h.zslider, 'position');
            tmp(1) = aP(1) + aP(3) + 15;
            tmp(4) = aP(4) - 50;
            set(this.h.zslider, 'position', tmp);

            tmp(1) = tmp(1) + 25;
            set(this.h.saslider, 'position', tmp);

            tmp = get(this.h.zbox, 'position');
            tmp(1) = aP(1) + aP(3) + 15;
            tmp(2) = aP(1) + 20;
            set(this.h.zbox, 'position', tmp);

            tmp(1) = tmp(1) + 25;
            set(this.h.sabox, 'position', tmp);

            tP = get(this.h.tabs, 'Position');
            tP(4) = pP(4);
            set(this.h.tabs, 'Position', tP);

            tmp = get(this.h.ov_controls, 'Position');
            tmp(2) = tP(4) - tmp(4) - 40;
            set(this.h.ov_controls, 'Position', tmp);
            set(this.h.sel_controls, 'Position', tmp);
        end
        
        %% Callbacks:
        % mouseclick on plot
        function aplot_click_cb(this, varargin)
            cp = get(this.h.axes, 'CurrentPoint');
            cp = round(cp(1, 1:2));
            cp(cp == 0) = 1;

            index{this.curr_dims(1)} = cp(1); % x ->
            index{this.curr_dims(2)} = cp(2); % y ^
            index{this.curr_dims(3)} = this.ind{this.curr_dims(3)};
            index{this.curr_dims(4)} = this.ind{this.curr_dims(4)};

            for i = 1:4
                if index{i} > this.p.fileinfo.size(i)
                    index{i} = this.p.fileinfo.size(i);
                elseif index{i} <= 0
                     index{i} = 1;
                end
            end
            switch get(this.p.h.f, 'SelectionType')
                case 'normal'
                    if ~strcmp(this.p.fileinfo.path, '')
                        if sum(this.data(index{:}, :))
                            i = length(this.plt);
                            this.plt{i+1} = SiSaPlot([index{:}], this);
                        end
                    end
                case 'alt'
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

        function save_fig(this, varargin)
            if this.disp_fit_params
                tmp = 'gefittet';
            else
                tmp = 'geschaetzt';
            end
            [file, path] = uiputfile([this.savepath filesep() this.genericname...
                                     '_par=' this.get_parname(this.current_param)...
                                     '_' tmp '.pdf']);
            if ~ischar(file) || ~ischar(path) % no file selected
                return
            end
            this.set_savepath(path);
            this.generate_export_fig(this.h.axes, 'off');
            tmp = get(this.h.plot_pre, 'position');

            % save the plot and close the figure
            set(this.h.plot_pre, 'PaperUnits', 'points');
            set(this.h.plot_pre, 'PaperSize', [tmp(3) tmp(4)]*.8);
            set(this.h.plot_pre, 'PaperPosition', [0 0 tmp(3) tmp(4)]*.8);
            print(this.h.plot_pre, '-dpdf', '-r600', fullfile(path, file));
            close(this.h.plot_pre);
        end
        
        function add_ov_cb(this, varargin)
            this.add_ov(this.overlays{varargin{1}.Callback{2}});
        end
        
        function del_ov_cb(this, varargin)
            this.del_ov(varargin{1}.Callback{2});
        end
        
        function disp_ov_cb(this, varargin)
            this.set_disp_ov(varargin{1}.Value);
        end
        
        function set_current_ov_cb(this, varargin)
            dat = varargin{2};
            this.set_current_ov(str2double(dat.NewValue.Tag));
        end
        
        function change_par_source_cb(this, varargin)
            t = this.models(this.model);  
            ov = get(varargin{2}.OldValue, 'String');
            nv = get(varargin{2}.NewValue, 'String');
            if ~strcmp(ov, nv)
                if strcmp(nv, get(this.h.fit_par, 'string'))
                    this.disp_fit_params = true;
                    params = [t{4}, 'Chi^2'];
                else
                    this.disp_fit_params = false;
                    params = [t{4}, 'Summe'];
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
            this.generate_export_fig(this.h.axes, 'on');
        end
        
        % change global start point
        function set_gstart_cb(this, varargin)
            m = this.models(this.model);
            tmp = zeros(size(m{2}));
            for i = 1:length(m{4});
                tmp(i) = str2double(get(this.h.st{i}, 'string'));
                if tmp(i) < m{2}(i)
                    tmp(i) = m{2}(i);
                end
                if tmp(i) > m{3}(i)
                    tmp(i) = m{3}(i);
                end
                set(this.h.st{i}, 'string', tmp(i))
            end
            this.gstart = tmp;
        end 
                
        % fix parameter checkbox
        function set_param_fix_cb(this, varargin)
            m = this.models(this.model);
            n = length(m{4});
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
                    this.fix{index} = m{4}{i};
                end
            end
            this.set_gstart_cb();
        end
        
        % global SP checkbox
        function set_param_glob_cb(this, varargin)
            m = this.models(this.model);
            n = length(m{4});
            g = zeros(n,1);
            for i = 1:n
                if get(this.h.gst{i}, 'value') == 1
                    g(i) = 1;
                end
            end
            this.set_param_glob(g);
        end
        
        % scale of a pixel
        function set_scale_cb(this, varargin)
            if varargin{1} == this.h.scale_x
                this.set_scale([str2double(get(this.h.scale_x, 'string')), this.p.scale(2)]);
            elseif varargin{1} == this.h.scale_y
                this.set_scale([this.p.scale(1), str2double(get(this.h.scale_y, 'string'))]);
            end
        end 
       
        % fitmodel from dropdown
        function set_model_cb(this, varargin)
            t = keys(this.models);
            str = t{get(this.h.drpd, 'value')};
            this.set_model(str);
        end 
        
        % colormap
        function set_cmap_cb(this, varargin)
            cmaps = get(this.h.colormap_drpd, 'string'); 
            this.cmap = cmaps{get(this.h.colormap_drpd, 'value')};
            this.plot_array();
        end 
        
        % update bounds
        function set_bounds_cb(this, varargin)
            m = this.models(this.model);
            for i = 1:length(m{4});
                m{2}(i) = str2double(get(this.h.lb{i}, 'string'));
                m{3}(i) = str2double(get(this.h.ub{i}, 'string'));
            end
            this.models(this.model) = m;
        end 
        
        function set_dim_cb(this, varargin)
            t = str2double(get(varargin{1}, 'Tag'));
            val = get(varargin{1}, 'Value');
            oval = this.curr_dims(t);
            % swap elements
            a = this.curr_dims;
            a([find(a==oval) find(a==val)]) = a([find(a==val) find(a==oval)]);
            this.curr_dims = a;
            
            hs = {this.h.d1_select, this.h.d2_select, this.h.d3_select, this.h.d4_select};
            for i = 1:4
                set(hs{i}, 'value', this.curr_dims(i));
                if i <= 2
                    this.ind{this.curr_dims(i)} = ':';
                else
                    this.ind{this.curr_dims(i)} = 1;
                end
            end
                       
            this.update_sliders();
            this.plot_array();
        end
        
        function set_d3_cb(this, varargin)
            switch varargin{1}
                case this.h.zslider
                    val = round(get(this.h.zslider, 'value'));
                case this.h.zbox
                    val = round(str2double(get(this.h.zbox, 'string')));
            end
            if val > this.p.fileinfo.size(this.curr_dims(3))
                val = this.p.fileinfo.size(this.curr_dims(3));
            elseif val <= 0
                val = 1;
            end
            
            set(this.h.zslider, 'value', val);
            set(this.h.zbox, 'string', num2str(val));
            this.ind{this.curr_dims(3)} = val;
            
            this.plot_array();
        end
        
        function set_d4_cb(this, varargin)
            switch varargin{1}
                case this.h.saslider
                    val = round(get(this.h.saslider, 'value'));
                case this.h.sabox
                    val = round(str2double(get(this.h.sabox, 'string')));
            end
            if val > this.p.fileinfo.size(this.curr_dims(4))
                val = this.p.fileinfo.size(this.curr_dims(4));
            elseif val <= 0
                val = 1;
            end
            
            set(this.h.saslider, 'value', val);
            set(this.h.sabox, 'string', num2str(val));
            this.ind{this.curr_dims(4)} = val;
            
            this.plot_array();
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
                this.fit_all_par(1);
            else
                this.fit_all(1);
            end
        end
        
        function resume_fit_cb(this, varargin)
            this.hold_f = false;
            set(this.h.hold, 'string', 'Fit anhalten', 'callback', @this.hold_fit_cb);
            if get(this.h.parallel, 'value')
                this.fit_all_par(this.last_fitted + this.p.par_size);
            else
                this.fit_all(this.last_fitted);
            end
        end
        
        function cancel_fit_cb(this, varargin)
            this.cancel_f = true;
            set(this.h.fit, 'string', 'global Fitten', 'callback', @this.fit_all_cb);
            set(this.h.hold, 'visible', 'off');
        end
        
        % upper and lower bound of legend
        function set_tick_cb(this, varargin)
            switch varargin{1}
                case this.h.tick_min
                    new_l_min = str2double(get(this.h.tick_min, 'string'));
                    if new_l_min < this.l_max(this.current_param)
                        this.l_min(this.current_param) = new_l_min;
                        this.use_user_legend = true;
                    elseif isempty(get(this.h.tick_min, 'string'))
                        this.use_user_legend = false;
                    else
                        set(this.h.tick_min, 'string', this.l_min(this.current_param));
                    end
                case this.h.tick_max
                    new_l_max = str2double(get(this.h.tick_max, 'string'));
                    if new_l_max > this.l_min(this.current_param)
                        this.l_max(this.current_param) = new_l_max;
                        this.use_user_legend = true;
                    elseif isempty(get(this.h.tick_max, 'string'))
                        this.use_user_legend = false;
                    else
                        set(this.h.tick_max, 'string', this.l_max(this.current_param));
                    end
            end
            this.plot_array();
        end
        
    end
    
    methods (Static = true)
        function [param] = estimate_parameters_p(data, model, t_zero, t_offset, cw)
            data = smooth(data, 'loess');
            switch model
                case '1. A*(exp(-t/t1)-exp(-t/t2))+offset'
                    [A, t1] = max(data((t_zero + t_offset):end)); % Amplitude, first time
                    t1 = t1 + t_zero + t_offset;
                    param(1) = A;
                    param(3) = (t1-t_zero)*cw/2;
                    param(4) = mean(data(end-100:end));
                    data = data-param(4);
                    A = A-param(4);
                    t2 = find(abs(data <= round(A/2.7)));
                    t2 = t2(t2 > t1);
                    try
                        param(2) = (t2(1) - t_zero)*cw;
                    catch
                        param(2) = 1;
                    end
                case {'2. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset',...
                      '3. A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset'}
                    [A, t1] = max(data((t_zero + t_offset):end)); % Amplitude, first time
                    t1 = t1 + t_zero + t_offset;
                    param(1) = A;
                    param(3) = (t1-t_zero)*cw/2;
                    param(4) = A/4;
                    param(5) = mean(data(end-100:end));
                    data = data-param(5);
                    A = A-param(5);
                    t2 = find(abs(data <= round(A/2.7)));
                    t2 = t2(t2 > t1);
                    try
                        param(2) = (t2(1) - t_zero)*cw;
                    catch
                        param(2) = 1;
                    end
                case '4. A*(exp(-t/t1)+B*exp(-t/t2)+offset'
                    [A, i] = max(data((t_zero + t_offset):end));
                    B = A/4;
                    t1 = find(abs(data <= round(A/2.7)));
                    t1 = t1(t1>i+t_offset);
                    t2 = t1(1)/4;
                    param(5) = mean(data(end-100:end));
                    param(1) = A;
                    param(2) = t1(1)*cw;
                    param(3) = t2*cw;
                    param(4) = B;
                otherwise
                    param = 50*ones(5, 1);
            end
        end
    end
end