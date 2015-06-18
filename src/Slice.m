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
            end
        end

        function update_point_2_cb(this, varargin)
            switch get(this.p.get_figure(), 'SelectionType')
                case 'normal'
                    this.p.get_figure().WindowButtonUpFcn = @this.stop_dragging_cb_2;
                case 'alt'
                    this.open_plot();
            end
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
            
            m = (this.point_2{this.p.curr_dims(2)}-this.point_1{this.p.curr_dims(2)})/...
                (this.point_2{this.p.curr_dims(1)}-this.point_1{this.p.curr_dims(1)});
            
            b = this.point_1{this.p.curr_dims(2)} - m*this.point_1{this.p.curr_dims(1)};
            
            l = @(x) round(m.*x + b, 1);
            
            d = this.p.get_data();
            tmp = this.p.get_slice();
            d = squeeze(d(tmp{:}));
            [x, y] = size(d);
            gi = griddedInterpolant(d);
            plot(gi([(1:.1:x)', l(1:.1:x)']));
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

