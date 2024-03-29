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
        number;
        h = struct();
    end

    methods
        function this = Slice(parent, point_1, color, ax, no)
            if nargin < 5
                no = 0;
            end
            
            this.number = no;
            
            this.p = parent;
            this.point_1 = point_1;
            this.old_fcn = this.p.h.axes.ButtonDownFcn;
            this.p.h.axes.ButtonDownFcn = @this.button_down_cb;
            
            this.ax = ax;
            this.color = color;

            [x, y] = this.p.get_xy_dims();
            axes(this.p.h.axes);
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
            parts = fieldnames(this.h);
            for i = 1:length(parts)
                delete(this.h.(parts{i}))
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
                parts = fieldnames(this.h);
                for i = 1:length(parts)
                    delete(this.h.(parts{i}))
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
%                 this.h.p1_text = text(this.point_1{x}, this.point_1{y}, num2str(this.number));
                hold off
            end
        end

        function open_slice_plot(this)
            [x_vec, plot_vec, plot_vec_err, x_label] = this.get_slice_data();
            SinglePlot(x_vec, plot_vec, plot_vec_err, 'savepath', fullfile(this.p.p.p.savepath, this.p.p.p.genericname),...
                       'xlabel', x_label);
        end
        
        function [x_vec, plot_vec, plot_vec_err, x_label] = get_slice_data(this,varargin)
            if nargin == 2
                cur_par = varargin(1);
                d = this.p.get_data(cur_par);
                dd = this.p.get_errs(cur_par);
            else
                d = this.p.get_data();
                dd = this.p.get_errs();
            end
            
%             if(isempty(dd))
%                 dd = zeros(size(d));
%             end
            tmp = this.p.get_slice();
            d = squeeze(d(tmp{:}));
            if ~isempty(dd)
                dd = squeeze(dd(tmp{:}));
            end
            
            if this.p.transpose
                d = d';
                dd = dd';
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
                dd = dd';
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
                if ~isempty(dd)
                    plot_vec_err(x_i) = dd(i, l(i));
                else
                    plot_vec_err = [];
                end
                if x_i == 1
                    x_vec(1) = x_1;
                    continue
                end
                x_vec(x_i) = x_vec(x_i-1) + sqrt(1 + (l(i)-l(i-1))^2);
            end

            % needs to be generalized to not-uniformly-spaced datapoints!
            %     (errors for wavelength, but not a problem because a click
            %      will give that anyways.)
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
                % was h�bsches zum skalieren �berlegen...
            else
                x_label = 'a.u.';
            end
            
            if x_vec == zeros(size(x_vec))
                x_vec = 1:length(x_vec);
            end
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

