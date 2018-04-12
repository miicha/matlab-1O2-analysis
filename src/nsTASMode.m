classdef nsTASMode < GenericMode
    %PSTASMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x_data;
        y_err;
    end
    
    methods
        function this = nsTASMode(parent, data, x_data, y_err)
            this.p = parent;
            this.data = data;
            this.x_data = x_data;
            this.y_err = y_err;
            
            this.h.parent = parent.h.modepanel;
            
            this.h.nsTASMode = uitab(this.h.parent);
            
            this.h.plotpanel = uipanel(this.h.nsTASMode);
                this.h.plttxt = uicontrol(this.h.plotpanel);
                this.h.param = uicontrol(this.h.plotpanel);
                this.h.fit_est = uibuttongroup(this.h.plotpanel);
                    this.h.fit_par = uicontrol();
                    this.h.est_par = uicontrol();
            
            set(this.h.nsTASMode, 'title', 'nsTAS',...
                                 'tag', '1',...
                                 'SizeChangedFcn', @this.resize);
            
            %% Plot
                set(this.h.plotpanel, 'units', 'pixels',...
                                    'position', [5 5 500 500],...
                                    'bordertype', 'line',...
                                    'highlightcolor', [.7 .7 .7],...
                                    'BackgroundColor', [.85 .85 .85]);

                this.plotpanel = nsTASPanel(this, size(data), this.h.plotpanel);
                this.resize();
                this.plot_array();
            
            
        end
        
        function click_on_axes_cb(this, point, button, shift, ctrl, alt)
            if sum(squeeze(this.data(point{1:4}, :))) ~= 0 && button == 1
                nsTASPlot(squeeze(this.x_data(point{1:4}, :)), squeeze(this.data(point{1:4}, :)), squeeze(this.y_err(point{1:4}, :)),...
                           fullfile(this.p.savepath, this.p.genericname),...
                           'title', num2str(cell2mat(point)));
            end
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);
        end
        
        function plot_array(this)
            this.plotpanel.plot_array(this.data(:, :, :, :, :), 'a');
        end
        
    end
end

