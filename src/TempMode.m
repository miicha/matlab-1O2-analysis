classdef TempMode
    %TEMPMODE
    % Platzhalter. Macht was draus! :)
    
    properties
        p;
        data;
        l_min = 0; % maximum of the current parameter over all data points
        l_max = 1; % minimum of the current parameter over all data points
        use_user_legend = false;
        
        h = struct();
    end
    
    methods
        function this = TempMode(parent, data)
            this.p = parent;
            data(data == 0) = nan;
            this.data = data;
            
            this.h.parent = parent.h.modepanel;
            
            this.h.tempmode = uitab(this.h.parent);
                             
            this.h.plotpanel = uipanel(this.h.tempmode);
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
                
                
            set(this.h.tempmode, 'title', 'Temperatur',...
                                 'tag', '3');
                             
            set(this.h.parent, 'SizeChangedFcn', @this.resize);
            %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [5 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
            
            set(this.h.axes, 'units', 'pixels',...
                           'position', [40 60 380 390],...
                           'Color', get(this.h.plotpanel, 'BackgroundColor'),...
                           'xtick', [], 'ytick', [],...
                           'XColor', get(this.h.plotpanel, 'BackgroundColor'),...
                           'YColor', get(this.h.plotpanel, 'BackgroundColor'));
                       
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

            this.resize();
            this.plot_array();
        end
        
        function destroy(this, children_only)
            % needs to be implemented
        end
        
        function save_fig(this)
            % needs to be implemented
        end
        
        function plot_array(this)
            axes(this.h.axes);
            hmap(this.data(:, :, 1, 1));
            if ~this.use_user_legend
                this.l_min = min(min(min(min(this.data))));
                this.l_max = max(max(max(max(this.data))));
            end
            
            tickmin = this.l_min;
            tickmax = this.l_max;

            caxis([tickmin tickmax])

            set(this.p.h.f, 'CurrentAxes', this.h.legend);
            l_data = tickmin:(tickmax-tickmin)/20:tickmax;
            cla
            hold on
            hmap(l_data, false);
            hold off
            xlim([.5 length(l_data)+.5])
            set(this.h.legend, 'visible', 'on');
            set(this.h.tick_min, 'visible', 'on', 'string', num2str(l_data(1),4));
            set(this.h.tick_max, 'visible', 'on', 'string', num2str(l_data(end),4));
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
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
        
        % upper and lower bound of legend
        function set_tick_cb(this, varargin)
            this
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
            this.plot_array();
        end
        
    end
    
end

