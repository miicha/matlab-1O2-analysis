classdef hyper < handle
    
    properties
        kinetik_start = 88;
        g_start = 200;
        b_start = 880;
        cw = 0.02;
        np = 66;
        
        fsize = 12;
        
        h = struct();        % handles
        
        sisa_data;
        current_draggable
        kinetik_real_start
        g_real_start
        b_real_start
        
        max_short
        max_long
        short_color = [0.19 0.76 0.41];
        long_color = [0.05 0.32 0.95];
        
        reader;
        
    end
    
    methods
        % create new instance with basic controls
        function this = hyper(filename, pos)
            
            this.kinetik_start = pos(1);
            this.np = pos(2);
%             addpath(genpath([pwd '\3rdParty']));
            this.h.figure = figure(4375);
            
            this.h.figure
            
            cmap = colormap('lines');
            this.short_color = cmap(2,:);
            this.long_color = cmap(5,:);
            
            this.h.load_data = uicontrol(this.h.figure);
            
            set(this.h.load_data,  'units', 'pixels',...
                           'style', 'push',...
                           'position', [105 2 140 28],...
                           'string', 'Bilder Speichern',...
                           'callback', @this.save_figures);

                       
%             filename = 'D:\Michael\Uni\Promotion\Projekte\CAM_Berlin\Scans\20170411\Ei 1.2 240min IV ueber Aderkreuzung-20170411_161729.h5';
            
%             filename = 'D:\Michael\Uni\Promotion\Projekte\CAM_Berlin\Scans\20170410\Ei 1.7 1h stelle 2-20170410_180151.h5';
            
            if ~exist('reader', 'var')
                this.reader = HDF5_reader(filename);
                this.reader.readfluo = false;
                this.reader.read_data;
            end
            
            this.prepare_data();
            
            this.h.map = subplot(2,1,1);
            this.show_image();
            
            this.h.kinetik = subplot(2,1,2); 
            this.show_kinetic(this.h.kinetik);
            
            %% Kinetik
            
        end
        
        function prepare_data(this,varargin)
            this.cw = this.reader.meta.sisa.Kanalbreite;
            this.kinetik_real_start = (this.kinetik_start-this.np)*this.cw;
            this.g_real_start = (this.g_start-this.np)*this.cw;
            this.b_real_start = (this.b_start-this.np)*this.cw;
            tmp = this.reader.get_sisa_data();
            this.sisa_data = squeeze(tmp(:,:,1,1,:));
        end
        
        function show_kinetic(this,varargin)
            
            ax = varargin{1};
            this.max_long
            this.max_short
            tmp = flipud(permute(this.sisa_data,[2,1,3]));
            kin = squeeze(tmp(this.max_short(2),this.max_short(1),:));            
            kin2 = squeeze(tmp(this.max_long(2),this.max_long(1),:));
            
            x_achse = 1:length(kin);
            x_achse = (x_achse-this.np)*this.cw;
            
            
                    
            
            alpha = 0.1;
            
            plot_max1 = max(kin(this.kinetik_start:end));
            plot_max2 = max(kin2(this.kinetik_start:end));
            
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
            
            hold on
            
            x = [this.g_real_start this.b_real_start];
            this.h.green_area = area(ax,x,y,'FaceColor','green');
            this.h.green_area.FaceAlpha = alpha;
            this.h.green_area.EdgeColor = 'none';
            
            x = [this.b_real_start max(x_achse)];
            this.h.blue_area = area(ax,x,y,'FaceColor','blue');
            this.h.blue_area.FaceAlpha = alpha;
            this.h.blue_area.EdgeColor = 'none';
            
            plot(ax,x_achse, kin, 'color', this.short_color);
            this.h.axes = gca;

            plot(x_achse, kin2, 'color', this.long_color)
            hold off
            
            
%             [906 92 694 880]
            this.h.figure.OuterPosition = [20 150 450 880];
            
%             this.h.figure.FontSize = 20;
            
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
            xlim([-0.5 80])
            
            
            ax.FontSize = this.fsize;
            
        end
        
        function save_figures(this,varargin)
            
            aspect = 1;
            fsize = 6.5;
            width = 0.35;
            
            f1 = figure; % Open a new figure with handle f1
            ax = axes(f1);
            this.show_image(ax);
            ax = gca
            
            save2pdf('map', 'width', width, 'texi', false, 'fontsize',fsize, 'aspectratio', 1.3)
            
            f1.delete();
            
            f2 = figure; % Open a new figure with handle f1
            ax = axes(f2);
            this.show_kinetic(ax);
            save2pdf('kinetik', 'width', width, 'texi', false, 'fontsize',fsize, 'aspectratio', 4/3)
            
            f2.delete()
        end
        
        function show_image(this, varargin)
            ax = this.h.map;
            r = sum(this.sisa_data(:,:,this.kinetik_start:this.g_start-1),3);
            g = sum(this.sisa_data(:,:,this.g_start:this.b_start-1),3);
            b = sum(this.sisa_data(:,:,this.b_start:end),3);
            
            clor(:,:,1) = r'/max(r(:));
            clor(:,:,2) = g'/max(g(:));
            clor(:,:,3) = b'/max(b(:));
            clor = flipud(clor);

%             clor(:,:,1) = r';
%             clor(:,:,2) = g';
%             clor(:,:,3) = b';
%             clor = flipud(clor/max(clor(:)));
            
            
            
%             [ii,jj] = find(clor(:,:,2)>0.5);
%             this.short_color = squeeze(mean(mean(clor(ii,jj,:))))
%             
%             
%             [ii,jj] = find(clor(:,:,3)>0.5);
%             this.long_color = squeeze(mean(mean(clor(ii,jj,:))))
            
            r2 = mean(this.sisa_data(:,:,this.kinetik_start:this.g_start-1),3);
            g2 = mean(this.sisa_data(:,:,this.g_start:this.b_start-1),3);
            b2 = mean(this.sisa_data(:,:,this.b_start:end),3);
            clor2(:,:,1) = r2';
            clor2(:,:,2) = g2';
            clor2(:,:,3) = b2';
            clor2 = flipud(clor2/max(max(max(clor2))));
            
            
%             [a,b] = max(max(clor(:,:,3)))
%             [Ii,Jj] = ind2sub(size(clor(:,:,1)), b)
            
            r = squeeze(clor(:,:,1));
            g = squeeze(clor(:,:,2));
            b = squeeze(clor(:,:,3));
            
            [~, pos] = max(r(:));
            
            [~, pos1] = max(g(:));
            
            [~, pos2] = max(b(:));
            
            [I,J] = ind2sub(size(r), pos1);
            this.max_short = [J, I];
%             this.max_short = [J-1, I-0];
            [I,J] = ind2sub(size(r), pos2);
            this.max_long = [J,I];
%             hold on
            
            
            imshow(clor,'InitialMagnification',3000, 'Parent', ax)
%             title('Summe')
            
            p1 = patch(ax,[this.max_short(1)-0.5, this.max_short(1)-0.5, this.max_short(1)+0.5, this.max_short(1)+0.5], [this.max_short(2)-0.5, this.max_short(2)+0.5, this.max_short(2)+0.5, this.max_short(2)-0.5], this.short_color);
            p1.EdgeColor = this.short_color;
            p1.LineWidth = 2.5;
            p1.FaceColor = 'none';
            
            t1 = text(ax,this.max_short(1)+0.8, this.max_short(2)-1.1, 'A');
            t1.Color = this.short_color;
            t1.FontSize = this.fsize;
            
            p2 = patch(ax,[this.max_long(1)-0.5, this.max_long(1)-0.5, this.max_long(1)+0.5, this.max_long(1)+0.5], [this.max_long(2)-0.5, this.max_long(2)+0.5, this.max_long(2)+0.5, this.max_long(2)-0.5], this.long_color);
            p2.EdgeColor = this.long_color;
            p2.LineWidth = p1.LineWidth;
            p2.FaceColor = 'none';
            
            t2 = text(ax,this.max_long(1)+0.8, this.max_long(2)-1.1, 'B');
            t2.Color = this.long_color;
            t2.FontSize = this.fsize;

%             subplot(2,2,2)
%             imshow(clor2,'InitialMagnification',3000)
%             title('Mittelwert')
            
%             hold off
            
            
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
            this.h.left.XData = [cpoint cpoint];
            
            this.h.red_area.XData(2) = cpoint;
            this.h.green_area.XData(1) = cpoint;
        end
        
        function drag_right(this,varargin)
            this.current_draggable = 'right';
            cpoint = get(this.h.axes, 'CurrentPoint');
            cpoint = cpoint(1, 1);
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
        end        
    end
end