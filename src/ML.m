classdef ML < handle
    
    properties
        kinetik_start = 88;
        g_start = 200;
        b_start = 880;
        b_end = 4095;
        cw = 0.02;
        np = 66;
        
        fsize = 12;
        
        h = struct();        % handles
        
        sisa_data;
        sisa_point_names;
        current_draggable
        kinetik_real_start
        g_real_start
        b_real_start
        
        max_short
        short_name
        max_long
        long_name
        short_color = [0.19 0.76 0.41];
        long_color = [0.05 0.32 0.95];
        
        shown_points;
        reader;
        filename;
        dbconfig;
        fileinfo;
        UI_obj;
        window_pos = false;
        single_channels = false;
        
    end
    
    methods
        % create new instance with basic controls
        function this = ML(filename, pos, reader, dbconfig, fileinfo, ui)
            this.kinetik_start = pos(1);
            this.np = pos(2);
            this.h.figure = figure;
            this.window_pos = [0 50 560 960];
            if nargin == 6
                this.UI_obj = ui;
                if this.UI_obj.hyper_pos
                    this.h.figure.Position = ui.hyper_pos;
                    this.window_pos = ui.hyper_pos;
                end
            end
            this.h.figure.Position = this.window_pos;
            this.h.figure.DeleteFcn = @this.close;
            
            cmap = colormap('lines');
            this.short_color = cmap(2,:);
            this.long_color = cmap(5,:);
            
            this.h.save_figures = uicontrol(this.h.figure);
            
            this.h.update_points = uicontrol(this.h.figure);
            
            this.h.show_channels = uicontrol(this.h.figure);
            
            set(this.h.save_figures,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [40 2 140 28],...
                           'string', 'Bilder Speichern',...
                           'callback', @this.save_figures);
                       
            set(this.h.update_points,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [200 2 140 28],...
                           'string', 'Update PointInfo',...
                           'callback', @this.update_points);
                       
            set(this.h.show_channels,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [360 2 140 28],...
                           'string', 'Show Channels',...
                           'callback', @this.show_channels_cb);
                       
            if nargin<3
                this.reader = HDF5_reader(filename);
                this.reader.readfluo = false;
                this.reader.read_data;
            else
                this.reader = reader;
            end
            if nargin<4
                this.dbconfig = struct();
            else
                this.dbconfig = dbconfig;
            end
            if nargin<5
                this.fileinfo = struct();
            else
                this.fileinfo = fileinfo;
            end
            
            this.filename = filename;
            
            this.prepare_data();
            
            this.h.map = subplot(2,2,1);
            
            this.h.ml = subplot(2,2,2);
            
            this.h.kinetik = subplot(2,2,3);
            
            this.h.ml2 = subplot(2,2,4);
            
            [~,r,g,b] = this.calc_rgb();
            this.calc_points(r,g,b);
            this.show_image();
            set(this.h.map,'ButtonDownFcn', @this.aplot_click_cb);

            this.show_kinetic();
            
            this.show_ml();
        end
        
        function close(this, varargin)
            if isfield(this.h, 'channels') && isvalid(this.h.channels)
                close(this.h.channels);
            end
            this.UI_obj.hyper_pos = this.h.figure.Position;
        end
    end
    
    methods (Access = private)
        function prepare_data(this,varargin)
            this.cw = this.reader.meta.sisa.Kanalbreite;
            this.kinetik_real_start = (this.kinetik_start-this.np)*this.cw;
            this.g_real_start = (this.g_start-this.np)*this.cw;
            this.b_real_start = (this.b_start-this.np)*this.cw;
            [tmp,tmp2] = this.reader.get_sisa_data();
            this.sisa_point_names = squeeze(tmp2(:,:,1,1,:));
            this.sisa_data = squeeze(tmp(:,:,1,1,:));
        end
        
        function show_ml(this,varargin)
            if nargin > 1
                ax = varargin{1};
            else
                ax = this.h.ml;
                ax2 = this.h.ml2;
            end
            axes(ax);
            
            
            try
                CompactMdl = loadCompactModel('mySVM');
            catch
                disp('CompactModel liegt nicht im src ordner bzw. heißt nicht "mySVM.mat"...');
                return
            end
            
            s_size = size(this.sisa_data);
            
            tmp = reshape(this.sisa_data, s_size(1)*s_size(2),s_size(3));
            
            dataNames = cellstr("data" + [1:4095]);
            test_tab = array2table(tmp, 'VariableNames',dataNames);
            
            
            rot = [0.8 0.2 0.2];
            gr = [0.2 0.8 0.2];
            blau = [0.2 0.2 0.8];
            backgr = [0.1 0.1 0.1];
            

            [result, score] = predict(CompactMdl,test_tab);
            
            result = categorical(result,[1,2,3,4], {'background', 'art','ven','tumor'});
            
            clor = nan(length(result),3);
            for i = 1:3
                clor(result=='art',i) = gr(i);
                clor(result=='ven',i) = rot(i);
                clor(result=='tumor',i) = blau(i);
                clor(result=='background',i) = backgr(i);
            end  
            
            clor = reshape(clor, s_size(1), s_size(2),3);
            
            clor = this.zurechtdrehen(clor);
            tmp = imshow(clor,'InitialMagnification',3000, 'Parent', ax);
            
            result = reshape(result, s_size(1), s_size(2));
            result = this.zurechtdrehen(result);
            
            clor3 = this.calc_rgb();
            clor = labeloverlay(clor3,result);
            axes(ax2);
            tmp = imshow(clor,'InitialMagnification',3000, 'Parent', ax2);
            
            
        end
        
        function show_kinetic(this,varargin)
            if nargin > 1
                ax = varargin{1};
            else
                ax = this.h.kinetik;
            end
            if nargin == 3 && strcmp(varargin{2}, 'export')
                showlegend = false;
            else
                showlegend = true;
            end
            
            axes(ax);
            if length(size(this.sisa_data)) == 3
                tmp = flipud(permute(this.sisa_data,[2,1,3]));
                kin = squeeze(tmp(this.max_short(2),this.max_short(1),:));          
                kin2 = squeeze(tmp(this.max_long(2),this.max_long(1),:));
            else
                kin = this.sisa_data(this.max_short(1),:);
                kin2 = this.sisa_data(this.max_long(1),:);
            end
            
            
            x_achse = 1:length(kin);
            x_achse = (x_achse-this.np)*this.cw;

            alpha = 0.1;
            
            plot_max1 = max(kin(this.kinetik_start+10:end));
            plot_max2 = max(kin2(this.kinetik_start+10:end));
            
            if plot_max1 > plot_max2
                plot_max = plot_max1*1.1;
            else
                plot_max = plot_max2*1.1;
            end
            
            x = [this.kinetik_real_start this.g_real_start];
            y = [plot_max plot_max];
            this.h.red_area = area(ax,x,y,'FaceColor','red');
            this.h.red_area.FaceAlpha = alpha;
            this.h.red_area.EdgeColor = 'none';
            
            if showlegend
                legend();
            end
            
            hold on
            
            x = [this.g_real_start this.b_real_start];
            this.h.green_area = area(ax,x,y,'FaceColor','green');
            this.h.green_area.FaceAlpha = alpha;
            this.h.green_area.EdgeColor = 'none';
            
            x = [this.b_real_start max(x_achse)];
            this.h.blue_area = area(ax,x,y,'FaceColor','blue');
            this.h.blue_area.FaceAlpha = alpha;
            this.h.blue_area.EdgeColor = 'none';
            
            short_line = plot(ax,x_achse, kin, 'color', this.short_color);
            this.h.axes = gca;

            long_line = plot(x_achse, kin2, 'color', this.long_color);
            hold off
            
            this.h.left = line([this.g_real_start this.g_real_start], [0 realmax], 'Color', [.7 0 .5],... 
                      'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2, 'LineStyle', '--',...
                      'Tag', 'line');
            
            this.h.right = line([this.b_real_start this.b_real_start], [0 realmax], 'Color', [.7 0 .5],... 
                      'ButtonDownFcn', @this.plot_click, 'LineWidth', 1.2, 'LineStyle', '--',...
                      'Tag', 'line');
                  
            hold off

            this.h.left.Color = 'none';
            this.h.left.PickableParts = 'all';
            
            this.h.right.Color = 'none';
            this.h.right.PickableParts = 'all';
            
            ylabel('# counts')
            xlabel('time [\mus]')

            ylim([0 plot_max])
            xlim([-0.5 floor(x_achse(end)/10)*10])
            
            
            ax.FontSize = this.fsize;
            
            if showlegend
                legend([short_line long_line],{num2str(this.short_name),num2str(this.long_name)})
            end

%             legend({num2str(this.short_name),num2str(this.long_name)})
            
        end
        
        function save_figures(this,varargin)
            fsize = 10;
            width = 0.40;
            
            f1 = figure; % Open a new figure with handle f1
            ax1 = axes; % subplot(2,1,1);
            this.show_image(ax1, 'export');
            figdim = save2pdf(strrep(this.filename,'.h5','-map.pdf'),'figure',f1,'tight', true, 'keepAscpect', true, 'width', width, 'texi', true, 'fontsize',fsize, 'aspectratio', 2/2, 'removeClipping', true);
            f1.delete()

            f2 = figure;
            ax2 = axes; % subplot(2,1,2);
            this.show_kinetic(ax2, 'export');  
            ax2.Box = 'off';
            ax2.TickDir = 'out';
            save2pdf(strrep(this.filename,'.h5','-kin.pdf'),'figure',f2,'tight', true, 'fixsize', figdim, 'texi', true, 'fontsize',fsize);
            f2.delete()
        end
        
        function [clor,r,g,b] = calc_rgb(this,varargin)
            if length(size(this.sisa_data)) < 3
                r = sum(this.sisa_data(:,this.kinetik_start:this.g_start-1),2);
                g = sum(this.sisa_data(:,this.g_start:this.b_start-1),2);
                b = sum(this.sisa_data(:,this.b_start:this.b_end),2);
            else
                r = sum(this.sisa_data(:,:,this.kinetik_start:this.g_start-1),3);
                g = sum(this.sisa_data(:,:,this.g_start:this.b_start-1),3);
                b = sum(this.sisa_data(:,:,this.b_start:this.b_end),3);
            end
            
            clor(:,:,1) = r/max(r(:));
            clor(:,:,2) = g/max(g(:));
            clor(:,:,3) = b/max(b(:));

            clor = this.zurechtdrehen(clor);
            
            r = squeeze(clor(:,:,1));
            g = squeeze(clor(:,:,2));
            b = squeeze(clor(:,:,3));
        end
        
        function data = zurechtdrehen(this,input)
            data = permute(input,[2 1 3]);
            data = flipud(data);
        end
        
        function calc_points(this,r,g,b)
            [~, pos1] = max(g(:));
            
            [~, pos2] = max(b(:));
            
            [I,J] = ind2sub(size(r), pos1);
            this.max_short = [J, I];
%             this.max_short = [J-1, I-0];
            [I,J] = ind2sub(size(r), pos2);
            this.max_long = [J,I];
            [~,this.long_name] = this.get_current_point(this.max_long);
            [~,this.short_name] = this.get_current_point(this.max_short);
        end
        
        function show_image(this, varargin)
            if nargin > 1
                ax = varargin{1};
            else
                ax = this.h.map;
            end
            if nargin == 3 && strcmp(varargin{2}, 'export')
                showscale = true;
                showother = false;
            else
                showscale = false;
                showother = true;
            end
            if ~this.single_channels
                showother = false;
            end
            
            clor = this.calc_rgb();
            
            
%             hold on
            
            
            tmp = imshow(clor,'InitialMagnification',3000, 'Parent', ax);
            
            
%             title('Summe')
            patch1points = [this.max_short(1)-0.5, this.max_short(1)-0.5, this.max_short(1)+0.5, this.max_short(1)+0.5];
            patch2points = [this.max_short(2)-0.5, this.max_short(2)+0.5, this.max_short(2)+0.5, this.max_short(2)-0.5];
            patch3points = [this.max_long(1)-0.5, this.max_long(1)-0.5, this.max_long(1)+0.5, this.max_long(1)+0.5];
            patch4points = [this.max_long(2)-0.5, this.max_long(2)+0.5, this.max_long(2)+0.5, this.max_long(2)-0.5];
            
            posA1 = this.max_short(1)+0.8;
            posA2 = this.max_short(2)-1.1;
            posB1 = this.max_long(1)+0.8;
            posB2 = this.max_long(2)-1.1;
            
            if showscale
                scale = this.reader.meta.sisaScale(1:2); 
                patch1points = patch1points*scale(1);
                patch2points = patch2points*scale(1);
                posA1 = posA1 * scale(1);
                posA2 = posA2 * scale(2);
                patch3points = patch3points*scale(1);
                patch4points = patch4points*scale(1);
                posB1 = posB1 * scale(1);
                posB2 = posB2 * scale(2);
            end
            
            p1 = patch(ax,patch1points,patch2points, this.short_color);
            p1.EdgeColor = this.short_color;
            p1.LineWidth = 1.5;
            p1.FaceColor = 'none';
            
            t1 = text(ax,posA1,posA2, 'A');
            t1.Color = this.short_color;
            t1.FontSize = this.fsize;
            
            
            
            p2 = patch(ax,patch3points,patch4points, this.long_color);
            p2.EdgeColor = this.long_color;
            p2.LineWidth = p1.LineWidth;
            p2.FaceColor = 'none';
            
            t2 = text(ax,posB1,posB2, 'B');
            t2.Color = this.long_color;
            t2.FontSize = this.fsize;
            
            if showscale
                axis on
                XDataInMM = get(tmp,'XData')*scale(1);
                YDataInMM = get(tmp,'YData')*scale(2);

                set(tmp,'XData',XDataInMM,'YData',YDataInMM);    
                set(gca,'XLim',[XDataInMM(1)-scale(1)/2 XDataInMM(2)+scale(1)/2],'YLim',[YDataInMM(1)-scale(2)/2 YDataInMM(2)+scale(2)/2]);
                set(gca,'ytick',[])
                box off
                set(gca,'YColor','none','TickDir','out')
                xlabel('distance [mm]')
%                 ylabel('distance [mm]')
            end

%             subplot(2,2,2)
%             imshow(clor2,'InitialMagnification',3000)
%             title('Mittelwert')
            
%             hold off
            set(tmp,'ButtonDownFcn', @this.aplot_click_cb);
            
            if showother
                r = clor;
                g = clor;
                b = clor;
                r(:,:,2:3) = 0;
                g(:,:,1) = 0;
                g(:,:,3) = 0;
                b(:,:,1:2) = 0;

                this.h.channels = figure(421);
                ax_r = subplot(2,2,1);
                imshow(r,'InitialMagnification',3000, 'Parent',ax_r);
                ax_g = subplot(2,2,2);
                imshow(g,'InitialMagnification',3000, 'Parent',ax_g);
                ax_b = subplot(2,2,3);
                imshow(b,'InitialMagnification',3000, 'Parent',ax_b);
                ax_rgb = subplot(2,2,4);
                this.show_kinetic(ax_rgb)
    %             imshow(clor,'InitialMagnification',3000, 'Parent',ax_rgb);
            end
        end
        
        function plot_click(this, varargin)
            switch varargin{1}
                case this.h.left
                    set(this.h.figure, 'WindowButtonMotionFcn', @this.drag_left);
                    set(this.h.figure, 'WindowButtonUpFcn', @this.stop_dragging);
                case this.h.right
                    set(this.h.figure, 'WindowButtonMotionFcn', @this.drag_right);
                    set(this.h.figure, 'WindowButtonUpFcn', @this.stop_dragging);
            end
        end
        
        function drag_left(this,varargin)
            this.current_draggable = 'left';
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            this.g_real_start = cpoint;
            this.h.left.XData = [cpoint cpoint];
            
            this.h.red_area.XData(2) = cpoint;
            this.h.green_area.XData(1) = cpoint;
        end
        
        function drag_right(this,varargin)
            this.current_draggable = 'right';
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
            this.b_real_start = cpoint;
            this.h.right.XData = [cpoint cpoint];
            
            this.h.green_area.XData(2) = cpoint;
            this.h.blue_area.XData(1) = cpoint;
        end
        
        function stop_dragging(this, varargin)
            if strcmp(this.current_draggable, 'left')
                cpoint = get(this.h.axes, 'CurrentPoint');
                cpoint(1, 1)
                this.g_start = round(cpoint(1, 1)/this.cw+this.np);
            end
            
            if strcmp(this.current_draggable, 'right')
                cpoint = get(this.h.axes, 'CurrentPoint');
                cpoint(1, 1)
                this.b_start = round(cpoint(1, 1)/this.cw+this.np);
            end
                
            
            this.current_draggable = 'none';
            set(this.h.figure, 'WindowButtonMotionFcn', '');
            set(this.h.figure, 'WindowButtonUpFcn', '');
            this.show_image();
            this.show_kinetic();
        end
        
        function aplot_click_cb(this, varargin)
            [index, name] = this.get_current_point();
            modifiers = this.h.figure.CurrentModifier;
            wasShiftPressed = ismember('shift',   modifiers);  % true/false
%             wasCtrlPressed  = ismember('control', modifiers);  % true/false
%             wasAltPressed   = ismember('alt',     modifiers);  % true/false
            
            mouseButton = varargin{2}.Button;
            
            % shift-leftclick:
            if mouseButton == 1
                this.max_short = index;
                this.short_name = name;
            elseif mouseButton == 3 % other
                this.max_long = index;
                this.long_name = name;
            end
            this.show_image();
            this.show_kinetic();
        end
        
        function show_channels_cb(this,varargin)
            this.single_channels = true;
            this.show_image();
        end
        
        function [index, name] = get_current_point(this,varargin)
            if nargin == 1
                cp = get(this.h.map, 'CurrentPoint');
                cp = round(cp(1, 1:2));
                cp(cp == 0) = 1;
                index = cp;
            else
                index = varargin{1};
            end
            tmp = size(this.sisa_data);
            if length(tmp)>2
                name(1) = squeeze(this.sisa_point_names(index(1),tmp(2)+1-index(2),1));
                name(2) = squeeze(this.sisa_point_names(index(1),tmp(2)+1-index(2),2));
            else
                name(1) = squeeze(this.sisa_point_names(index(1),1,1));
            end
        end
        
        function update_points(this,varargin)  
            t = size(this.reader.data.sisa);
            t = t(1:4);
            s = prod(t);            
            ii = 0;
            for n = 1:s
                [i,j,k,l] = ind2sub(t, n);
                if all(~isnan(this.sisa_data(i, j)))
                    ii = ii+1;                    
                    pointinfo(ii).ort = 'undefined';
                    pointinfo(ii).int_time = this.reader.meta.sisa.int_time;
                    pointinfo(ii).note = '';
                    
%                     [~,indx]=ismember(this.reader.meta.pointinfo.point_names,[i-1,j-1,k-1],'rows');                    
%                     try
%                         pointinfo(ii).messzeit = round(this.reader.meta.pointinfo.point_time(indx == 1));
%                     catch
%                         pointinfo(ii).messzeit = 0;
%                     end
%                     pointinfo(ii).ink = (this.reader.meta.sample.measure_time - this.reader.meta.sample.prep_time) + pointinfo(ii).messzeit; % in seconds
                    pointinfo(ii).name = sprintf('%i/%i/%i/%i',squeeze(this.reader.data.sisa_point_name(i, j, k, l, :))-1);
                    
                    result(ii).t_zero = this.np;
                    result(ii).r_start = this.kinetik_start;
                    result(ii).r_sum = sum(this.reader.data.sisa(i,j,k,l,this.kinetik_start:this.g_start-1));
%                     
                    result(ii).g_start = this.g_start;
                    result(ii).g_sum = sum(this.reader.data.sisa(i,j,k,l,this.g_start:this.b_start-1));
%                     
                    result(ii).b_start = this.b_start;
                    result(ii).b_sum = sum(this.reader.data.sisa(i,j,k,l,this.b_start:this.b_end));
                    result(ii).b_end = this.b_end;

                end
            end
            db = db_interaction(this.dbconfig);
            db.set_progress_cb(@(x) this.update_infos(x));
            inserted = db.hyper(this.fileinfo,pointinfo, result)
            db.close;
        end
    end
end