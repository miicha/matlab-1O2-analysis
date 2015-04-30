classdef TempMode
    %TEMPMODE
    % Platzhalter. Macht was draus! :)
    
    properties
        p;
        data;
        
        h = struct();
    end
    
    methods
        function this = TempMode(parent, data)
            this.p = parent;
            this.data = data;
            
            this.h.parent = parent.h.modepanel;
            
            this.h.tempmode = uitab(this.h.parent);
            
            set(this.h.tempmode, 'title', 'Temperatur');
        end
    end
    
end

