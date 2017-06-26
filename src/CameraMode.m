classdef CameraMode < GenericMode
    %CAMERAMODE
    % Platzhalter. Macht was draus! :)
    properties
        spec_pos = 1;
        num_pictures;
        current_spec_point = 1;
        wavelengths;
        bg_data;
        current_draggable;
        histo_start;
        histo_end;
        current_index = {'','','',''};
    end
    
    methods
        function this = CameraMode(parent, data, int_time, tag)
            
            if isnan(data)
                warning('Keine Kamera-Daten vorhanden')
            else
                if nargin < 3
                    int_time = 100;
                end                

                this.p = parent;
                
                this.num_pictures = size(data, 3);
                
                for i = 1:this.num_pictures
                    for j = 1:size(data, 4)
                        tmp(:,:,i,j) = data(:,:,i,j)';
                    end
                end
                data = tmp;
                clear tmp;
                    
                this.data = data;    
                this.scale = this.p.scale;
                this.units = this.p.units;

                this.scale(4) = int_time/1000;
                this.units{4} = 't [s]';
                this.units{5} = 'nm';

                this.h.parent = parent.h.modepanel;

                this.h.cameramode = uitab(this.h.parent);
                
                this.h.evalpanel = uipanel(this.h.cameramode);
                    this.h.colorpanel = uipanel(this.h.evalpanel);
                        this.h.chose_cmap_button = uicontrol(this.h.colorpanel);
                        this.h.histogr_axes = axes('parent', this.h.colorpanel);
                    this.h.removeBackground = uicontrol(this.h.evalpanel);
                    this.h.restoreBackground = uicontrol(this.h.evalpanel);

                this.h.plotpanel = uipanel(this.h.cameramode);

                set(this.h.cameramode, 'title', 'Camera',...
                                'tag', num2str(tag),...
                                'SizeChangedFcn', @this.resize);

                %% Plot
                
                set(this.h.evalpanel, 'units', 'pixels',...
                                    'position', [10 5 250 550],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7],...
                                    'BackgroundColor', [.85 .85 .85]);
                                
                set(this.h.colorpanel, 'units', 'pixels',...
                            'position', [3 290 244 300]);
                        
                    set(this.h.histogr_axes, 'units', 'pixels',...
                               'position', [5 82 233 175]);
                               this.h.histogr_axes.YAxis.Visible = 'off';

                    set(this.h.chose_cmap_button, 'units', 'pixels',...
                               'style', 'popupmenu',...
                               'string', {'summer','jet','parula','bone','hot'},...
                               'value', 1,...
                               'position', [15 270 214 15],...
                               'callback', @this.set_cmap_cb,...
                               'BackgroundColor', [1 1 1],...
                               'FontSize', 9);
                                
                set(this.h.removeBackground,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 2 120 28],...
                           'string', 'Set and remove Background',...
                           'callback', @this.setBG);
                       
                set(this.h.restoreBackground,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 35 120 28],...
                           'string', 'Restore Background',...
                           'callback', @this.restoreBG_cb);
                
                set(this.h.plotpanel, 'units', 'pixels',...
                                    'position', [270 5 500 500],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7],...
                                    'BackgroundColor', [.85 .85 .85]);

                this.plotpanel = CameraPanel(this, size(data), this.h.plotpanel);
                this.resize();
                this.plot_array();
            end
        end
        
        function save_fig(this, varargin)
            np = this.plotpanel.save_fig([this.p.savepath filesep() this.p.genericname...
                                          '_Fluo_lambda=' num2str(this.current_spec_point) '.pdf']);
            this.p.set_savepath(np);
        end
                
        function plot_array(this)
            this.plotpanel.plot_array(this.get_data, 'a');
            this.plot_histogram();
            this.plot_histo_slider();
            
            this.current_index = this.plotpanel.ind;
        end
        
        function left_click_on_axes(this, point)
            point
            this.data(point{1:4})
        end
        
        function right_click_on_axes(this, point)
            % nothing yet. Do something about that! :)
        end
        
        function show_plot(this, plot_data)
            
                if ~this.plotpanel.transpose
                    plot_data = plot_data';
                end
%                 figure(1235)
                hmap(plot_data);
                colorbar
                
                s = size(plot_data);
                xlim([.5 s(2)+.5])
                ylim([.5 s(1)+.5])
                
                ca = gca;
                
                % ToDo warum muss das horizontal gespiegelt werden und wie
                % geht das??? so:            
                ca.YDir = 'normal';
                % aus irgendeinem grund ist das fuer das plotpanel schon
                % auf 'normal' gesetzt, aber nicht explizit -- konnte auf
                % die schnelle jetzt auch keinen grund dafuer finden
                
                ca.XTickLabel = this.plotpanel.ticklabels{this.plotpanel.curr_dims(1)};
                ca.YTickLabel = this.plotpanel.ticklabels{this.plotpanel.curr_dims(2)};
                ca.XTick = this.plotpanel.tickvalues{this.plotpanel.curr_dims(1)};
                ca.YTick = this.plotpanel.tickvalues{this.plotpanel.curr_dims(2)};
        end
        
    end
    
    methods (Access = private)
        
        function plot_histogram(this)
            vergl = zeros(length(this.plotpanel.ind),1);
            for i = 1:length(this.plotpanel.ind)
                if this.plotpanel.ind{i} == this.current_index{i}
                    vergl(i) = 1;
                end
            end
            
            if sum(vergl) ~= 4
                clear this.h.histogr
                this.h.histogr = histogram(this.h.histogr_axes,this.data(this.plotpanel.ind{:}));
%                             this.h.histogr.Parent.XTick = [];
                this.h.histogr.Parent.YTick = [];
                if isfield(this.h, 'startline')
                    this.h = rmfield(this.h, 'startline');
                    this.h = rmfield(this.h, 'endline');
                end
            end 
        end
        
        function plot_histo_slider(this)
            if ~isfield(this.h, 'startline')
                min_max = this.h.histogr.BinLimits;
                hist_cutoff = 0.05;
                if isempty(this.histo_start)
                    start_line = min_max(1) + (min_max(2)-min_max(1))*hist_cutoff;
                else
                    start_line = this.histo_start;
                end
                
                if isempty(this.histo_end)
                    end_line = min_max(2)-(min_max(2)-min_max(1))*hist_cutoff;
                else
                    end_line = this.histo_end;
                end
                
                realmax = max(this.h.histogr.Values);
                this.h.endline = line(this.h.histogr_axes,[end_line end_line],...
                    [0 realmax], 'Color', [0.8 .2 .2], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.5,...
                    'LineStyle', '-.', 'Tag', 'line');
                this.h.startline = line(this.h.histogr_axes,[start_line start_line],...
                    [0 realmax], 'Color', [0.8 .2 .2], 'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.5,...
                    'LineStyle', '-.', 'Tag', 'line');
            end
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            this.h.plotpanel.Position = pP;
            
            eP = this.h.evalpanel.Position;
            eP(4) = (mP(4)-eP(2))-10;
            this.h.evalpanel.Position = eP;
            
            cP = this.h.colorpanel.Position;
            cP(2) = (eP(4)-cP(4))-3;
            this.h.colorpanel.Position = cP;
        end
        
        function setBG(this,varargin)
            % Background aus aktueller Ansicht übernehmen, abspeichern und
            % in this.data von allen Daten abziehen.
            this.restoreBG();
            
            this.bg_data = this.get_current_data();
            this.data = this.data-this.bg_data;
            this.plot_array();
        end
        
        function restoreBG(this)
            if ~isempty(this.bg_data)
                this.data = this.data+this.bg_data;
            end
        end
        
        function data = get_data(this)
            data = this.data(:, :, :, :, :);
        end
        
        function data = get_current_data(this)
            data = this.data(this.plotpanel.ind{:});
        end
        
        
        function plot_click(this, varargin)
            switch varargin{1}
                case this.h.startline
                    set(gcf, 'WindowButtonMotionFcn', @this.plot_drag_start);
                    set(gcf, 'WindowButtonUpFcn', @this.stop_dragging);
                case this.h.endline
%                     get(this.p)
                    set(gcf, 'WindowButtonMotionFcn', @this.plot_drag_end);
                    set(gcf, 'WindowButtonUpFcn', @this.stop_dragging);
            end
        end
        
        function plot_drag_start(this, varargin)
            this.current_draggable = 'start';
            cpoint = get(this.h.histogr_axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);

            this.h.startline.XData = [cpoint cpoint];
            
            y_max = max(this.h.histogr.Values(this.h.histogr.BinEdges(1:end-1) > cpoint));
            y_max = y_max + y_max*0.1;
            this.h.histogr_axes.YLim = [0 y_max];
            
            this.histo_start = cpoint;
            
            this.plotpanel.h.tick_min.String = num2str(this.h.startline.XData(1));
            this.plotpanel.set_tick_cb(this.plotpanel.h.tick_min);
            
        end
        
        
        function plot_drag_end(this, varargin)
            this.current_draggable = 'end';
            cpoint = get(this.h.histogr_axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            this.h.endline.XData = [cpoint cpoint];
            
            this.histo_end = cpoint;
            
            this.plotpanel.h.tick_max.String = num2str(this.h.endline.XData(1));
            this.plotpanel.set_tick_cb(this.plotpanel.h.tick_max);
            
        end
        
        function stop_dragging(this, varargin)
            set(gcf, 'WindowButtonMotionFcn', '');
            set(gcf, 'WindowButtonUpFcn', '');
            this.adjust_histo_x();
        end
        
        function adjust_histo_x(this)
            over = 0.2;
            min_max = this.h.histogr_axes.XLim;
            
            if ~isempty(this.histo_start) && ~isempty(this.histo_end)
                min_max(1) = this.histo_start - (this.histo_end - this.histo_start)*over;
                min_max(2) = this.histo_end + (this.histo_end - this.histo_start)*over;
                this.h.histogr_axes.XLim =min_max;
            end
        end
            
        
        function restoreBG_cb(this, varargin)
            this.restoreBG();
            this.plot_array();
        end
        
        function set_cmap_cb(this,varargin)
            drpdwn = varargin{1};
            this.plotpanel.cmap = drpdwn.String{drpdwn.Value};
            this.plot_array();
            
        end
    end
end
