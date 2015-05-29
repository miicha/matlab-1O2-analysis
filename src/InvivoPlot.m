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
            this.evo_data = imode.evo_data(point);
            
            this.h.inset = axes();

            this.plotdata();
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
%             this.inset = axes();

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

