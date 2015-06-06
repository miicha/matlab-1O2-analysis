classdef InvivoPlot < SiSaPlot
    %INVIVOPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        evo_data;
        first_call = 1;
    end
    
    methods
        function this = InvivoPlot(point, imode)
            this = this@SiSaPlot(point, imode);
            location = imode.locations(point(2));
            
%             title(location)
            
            this.evo_data = squeeze(imode.evo_data(point(1), point(2), point(3), point(4),:));
            
            this.h.inset = axes();

            this.plotdata();
            
            basename = this.h.f.Name;
            
            this.h.f.Name = [basename ' - ' location{1}];
            
            set(this.h.inset, 'units', 'pixels',...
                              'position', [700 500 200 100],...
                              'xtick', [], 'ytick', []);
                          
            set(this.h.f, 'ResizeFcn', @this.resize);
            this.resize();
        end
        
        function plotdata(this, realtime)
            if nargin < 2
                realtime = false;
            end

            plotdata@SiSaPlot(this, realtime);
            
            if this.first_call
                this.first_call = 0;
                return
            end
            if ~realtime
                uistack(this.h.inset, 'top');
            end
            axes(this.h.inset)
            plot(this.evo_data); 
            xlim([1 length(this.evo_data)]);
            
            set(this.h.inset, 'xtick', [], 'ytick', []);
            title(this.h.inset, 'Verlauf', 'FontWeight', 'normal');
        end
    end

    methods (Access = protected)
        function resize(this, varargin)
            resize@SiSaPlot(this);
            
            iP = get(this.h.inset, 'Position');
            aP = get(this.h.axes, 'Position');
            
            iP(1:2) = aP(1:2)+aP(3:4)-iP(3:4) - 40;
            
            set(this.h.inset, 'Position', iP);
        end
    end
    
end

