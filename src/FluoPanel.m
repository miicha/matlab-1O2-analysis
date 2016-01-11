classdef FluoPanel < PlotPanel

    methods
        function this = FluoPanel(parent, dims, gui_parent)
            dimnames = {'x', 'y', 'z', 's', 'l'};
            this@PlotPanel(parent, dims, dimnames, gui_parent, dimnames ,{[], [], [], [], []});       
        end
        
    end
    
    methods (Access = protected)      
        function set_nth_val_cb(this, caller, varargin)
            dim = str2double(caller.Tag);
            if strcmp(this.dimnames{this.curr_dims(dim)}, 'l')
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
            else
                set_nth_val_cb@PlotPanel(this, caller, varargin{:})
            end
        end
            
    end
    
end

