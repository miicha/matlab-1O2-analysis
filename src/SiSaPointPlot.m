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
            
            this.h.set_startvalues = uicontrol(this.h.fit_tab);
            this.h.set_fitvalues = uicontrol(this.h.fit_tab);
            
            set(this.h.set_startvalues, 'units', 'pixels',...
                          'position', [225 35 80 28],...
                          'string', 'copy as start',...
                          'FontSize', 9,...
                          'callback', @this.cb_set_startvalues);
            
            set(this.h.set_fitvalues, 'units', 'pixels',...
                          'position', [225 5 80 28],...
                          'string', 'set as fitted',...
                          'FontSize', 9,...
                          'callback', @this.cb_set_fitvalues);

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

            this.getdata(name);
            
            this.est_params = squeeze(this.smode.est_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
%             this.sisa_fit.estimate(this.data);
            this.generate_param();
            
             
            if length(smode.p.fileinfo.name) > 1
                name = smode.p.fileinfo.name{this.cp(1)};
            else
                name = [smode.p.fileinfo.name{1} ' - ' num2str(name')];
            end
            
            this.set_window_name(name);
            this.plotdata();
            
            par_names = this.sisa_fit.parnames;
            for i = 1:this.sisa_fit.par_num
                set(this.h.pc{i}, 'Value', ismember(par_names(i), this.smode.fix));
                if this.smode.use_gstart(i) == 1 && this.smode.fitted == 0
                    this.h.pe{i}.String = num2str(this.smode.gstart(i));
                end
            end
        end
        
        function getdata(this, pointname)
            
            this.chisq = 0;
            this.data = squeeze(this.smode.data(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
            if this.fitted
                this.chisq =  squeeze(this.smode.fit_chisq(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                this.fit_params = squeeze(this.smode.fit_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                this.fit_params_err = squeeze(this.smode.fit_params_err(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                this.sisa_esti = squeeze(this.smode.sisa_esti(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :));
                try
                    pointname = pointname'+[1 1 0 0];
                    this.fluo_val = this.smode.p.modes{1}.get_mean_value(pointname,720);
                    tmp{1} = this.sisa_esti;
                    tmp{2} = this.fluo_val;
                    tmp{3} = this.sisa_esti/this.fluo_val
                end
            end
        end
        
        function cb_set_startvalues(this, varargin)
            this.set_point_values(true)
        end
        
        function cb_set_fitvalues(this, varargin)
            this.set_point_values(false)
        end
        
        function set_point_values(this,estimates)    % estimates: true --> set as start values otherwise as fit result
            if this.sisa_fit.curr_fitfun ~= this.smode.sisa_fit.curr_fitfun || ...
                    this.smode.sisa_fit.t_0 ~= this.sisa_fit.t_0
                this.smode.sisa_fit.t_0 = this.sisa_fit.t_0;
                this.smode.set_model(this.sisa_fit.curr_fitfun);
            end
            
            if this.fitted
                if estimates
                    this.smode.est_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :) = this.fit_params;
                else
                    this.smode.fit_params(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :) = this.fit_params;
                    this.smode.fit_params_err(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :) = this.fit_params_err;
                    this.smode.fit_chisq(this.cp(1), this.cp(2), this.cp(3), this.cp(4), :) = this.chisq;
                end
                this.smode.plot_array();
            end
        end
        
    end
end