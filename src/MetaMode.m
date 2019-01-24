classdef MetaMode < GenericMode
    %METAMODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tempdata
        intdata
        
        d_scale
        d_units
        d_names
    end
    
    methods
        function this = MetaMode(parent, tempdata, intdata)
            this.p = parent;
            this.tempdata = tempdata;
            this.intdata = intdata;
            
            this.d_scale = this.p.scale;
            this.d_units = this.p.units;
            this.d_names = {'x', 'y', 'z', 'sa'};
            
            this.h.parent = parent.h.modepanel;
            
            this.h.metamode = uitab(this.h.parent);
            
            this.h.tabs = uitabgroup(this.h.metamode);
                this.h.meta_tab = uitab(this.h.tabs);
                this.h.temp_tab = uitab(this.h.tabs);
                    this.h.plotpabel = uipanel(this.h.temp_tab);
                this.h.int_tab = uitab(this.h.tabs);
            
            set(this.h.metamode, 'title', 'Meta',...
                                 'tag', '1',...
                                 'SizeChangedFcn', @this.resize);
            
            set(this.h.tabs, 'units', 'pixels',...
                             'position', [10, 10, 500, 500]);
                         
            set(this.h.meta_tab, 'title', 'Meta');
            
            set(this.h.temp_tab, 'title', 'Temperatur');
            
            set(this.h.int_tab, 'title', 'Intensität');
            
%             this.t_plotpanel = PlotPanel(this, 1:4, {'x', 'y', 'z', 's'});
%             this.i_plotpanel = PlotPanel(this, 1:4, {'x', 'y', 'z', 's'});
            
            for i = 1:4
                this.h.d_name{i}  = uicontrol(this.h.meta_tab,...
                                              'units', 'pixels',...
                                              'style', 'edit',...
                                              'position', [10, 200-22*(i-1), 60, 20],...
                                              'callback', @this.set_d_name_cb,...
                                              'string', this.d_names{i}); 
                this.h.d_scale{i} = uicontrol(this.h.meta_tab,...
                                              'units', 'pixels',...
                                              'style', 'edit',...
                                              'position', [80, 200-22*(i-1), 60, 20],...
                                              'callback', @this.set_scale_cb,...
                                              'string', this.d_scale(i));
                this.h.d_unit{i}  = uicontrol(this.h.meta_tab,...
                                              'units', 'pixels',...
                                              'style', 'edit',...
                                              'position', [150, 200-22*(i-1), 60, 20],...
                                              'callback', @this.set_unit_cb,...
                                              'string', this.d_units(i));
            end
        end
        
        % scale of a pixel
        function set_scale_cb(this, varargin)
            if varargin{1} == this.h.scale_x
                this.set_scale([str2double(get(this.h.scale_x, 'string')), this.p.scale(2)]);
            elseif varargin{1} == this.h.scale_y
                this.set_scale([this.p.scale(1), str2double(get(this.h.scale_y, 'string'))]);
            end
        end 
        
        function set_unit_cb(this, varargin)
            
        end
        
        function set_d_name_cb(this, varargin)
            
        end
        
        function resize(this, varargin)
            
        end
        
        function destroy(this, children_only)
            if ~children_only
                delete(this.h.metamode)
                delete(this);
            end
        end
    end
    
end

