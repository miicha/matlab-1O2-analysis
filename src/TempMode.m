classdef TempMode
    %TEMPMODE
    % Platzhalter. Macht was draus! :)
    
    properties
        p;
        data;
        l_min = 0; % maximum of the current parameter over all data points
        l_max = 1; % minimum of the current parameter over all data points
        use_user_legend = false;
        curr_dims = [1, 2, 3, 4];
        
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
            
            this.h.pp = PlotPanel(this);

            set(this.h.tempmode, 'title', 'Temperatur',...
                                 'tag', '3');
                             
            set(this.h.parent, 'SizeChangedFcn', @this.resize);
            %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [5 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
            


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
            this
            this.h.pp.plot_array(this.data);
        end
        
        function right_click_on_axes(this, point)
        end
        
        function left_click_on_axes(this, point)
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);
        end
    end
end

