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
                 'ButtonDownFcn', @this.update_point_1_cb);
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
                    this.open_plot();
                case 'open'
                    this.delete_slice();
            end
        end

        function update_point_2_cb(this, varargin)
            switch get(this.p.get_figure(), 'SelectionType')
                case 'normal'
                    this.p.get_figure().WindowButtonUpFcn = @this.stop_dragging_cb_2;
                case 'alt'
                    this.open_plot();
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
            if isfield(this.h, 'l')
                delete(this.h.l)
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
                if isfield(this.h, 'l')
                    delete(this.h.l)
                end
                
                hold on
                this.h.l = line([this.point_1{x} this.point_2{x}], [this.point_1{y} this.point_2{y}],...
                      'color', this.color,  'HitTest', 'off');
                this.h.p2 = plot(this.point_2{x}, this.point_2{y}, 'o', 'color', this.color,...
                     'markerfacecolor', this.color, 'markeredgecolor', 'k', 'ButtonDownFcn', @this.update_point_2_cb);
                this.h.p1 = plot(this.point_1{x}, this.point_1{y}, 'o', 'color', this.color, 'markerfacecolor', this.color,...
                     'markeredgecolor', 'k', 'ButtonDownFcn', @this.update_point_1_cb);
                hold off
            end
        end

        function open_plot(this)
            figure()
            d = this.p.get_data();
            tmp = this.p.get_slice();
            d = squeeze(d(tmp{:}));
            
            
            m = (this.point_2{this.p.curr_dims(2)}-this.point_1{this.p.curr_dims(2)})/...
                (this.point_2{this.p.curr_dims(1)}-this.point_1{this.p.curr_dims(1)});
            
            if isinf(m)
                d = d';
                m = 0;
            end
            b = this.point_1{this.p.curr_dims(2)} - m*this.point_1{this.p.curr_dims(1)};
            
            l = @(x) round(m.*x + b);
            

            [x, y] = size(d);
            x_i = 0;
            for i = this.point_1{this.p.curr_dims(1)}:this.point_2{this.p.curr_dims(1)}
                x_i = x_i + 1;

                if l(i) < 1 || l(i) > y
                    continue
                end
                
                plot_vec(x_i) = d(i, l(i));
                if x_i == 1
                    x_vec(1) = 0;
                    continue
                end
                x_vec(x_i) = x_vec(x_i-1) + sqrt(1 + (l(i)-l(i-1))^2);
                
            end
            
            plot(x_vec, plot_vec);
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

