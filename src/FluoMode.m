classdef FluoMode < GenericMode
    %FLUOMODE
    % Platzhalter. Macht was draus! :)
    properties
        spec_pos = 1;
        num_spec_points;
        current_spec_point = 1;
        wavelengths;
        scale;
        units;
    end
    
    methods
        function this = FluoMode(parent, data, wavelengths, int_time)
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
            
            this.h.plotpanel = uipanel(this.h.fluomode);
            
            set(this.h.fluomode, 'title', 'Fluoreszenz',...
                                 'tag', '2');
                        
            %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [5 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
                            
            this.plotpanel = FluoPanel(this, size(data));
            this.resize();
            this.plot_array();
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
            SinglePlot(this.wavelengths, squeeze(this.data(point{1:4}, :)),...
                       fullfile(this.p.savepath, this.p.genericname),...
                       'title', num2str(cell2mat(point)));
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

        function data = get_data(this)
            data = this.data(:, :, :, :, :);
        end
    end
end
