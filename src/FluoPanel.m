classdef FluoPanel < PlotPanel

    methods
        function this = FluoPanel(parent, dims)
            dimnames = {'x', 'y', 'z', 's', 'l'};
            this@PlotPanel(parent, dims, dimnames);
            
            this.h.d5_slider.Callback = @this.set_wl_cb;
            this.h.d5_edit.Callback = @this.set_wl_cb;          
        end
        
        function set_wl_cb(this, caller, varargin)
            dim = 5;
            switch caller.Style
                case 'slider'
                    value = round(caller.Value);
                case 'edit' 
                    value = round(str2double(caller.String));
                    [~, value] = min(abs(this.p.wavelengths - value));
            end
            
            value = this.set_nth_val(dim, value);
            
            this.h.(sprintf('d%d_edit', dim)).String = sprintf('%.1f', this.p.wavelengths(value));
            this.h.(sprintf('d%d_slider', dim)).Value = value;
        end
    end
    
end

