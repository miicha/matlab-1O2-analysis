classdef CameraMode < GenericMode
    %CAMERAMODE
    % Platzhalter. Macht was draus! :)
    properties
        spec_pos = 1;
        num_pictures;
        current_spec_point = 1;
        wavelengths;
        bg_data;
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
                        this.h.jRangeSlider = com.jidesoft.swing.RangeSlider(0,14000,6000,12500);  % min,max,low,high
                        this.h.jRangeSlider = javacomponent(this.h.jRangeSlider, [0,0,242,40], this.h.colorpanel);
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
                            'position', [3 290 244 260]);
                        
                    set(this.h.histogr_axes, 'units', 'pixels',...
                               'position', [5 42 233 175]);
                               this.h.histogr_axes.YAxis.Visible = 'off';

                    set(this.h.chose_cmap_button, 'units', 'pixels',...
                               'style', 'popupmenu',...
                               'string', {'summer','jet','parula','bone','hot'},...
                               'value', 1,...
                               'position', [15 230 214 15],...
                               'callback', @this.set_cmap_cb,...
                               'BackgroundColor', [1 1 1],...
                               'FontSize', 9);
                           
                    set(this.h.jRangeSlider, 'MajorTickSpacing',25, 'MinorTickSpacing',5,...
                               'PaintTicks',true, 'PaintLabels',true, ...
                               'Background',java.awt.Color.white,...
                               'StateChangedCallback',@this.histo_slider_cb);
                                
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
        end
        
        function plot_histogram(this)
            this.h.histogr = histogram(this.h.histogr_axes,this.data(this.plotpanel.ind{:}));
            this.h.histogr.Parent.XTick = [];
            this.h.histogr.Parent.YTick = [];
            min_max = this.h.histogr.BinLimits;
            
            this.h.jRangeSlider.LabelTable = [];    % wichtig damit Labels automatisch neu berechnet werden
            majTick = round((min_max(2)-min_max(1))/5);
            this.h.jRangeSlider.MajorTickSpacing = majTick;
            this.h.jRangeSlider.MinorTickSpacing = majTick/2;
            if min_max(2) > 100
                this.h.histogr.Parent.XLim = min_max;
                this.h.jRangeSlider.Maximum = min_max(2);
            end
%             this.h.jRangeSlider.HighValue = min_max(2);
        end
        
        function left_click_on_axes(this, point)
            point
            this.data(point{1:4})
        end
        
        function set_cmap_cb(this,varargin)
            drpdwn = varargin{1};
            this.plotpanel.cmap = drpdwn.String{drpdwn.Value};
            this.plot_array();
            
        end
        
        function right_click_on_axes(this, point)
            % nothing yet. Do something about that! :)
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
        
        function show_diff_cb(this, varargin)
            if this.plotpanel.h.d5_select.Value == 5
               
                [ind1, ind2] = acquire_WLs(this, varargin);
                
                plot_data = squeeze(this.data(ind1{:}))-squeeze(this.data(ind2{:}));
                
                figure(1234)
                show_plot(this, plot_data)
            end
        end
        
        function show_quot_cb(this, varargin)
            if this.plotpanel.h.d5_select.Value == 5

                [ind1, ind2] = acquire_WLs(this, varargin);
                
                plot_data = squeeze(this.data(ind1{:}))./squeeze(this.data(ind2{:}));
                
                figure(1235)
                show_plot(this, plot_data)
            end
        end
        
        function [ind1, ind2] = acquire_WLs(this, varargin)
            wl2_index = find(this.wavelengths >= str2double(this.h.wl2.String)-0.1,1,'first');
                
            ind1 = this.plotpanel.ind;
            ind2 = ind1;
            ind2{5} = wl2_index;
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

        function data = get_data(this)
            data = this.data(:, :, :, :, :);
        end
        
        function histo_slider_cb(this, varargin)
            werte = get(get(varargin{2}, 'Source'));
            [werte.LowValue werte.HighValue];
            
            max_y = max(this.h.histogr.BinCounts(this.h.histogr.BinEdges(1:end-1) > werte.LowValue));
            if isempty(max_y)
                max_y = 20;
            end
%             get(this.h.histogr)
%             pause(0.1);
            this.plotpanel.h.tick_min.String = num2str(werte.LowValue);
            this.plotpanel.set_tick_cb(this.plotpanel.h.tick_min);
            
            this.plotpanel.h.tick_max.String = num2str(werte.HighValue);
            this.plotpanel.set_tick_cb(this.plotpanel.h.tick_max);
            
            this.h.histogr.Parent.YLim = [0 max_y];
        end
    end
    
    methods (Access = private)
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
        
        function data = get_current_data(this)
            data = this.data(this.plotpanel.ind{:});
        end
        
        function restoreBG_cb(this, varargin)
            this.restoreBG();
            this.plot_array();
        end
    end
end
