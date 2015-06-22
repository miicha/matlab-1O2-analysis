classdef Slice < handle
    %SLICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        point_1;
        point_2;
        p;
        ax;
        color;
        old_fcn;
        
        h = struct();
    end

    methods
        function this = Slice(parent, point_1, color, ax)
            this.p = parent;
            this.point_1 = point_1;
            this.old_fcn = this.p.h.axes.ButtonDownFcn;
            this.p.h.axes.ButtonDownFcn = @this.button_down_cb;
            
            this.ax = ax;
            this.color = color;

            [x, y] = this.p.get_xy_dims();
            axes(this.p.h.axes)
            hold on
            this.h.p1 = plot(point_1{x}, point_1{y}, 'o', 'color', this.color, 'markerfacecolor', this.color,...
                 'markeredgecolor', 'k', 'ButtonDownFcn', @this.update_point_1_cb);
            hold off
        end

        function button_down_cb(this, varargin)
            % get second point
            this.point_2 = this.p.get_current_point();
            this.plot_slice();
            this.p.h.axes.ButtonDownFcn = this.old_fcn;
        end

        function update_point_1_cb(this, varargin)
            switch get(this.p.get_figure(), 'SelectionType')
                case 'normal'
                    this.p.get_figure().WindowButtonUpFcn = @this.stop_dragging_cb_1;
                case 'alt'
                    this.open_slice_plot();
                case 'open'
                    this.delete_slice();
            end
        end

        function update_point_2_cb(this, varargin)
            switch get(this.p.get_figure(), 'SelectionType')
                case 'normal'
                    this.p.get_figure().WindowButtonUpFcn = @this.stop_dragging_cb_2;
                case 'alt'
                    this.open_slice_plot();
                case 'open'
                    this.delete_slice();
            end
        end
        
        function delete_slice(this)
            if isfield(this.h, 'p1')
                delete(this.h.p1)
            end
            if isfield(this.h, 'p2')
                delete(this.h.p2)
            end
            if isfield(this.h, 'l1')
                delete(this.h.l1)
            end
            if isfield(this.h, 'l2')
                delete(this.h.l2)
            end
            this.p.delete_slice(this);
            delete(this);
        end

        function plot_slice(this)
            flag = true;
            [x, y] = this.p.get_xy_dims();
            curr_slice = this.p.get_slice();
            for i = 1:length(curr_slice)
                if curr_slice{i} ~= this.point_1{i} && curr_slice{i} ~= ':'
                    return
                end
            end
            if flag
                axes(this.p.h.axes)
                if isfield(this.h, 'p1')
                    delete(this.h.p1)
                end
                if isfield(this.h, 'p2')
                    delete(this.h.p2)
                end
                if isfield(this.h, 'l1')
                    delete(this.h.l1)
                end
                if isfield(this.h, 'l2')
                    delete(this.h.l2)
                end
                
                hold on
                this.h.l1 = line([this.point_1{x} this.point_2{x}], [this.point_1{y} this.point_2{y}],...
                      'color', [.2 .2 .2],  'HitTest', 'off', 'linewidth', 1.8);
                this.h.l2 = line([this.point_1{x} this.point_2{x}], [this.point_1{y} this.point_2{y}],...
                      'color', this.color,  'HitTest', 'off', 'linewidth', 1);
                this.h.p2 = plot(this.point_2{x}, this.point_2{y}, 'o', 'color', this.color,...
                     'markerfacecolor', this.color, 'markeredgecolor', 'k', 'ButtonDownFcn', @this.update_point_2_cb);
                this.h.p1 = plot(this.point_1{x}, this.point_1{y}, 'o', 'color', this.color, 'markerfacecolor', this.color,...
                     'markeredgecolor', 'k', 'ButtonDownFcn', @this.update_point_1_cb);
                hold off
            end
        end

        function open_slice_plot(this)
            d = this.p.get_data();
            tmp = this.p.get_slice();
            d = squeeze(d(tmp{:}));
            
            if this.p.transpose
                d = d';
            end
            
            x_1 = this.point_1{this.p.curr_dims(1)};
            x_2 = this.point_2{this.p.curr_dims(1)};
            
            y_1 = this.point_1{this.p.curr_dims(2)};
            y_2 = this.point_2{this.p.curr_dims(2)};
            
            m = (this.point_2{this.p.curr_dims(2)}-this.point_1{this.p.curr_dims(2)})/...
                (this.point_2{this.p.curr_dims(1)}-this.point_1{this.p.curr_dims(1)});
            b = this.point_1{this.p.curr_dims(2)} - m*this.point_1{this.p.curr_dims(1)};

            
            transp = false;
            if abs(m) > 1 % guarantees that x_2 - x_1 > y_2 - y_1
                d = d';
                m = (this.point_2{this.p.curr_dims(1)}-this.point_1{this.p.curr_dims(1)})/...
                    (this.point_2{this.p.curr_dims(2)}-this.point_1{this.p.curr_dims(2)});
                b = this.point_1{this.p.curr_dims(1)} - m*this.point_1{this.p.curr_dims(2)};
                
                x_1 = this.point_1{this.p.curr_dims(2)};
                x_2 = this.point_2{this.p.curr_dims(2)};
                
                y_1 = this.point_1{this.p.curr_dims(1)};
                y_2 = this.point_2{this.p.curr_dims(1)};
                transp = true;
            end
            
            l = @(x) round(m.*x + b);
            
            if x_1 > x_2
                tmp = x_2;
                x_2 = x_1;
                x_1 = tmp;
            end

            [x, y] = size(d);
            x_i = 0;
            for i = x_1:x_2
                x_i = x_i + 1;
                if l(i) < 1 || l(i) > y
                    continue
                end
                plot_vec(x_i) = d(i, l(i));
                if x_i == 1
                    x_vec(1) = x_1;
                    continue
                end
                x_vec(x_i) = x_vec(x_i-1) + sqrt(1 + (l(i)-l(i-1))^2);
            end

            if y_2 == y_1
                if transp
                    x_label = this.p.p.units{this.p.curr_dims(2)};
                    x_vec = x_vec * this.p.p.scale(this.p.curr_dims(2));
                else
                    x_label = this.p.p.units{this.p.curr_dims(1)};
                    x_vec = x_vec * this.p.p.scale(this.p.curr_dims(1));
                end
            elseif x_2 == x_1
                if transp
                    x_label = this.p.p.units{this.p.curr_dims(1)};
                    x_vec = x_vec * this.p.p.scale(this.p.curr_dims(1));
                else
                    x_label = this.p.p.units{this.p.curr_dims(2)};
                    x_vec = x_vec * this.p.p.scale(this.p.curr_dims(2));
                end
            elseif strcmp(this.p.p.units{this.p.curr_dims(1)}, this.p.p.units{this.p.curr_dims(2)})
                x_label = this.p.p.units{this.p.curr_dims(1)};
                % was hübsches zum skalieren überlegen...
            else
                x_label = 'a.u.';
            end
            
            SinglePlot(x_vec, plot_vec, fullfile(this.p.p.p.savepath, this.p.p.p.genericname),...
                       'xlabel', x_label);
        end

        function stop_dragging_cb_1(this, varargin)
            this.point_1 = this.p.get_current_point();
            this.p.get_figure().WindowButtonUpFcn = '';
            this.plot_slice();
        end

        function stop_dragging_cb_2(this, varargin)
            this.point_2 = this.p.get_current_point();
            this.p.get_figure().WindowButtonUpFcn = '';
            this.plot_slice();
        end
    end
    
end

