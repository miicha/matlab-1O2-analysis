classdef DB_Viewer < handle
    %DB_VIEWER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        h = struct();        % handles
    end
    
    methods
        function this = DB_Viewer(path, name)
            this.h.f = figure();
            
            scsize = get(0,'screensize');
            
            set(this.h.f, 'units', 'pixels',...
                        'position', [scsize(3)-950 scsize(4)-750 900 680],...
                        'numbertitle', 'off',...
                        'menubar', 'none',...
                        'name', name,...
                        'resize', 'on',...
                        'Color', [.95, .95, .95],...
                        'ResizeFcn', @this.resize,...
                        'DeleteFcn', @this.destroy_cb);
                    
                    
        end
        
        
        
        function resize(this, varargin)
        end
        
        function destroy_cb(this, varargin)
            this.destroy(false);
        end
        
        function destroy(this, children_only)
            for i = 1:10
                try
                    this.saveini();
                catch
                    % some problem with the file system?!
                    % doesn't matter all that much, actually; just try
                    % again.
                    continue;
                end
                break;
            end
            
            if ~children_only
                delete(this.h.f);
                delete(this);
            end
        end
    end
    
end

