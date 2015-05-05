classdef GenericMode < handle
    %MODE
    
    properties
        p;              % parent
        
        plotpanel;      % PlotPanel
        data;           % data
        l_min = 0;      % maximum of the current parameter over all data points
        l_max = 1;      % minimum of the current parameter over all data points
        use_user_legend = false;
        
        h = struct();    % handles to GUI objects
    end
    
    methods
        function destroy(this, children_only)
            % needs to be implemented
        end
        
        function save_fig(this)
            % needs to be implemented
        end
        
        function f = get_figure(this)
            f = this.p.h.f;
        end
    end
    
end

