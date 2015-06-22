classdef InvivoMode < SiSaMode
    %INVIVOMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        locations;
        evo_data;
    end
    
    methods
        function this = InvivoMode(parent, data, evo_data, int_time, reader)
            this@SiSaMode(parent, data);
            if reader.meta.sisa.Optik == 1270
                set(this.h.sisamode, 'background', [0.8 0.2 0.2]);
            else
                set(this.h.sisamode, 'background', [0.2 0.2 0.8]);
            end

            this.scale(4) = int_time;
            this.units{4} = 's';
            
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
        
        function read_channel_width(this)
            % read Channel Width
            
            try
                chanWidth=h5read(fullfile(this.p.fileinfo.path, this.p.fileinfo.name{1}), '/Meta/sisa/Parameter');
                
                this.channel_width=single(chanWidth.Kanalbreite);
            catch
                % nothing. just an old file.
            end
        end
        
    end
    
end

