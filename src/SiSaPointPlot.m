classdef SiSaPointPlot < SiSaGenericPlot
    %SiSaPlot
    
    properties
%         res;        
%         cfit;
%         fit_info = true; % should probably be false?
    end
    
    methods
        function this = SiSaPointPlot(point, smode)    
            this = this@SiSaGenericPlot(smode);

            %% get data from main UI
            
            this.cp = point;
            if ~isnan(this.smode.fit_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4)))
                this.fitted = true;
            end
            
            try
                name = squeeze(this.smode.reader.data.sisa_point_name(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
            catch
                name = point;
            end
            
            this.getdata();
            
            this.est_params = this.sisa_fit.estimate(this.data);
            this.generate_param();
            
             
            if length(smode.p.fileinfo.name) > 1
                name = smode.p.fileinfo.name{this.cp(1)};
            else
                name = [smode.p.fileinfo.name{1} ' - ' num2str(name')];
            end
            
            this.set_window_name(name);
            this.plotdata();
        end
        
        function getdata(this, ~)
            this.chisq = 0;
            this.data = squeeze(this.smode.data(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
            if this.fitted
                this.chisq =  squeeze(this.smode.fit_chisq(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                this.fit_params = squeeze(this.smode.fit_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                this.fit_params_err = squeeze(this.smode.fit_params_err(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
            end
        end
    end
end