classdef UI < handle
    %UI 

    properties
        gplt = {};
        plt = {};
        
        reorder = [3 4 1 2];
        
        version = 0.31;
        online_ver = 'http://www.daten.tk/webhook/tags.php?owner=sebastian.pfitzner&project=sisa-scan-auswertung';
        
        % fileinfo (dims, path, ...)
        fileinfo = struct('path', '', 'size', [0 0 0 0],...
                          'name', '', 'np', 0); 
        data;       % source data from HDF5
        data_sum;
        scale = [5 5];          % distance between to pixels in mm
        x_data;         % time data
        fit_params;     % fit params, size(params) = [x y z length(fitparams)]
        fit_params_err;
        fit_chisq;
        est_params;     % estimated parameters
        last_fitted;    % last fitted point
        
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
        t_zero = 0;      % channel in which the maximum of the excitation was reached
           
        file_opened = 0;
        
        % slices to be displayed
        dimnames = {'x', 'y', 'z', 's'};
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
        
        genericname;
        openpath; % persistent, in ini
        savepath; % persistent, in ini

        points;
        data_read = false;
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
                    {@(A, t1, t2, offset, t) A*(exp(-t/t1)-exp(-t/t2))+offset, [1 0.1 0.1 1], [500 20 10 50], {'A', 't1', 't2', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t2)+offset, [1 0.1 0.1 1 1], [500 20 10 300 50], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*(exp(-t/t1)-exp(-t/t2))+B*exp(-t/t1)+offset, [1 0.1 0.1 1 1], [500 20 10 300 50], {'A', 't1', 't2', 'B', 'offset'} }...
                    {@(A, t1, t2, B, offset, t) A*exp(-t/t1)+B*exp(-t/t2)+offset, [1 0.1 0.1 1 1], [500 20 10 50 50], {'A', 't1', 't2', 'B', 'offset'} }...
                  })
                    
        h = struct();        % handles
    end

    methods
        % create new instance with basic controls
        function ui = UI(path, name, pos)
            %% initialize all UI objects:
            ui.h.f = figure();
            
            ui.h.menu = uimenu(ui.h.f);
            ui.h.helpmenu = uimenu(ui.h.f);
            
            ui.h.plotpanel = uipanel();
                ui.h.axes = axes('parent', ui.h.plotpanel);
                ui.h.legend = axes('parent', ui.h.plotpanel);
                ui.h.tick_min = uicontrol(ui.h.plotpanel);
                ui.h.tick_max = uicontrol(ui.h.plotpanel);
                ui.h.plttxt = uicontrol(ui.h.plotpanel);
                ui.h.zslider = uicontrol(ui.h.plotpanel);
                ui.h.zbox = uicontrol(ui.h.plotpanel);
                ui.h.saslider = uicontrol(ui.h.plotpanel);
                ui.h.sabox = uicontrol(ui.h.plotpanel);
                ui.h.param = uicontrol(ui.h.plotpanel);
                ui.h.fit_est = uibuttongroup(ui.h.plotpanel);
                    ui.h.fit_par = uicontrol();
                    ui.h.est_par = uicontrol();
                ui.h.d1_select = uicontrol(ui.h.plotpanel);
                ui.h.d2_select = uicontrol(ui.h.plotpanel);
                ui.h.d3_select = uicontrol(ui.h.plotpanel);
                ui.h.d4_select = uicontrol(ui.h.plotpanel);
                
            ui.h.bottombar = uipanel();
                ui.h.info = uicontrol(ui.h.bottombar);
                       
            ui.h.tabs = uitabgroup();
                ui.h.fit_tab = uitab(ui.h.tabs);
                    ui.h.fitpanel = uipanel(ui.h.fit_tab);
                        ui.h.fittxt = uicontrol(ui.h.fitpanel);
                        ui.h.drpd = uicontrol(ui.h.fitpanel);
                        ui.h.bounds = uipanel(ui.h.fitpanel);
                            ui.h.bounds_txt1 = uicontrol(ui.h.bounds);
                            ui.h.bounds_txt2 = uicontrol(ui.h.bounds);
                            ui.h.gstart_text = uicontrol(ui.h.bounds);
                            ui.h.fix_text = uicontrol(ui.h.bounds);
                            ui.h.glob_text = uicontrol(ui.h.bounds);
                    ui.h.parallel = uicontrol(ui.h.fit_tab);
                    ui.h.fit = uicontrol(ui.h.fit_tab);
                    ui.h.hold = uicontrol(ui.h.fit_tab);
                    ui.h.ov_controls = uipanel(ui.h.fit_tab);
                        ui.h.ov_disp = uicontrol(ui.h.ov_controls);
                        ui.h.ov_buttongroup = uibuttongroup(ui.h.ov_controls);
                            ui.h.ov_radiobtns = {uicontrol(ui.h.ov_buttongroup)};
                            ui.h.ov_drpd = uicontrol(ui.h.ov_controls);
                            ui.h.ov_rel = uicontrol(ui.h.ov_controls);
                            ui.h.ov_val = uicontrol(ui.h.ov_controls);
                            ui.h.ov_add_from_auto = uicontrol(ui.h.ov_controls);
                            ui.h.add_overlay = {};
                    
                ui.h.sel_tab = uitab(ui.h.tabs);
                    ui.h.sel_controls = uipanel(ui.h.sel_tab);
                        ui.h.sel_btn_plot = uicontrol(ui.h.sel_controls);

                    ui.h.sel_values = uipanel(ui.h.sel_tab);
                        
                ui.h.pres_tab = uitab(ui.h.tabs);
                    ui.h.savefig = uicontrol(ui.h.pres_tab);
                    ui.h.prevfig = uicontrol(ui.h.pres_tab);
                    ui.h.pres_controls = uipanel(ui.h.pres_tab);
                        ui.h.colormap_drpd_text = uicontrol(ui.h.pres_controls);
                        ui.h.colormap_drpd = uicontrol(ui.h.pres_controls);
                        ui.h.scale_x_text = uicontrol(ui.h.pres_controls);
                        ui.h.scale_x = uicontrol(ui.h.pres_controls);
                        ui.h.scale_y_text = uicontrol(ui.h.pres_controls);
                        ui.h.scale_y = uicontrol(ui.h.pres_controls);
                
            %% Figure, menu, bottombar
            set(ui.h.f, 'units', 'pixels',...
                        'position', [200 200 1010 600],...
                        'numbertitle', 'off',...
                        'menubar', 'none',...
                        'name', 'SISA Scan',...
                        'resize', 'on',...
                        'Color', [.95, .95, .95],...
                        'ResizeFcn', @ui.resize,...
                        'DeleteFcn', @ui.destroy_cb);
     
            set(ui.h.menu, 'Label', 'Datei');
            uimenu(ui.h.menu, 'label', 'Datei �ffnen...',...
                              'callback', @ui.open_file_cb);
            uimenu(ui.h.menu, 'label', 'Plot speichern',...
                              'callback', @ui.save_fig);
            uimenu(ui.h.menu, 'label', 'State speichern (experimentell!)',...
                              'callback', @ui.save_global_state_cb);
            set(ui.h.helpmenu, 'Label', '?');
            uimenu(ui.h.helpmenu, 'label', '�ber',...
                                  'Callback', @ui.open_versioninfo_cb);
            
            set(ui.h.bottombar, 'units', 'pixels',...
                                'position', [-1 0 1000 18],...
                                'BorderType', 'EtchedOut');
                            
            set(ui.h.info, 'units', 'pixels',...
                           'style', 'text',...
                           'string', ui.fileinfo.path,...
                           'HorizontalAlignment', 'left',...
                           'BackgroundColor', get(ui.h.f, 'Color'),...
                           'ForegroundColor', [.3 .3 .3],...
                           'FontSize', 9,...
                           'position', [0 0 1000 15]);
            
            %% Plot
            set(ui.h.plotpanel, 'units', 'pixels',...
                                'position', [270 28 500 500],...
                                'BackgroundColor', [.85 .85 .85]);
            
            set(ui.h.axes, 'units', 'pixels',...
                           'position', [40 60 380 390],...
                           'Color', get(ui.h.plotpanel, 'BackgroundColor'),...
                           'xtick', [], 'ytick', [],...
                           'XColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                           'YColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                           'ButtonDownFcn', @ui.aplot_click_cb);
                       
            set(ui.h.legend, 'units', 'pixels',...
                             'position', [40 12 400 20],...
                             'xtick', [], 'ytick', [],...
                             'XColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                             'YColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                             'visible', 'off');
                                     
            set(ui.h.plttxt, 'units', 'pixels',...
                             'style', 'text',...
                             'string', 'Parameter:',...
                             'position', [50 452 100 20],...
                             'HorizontalAlignment', 'left',...
                             'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                             'FontSize', 9,...
                             'visible', 'off');
                                                       
            set(ui.h.zslider, 'units', 'pixels',...
                              'style', 'slider',...
                              'position', [460 85 20 340],...
                              'value', 1,...
                              'visible', 'off',...
                              'callback', @ui.set_d3_cb,...
                              'BackgroundColor', [1 1 1]);
                           
            set(ui.h.zbox, 'units', 'pixels',...
                           'style', 'edit',...
                           'string', '1',...
                           'position', [460 430 20, 20],...
                           'callback', @ui.set_d3_cb,...
                           'visible', 'off',...
                           'BackgroundColor', [1 1 1]);
            
            set(ui.h.saslider, 'units', 'pixels',...
                               'style', 'slider',...
                               'position', [490 85 20 340],... 
                               'value', 1,...
                               'visible', 'off',...
                               'BackgroundColor', [1 1 1],...
                               'ForegroundColor', [0 0 0],...
                               'callback', @ui.set_d4_cb);

            set(ui.h.sabox, 'units', 'pixels',...
                            'style', 'edit',...
                            'string', '1',...
                            'position', [490 460 20 20],...
                            'callback', @ui.set_d4_cb,...
                            'visible', 'off',...
                            'BackgroundColor', [1 1 1]);

            set(ui.h.param, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', {},...
                            'position', [120 470 80 20],...
                            'FontSize', 9,...
                            'visible', 'off',...
                            'callback', @ui.set_param_cb,...
                            'BackgroundColor', [1 1 1]);
                        
            set(ui.h.tick_min, 'units', 'pixels',...
                               'style', 'edit',...
                               'visible', 'off',...
                               'FontSize', 9,...
                               'string', '1',...
                               'horizontalAlignment', 'left',...
                               'callback', @ui.set_tick_cb,...
                               'position', [40 34 65 17]);
                           
            set(ui.h.tick_max, 'units', 'pixels',...
                               'style', 'edit',...
                               'visible', 'off',...
                               'FontSize', 9,...
                               'string', '100',...
                               'horizontalAlignment', 'right',...
                               'callback', @ui.set_tick_cb,...
                               'position', [405 34 65 17]);  
                           
            set(ui.h.est_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                              'string', 'abgesch�tzt',...
                              'horizontalAlignment', 'left',...
                              'position', [10 1 100 17],...
                              'parent', ui.h.fit_est);
                           
            set(ui.h.fit_par, 'units', 'pixels',...
                              'style', 'radiobutton',...
                              'visible', 'on',...
                              'FontSize', 9,...
                              'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                              'string', 'gefittet',...
                              'horizontalAlignment', 'left',...
                              'position', [115 1 60 17],...
                              'parent', ui.h.fit_est,...
                              'visible', 'off');
                          
            set(ui.h.fit_est, 'units', 'pixels',...
                              'BackgroundColor', get(ui.h.plotpanel, 'BackgroundColor'),...
                              'BorderType', 'none',...
                              'SelectionChangeFcn', @ui.change_par_source_cb,...
                              'position', [220 445 200 21],...
                              'visible', 'off');          
                          
            set(ui.h.d1_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', ui.dimnames,...
                                'value', 1,...
                                'tag', '1',...
                                'visible', 'off',...
                                'callback', @ui.set_dim_cb,...
                                'position', [385 40 30 17],...
                                'BackgroundColor', [1 1 1]);
                            
            set(ui.h.d2_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', ui.dimnames,...
                                'value', 2,...
                                'visible', 'off',...
                                'tag', '2',...
                                'callback', @ui.set_dim_cb,...
                                'position', [5 300 30 17],...
                                'BackgroundColor', [1 1 1]);

            set(ui.h.d3_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', ui.dimnames,...
                                'value', 3,...
                                'visible', 'off',...
                                'tag', '3',...
                                'callback', @ui.set_dim_cb,...
                                'position', [465 520 30 17],...
                                'BackgroundColor', [1 1 1]);
                            
            set(ui.h.d4_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', ui.dimnames,...
                                'value', 4,...
                                'visible', 'off',...
                                'tag', '4',...
                                'callback', @ui.set_dim_cb,...
                                'position', [505 520 30 17],...
                                'BackgroundColor', [1 1 1]);
                            
            %% tabs for switching selection modes
            set(ui.h.tabs, 'units', 'pixels',...
                           'position', [10 28 250 550],...
                           'visible', 'off');
                           
            %% Fitten
            set(ui.h.fit_tab, 'Title', 'Fitten');
            
            set(ui.h.fit,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 2 80 28],...
                           'string', 'global Fitten',...
                           'BackgroundColor', [.8 .8 .8],...
                           'callback', @ui.fit_all_cb);
                       
            set(ui.h.hold, 'units', 'pixels',...
                           'style', 'push',...
                           'position', [84 2 80 28],...
                           'string', 'Fit anhalten',...
                           'BackgroundColor', [.8 .8 .8],...
                           'visible', 'off',...
                           'callback', @ui.hold_fit_cb);
                       
            set(ui.h.parallel, 'units', 'pixels',...
                            'style', 'checkbox',...
                            'string', 'parallel Fitten? (keine Interaktivit�t!)',...
                            'position', [2 35 200 15]);
                        
            %% overlay control
            set(ui.h.ov_controls, 'units', 'pixels',...
                                  'position', [2 260 243 200]);
                              
            set(ui.h.ov_buttongroup, 'units', 'pixels',...
                                     'position', [2 2 237 170]);

            set(ui.h.ov_disp, 'units', 'pixels',...
                              'style', 'checkbox',...
                              'position', [15 175 150 20],...
                              'string', 'Overlay anzeigen',...
                              'callback', @ui.disp_ov_cb);
                              
            set(ui.h.ov_buttongroup, 'SelectionChangedFcn', @ui.set_current_ov_cb);
            
            set(ui.h.ov_radiobtns{1}, 'units', 'pixels',...
                                   'style', 'radiobutton',...
                                   'tag', '1',...
                                   'position', [15 135 15 15]);
                               
            set(ui.h.ov_add_from_auto, 'units', 'pixels',...
                                       'style', 'pushbutton',...
                                       'string', '+',...
                                       'position', [190 134 20 20],...
                                       'callback', {@ui.add_ov_cb, 1});
                                           
            set(ui.h.ov_drpd, 'units', 'pixels',...
                              'style', 'popupmenu',...
                              'position', [35 125 60 30],...
                              'string', {''},...
                              'callback', @ui.change_overlay_cond_cb,...
                              'BackgroundColor', [1 1 1]);
                         
            set(ui.h.ov_rel, 'units', 'pixels',...
                             'style', 'popupmenu',...
                             'position', [96 125 30 30],...
                             'string', {'<', '>'},...
                             'value', 2,...
                             'callback', @ui.change_overlay_cond_cb,...
                             'BackgroundColor', [1 1 1]);
            
            set(ui.h.ov_val, 'units', 'pixels',...
                             'style', 'edit',...
                             'position', [127 133 60 22],...
                             'string', '',...
                             'callback', @ui.change_overlay_cond_cb,...
                             'BackgroundColor', [1 1 1]); 
                         
            %% Fit-Panel:
            set(ui.h.fitpanel, 'units', 'pixels',...
                               'position', [2 55 243 260],...
                               'title', 'Fit-Optionen',...
                               'FontSize', 9);

            % select fit model
            set(ui.h.fittxt, 'units', 'pixels',...
                             'style', 'text',...
                             'position', [15 220 50 15],...
                             'HorizontalAlignment', 'left',...
                             'string', 'Fitmodell:');

            set(ui.h.drpd, 'units', 'pixels',...
                           'style', 'popupmenu',...
                           'string', keys(ui.models),...
                           'value', 1,...
                           'position', [15 205 220 15],...
                           'callback', @ui.set_model_cb,...
                           'BackgroundColor', [1 1 1]);
                       
            set(ui.h.bounds, 'units', 'pixels',...
                             'position', [2 10 237 180],...
                             'title', 'Fitparameter',...
                             'FontSize', 9);
                          
            set(ui.h.bounds_txt1, 'units', 'pixels',...
                                  'position', [40 145 50 15],...
                                  'style', 'text',...
                                  'string', 'untere',...
                                  'horizontalAlignment', 'left');
                              
            set(ui.h.bounds_txt2, 'units', 'pixels',...
                                  'position', [95 145 50 15],...
                                  'style', 'text',...
                                  'string', 'obere',...
                                  'horizontalAlignment', 'left');
                              
            set(ui.h.gstart_text, 'units', 'pixels',...
                             'position', [150 145 50 15],...
                             'style', 'text',...
                             'string', 'Start',...
                             'tooltipString', 'globale Startwerte',...
                             'horizontalAlignment', 'left');
                            
            set(ui.h.fix_text, 'units', 'pixels',...
                               'position', [201 145 20 15],...
                               'style', 'text',...
                               'string', 'f',...
                               'tooltipString', 'Parameter fixieren',...
                               'horizontalAlignment', 'left');
                            
            set(ui.h.glob_text, 'units', 'pixels',...
                               'position', [218 145 20 15],...
                               'style', 'text',...
                               'string', 'g',...
                               'tooltipString', 'Startwerte globalisieren',...
                               'horizontalAlignment', 'left');
                            
            ui.h.lb = cell(1, 1);
            ui.h.ub = cell(1, 1);
            ui.h.st = cell(1, 1);
            ui.h.fix = cell(1, 1);
            ui.h.n = cell(1, 1);
            ui.h.gst = cell(1, 1);

            %% interpretation
            set(ui.h.sel_tab, 'Title', 'Auswertung');
            
            set(ui.h.sel_controls, 'units', 'pixels',...
                                   'position', [2 360 243 100])
      
            set(ui.h.sel_btn_plot, 'units', 'pixels',...
                             'style', 'push',...
                             'position', [15 50 50 20],...
                             'string', 'Plotten',...
                             'callback', @ui.plot_group);

            % info about the selected data
            set(ui.h.sel_values, 'units', 'pixels',...
                                 'position', [2 100 243 250])  
            
            ui.h.mean = cell(1, 1);
            ui.h.var = cell(1, 1);
            ui.h.par = cell(1, 1);
            
            %% presentation
            set(ui.h.pres_tab, 'Title', 'Darstellung');
            
            set(ui.h.pres_controls, 'units', 'pixels',...
                                    'position', [2 50 243 250])
                               
            set(ui.h.savefig, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [2 2 80 28],...
                              'string', 'Plot speichern',...
                              'BackgroundColor', [.8 .8 .8],...
                              'callback', @ui.save_fig);
                          
            set(ui.h.prevfig, 'units', 'pixels',...
                              'style', 'push',...
                              'position', [92 2 80 28],...
                              'string', 'Vorschau',...
                              'BackgroundColor', [.8 .8 .8],...
                              'callback', @ui.generate_export_fig_cb);
                          
            set(ui.h.colormap_drpd_text, 'units', 'pixels',...
                                         'style', 'text',...
                                         'string', 'Colormap:',...
                                         'horizontalAlignment', 'left',...
                                         'position', [10, 142, 50, 25]);
                          
            set(ui.h.colormap_drpd, 'units', 'pixels',...
                                    'style', 'popupmenu',...
                                    'position', [70, 160, 80, 10],...
                                    'string', {'parula', 'jet', 'hsv',...
                                               'hot', 'cool', 'spring',...
                                               'summer', 'autumn', 'winter',...
                                               'gray', 'bone', 'copper',...
                                               'pink'},...
                                    'value', 7,...
                                    'callback', @ui.set_cmap_cb);
            
            set(ui.h.scale_x_text, 'units', 'pixels',...
                                   'style', 'text',...
                                   'string', 'mm/px X:',...
                                   'horizontalAlignment', 'left',...
                                   'position', [10, 112, 80, 25]);
                                     
            set(ui.h.scale_x, 'units', 'pixels',...
                              'style', 'edit',...
                              'callback', @ui.set_scale_cb,...
                              'position', [70, 120, 80, 20]);
            
            set(ui.h.scale_y_text, 'units', 'pixels',...
                                   'style', 'text',...
                                   'string', 'mm/px Y:',...
                                   'horizontalAlignment', 'left',...
                                   'position', [10, 82, 80, 25]);

            set(ui.h.scale_y, 'units', 'pixels',...
                              'style', 'edit',...
                              'callback', @ui.set_scale_cb,...
                              'position', [70, 90, 80, 20]);                             
           
            %% check version (only if called as a binary)
            ui.check_version();
                                 
            %% limit size with java
            unsafe_limit_size(ui.h.f, [700 550]);
            
            %% init
            ui.resize();
            ui.set_model('1. A*(exp(-t/t1)-exp(-t/t2))+offset');
            
            if nargin > 1
                if nargin == 3
                    set(ui.h.f, 'position', pos);
                end
                pause(.1);
                ui.open_file(path, name);
            end
        end
        
    % functions for opening and reading various files:
        function open_file(ui, path, name)
            ui.loadini();
            ui.fileinfo.path = path;
            ui.openpath = path;
            filepath = path;
            if iscell(name)
                % multiple selection
                % TODO: check if all files end with *.diff
                ui.fileinfo.name = name;
                ui.openDIFF();
                [~, n] = fileparts(name{1});
            else
                % single selection
                [~, ~, ext] = fileparts(name);
                if regexp(ext, 'h5$')
                    ui.fileinfo.name = {name};
                    ui.openHDF5();
                elseif regexp(ext, 'state$')
                    ui.saveini();
                    ui.load_global_state([filepath name])
                    return
                end
                [~, n] = fileparts(name);
            end
            

            ui.genericname = n;
            
            tmp = size(ui.data);
            ui.fileinfo.size = tmp(1:4);
            
            ui.overlays{1} = ones(tmp(1), tmp(2), tmp(3), tmp(4));
            ui.overlays{2} = zeros(tmp(1), tmp(2), tmp(3), tmp(4));
            
            ui.saveini();
            
            % UI stuff
            t = keys(ui.models);
            t = ui.models(t{get(ui.h.drpd, 'value')});
             
            set(ui.h.plttxt, 'visible', 'on');
            set(ui.h.fit_est, 'visible', 'on');
            set(ui.h.param, 'visible', 'on', 'string', [t{4}, 'Summe']);
            set(ui.h.ov_drpd, 'string', [t{4}, 'Summe']);
            set(ui.h.tabs, 'visible', 'on');
            
            ui.update_infos();
            ui.set_model('1. A*(exp(-t/t1)-exp(-t/t2))+offset');
            ui.change_overlay_cond_cb();
            ui.update_sliders();
            ui.plot_array();
            
            ui.set_scale(ui.scale);
            ui.generate_overlay();
            
            % initialise here, so we can check whether a point is fitted or not
            s = num2cell(size(ui.est_params));
            ui.fit_chisq = nan(s{1:4});
        end
        
        function openHDF5(ui)
            filepath = [ui.fileinfo.path ui.fileinfo.name{1}];
            % get dimensions of scan, determine if scan finished
            try
                x_step = h5readatt(filepath, '/PATH/DATA','X Step Size mm');
                y_step = h5readatt(filepath, '/PATH/DATA','Y Step Size mm');
                z_step = h5readatt(filepath, '/PATH/DATA','Z Step Size mm');
                ui.scale = [x_step y_step z_step];
            end
            try
                dims = h5readatt(filepath, '/PATH/DATA', 'GRID DIMENSIONS');
                if strcmp(dims{:}, '')
                    dims = {'0/0/0'};
                end
                dims = strsplit(dims{:}, '/');

                        % offset of 1 should be fixed in labview scan software
                offset = 1;
                if str2double(dims{3}) < 0
                    offset = abs(str2double(dims{3}))+1;
                end
                ui.fileinfo.size = [str2double(dims{1})+1 str2double(dims{2})+1 str2double(dims{3})+offset];
                        % end of fix

                % get attributes from file
                fin = h5readatt(filepath, '/PATH/DATA', 'LAST POINT');

                % get scanned points
                tmp = h5read(filepath, '/PATH/DATA');
                tmp = tmp.Name;
                
                if  strcmp(fin{:}, 'CHECKPOINT')
                    ui.fileinfo.finished = true;
                    num_of_points = length(tmp) - 1;
                else
                    ui.fileinfo.finished = false;
                    num_of_points = length(tmp);
                end
            catch exception
                display(exception);
                offset=1;
                [tmp,dims]=estimate_path(filepath);
                ui.fileinfo.finished = true;
                ui.fileinfo.size = [dims{1} dims{2} dims{3}];
                fin=tmp{end};
                num_of_points = length(tmp);
            end
            
            % read Channel Width
            try
                chanWidth=h5readatt(filepath, '/META/SISA', 'Channel Width (ns)');
                ui.channel_width=single(chanWidth)/1000;
            end
            
            % get max number of samples per point (should be at /0/0/0/sisa)
            info = h5info(filepath, '/0/0/0/sisa');
            ui.fileinfo.size(4) = length(info.Datasets);
            
            % create map between string and position in data
                % now reasonably fast(about 10 times faster then before), 
                % approx factor 2 possible with:
                % vec = cellfun(@(x) textscan(x,'%d/%d/%d', 'CollectOutput', 1),tmp);
                % but vec is the complete matrix and I don't know how to 
                % put this matrix into ui.points()
            ui.points = containers.Map;
            for i = 1:num_of_points
                vec = cell2mat(textscan(tmp{i},'%n/%n/%n')) + [1 1 offset];
                ui.points(tmp{i}) = vec;
                if mod(i, round((length(tmp) - 1)/10)) == 0
                    ui.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
                if strcmp(tmp{i}, fin)
                    break
                end
            end

            % get number of scanned points
            ui.fileinfo.np = ui.points.Count;
            
            % UI stuff
            set(ui.h.f, 'name', ['SISA Scan - ' ui.fileinfo.name{1}]);
            
            ui.readHDF5();
        end

        function readHDF5(ui, varargin)
            filepath = [ui.fileinfo.path ui.fileinfo.name{1}];
            time_zero = 0;
            k = keys(ui.points);
            fid = H5F.open(filepath);
            for i = 1:ui.fileinfo.np
                ind = ui.points(k{i});
                % every point should have exactly as many samples
                % as the first point, except for the last one
%                 if i == ui.fileinfo.np % get number of samples for last point
                    dataset_group= sprintf('/%s/sisa',k{i});
                    gid = H5G.open(fid,dataset_group);
                    info = H5G.get_info(gid);
%                 else % take number of samples of first point
%                     samples = ui.fileinfo.size(4);
%                 end
                for j = 1:info.nlinks % iterate over all samples
                    dset_id = H5D.open(gid,sprintf('%d',j));
                    d = H5D.read(dset_id);
                    H5D.close(dset_id);
                    ui.data(ind(1), ind(2), ind(3), j, :) = d;
                    [~, t] = max(d(1:end));
                    time_zero = (time_zero + t)/2;
                end
                H5G.close(gid);
                if mod(i, round(ui.fileinfo.np/20)) == 0
                    ui.update_infos(['   |   Daten einlesen ' num2str(i) '/' num2str(ui.fileinfo.np) '.']);
                end
            end
            H5F.close(fid);
            
            ui.t_zero = round(time_zero);
            ui.x_data = ((1:length(ui.data(1, 1, 1, 1, :)))-ui.t_zero)'*ui.channel_width;
            ui.data_read = true;
        end
        
        function openDIFF(ui)
            time_zero = 0;
            name = ui.fileinfo.name;
            if iscell(name)
                for i = 1:length(name)
                    ui.fileinfo.size = [length(name), 1, 1];
                    d = dlmread([ui.fileinfo.path name{i}]);
                    [~, t] = max(d(1:end));
                    time_zero = (time_zero + t)/2;
                    ui.data(i, 1, 1, 1,:) = d;
                end
                ui.fileinfo.np = length(name);
            end
            ui.t_zero = round(time_zero);
            ui.x_data = ((1:length(ui.data(1, 1, 1, 1, :)))-ui.t_zero)'*ui.channel_width;
            ui.data_read = true;
            
            tmp = size(ui.data);
            ui.fileinfo.size = tmp(1:4);
            
            ui.points = containers.Map;
            for i = 1:length(name)
                vec = [i 1 1];
                ui.points(num2str(vec)) = vec;
                if mod(i, round(length(name)/10)) == 0
                    ui.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
                end
            end
        end
        
        function load_global_state(ui, file)
            load(file, '-mat');
            if ui_new.version ~= ui.version
                wh = warndlg({['Version des geladenen Files (' num2str(ui_new.version)...
                              ') entspricht nicht der Version des aktuellen Programms'...
                              ' (' num2str(ui.version) '). Dies wird zu unerwartetem '...
                              'Verhalten (bspw. fehlender Funktionalit�t) f�hren!'], ...
                              ['Zum Umgehen dieses Problems sollten die zugrundeliegenden '...
                              'Daten erneut ge�ffnet und gefittet werden']}, 'Warnung', 'modal');
                pos = wh.Position;
                wh.Position = [pos(1) pos(2) pos(3)+20 pos(4)];
                wh.Children(3).Children.FontSize = 9;
                
            end
            ui_new.destroy(true);
            unsafe_limit_size(ui_new.h.f, [700 550]);
            close(ui.h.f);
            delete(ui);
        end
        
    % functions for updating the GUI
        function update_sliders(ui)
            [s1, s2, s3, s4, ~] = size(ui.est_params);
            s = [s1 s2 s3 s4];

            % handle z-scans
            if s(ui.curr_dims(3)) > 1 
                set(ui.h.zslider, 'min', 1, 'max', s(ui.curr_dims(3)),...
                                  'visible', 'on',...
                                  'SliderStep', [1 5]/(s(ui.curr_dims(3))-1));
                set(ui.h.zbox, 'visible', 'on');
                set(ui.h.d3_select, 'visible', 'on');
            else 
                set(ui.h.zbox, 'visible', 'off');
                set(ui.h.zslider, 'visible', 'off');
                set(ui.h.d3_select, 'visible', 'off');
            end
            % handle multiple samples
            if s(ui.curr_dims(4)) > 1 
                set(ui.h.saslider, 'min', 1, 'max', s(ui.curr_dims(4)),...
                                  'visible', 'on',...
                                  'SliderStep', [1 5]/(s(ui.curr_dims(4))-1));
                set(ui.h.sabox, 'visible', 'on');
                set(ui.h.d4_select, 'visible', 'on');
            else 
                set(ui.h.sabox, 'visible', 'off');
                set(ui.h.saslider, 'visible', 'off');
                set(ui.h.d4_select, 'visible', 'off');
            end
        end

        function update_infos(ui, text)
            pause(.0001);                    
            if nargin < 2
                text = '';
            end
            str = [[ui.fileinfo.path ui.fileinfo.name{1}] '  |   Dimensionen: ' num2str(ui.fileinfo.size)];
            if ui.fitted
                str = [str '   |   Daten global gefittet.'];
            elseif ui.data_read
                str = [str '   |    Daten eingelesen.'];
            end
            set(ui.h.info, 'string', [str text]);
            pause(.0001);
        end

        function plot_array(ui, varargin)
            ui.generate_mean();
            param = ui.current_param;

            if ui.disp_fit_params
                switch param
                    case length(ui.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = ui.fit_chisq;
                    otherwise
                        plot_data = ui.fit_params(:, :, :, :, param);
                end
            else
                switch param
                    case length(ui.est_params(1, 1, 1, 1, :)) + 1
                        plot_data = ui.data_sum;
                    otherwise
                        plot_data = ui.est_params(:, :, :, :, param);
                end
            end
            
            ui.set_transpose();
            
            sx = size(plot_data, ui.curr_dims(1));
            sy = size(plot_data, ui.curr_dims(2));
            
            plot_data = squeeze(plot_data(ui.ind{:}));
            
            % squeeze does strange things: (1x3x1)-array -> (3x1)-array
            
            [sxn, syn] = size(plot_data);
           
            if (sxn ~= sx || syn ~= sy) % breaks for sx == sy...
                ui.transpose = ~ui.transpose;
                plot_data = plot_data';
                ov_data = squeeze(ui.overlays{ui.current_ov}(ui.ind{:}))';
            elseif sx > 1 && sy > 1 && ui.transpose
                plot_data = plot_data';
                ov_data = squeeze(ui.overlays{ui.current_ov}(ui.ind{:}))';
            else
                ov_data = squeeze(ui.overlays{ui.current_ov}(ui.ind{:}));
            end
            
            ui.overlay_data = ov_data;
            
            % for legend minimum and maximum
            if ~ui.use_user_legend
                ui.calculate_legend();
            end
            tickmax = ui.l_max(param);
            tickmin = ui.l_min(param);
            % plotting:
            % Memo to self: Don't try using HeatMaps... seriously.
            if gcf == ui.h.f || ui.fitted % don't plot when figure is in background
                set(ui.h.f, 'CurrentAxes', ui.h.axes); 
                cla
                hold on
                hmap(plot_data', false, ui.cmap);
                if ui.disp_ov
                    plot_overlay(ov_data');
                end
                hold off
                s = size(plot_data');
                xlim([.5 s(2)+.5])
                ylim([.5 s(1)+.5])

                if tickmin < tickmax
                    caxis([tickmin tickmax])
                    
                    set(ui.h.f, 'CurrentAxes', ui.h.legend);
                    l_data = tickmin:(tickmax-tickmin)/20:tickmax;
                    cla
                    hold on
                    hmap(l_data, false, ui.cmap);
                    hold off
                    xlim([.5 length(l_data)+.5])
                    set(ui.h.legend, 'visible', 'on');
                    set(ui.h.tick_min, 'visible', 'on', 'string', num2str(l_data(1),4));
                    set(ui.h.tick_max, 'visible', 'on', 'string', num2str(l_data(end),4));
                end
            end
            set(ui.h.d1_select, 'visible', 'on');
            set(ui.h.d2_select, 'visible', 'on');
        end
        
        function set_model(ui, str)
            t = keys(ui.models);
            set(ui.h.drpd, 'value', find(strcmp(t, str))); % set the model in the drpd
            
            t = ui.models(str);
            ui.fit_params = nan(ui.fileinfo.size(1), ui.fileinfo.size(2),...
                                ui.fileinfo.size(3), ui.fileinfo.size(4), length(t{4}));
            ui.l_max = nan(length(t{4}) + 1, 1);
            ui.l_min = nan(length(t{4}) + 1, 1);
            ui.model = str;
            if ui.data_read
                ui.estimate_parameters();
                set(ui.h.plttxt, 'visible', 'on');
                set(ui.h.param, 'visible', 'on',...
                                'string', [t{4}, 'Summe']);
                ui.plot_array();
            end
        end
        
        function set_gstart(ui, gst)
            ui.gstart = gst;
            for i = 1:length(ui.gstart);
                set(ui.h.st{i}, 'string', gst(i));
            end
        end
        
        function set_param_glob(ui, glob)
            if length(glob) == length(ui.gstart)
                ui.use_gstart = glob;
                for i = 1:length(glob)
                    set(ui.h.gst{i}, 'value', glob(i))
                end
            end
        end
        
        function set_scale(ui, scl)
            ui.scale = scl;
            set(ui.h.scale_x, 'string', ui.scale(1));
            set(ui.h.scale_y, 'string', ui.scale(2));
        end
        
        function generate_sel_vals(ui)
            m = ui.models(ui.model);
            n = length(m{4});

            for i = 1:length(ui.h.mean)
                delete(ui.h.mean{i});
                delete(ui.h.var{i});
                delete(ui.h.par{i});
            end 
            ui.h.mean = cell(n, 1);
            ui.h.var = cell(n, 1);
            ui.h.par = cell(n, 1);
            for i = 1:n
                ui.h.mean{i} = uicontrol(ui.h.sel_values, 'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', sprintf('%1.2f', ui.selection_props.mean(i)),...
                                                    'position', [55 155-i*23-10 45 20],...
                                                    'BackgroundColor', [1 1 1]);
                ui.h.var{i} = uicontrol(ui.h.sel_values, 'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', sprintf('%1.2f', ui.selection_props.var(i)),...
                                                    'position', [115 155-i*23-10 45 20],...
                                                    'BackgroundColor', [1 1 1]);
                ui.h.par{i} = uicontrol(ui.h.sel_values,  'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', m{4}{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [15 155-i*23-14 40 20]);
            end
        end % mean, std, etc.

        function generate_export_fig(ui, ax_in, vis)
            x = size(ui.data, ui.curr_dims(1));
            y = size(ui.data, ui.curr_dims(2));

            if x > y
                d = x;
            else
                d = y;
            end

            scale_pix = 800/d;  % max width or height of the axes
            scl = ui.scale./max(ui.scale);
            
            x_pix = x*scale_pix*scl(1);
            y_pix = y*scale_pix*scl(2);
            
            tmp = get(ax_in, 'position');
            if isfield(ui.h, 'plot_pre') && ishandle(ui.h.plot_pre)
                figure(ui.h.plot_pre);
                clf();
            else
                ui.h.plot_pre = figure('visible', vis);
            end
            screensize = get(0, 'ScreenSize');
            windowpos = [screensize(3)-(x_pix+150) screensize(4)-(y_pix+150)  x_pix+80 y_pix+100];
            set(ui.h.plot_pre, 'units', 'pixels',...
                   'position', windowpos,...
                   'numbertitle', 'off',...
                   'name', 'SISA Scan Vorschau',...
                   'menubar', 'none',...
                   'resize', 'off',...
                   'Color', [.95, .95, .95]);

            ax = copyobj(ax_in, ui.h.plot_pre);
            set(ax, 'position', [tmp(1) tmp(2) x_pix y_pix],...
                    'XColor', 'black',...
                    'YColor', 'black');
            xlabel([ui.dimnames{ui.curr_dims(1)} ' [mm]'])
            ylabel([ui.dimnames{ui.curr_dims(2)} ' [mm]'])
            
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
            
            x_tick_label = num2cell((0:x_label_res:x-1)*ui.scale(1));
            y_tick_label = num2cell((0:y_label_res:y-1)*ui.scale(2));
            
            set(ax, 'xtick', x_tick, 'ytick', y_tick,...
                    'xticklabel', x_tick_label,...
                    'yticklabel', y_tick_label);
            caxis([ui.l_min ui.l_max]);
            colormap(ui.cmap);
            c = colorbar();
            set(c, 'units', 'pixels');
            tmp2 = get(c, 'position');
            tmp2(1) = tmp(1)+x_pix+15;
            set(c, 'position', tmp2);
            if tmp2(1) + tmp2(3) > windowpos(3)
                windowpos(3) = windowpos(3) + tmp2(3) + 20;
                set(ui.h.plot_pre, 'position', windowpos);
            end
        end

        function add_ov(ui, init)
            new_ov_number = length(ui.overlays)+1;
            ui.overlays{new_ov_number} = init;
            ui.generate_overlay();
            ui.set_current_ov(new_ov_number);
            ui.plot_array();
        end
        
        function del_ov(ui, position)
            if position == 1 % cannot delete first overlay
                return
            end
     
            ui.overlays(position) = [];
            ui.generate_overlay();
            ui.set_current_ov(ui.current_ov-1);
        end
        
        function set_current_ov(ui, pos)
            if pos < 1
                pos = 1;
            end
            ui.current_ov = pos;
            ui.plot_array();
            ui.h.ov_radiobtns{pos}.Value = true;
        end
        
        function set_savepath(ui, path)
            ui.savepath = path; 
        end
        
        function generate_overlay(ui)
            ov_number = length(ui.overlays);
            pos_act_r = [15 135 115 20];
            for i = 2:length(ui.h.ov_radiobtns)
                delete(ui.h.ov_radiobtns{i});
                delete(ui.h.del_overlay{i});
                delete(ui.h.add_overlay{i});
            end
            
            for i = 2:ov_number
                pos_act_r = pos_act_r-[0 25 0 0];
                ui.h.ov_radiobtns{i} = uicontrol(ui.h.ov_buttongroup,...
                                                 'units', 'pixels',...
                                                 'style', 'radiobutton',...
                                                 'Tag', num2str(i),...
                                                 'string', ['Overlay ' num2str(i)],...
                                                 'position', pos_act_r);
                ui.h.del_overlay{i} = uicontrol(ui.h.ov_controls,...
                                                 'units', 'pixels',...
                                                 'style', 'pushbutton',...
                                                 'string', '-',...
                                                 'visible', 'on',...
                                                 'position', [190 pos_act_r(2) 20 20],...
                                                 'callback', {@ui.del_ov_cb, i});
                ui.h.add_overlay{i} = uicontrol(ui.h.ov_controls,...
                                                 'units', 'pixels',...
                                                 'style', 'pushbutton',...
                                                 'string', '+',...
                                                 'visible', 'on',...
                                                 'position', [211 pos_act_r(2) 20 20],...
                                                 'callback', {@ui.add_ov_cb, i});
            end
        end

        function check_version(ui)
            if isdeployed()
                try
                    newestversion = str2double(urlread(ui.online_ver));
                    if newestversion > ui.version
                        wh = warndlg({['Es ist eine neue Version der Software verf�gbar ('...
                                       num2str(newestversion) ').'], ['Aktuelle Version: '...
                                       num2str(ui.version) '.'],... 
                                       'Download unter: https://git.daten.tk/'}, 'Warnung', 'modal');
                        pos = wh.Position;
                        wh.Position = [pos(1) pos(2) pos(3)+20 pos(4)];
                        wh.Children(3).Children.FontSize = 9;
                    end
                end
            end
        end
        
        function loadini(ui)
            p = get_executable_dir();
            if exist([p filesep() 'config.ini'], 'file')
                conf = readini('config.ini');
                if isfield(conf, 'openpath')
                    ui.openpath = conf.openpath;
                else
                    ui.openpath = [p filesep()];
                end
                if isfield(conf, 'savepath')
                    ui.savepath = conf.savepath;
                else
                    ui.savepath = [p filesep()];
                end
            else
                ui.openpath = [p filesep()];
                ui.savepath = [p filesep()];
            end
        end
        
        function saveini(ui)
            p = get_executable_dir();
            strct.version = ui.version;
            strct.openpath = ui.openpath;
            strct.savepath = ui.savepath;

            writeini([p filesep() 'config.ini'], strct);
        end
        
        function destroy(ui, children_only)
            try
                ui.saveini();
            end
            
            if ~isempty(ui.plt)
                for i = 1:length(ui.plt)
                    if isvalid(ui.plt{i}) && isa(ui.plt{i}, 'UIPlot')
                        delete(ui.plt{i}.h.f);
                        delete(ui.plt{i});
                    end
                end
            end
            if ~isempty(ui.gplt)
                for i = 1:length(ui.gplt)
                    if isvalid(ui.gplt{i}) && isa(ui.gplt{i}, 'UIGroupPlot')
                        delete(ui.gplt{i}.h.f);
                        delete(ui.gplt{i});
                    end
                end
            end
            if ~children_only
                delete(ui.h.f);
                delete(ui);
            end
        end
        
        function set_disp_ov(ui, val)
            ui.disp_ov = val;
            set(ui.h.ov_disp, 'Value', val);
            ui.plot_array();
        end
        
        function set_transpose(ui)
            if ui.curr_dims(1) > ui.curr_dims(2)
                ui.transpose = true;
            else 
                ui.transpose = false;
            end
        end
                
    % functions that actually compute something
        function compute_ov(ui)
             if ui.disp_fit_params
                val = str2double(get(ui.h.ov_val, 'string'));
                par = get(ui.h.ov_drpd, 'value');
                no_pars = size(ui.fit_params, 5);
                switch get(ui.h.ov_rel, 'value')
                    case 1
                        if par <= no_pars
                            ui.overlays{1} = ui.fit_params(:, :, :, :, par) < val;
                        else
                            ui.overlays{1} = ui.fit_chisq < val;
                        end
                    case 2
                        if par <= no_pars
                            ui.overlays{1} = ui.fit_params(:, :, :, :, par) > val;
                        else
                            ui.overlays{1} = ui.fit_chisq > val;
                        end
                end
            else
                val = str2double(get(ui.h.ov_val, 'string'));
                par = get(ui.h.ov_drpd, 'value');
                no_pars = size(ui.est_params, 5);
                switch get(ui.h.ov_rel, 'value')
                    case 1
                        if par <= no_pars
                            ui.overlays{1} = ui.est_params(:, :, :, :, par) < val;
                        else
                            ui.overlays{1} = ui.data_sum < val;
                        end
                    case 2
                        if par <= no_pars
                            ui.overlays{1} = ui.est_params(:, :, :, :, par) > val;
                        else
                            ui.overlays{1} = ui.data_sum > val;
                        end
                end
            end
        end
    
        function estimate_parameters(ui)
            n = ui.models(ui.model);
            ui.est_params = zeros(ui.fileinfo.size(1), ui.fileinfo.size(2),...
                              ui.fileinfo.size(3), ui.fileinfo.size(4), length(n{2}));
            ub = zeros(length(n{3}), 1);
            lb = ones(length(n{2}), 1)*100;
            p = values(ui.points);
            for i = 1:ui.fileinfo.np
                for j = 1:ui.fileinfo.size(4)
                    d = ui.data(p{i}(1), p{i}(2), p{i}(3), j, :);
                    ps = UI.estimate_parameters_p(d, ui.model, ui.t_zero, ui.t_offset, ui.channel_width);
                    ui.est_params(p{i}(1), p{i}(2), p{i}(3), j, :) = ps;
                    if mod(i, round(ui.fileinfo.np/20)) == 0
                        ui.update_infos(['   |   Parameter absch�tzen ' num2str(i) '/' num2str(ui.fileinfo.np) '.']);
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
            ui.data_sum = sum(ui.data(:, :, :, :, (ui.t_zero+ui.t_offset):end), 5);
            ui.fitted = false;
                          
            % set bounds from estimated parameters
            tmp = ui.models(ui.model);
            tmp{3} = ub*1.5;
            tmp{2} = lb*0.5;
            ui.models(ui.model) = tmp;
            ui.gstart = (ub+lb)./2;
            
            ui.generate_bounds();
            
            ui.update_infos();
            set(ui.h.ov_val, 'string', mean(mean(mean(mean(squeeze(ui.est_params(:, :, :, :, 1)))))));
        end

        function fit_all(ui, start)
            if ui.disp_ov
                ma = length(find(ui.overlays{ui.current_ov}));
            else
                ma = prod(ui.fileinfo.size);
            end
            % set cancel button:
            set(ui.h.fit, 'string', 'Abbrechen', 'callback', @ui.cancel_fit_cb);
            set(ui.h.hold, 'visible', 'on');
            
            s = num2cell(size(ui.est_params));
            if start == 1
                ui.fit_params = nan(s{:});
                ui.fit_params_err = nan(s{:});
            end
           
            for n = start:ma
                [i,j,k,l] = ind2sub(ui.fileinfo.size, n);               
                if ui.overlays{ui.current_ov}(i, j, k, l) || ~ui.disp_ov
                    y = squeeze(ui.data(i, j, k, l, (ui.t_offset+ui.t_zero):end));
                    x = ui.x_data((ui.t_zero + ui.t_offset):end);
                    w = sqrt(y);
                    w(w == 0) = 1;
                    if sum(ui.use_gstart) > 0
                        start = ui.est_params(i, j, k, l, :);
                        start(find(ui.use_gstart)) = ui.gstart(find(ui.use_gstart));
                        [p, p_err, chi] = fitdata(ui.models(ui.model),...
                            x, y, w, start, ui.fix);
                    else

                        [p, p_err, chi] = fitdata(ui.models(ui.model),...
                            x, y, w, ui.est_params(i, j, k, l, :), ui.fix); 
                    end
                    ui.fit_params(i, j, k, l, :) = p;
                    ui.fit_params_err(i, j, k, l, :) = p_err;
                    ui.fit_chisq(i, j, k, l) = chi;
                    ui.update_infos(['   |   Fitte ' num2str(n) '/' num2str(ma) '.'])
                    ui.last_fitted = n;
                end
                if n == 1
                    set(ui.h.fit_par, 'visible', 'on');
                end
                if ui.disp_fit_params
                    ui.plot_array();
                end
                if ui.hold_f
                    ui.hold_f = false;
                    set(ui.h.hold, 'string', 'Fortsetzen',...
                                   'callback', @ui.resume_fit_cb);
                    return
                end
                if ui.cancel_f
                    ui.cancel_f = false;
                    return
                end
            end
            
            set(ui.h.hold, 'visible', 'off');
            set(ui.h.fit, 'string', 'global Fitten', 'callback', @ui.fit_all_cb);
            ui.fitted = true;
            ui.update_infos();
            ui.plot_array();
        end
        
        function fit_all_par(ui, start)
            if ui.disp_ov
                ma = length(find(ui.overlays{ui.current_ov}));
            else
                ma = prod(ui.fileinfo.size);
            end
            
            ui.update_infos('   |   Fitte parallel.')
            
            s = num2cell(size(ui.est_params));
            if start == 1
                ui.fit_params = nan(s{:});
                ui.fit_params_err = nan(s{:});
            end
            s = ui.fileinfo.size;
            ov = ui.overlays{ui.current_ov};
            d_ov = ui.disp_ov;
            d = ui.data;
            xd = ui.x_data;
            t_o = ui.t_offset;
            t_z = ui.t_zero;
            u_gstart = ui.use_gstart;
            gstart = ui.gstart;
            m = ui.models(ui.model);
            e_pars = ui.est_params;
            f = ui.fix;
            f_pars = zeros(ma, 4);
            f_pars_e = zeros(ma, 4);
            f_chisq = zeros(ma, 1);

            parfor n = start:ma
                [i,j,k,l] = ind2sub(s, n);               
                if ov(i,j,k,l) || ~d_ov
                    y = squeeze(d(i, j, k, l, (t_o+t_z):end));
                    x = xd((t_o+t_z):end);
                    w = sqrt(y);
                    w(w == 0) = 1;
                    if sum(u_gstart) > 0
                        start = ui.est_params(i, j, k, l, :);
                        start(find(u_gstart)) = gstart(find(u_gstart));
                        [p, p_err, chi] = fitdata(m ,...
                            x, y, w, start, ui.fix);
                    else
                        [p, p_err, chi] = fitdata(m,...
                            x, y, w, e_pars(i, j, k, l, :), f); 
                    end
                    f_pars(n, :) = p;
                    f_pars_e(n, :) = p_err;
                    f_chisq(n) = chi;
                end
            end
            set(ui.h.fit_par, 'visible', 'on');
            ui.fitted = true;
            ui.update_infos();
            ui.fit_params = reshape(f_pars, [ui.fileinfo.size size(f_pars, 2)]);
            ui.fit_params_err = reshape(f_pars_e, [ui.fileinfo.size size(f_pars, 2)]);
            ui.fit_chisq = reshape(f_chisq, ui.fileinfo.size);
            ui.plot_array();
        end
        
        function generate_bounds(ui)
            m = ui.models(ui.model);
            n = length(m{4});
            
            if  length(ui.gstart) < n
                ui.gstart = (m{2}(:)+m{3}(:))./2;
            end
            if length(ui.use_gstart) < n
                ui.use_gstart = [ui.use_gstart; zeros(n - length(ui.use_gstart), 1)];
            end
            
            for i = 1:length(ui.h.lb)
                delete(ui.h.lb{i});
                delete(ui.h.ub{i});
                delete(ui.h.n{i});
                delete(ui.h.st{i});
                delete(ui.h.fix{i});
                delete(ui.h.gst{i});
            end 
            ui.h.lb = cell(n, 1);
            ui.h.ub = cell(n, 1);
            ui.h.n = cell(n, 1);
            ui.h.st = cell(n, 1);
            ui.h.fix = cell(n, 1);
            ui.h.gst = cell(n, 1);

            for i = 1:n
                ui.h.n{i} = uicontrol(ui.h.bounds,  'units', 'pixels',...
                                                    'style', 'text',...
                                                    'string', m{4}{i},...
                                                    'horizontalAlignment', 'left',...
                                                    'position', [5 155-i*23-14 35 20]);
                                                
                ui.h.lb{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', m{2}(i)),...
                                                    'position', [40 155-i*23-10 45 20],...
                                                    'callback', @ui.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                ui.h.ub{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', m{3}(i)),...
                                                    'position', [95 155-i*23-10 45 20],...
                                                    'callback', @ui.set_bounds_cb,...
                                                    'BackgroundColor', [1 1 1]);

                ui.h.st{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                    'style', 'edit',...
                                                    'string', sprintf('%1.2f', ui.gstart(i)),...
                                                    'position', [150 155-i*23-10 45 20],...
                                                    'callback', @ui.set_gstart_cb,...
                                                    'BackgroundColor', [1 1 1]);
                                                
                ui.h.fix{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                     'style', 'checkbox',...
                                                     'value', ismember(m{4}(i), ui.fix),...
                                                     'position', [198 155-i*23-10 40 20],...
                                                     'callback', @ui.set_param_fix_cb);
                                                 
                ui.h.gst{i} = uicontrol(ui.h.bounds, 'units', 'pixels',...
                                                     'style', 'checkbox',...
                                                     'value', ui.use_gstart(i),...
                                                     'position', [215 155-i*23-10 40 20],...
                                                     'callback', @ui.set_param_glob_cb);
            end
        end

        function generate_mean(ui)
            s = size(ui.fit_params);
            sel = find(ui.overlays{ui.current_ov});
            for i = 1:s(end)
                if ui.fitted && ui.disp_fit_params
                    fp = squeeze(ui.fit_params(:, :, :, :, i));
                else
                    fp = squeeze(ui.est_params(:, :, :, :, i));
                end
                ui.selection_props.mean(i) = mean(fp(sel));
                ui.selection_props.var(i) = std(fp(sel));
            end
            ui.generate_sel_vals();
        end
        
        function calculate_legend(ui)
            tmp = ui.models(ui.model);
            for i = 1:length(tmp{2})
                if ui.disp_fit_params
                    ui.l_max(i) = squeeze(max(max(max(max(ui.fit_params(:,:,:,:,i))))))+10*eps;
                    ui.l_min(i) = squeeze(min(min(min(min(ui.fit_params(:,:,:,:,i))))))-10*eps;
                else
                    ui.l_max(i) = squeeze(max(max(max(max(ui.est_params(:,:,:,:,i))))))+10*eps;
                    ui.l_min(i) = squeeze(min(min(min(min(ui.est_params(:,:,:,:,i))))))-10*eps;
                end
            end
            if ui.disp_fit_params
                ui.l_min(end) = squeeze(min(min(min(min(ui.fit_chisq)))))-10*eps;
                ui.l_max(end) = squeeze(max(max(max(max(ui.fit_chisq)))))+10*eps;
            else
                ui.l_min(end) = squeeze(min(min(min(min(ui.data_sum)))))-10*eps;
                ui.l_max(end) = squeeze(max(max(max(max(ui.data_sum)))))+10*eps;
            end
        end
    end

    methods (Access = private)
        function resize(ui, varargin)
            % resize elements in figure to match window size
            if isfield(ui.h, 'f') % workaround for error when a loading a file
                fP = get(ui.h.f, 'Position');
                pP = get(ui.h.plotpanel, 'Position');
                pP(3:4) = [(fP(3)-pP(1))-10 (fP(4)-pP(2))-10];
                set(ui.h.plotpanel, 'Position', pP);

                aP = get(ui.h.axes, 'Position');
                aP(3:4) = [(pP(3)-aP(1))-80 (pP(4)-aP(2))-50];
                set(ui.h.axes, 'Position', aP);

                tmp = get(ui.h.d2_select, 'Position');
                tmp(2) = aP(2) + aP(4)/2;
                set(ui.h.d2_select, 'Position', tmp);
                
                tmp = get(ui.h.d1_select, 'Position');
                tmp(1) = aP(1) + aP(3)/2;
                set(ui.h.d1_select, 'Position', tmp);
                
                tmp = get(ui.h.d3_select, 'Position');
                tmp(1) = aP(1) + aP(3) + 5;
                tmp(2) = aP(2) + aP(4) - 16;
                set(ui.h.d3_select, 'Position', tmp);
                
                tmp(1) = aP(1) + aP(3) + 40;
                set(ui.h.d4_select, 'Position', tmp);
                
                tmp = get(ui.h.legend, 'position');
                tmp(3) = aP(3);
                set(ui.h.legend, 'position', tmp);

                tmp = get(ui.h.tick_max, 'position');
                tmp(1) = aP(3) + aP(1) - tmp(3);
                set(ui.h.tick_max, 'position', tmp);

                tmp = get(ui.h.plttxt, 'position');
                tmp(2) = aP(2)+aP(4)+2;
                set(ui.h.plttxt, 'position', tmp);

                tmp = get(ui.h.param, 'position');
                tmp(2) = aP(2)+aP(4)+6;
                set(ui.h.param, 'position', tmp);

                tmp = get(ui.h.fit_est, 'position');
                tmp(2) = aP(2)+aP(4) + 6;
                set(ui.h.fit_est, 'position', tmp);

                tmp = get(ui.h.zslider, 'position');
                tmp(1) = aP(1) + aP(3) + 15;
                tmp(4) = aP(4) - 50;
                set(ui.h.zslider, 'position', tmp);
                
                tmp(1) = tmp(1) + 25;
                set(ui.h.saslider, 'position', tmp);
                
                tmp = get(ui.h.zbox, 'position');
                tmp(1) = aP(1) + aP(3) + 15;
                tmp(2) = aP(1) + 20;
                set(ui.h.zbox, 'position', tmp);
                
                tmp(1) = tmp(1) + 25;
                set(ui.h.sabox, 'position', tmp);

                bP = get(ui.h.bottombar, 'Position');
                bP(3) = fP(3)+3;
                set(ui.h.bottombar, 'Position', bP);

                bP = get(ui.h.info, 'Position');
                bP(3) = fP(3);
                set(ui.h.info, 'Position', bP);

                tP = get(ui.h.tabs, 'Position');
                tP(4) = pP(4);
                set(ui.h.tabs, 'Position', tP);

                tmp = get(ui.h.ov_controls, 'Position');
                tmp(2) = tP(4) - tmp(4) - 40;
                set(ui.h.ov_controls, 'Position', tmp);
                set(ui.h.sel_controls, 'Position', tmp);
                
            end
        end

        %% Callbacks:
        function save_global_state_cb(ui, varargin)
            [name, path] = uiputfile('*.state', 'State speichern', [ui.savepath ui.genericname '.state']);
            if name == 0
                return
            end
            ui.set_savepath(path);
            
            ui_new = ui;
            save([path name], 'ui_new');
        end % save global state as .mat

        function aplot_click_cb(ui, varargin)
            cp = get(ui.h.axes, 'CurrentPoint');
            cp = round(cp(1, 1:2));
            cp(cp == 0) = 1;

            index{ui.curr_dims(1)} = cp(1); % x ->
            index{ui.curr_dims(2)} = cp(2); % y ^
            index{ui.curr_dims(3)} = ui.ind{ui.curr_dims(3)};
            index{ui.curr_dims(4)} = ui.ind{ui.curr_dims(4)};

            for i = 1:4
                if index{i} > ui.fileinfo.size(i)
                    index{i} = ui.fileinfo.size(i);
                elseif index{i} <= 0
                     index{i} = 1;
                end
            end
            switch get(ui.h.f, 'SelectionType')
                case 'normal'
                    if ~strcmp(ui.fileinfo.path, '')
                        if sum(ui.data(index{:}, :))
                            i = length(ui.plt);
                            ui.plt{i+1} = UIPlot([index{:}], ui);
                        end
                    end
                case 'alt'
                    if ~ui.disp_ov
                        ui.set_disp_ov(true);
                    end
                    if ~strcmp(ui.fileinfo.path, '')
                        if sum(ui.data(index{:}, :))
                            ui.overlays{ui.current_ov}(index{:}) = ...
                            ~ui.overlays{ui.current_ov}(index{:});
                        end
                    end
                    ui.plot_array();
            end
        end % mouseclick on plot
        
        % callback for opening a new file
        % destroys current figure and creates a new one
        function open_file_cb(ui, varargin)
            ui.loadini();
            % get path of file from user
            [name, filepath] = uigetfile({[ui.openpath '*.h5;*.diff;*.state']}, 'Dateien ausw�hlen', 'MultiSelect', 'on');
            if (~ischar(name) && ~iscell(name)) || ~ischar(filepath) % no file selected
                return
            end
            ui.openpath = filepath;
            ui.saveini()
            set(ui.h.f, 'visible', 'off');
            global debug_u
            if debug_u == true
                debug_u = UI(filepath, name, get(ui.h.f, 'position'));
            else
                UI(filepath, name, get(ui.h.f, 'position'));
            end
            close(ui.h.f);
            delete(ui);
        end
                
        function change_overlay_cond_cb(ui, varargin)
            ui.compute_ov();
            ui.plot_array();
        end
        
        function plot_group(ui, varargin)
            i = length(ui.gplt);
            ui.gplt{i+1} = UIGroupPlot(ui);
            ui.generate_sel_vals();
        end

        function save_fig(ui, varargin)
            [file, path] = uiputfile([ui.savepath filesep() ui.genericname '.pdf']);
            if ~ischar(file) || ~ischar(path) % no file selected
                return
            end
            ui.set_savepath(path);
            ui.generate_export_fig(ui.h.axes, 'off');
            tmp = get(ui.h.plot_pre, 'position');

            % save the plot and close the figure
            set(ui.h.plot_pre, 'PaperUnits', 'points');
            set(ui.h.plot_pre, 'PaperSize', [tmp(3) tmp(4)]*.8);
            set(ui.h.plot_pre, 'PaperPosition', [0 0 tmp(3) tmp(4)]*.8);
            print(ui.h.plot_pre, '-dpdf', '-r600', fullfile(path, file));
            close(ui.h.plot_pre);
        end
        
        function add_ov_cb(ui, varargin)
            ui.add_ov(ui.overlays{varargin{1}.Callback{2}});
        end
        
        function del_ov_cb(ui, varargin)
            ui.del_ov(varargin{1}.Callback{2});
        end
        
        function disp_ov_cb(ui, varargin)
            ui.set_disp_ov(varargin{1}.Value);
        end
        
        function set_current_ov_cb(ui, varargin)
            dat = varargin{2};
            ui.set_current_ov(str2double(dat.NewValue.Tag));
        end
        
        function change_par_source_cb(ui, varargin)
            t = ui.models(ui.model);  
            ov = get(varargin{2}.OldValue, 'String');
            nv = get(varargin{2}.NewValue, 'String');
            if ~strcmp(ov, nv)
                if strcmp(nv, get(ui.h.fit_par, 'string'))
                    ui.disp_fit_params = true;
                    params = [t{4}, 'Chi^2'];
                else
                    ui.disp_fit_params = false;
                    params = [t{4}, 'Summe'];
                end
                set(ui.h.param, 'visible', 'on',...
                                'string', params);
                
                ui.generate_mean();
                ui.compute_ov();
                ui.plot_array();
            end
        end
        
        function generate_export_fig_cb(ui, varargin)
            ui.generate_export_fig(ui.h.axes, 'on');
        end
        
        function set_gstart_cb(ui, varargin)
            m = ui.models(ui.model);
            tmp = zeros(size(m{2}));
            for i = 1:length(m{4});
                tmp(i) = str2double(get(ui.h.st{i}, 'string'));
                if tmp(i) < m{2}(i)
                    tmp(i) = m{2}(i);
                end
                if tmp(i) > m{3}(i)
                    tmp(i) = m{3}(i);
                end
                set(ui.h.st{i}, 'string', tmp(i))
            end
            ui.gstart = tmp;
        end % change global start point
                
        function set_param_fix_cb(ui, varargin)
            m = ui.models(ui.model);
            n = length(m{4});
            ind = 0;
            ui.fix = {};
            for i = 1:n
                if get(ui.h.fix{i}, 'value') == 1
                    ind = ind + 1;
                    if ui.use_gstart(i) ~= 1
                        set(ui.h.gst{i}, 'value', 1);
                        ui.use_gstart(i) = 1;
                    end
                    if ind == n
                        msgbox('Kann ohne freie Parameter nicht fitten.', 'Fehler', 'modal');
                        set(ui.h.fix{i}, 'value', 0);
                        return;
                    end
                    ui.fix{ind} = m{4}{i};
                end
            end
            ui.set_gstart_cb();
        end % fix parameter checkbox
        
        function set_param_glob_cb(ui, varargin)
            m = ui.models(ui.model);
            n = length(m{4});
            g = zeros(n,1);
            for i = 1:n
                if get(ui.h.gst{i}, 'value') == 1
                    g(i) = 1;
                end
            end
            ui.set_param_glob(g);
        end % global SP checkbox
        
        function set_scale_cb(ui, varargin)
            if varargin{1} == ui.h.scale_x
                ui.set_scale([str2double(get(ui.h.scale_x, 'string')), ui.scale(2)]);
            elseif varargin{1} == ui.h.scale_y
                ui.set_scale([ui.scale(1), str2double(get(ui.h.scale_y, 'string'))]);
            end
        end % scale of a pixel
       
        function set_model_cb(ui, varargin)
            t = keys(ui.models);
            str = t{get(ui.h.drpd, 'value')};
            ui.set_model(str);
        end % fitmodel from dropdown
        
        function set_cmap_cb(ui, varargin)
            cmaps = get(ui.h.colormap_drpd, 'string'); 
            ui.cmap = cmaps{get(ui.h.colormap_drpd, 'value')};
            ui.plot_array();
        end % colormap
        
        function set_bounds_cb(ui, varargin)
            m = ui.models(ui.model);
            for i = 1:length(m{4});
                m{2}(i) = str2double(get(ui.h.lb{i}, 'string'));
                m{3}(i) = str2double(get(ui.h.ub{i}, 'string'));
            end
            ui.models(ui.model) = m;
        end % update bounds
        
        function set_dim_cb(ui, varargin)
            t = str2double(get(varargin{1}, 'Tag'));
            val = get(varargin{1}, 'Value');
            oval = ui.curr_dims(t);
            % swap elements
            a = ui.curr_dims;
            a([find(a==oval) find(a==val)]) = a([find(a==val) find(a==oval)]);
            ui.curr_dims = a;
            
            hs = {ui.h.d1_select, ui.h.d2_select, ui.h.d3_select, ui.h.d4_select};
            for i = 1:4
                set(hs{i}, 'value', ui.curr_dims(i));
                if i <= 2
                    ui.ind{ui.curr_dims(i)} = ':';
                else
                    ui.ind{ui.curr_dims(i)} = 1;
                end
            end
                       
            ui.update_sliders();
            ui.plot_array();
        end
        
        function set_d3_cb(ui, varargin)
            switch varargin{1}
                case ui.h.zslider
                    val = round(get(ui.h.zslider, 'value'));
                case ui.h.zbox
                    val = round(str2double(get(ui.h.zbox, 'string')));
            end
            if val > ui.fileinfo.size(ui.curr_dims(3))
                val = ui.fileinfo.size(ui.curr_dims(3));
            elseif val <= 0
                val = 1;
            end
            
            set(ui.h.zslider, 'value', val);
            set(ui.h.zbox, 'string', num2str(val));
            ui.ind{ui.curr_dims(3)} = val;
            
            ui.plot_array();
        end
        
        function set_d4_cb(ui, varargin)
            switch varargin{1}
                case ui.h.saslider
                    val = round(get(ui.h.saslider, 'value'));
                case ui.h.sabox
                    val = round(str2double(get(ui.h.sabox, 'string')));
            end
            if val > ui.fileinfo.size(ui.curr_dims(4))
                val = ui.fileinfo.size(ui.curr_dims(4));
            elseif val <= 0
                val = 1;
            end
            
            set(ui.h.saslider, 'value', val);
            set(ui.h.sabox, 'string', num2str(val));
            ui.ind{ui.curr_dims(4)} = val;
            
            ui.plot_array();
        end
        
        function set_param_cb(ui, varargin)
            ui.current_param = get(ui.h.param, 'value');
            ui.plot_array();
        end
        
        function hold_fit_cb(ui, varargin)
            ui.hold_f = true;
        end
        
        function fit_all_cb(ui, varargin)
            if get(ui.h.parallel, 'value')
                ui.fit_all_par(1);
            else
                ui.fit_all(1);
            end
        end
        
        function resume_fit_cb(ui, varargin)
            set(ui.h.hold, 'string', 'Fit anhalten', 'callback', @ui.hold_fit_cb);
            ui.fit_all(ui.last_fitted);
        end
        
        function cancel_fit_cb(ui, varargin)
            ui.cancel_f = true;
            set(ui.h.fit, 'string', 'global Fitten', 'callback', @ui.fit_all_cb);
        end
        
        % upper and lower bound of legend
        function set_tick_cb(ui, varargin)
            switch varargin{1}
                case ui.h.tick_min
                    new_l_min = str2double(get(ui.h.tick_min, 'string'));
                    if new_l_min < ui.l_max(ui.current_param)
                        ui.l_min(ui.current_param) = new_l_min;
                        ui.use_user_legend = true;
                    elseif isempty(get(ui.h.tick_min, 'string'))
                        ui.use_user_legend = false;
                    else
                        set(ui.h.tick_min, 'string', ui.l_min(ui.current_param));
                    end
                case ui.h.tick_max
                    new_l_max = str2double(get(ui.h.tick_max, 'string'));
                    if new_l_max > ui.l_min(ui.current_param)
                        ui.l_max(ui.current_param) = new_l_max;
                        ui.use_user_legend = true;
                    elseif isempty(get(ui.h.tick_max, 'string'))
                        ui.use_user_legend = false;
                    else
                        set(ui.h.tick_max, 'string', ui.l_max(ui.current_param));
                    end
            end
            ui.plot_array();
        end
        
        function destroy_cb(ui, varargin)
            ui.destroy(false);
        end
        
        function open_versioninfo_cb(ui, varargin)
            f = figure('units', 'pixels',...
                       'numbertitle', 'off',...
                       'menubar', 'none',...
                       'name', 'SISA Scan Versioninfo',...
                       'resize', 'off',...
                       'Color', [.95, .95, .95]);
                   
            fP = f.Position;
            fP(3:4) = [500 230];
            f.Position = fP;
            uicontrol(f, 'style', 'text',...
                          'position', [20 190 480 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 15,...
                          'string', 'SiSa-Scan Auswerte-Software');
            
            uicontrol(f, 'style', 'text',...
                          'position', [20 160 480 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 11,...
                          'string', 'Autor: Sebastian Pfitzner, pfitzseb@physik');
                      
            try
                server_ver =urlread(ui.online_ver);
            catch
                server_ver = 'keine Internet-Verbindung!';
            end
            
            str = ['Aktuelle Version: lokal ' num2str(ui.version) '  -  online ' server_ver];

            uicontrol(f, 'style', 'text',...
                          'position', [20 120 460 20],...
                          'HorizontalAlignment', 'center',...
                          'FontSize', 10,...
                          'string', str);
                          
            str = {['Die aktuellsten Versionen finden sich immer auf dem Git-Server'...'
                   ' unter git.daten.tk. Dort gibt es sowohl die Binary-Releases als '...
                   'auch den Source-Code und die Readme.'], ['Alternativ sind die '...
                   'Binaries auch auf dem Share im Software-Ordner zu finden.']};
            uicontrol(f, 'style', 'text',...
                          'position', [20 20 470 80],...
                          'FontSize', 10,...
                          'HorizontalAlignment', 'left',...
                          'string', str);
              
        end
    end

    methods (Static=true)
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
                    param(2) = (t2(1) - t_zero)*cw;
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
                    param(2) = (t2(1) - t_zero)*cw;
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

% Plots `data` as an overlay over the current axis.
function plot_overlay(data)
    [m, n] = size(data);
    image = ones(m, n, 3);
    image(:, :, 1) = (image(:, :, 1) - data);
    for i = 2:3
        image(:, :, i) = (image(:, :, i) - data)*0.2;
    end
    im = imagesc(image);
    set(im, 'HitTest', 'off',...
            'AlphaData', image(:,:,1)*.4);
end

% Creates a heat map in the curren axis. Colormap is given by cmap, grid
% can be either true or false and determines whether a grid is plotted or
% not.
function hmap(data, grid, cmap)
    if nargin < 3
        cmap = 'summer';
        if nargin < 2
            grid = false;
        end
    end
    im = imagesc(data);
    set(im, 'HitTest', 'off');
    colormap(cmap);
    if grid
        [max_x, max_y] = size(data');
        hold on
        for i = 1:max_x-1
            for j = 1:max_y-1
                line([0 max_x]+.5,[j j]+.5, 'color', [.6 .6 .6], 'HitTest', 'off');
                line([i i]+.5, [0 max_y]+.5, 'color', [.6 .6 .6], 'HitTest', 'off');
            end
        end
        hold off
    end
end

% Uses calls to the underlying java-window-object to limit the size of
% figure `fig` to `minSize` (vector with two entries, min_x and min_y).
function unsafe_limit_size(fig, minSize)
    drawnow;
    jFrame = get(handle(fig), 'JavaFrame');
    jWindow = jFrame.fHG2Client.getWindow;
    tmp = java.awt.Dimension(minSize(1), minSize(2));
    jWindow.setMinimumSize(tmp);
end

% Get the dir from which this file is run. If deployed, get the location of
% the compiled *.exe.
function p = get_executable_dir()
    if isdeployed
        [~, result] = system('path');
        p = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    else
        p = fileparts(mfilename('fullpath'));
    end
end