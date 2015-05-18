classdef PlotPanel < handle
    %PLOTPANEL
    % parent class _must_ implement 
    %  - plot_array()
    %  - left_click_on_axes()
    %  - right_click_on_axes()
    %  - get_figure()
    %
    % methods
    %   plot_array(data, overlay_data)
    %   handle = generate_export_fig(visibility)
    %   newpath = save_fig(path)
    
    properties
        p;     % parent
        cmap = 'summer';
        
        dims;
        curr_dims = [1, 2, 3, 4];
        ind = {':', ':', 1, 1};
        dimnames = {'x', 'y', 'z', 's'};
        transpose = false;
        
        l_min; % maximum of the current parameter over all data points
        l_max; % minimum of the current parameter over all data points
        use_user_legend = false;
        
        first_call = true;
        
        h = struct();
    end
    
    methods
        function this = PlotPanel(parent)
            this.p = parent;
            this.h.parent = parent.h.plotpanel;
            
            this.dims = parent.p.fileinfo.size;
            
            this.h.plotpanel = uipanel(this.h.parent);
                this.h.axes = axes('parent', this.h.plotpanel);
                this.h.legend = axes('parent', this.h.plotpanel);
                this.h.tick_min = uicontrol(this.h.plotpanel);
                this.h.tick_max = uicontrol(this.h.plotpanel);
                this.h.plttxt = uicontrol(this.h.plotpanel);
                this.h.zslider = uicontrol(this.h.plotpanel);
                this.h.zbox = uicontrol(this.h.plotpanel);
                this.h.saslider = uicontrol(this.h.plotpanel);
                this.h.sabox = uicontrol(this.h.plotpanel);
                
                this.h.d1_select = uicontrol(this.h.plotpanel);
                this.h.d2_select = uicontrol(this.h.plotpanel);
                this.h.d3_select = uicontrol(this.h.plotpanel);
                this.h.d4_select = uicontrol(this.h.plotpanel);
                
            set(this.h.parent, 'SizeChangedFcn', @this.resize);
                
            set(this.h.plotpanel, 'units', 'pixels',...
                                  'position', [5 5 500 500],...
                                  'BackgroundColor', get(this.h.parent, 'BackgroundColor'),...
                                  'bordertype', 'none');
            
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
                          
            set(this.h.d1_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.dimnames,...
                                'value', 1,...
                                'tag', '1',...
                                'visible', 'off',...
                                'callback', @this.set_dim_cb,...
                                'position', [385 40 30 17],...
                                'BackgroundColor', [1 1 1]);
                            
            set(this.h.d2_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.dimnames,...
                                'value', 2,...
                                'visible', 'off',...
                                'tag', '2',...
                                'callback', @this.set_dim_cb,...
                                'position', [5 300 30 17],...
                                'BackgroundColor', [1 1 1]);


            set(this.h.d3_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.dimnames,...
                                'value', 3,...
                                'visible', 'off',...
                                'tag', '3',...
                                'callback', @this.set_dim_cb,...
                                'position', [465 520 30 17],...
                                'BackgroundColor', [1 1 1]);

                            
            set(this.h.d4_select, 'units', 'pixels',...
                                'style', 'popupmenu',...
                                'string', this.dimnames,...
                                'value', 4,...
                                'visible', 'off',...
                                'tag', '4',...
                                'callback', @this.set_dim_cb,...
                                'position', [505 520 30 17],...
                                'BackgroundColor', [1 1 1]);
        end
        
        function plot_array(this, data, ov_data)
            if nargin < 3 || isempty(ov_data)
                disp_ov = false;
            else
                disp_ov  = true;
            end
                       
            plot_data = squeeze(data(this.ind{:}));
            
            if this.first_call
                this.update_dims(size(data));
                this.first_call = false;
            end
            
            this.transpose = this.get_transpose(size(data, this.curr_dims(1)),...
                                                size(data, this.curr_dims(2)),...
                                                size(plot_data));
            
            % squeeze does strange things: (1x3x1)-array -> (3x1)-array
            if this.transpose
                plot_data = plot_data';
                if disp_ov
                    ov_data = squeeze(ov_data(this.ind{:}))';
                end
            else
                if disp_ov
                    ov_data = squeeze(ov_data(this.ind{:}));
                end
            end
            if ~this.use_user_legend
                [this.l_min, this.l_max] = this.calculate_legend(data);
            end
            tickmin = this.l_min;
            tickmax = this.l_max;
            
            % plotting:
            % Memo to self: Don't try using HeatMaps... seriously.
            if gcf == this.p.get_figure()  % don't plot when figure is in background
                set(this.p.get_figure(), 'CurrentAxes', this.h.axes); 
                cla
                hold on
                hmap(plot_data', false, this.cmap);
                if disp_ov
                    plot_overlay(ov_data');
                end
                hold off
                s = size(plot_data');
                xlim([.5 s(2)+.5])
                ylim([.5 s(1)+.5])

                if tickmin < tickmax
                    caxis([tickmin tickmax])
                    
                    set(this.p.get_figure(), 'CurrentAxes', this.h.legend);
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
        
        function fighandle = generate_export_fig(this, vis)
            x = size(this.p.data, this.curr_dims(1));
            y = size(this.p.data, this.curr_dims(2));

            if x > y
                d = x;
            else
                d = y;
            end

            scale_pix = 800/d;  % max width or height of the axes
            scl = this.p.p.scale./max(this.p.p.scale);
            
            x_pix = x*scale_pix*scl(1);
            y_pix = y*scale_pix*scl(2);
            
            tmp = get(this.h.axes, 'position');

            if isfield(this.h, 'plot_pre') && ishandle(this.h.plot_pre)
                figure(this.h.plot_pre);
                clf();
            else
                this.h.plot_pre = figure('visible', vis);
            end
            screensize = get(0, 'ScreenSize');
            windowpos = [screensize(3)-(x_pix+150) screensize(4)-(y_pix+150)  x_pix+100 y_pix+100];
            set(this.h.plot_pre, 'units', 'pixels',...
                   'position', windowpos,...
                   'numbertitle', 'off',...
                   'name', 'SISA Scan Vorschau',...
                   'menubar', 'none',...
                   'resize', 'off',...
                   'Color', [.95, .95, .95]);

            ax = copyobj(this.h.axes, this.h.plot_pre);
            set(ax, 'position', [tmp(1)+22 tmp(2) x_pix y_pix],...
                    'XColor', 'black',...
                    'YColor', 'black');
            xlabel([this.dimnames{this.curr_dims(1)} ' [mm]'])
            ylabel([this.dimnames{this.curr_dims(2)} ' [mm]'])
            
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
            
            x_tick_label = num2cell((0:x_label_res:x-1)*this.p.p.scale(1));
            y_tick_label = num2cell((0:y_label_res:y-1)*this.p.p.scale(2));
            
            set(ax, 'xtick', x_tick, 'ytick', y_tick,...
                    'xticklabel', x_tick_label,...
                    'yticklabel', y_tick_label);

            caxis([this.l_min this.l_max]);
            colormap(this.cmap);
            c = colorbar();
            set(c, 'units', 'pixels');
            tmp2 = get(c, 'position');
            tmp2(1) = tmp(1)+x_pix+35;
            set(c, 'position', tmp2);
            if tmp2(1) + tmp2(3) > windowpos(3)
                windowpos(3) = windowpos(3) + tmp2(3) + 20;
                set(this.h.plot_pre, 'position', windowpos);
            end
            fighandle = this.h.plot_pre;
        end
        
        function newpath = save_fig(this, path)
            [newpath, ~, ~] = fileparts(path);
            [file, path] = uiputfile(path);
            if ~ischar(file) || ~ischar(path) % no file selected
                return
            end
            newpath = path;
            f = this.generate_export_fig('off');
            tmp = get(f, 'position');

            % save the plot and close the figure
            set(f, 'PaperUnits', 'points');
            set(f, 'PaperSize', [tmp(3) tmp(4)]*.8);
            set(f, 'PaperPosition', [0 0 tmp(3) tmp(4)]*.8);
            print(f, '-dpdf', '-r600', fullfile(path, file));
            close(f);
        end
        
        function slice = get_slice(this)
            slice = this.ind;
        end
    end
    
    methods (Access = private)       
        function transp = get_transpose(this, sx, sy, sn)
            sxn = sn(1);
            syn = sn(2);
            transp = (sxn ~= sx || syn ~= sy) ||...
                     (sx > 1 && sy > 1 && this.curr_dims(1) > this.curr_dims(2));
        end
        
        function update_plot(this)
            this.p.plot_array();
        end
        
        function aplot_click_cb(this, varargin)
            cp = get(this.h.axes, 'CurrentPoint');
            cp = round(cp(1, 1:2));
            cp(cp == 0) = 1;

            index{this.curr_dims(1)} = cp(1); % x ->
            index{this.curr_dims(2)} = cp(2); % y ^
            index{this.curr_dims(3)} = this.ind{this.curr_dims(3)};
            index{this.curr_dims(4)} = this.ind{this.curr_dims(4)};

            for i = 1:4
                if index{i} > this.dims(i)
                    index{i} = this.dims(i);
                elseif index{i} <= 0
                     index{i} = 1;
                end
            end
            switch get(this.p.get_figure(), 'SelectionType')
                case 'normal'
                    this.p.left_click_on_axes(index);
                case 'alt'
                    this.p.right_click_on_axes(index);
            end
        end 
        
        function set_transpose(this)
            if this.curr_dims(1) > this.curr_dims(2)
                this.transpose = true;
            else 
                this.transpose = false;
            end
        end
        
        function update_dims(this, dims)
            dims = padarray(dims(:), 4-length(dims), 1, 'post');
            this.dims = dims;
            this.update_sliders();
        end
        
        function [tickmin, tickmax] = calculate_legend(this, data)
            tickmin = min(min(min(min(data))));
            tickmax = max(max(max(max(data))));
        end
        
        function update_sliders(this)
            s = this.dims;

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
        
        % change dimension on x/y/z/sa-axes
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
            this.update_plot();
        end
        
        % slider for 3rd dimension
        function set_d3_cb(this, varargin)
            switch varargin{1}
                case this.h.zslider
                    val = round(get(this.h.zslider, 'value'));
                case this.h.zbox
                    val = round(str2double(get(this.h.zbox, 'string')));
            end
            if val > this.dims(this.curr_dims(3))
                val = this.dims(this.curr_dims(3));
            elseif val <= 0
                val = 1;
            end
            
            if isnan(val)   
                set(this.h.zslider, 'value', this.ind{this.curr_dims(3)});
                set(this.h.zbox, 'string', num2str(this.ind{this.curr_dims(3)}));
                return
            end
            set(this.h.zslider, 'value', val);
            set(this.h.zbox, 'string', num2str(val));
            this.ind{this.curr_dims(3)} = val;
            
            this.update_plot();
        end
        
        % slider for fourth dimension
        function set_d4_cb(this, varargin)
            switch varargin{1}
                case this.h.saslider
                    val = round(get(this.h.saslider, 'value'));
                case this.h.sabox
                    val = round(str2double(get(this.h.sabox, 'string')));
            end
            if val > this.dims(this.curr_dims(4))
                val = this.dims(this.curr_dims(4));
            elseif val <= 0
                val = 1;
            end
            if isnan(val)   
                set(this.h.saslider, 'value', this.ind{this.curr_dims(4)});
                set(this.h.sabox, 'string', num2str(this.ind{this.curr_dims(4)}));
                return
            end
            set(this.h.saslider, 'value', val);
            set(this.h.sabox, 'string', num2str(val));
            this.ind{this.curr_dims(4)} = val;
            
            this.update_plot();
        end
     
        % upper and lower bound of legend
        function set_tick_cb(this, varargin)
            switch varargin{1}
                case this.h.tick_min
                    new_l_min = str2double(get(this.h.tick_min, 'string'));
                    if new_l_min < this.l_max
                        this.l_min = new_l_min;
                        this.use_user_legend = true;
                    elseif isempty(get(this.h.tick_min, 'string'))
                        this.use_user_legend = false;
                    else
                        set(this.h.tick_min, 'string', this.l_min);
                    end
                case this.h.tick_max
                    new_l_max = str2double(get(this.h.tick_max, 'string'));
                    if new_l_max > this.l_min
                        this.l_max = new_l_max;
                        this.use_user_legend = true;
                    elseif isempty(get(this.h.tick_max, 'string'))
                        this.use_user_legend = false;
                    else
                        set(this.h.tick_max, 'string', this.l_max);
                    end
            end
            this.update_plot();
        end
                
        function resize(this, varargin)
            mP = get(this.h.parent, 'Position');
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1)) (mP(4)-pP(2))-35];
            set(this.h.plotpanel, 'Position', pP);

            aP = get(this.h.axes, 'Position');
            aP(3:4) = [(pP(3)-aP(1))-80 (pP(4)-aP(2))-5];
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
        end
    end
    
end

