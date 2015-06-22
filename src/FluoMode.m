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
        function this = FluoMode(parent, data, wavelengths)
            this.p = parent;
            this.data = data;
            this.num_spec_points = size(data, 5);
            this.wavelengths = wavelengths;
            
            this.h.parent = parent.h.modepanel;
            
            this.h.fluomode = uitab(this.h.parent);
            
            this.h.plotpanel = uipanel(this.h.fluomode);
                this.h.specslider = uicontrol(this.h.plotpanel);
                this.h.specbox = uicontrol(this.h.plotpanel);
            
            set(this.h.fluomode, 'title', 'Fluoreszenz',...
                                 'tag', '2');
                        
            %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [5 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
            
            set(this.h.specslider, 'units', 'pixels',...
                                   'style', 'slider',...
                                   'value', 1,...
                                   'min', 1,...
                                   'max', this.num_spec_points,...
                                   'SliderStep', [1 20]./this.num_spec_points,...
                                   'position', [40, 500, 500, 20],...
                                   'BackgroundColor', [1 1 1],...
                                   'callback', @this.spec_cb);
                               
            set(this.h.specbox, 'units', 'pixels',...
                                'style', 'edit',...
                                'position', [510, 500, 65, 20],...
                                'string', 1,...
                                'BackgroundColor', [1 1 1],...
                                'callback', @this.spec_cb);

                            
            this.plotpanel = PlotPanel(this, size(data(:,:,:,:,1)));
            this.resize();
            this.plot_array();
        end
        
        function save_fig(this, varargin)
            np = this.plotpanel.save_fig([this.p.savepath filesep() this.p.genericname...
                                          '_Fluo_lambda=' num2str(this.current_spec_point) '.pdf']);
            this.p.set_savepath(np);
        end
                
        function plot_array(this)
            this.plotpanel.plot_array(this.data(:, :, :, :, this.current_spec_point), 'a');
        end
        
        function left_click_on_axes(this, point)
            figure;
            plot(this.wavelengths,squeeze(this.data(point{1:4}, :)))
            title(num2str(cell2mat(point)))
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);
            
            tmp = get(this.h.specslider, 'Position');
            tmp(2) = pP(4) - 30;
            tmp(3) = pP(3) - 120;
            set(this.h.specslider, 'Position', tmp);
            
            tmp = get(this.h.specbox, 'Position');
            tmp(1) = pP(3) - 76;
            tmp(2) = pP(4) - 30;
            set(this.h.specbox, 'Position', tmp);
        end
        
        function spec_cb(this, varargin)
            switch varargin{1}
                case this.h.specslider
                    val = round(get(this.h.specslider, 'value'));
                case this.h.specbox
                    temp = str2double(get(this.h.specbox, 'string'));
                    [~,val] = min(abs(this.wavelengths-temp));
            end

            if val > this.num_spec_points
                val = this.num_spec_points;
            elseif val <= 0
                val = 1;
            end

            if isnan(val)
                set(this.h.specslider, 'value', this.current_spec_point);
                set(this.h.specbox, 'string', num2str(this.current_spec_point));
                return
            end
            
            set(this.h.specslider, 'value', val);
            set(this.h.specbox, 'string', num2str(this.wavelengths(val)));
            this.current_spec_point = val;

            this.plot_array();
        end
        
        function data = get_data(this)
            data = this.data(:, :, :, :, this.current_spec_point);
        end
    end
end
