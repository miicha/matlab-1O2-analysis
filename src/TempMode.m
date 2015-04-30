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
            
            set(this.h.tempmode, 'title', 'Temperatur',...
                                 'tag', '3');
        end
        
        function destroy(this, children_only)
            % needs to be implemented
        end
        
        function save_fig(this)
            % needs to be implemented
        end
    end
    
end

