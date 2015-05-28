classdef InvivoMode < SiSaMode
    %INVIVOMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        locations;
    end
    
    methods
        function this = InvivoMode(parent, data, reader)
            this@SiSaMode(parent, data);
            set(this.h.sisamode, 'title', 'in-vivo');
            
            this.locations = reader.meta.locations;
        end
    end
    
end

