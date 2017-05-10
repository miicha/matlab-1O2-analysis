classdef DB_Viewer < handle
    %DB_VIEWER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        h = struct();        % handles
        filename;
        db_data;
    end
    
    methods
        function this = DB_Viewer(path, name)
            this.filename = path;
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

            fsize = this.h.f.Position;
            fsize = fsize(3:4)
            
            this.h.selectpanel = uipanel(this.h.f,'Title','Auswahl',...
                'BackgroundColor','white', 'Units','pixel',...
                'Position',[10 10 200 fsize(2)-20]);      
            
            this.h.l = uicontrol(this.h.selectpanel, 'Style','listbox',...
                'String',{'eins', 'zwei','drei'},...
                'Units','normalized','Position',[0.01 0.1 0.98 0.89]);
            
            this.h.b = uicontrol(this.h.selectpanel,'Style','pushbutton',...
                'String','OK',...
                'Position',[30 20 30 30],'callback',@this.ok);
            
            
            this.load_db();
            
            
            
            this.h.l.String = this.db_data.Name;

                    
                    
        end
        
        function ok(this, varargin)
            get(this.h.l)
            this.h.l.String{this.h.l.Value}
%             set(this.h.l,'String',{'vier','fuenf'});
        end
        
        function load_db(this)
            
            this.filename
            conn = database('','','','org.sqlite.JDBC',['jdbc:sqlite:' this.filename]);
            
            tablename = 'ScanData';
            
            
            sqlquery = ['SELECT * FROM ' tablename];
            
            curs = exec(conn,sqlquery);
            curs = fetch(curs,1);
            
            columnns = columnnames(curs, true);
            close(curs)
            
            
            sqlquery = ['SELECT * FROM ' tablename ...
                ' ORDER BY Name ASC'];
            
            curs = exec(conn,sqlquery);
            curs = fetch(curs);
            
            data = curs.Data;           
            close(curs)            
            close(conn)

            this.db_data = cell2table(data,'VariableNames',columnns);
            
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

