classdef TempMode < GenericMode
    %TEMPMODE
    % Platzhalter. Macht was draus! :)
    
    methods
        function this = TempMode(parent, data)
            this.p = parent;
            data(data == 0) = nan;
            this.data = data;
            
            this.h.parent = parent.h.modepanel;
            
            this.h.tempmode = uitab(this.h.parent);
                             
            this.h.plotpanel = uipanel(this.h.tempmode);
            
            set(this.h.tempmode, 'title', 'Temperatur',...
                                 'tag', '3');
                             
            %% Plot
            set(this.h.plotpanel, 'units', 'pixels',...
                                'position', [5 5 500 500],...
                                'bordertype', 'line',...
                                'highlightcolor', [.7 .7 .7],...
                                'BackgroundColor', [.85 .85 .85]);
            


            this.plotpanel = PlotPanel(this);

            this.resize();
            this.plot_array();
        end
                
        function save_fig(this, varargin)
            [file, path] = uiputfile([this.p.savepath filesep() this.p.genericname...
                                     '_Temp.pdf']);
            if ~ischar(file) || ~ischar(path) % no file selected
                return
            end
            this.p.set_savepath(path);
            f = this.plotpanel.generate_export_fig('off');
            tmp = get(f, 'position');

            % save the plot and close the figure
            set(f, 'PaperUnits', 'points');
            set(f, 'PaperSize', [tmp(3) tmp(4)]*.8);
            set(f, 'PaperPosition', [0 0 tmp(3) tmp(4)]*.8);
            print(f, '-dpdf', '-r600', fullfile(path, file));
            close(f);
        end     
        
        function plot_array(this)
            this.plotpanel.plot_array(this.data);
        end
        
        function right_click_on_axes(this, point)
        end
        
        function left_click_on_axes(this, point)
        end
        
        function resize(this, varargin)
            mP = get(this.h.parent, 'position');
            mP(4) = mP(4) - 25;
            
            pP = get(this.h.plotpanel, 'Position');
            pP(3:4) = [(mP(3)-pP(1))-10 (mP(4)-pP(2))-10];
            set(this.h.plotpanel, 'Position', pP);
        end
    end
end

