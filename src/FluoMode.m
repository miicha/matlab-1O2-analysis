classdef FluoMode
    %FLUOMODE
    % Platzhalter. Macht was draus! :)
    properties
        p;
        data;
        
        h = struct();
    end
    
    methods
        function this = FluoMode(parent, data)
            this.p = parent;
            this.data = data;
            
            this.h.parent = parent.h.modepanel;
            
            this.h.fluomode = uitab(this.h.parent);
            
            set(this.h.fluomode, 'title', 'Fluoreszenz');
            
            
        end
    end
    
end

