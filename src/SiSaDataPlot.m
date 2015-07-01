classdef SiSaDataPlot < SiSaGenericPlot
    %SiSaPlot
    
    properties
%         res;        
%         cfit;
%         fit_info = true; % should probably be false?
    end
    
    methods
        function this = SiSaDataPlot(data, smode)    
            this = this@SiSaGenericPlot(smode);  
            
            this.data = data;
            
            name = [smode.p.fileinfo.name{1} ' - SiSaPlot'];
            
            this.set_window_name(name);
            this.plotdata();
        end
    end
end