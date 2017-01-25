classdef FluoMode < GenericMode
    %FLUOMODE
    % Platzhalter. Macht was draus! :)
    properties
        spec_pos = 1;
        num_spec_points;
        current_spec_point = 1;
        wavelengths;
    end
    
    methods
        function this = FluoMode(parent, data, wavelengths, int_time, tag)
            
            if isnan(data)
                warning('Keine Fluodaten vorhanden')
            else
                if nargin < 3
                    wavelengths = 1:size(data, 5);
                    int_time = 100;
                end                

                this.p = parent;
                this.data = data;
                this.num_spec_points = size(data, 5);
                this.wavelengths = wavelengths;

                this.scale = this.p.scale;
                this.units = this.p.units;

                this.scale(4) = int_time/1000;
                this.units{4} = 't [s]';
                this.units{5} = 'nm';

                this.h.parent = parent.h.modepanel;

                this.h.fluomode = uitab(this.h.parent);
                
                this.h.evalpanel = uipanel(this.h.fluomode);
                this.h.diffbutton = uicontrol(this.h.evalpanel);
                this.h.wl2 = uicontrol(this.h.evalpanel);

                this.h.plotpanel = uipanel(this.h.fluomode);

                set(this.h.fluomode, 'title', 'Fluoreszenz',...
                                     'tag', num2str(tag));

                %% Plot
                
                set(this.h.evalpanel, 'units', 'pixels',...
                                    'position', [10 5 250 550],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7],...
                                    'BackgroundColor', [.85 .85 .85]);
                                
                set(this.h.diffbutton,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [2 2 80 28],...
                           'string', 'Differenz anzeigen',...
                           'callback', @this.show_diff_cb);
                       
               set(this.h.wl2, 'units', 'pixels',...
                                  'position', [40 145 50 15],...
                                  'style', 'edit',...
                                  'string', '666',...
                                  'horizontalAlignment', 'left');
                
                set(this.h.plotpanel, 'units', 'pixels',...
                                    'position', [270 5 500 500],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7],...
                                    'BackgroundColor', [.85 .85 .85]);

                this.plotpanel = FluoPanel(this, size(data), this.h.plotpanel);
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
            this.plotpanel.plot_array(this.data(:, :, :, :, :), 'a');
        end
        
        function left_click_on_axes(this, point)
            if sum(squeeze(this.data(point{1:4}, :))) > 0
                SinglePlot(this.wavelengths, squeeze(this.data(point{1:4}, :)), [],...
                           fullfile(this.p.savepath, this.p.genericname),...
                           'title', num2str(cell2mat(point)));
            end
        end
        
        function right_click_on_axes(this, point)
            % nothing yet. Do something about that! :)
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);
        end
        
        function show_diff_cb(this, varargin)
            if this.plotpanel.h.d5_select.Value == 5
                wl2_index = find(this.wavelengths >= str2double(this.h.wl2.String)-0.1,1,'first');
                
                ind1 = this.plotpanel.ind;
                ind2 = ind1;
                ind2{5} = wl2_index;
                
                plot_data = squeeze(this.data(ind1{:}))-squeeze(this.data(ind2{:}));
                if ~this.plotpanel.transpose
                    plot_data = plot_data';
                end
                figure(1234)
                hmap(plot_data);
                
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

        function data = get_data(this)
            data = this.data(:, :, :, :, :);
        end
    end
end
