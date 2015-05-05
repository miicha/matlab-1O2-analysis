classdef FluoMode < GenericMode
    %FLUOMODE
    % Platzhalter. Macht was draus! :)
    
    methods
        function this = FluoMode(parent, data)
            this.p = parent;
            this.data = data;
            
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
            


            this.plotpanel = PlotPanel(this);

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
            this.plotpanel.plot_array(sum(this.data, 5));
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

