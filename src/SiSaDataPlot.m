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
            
            name = [smode.p.fileinfo.name{1} ' - Sum over ' num2str(smode.sum_number) ' - SiSaPlot'];
            this.set_window_name(name);
            
            this.est_params = this.sisa_fit.estimate(this.data);
            this.generate_param();
            this.plotdata();
        end
    end
end