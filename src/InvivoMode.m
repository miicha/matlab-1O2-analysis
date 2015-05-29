classdef InvivoMode < SiSaMode
    %INVIVOMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        locations;
        
        evo_data;
    end
    
    methods
        function this = InvivoMode(parent, data, evo_data, reader)
            this@SiSaMode(parent, data);
            
            this.evo_data = evo_data;
                       
            set(this.h.sisamode, 'title', 'in-vivo');
            
            this.locations = reader.meta.locations;
        end
        
        function left_click_on_axes(this, index)
            if ~strcmp(this.p.fileinfo.path, '')
                if sum(this.data(index{:}, :))
                    i = length(this.plt);
                    this.plt{i+1} = InvivoPlot([index{:}], this);
                end
            end
        end
    end
    
end

