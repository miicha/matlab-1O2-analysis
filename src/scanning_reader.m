classdef scanning_reader < HDF5_reader
    %SCANNING_READER Summary of this class goes here
    %   Detailed explanation goes here
        
    methods
        function this = scanning_reader(file)
            this.filename =  file;

            if strcmp('1.0', this.get_version())
                this.read_1_0();
            else
                error('Cannot read this version of scanning HDF5 file.');
            end
        end
    end
    
    methods (Access = private)
        function read_1_0(this)
            filepath = this.filename;
            try
                x_step = h5readatt(filepath, '/PATH/DATA','X Step Size mm');
                y_step = h5readatt(filepath, '/PATH/DATA','Y Step Size mm');
                z_step = h5readatt(filepath, '/PATH/DATA','Z Step Size mm');
                this.meta.scale = [x_step y_step z_step];
            catch
                % nothing. just an old file.
            end
            
            try
                dims = h5readatt(filepath, '/PATH/DATA', 'GRID DIMENSIONS');
                if strcmp(dims{:}, '')
                    dims = {'0/0/0'};
                end
                dims = strsplit(dims{:}, '/');

                        % offset of 1 should be fixed in labview scan software
                offset = 1;
                if str2double(dims{3}) < 0
                    offset = abs(str2double(dims{3}))+1;
                end
                this.meta.size = [str2double(dims{1})+1 str2double(dims{2})+1 str2double(dims{3})+offset];
                        % end of fix

                % get attributes from file
                fin = h5readatt(filepath, '/PATH/DATA', 'LAST POINT');

                % get scanned points
                tmp = h5read(filepath, '/PATH/DATA');
                tmp = tmp.Name;
                
                if  strcmp(fin{:}, 'CHECKPOINT')
                    this.meta.finished = true;
                    num_of_points = length(tmp) - 1;
                else
                    this.meta.finished = false;
                    num_of_points = length(tmp);
                end
            catch
                % nothing.
            end
            info = h5info(filepath, '/0/0/0/sisa');
            this.meta.size(4) = length(info.Datasets);
            
            % create map between string and position in data
                % now reasonably fast(about 10 times faster then before), 
                % approx factor 2 possible with:
                % vec = cellfun(@(x) textscan(x,'%d/%d/%d', 'CollectOutput', 1),tmp);
                % but vec is the complete matrix and I don't know how to 
                % put this matrix into this.points()
            this.meta.points = containers.Map;
            for i = 1:num_of_points
                vec = cell2mat(textscan(tmp{i},'%n/%n/%n')) + [1 1 offset];
                this.meta.points(tmp{i}) = vec;
                
                if strcmp(tmp{i}, fin)
                    break
                end
            end

            % get number of scanned points
            this.meta.fileinfo.np = this.meta.points.Count;
            
            info = h5info(filepath, '/0/0/0');
            info = {info.Groups.Name};
            for i = 1:length(info)
                this.meta.modes_in_file{i} = regexprep(info{i}, '/0/0/0/', '');
            end
            
            %% read
            k = keys(this.meta.points);
            fid = H5F.open(filepath);

            
            for i = 1:this.meta.fileinfo.np
                index = this.meta.points(k{i});
                % every point should have exactly as many samples
                % as the first point, except for the last one
                for m = 1:length(this.meta.modes_in_file)
                    mode = this.meta.modes_in_file{m};
                    dataset_group= sprintf('/%s/%s',k{i}, mode);
                    gid = H5G.open(fid,dataset_group);
                    info = H5G.get_info(gid);
                    n = info.nlinks;
                    if info.nlinks > 1
                        n = n-1;
                    end
                    for j = 1:n % iterate over all samples
                        try
                            try
                                dset_id = H5D.open(gid, sprintf('%d', j-1));
                            catch
                                dset_id = H5D.open(gid, sprintf('%d', j));
                            end
                            d = H5D.read(dset_id);
                            H5D.close(dset_id);

                            if strcmp(mode, 'sisa')
                                this.data.sisa(index(1), index(2), index(3), j, :) = d;
                            elseif strcmp(mode, 'spec')
                                this.data.fluo(index(1), index(2), index(3), j, :) = d;
                            elseif strcmp(mode, 'Temp')
                                this.data.temp(index(1), index(2), index(3), j, :) = d;
                            end
                        catch
                        end
                    end
                    H5G.close(gid);
                end
            end
            H5F.close(fid);
            
            tmp = size(this.data.sisa);
            this.meta.fileinfo.size = tmp(1:4);
        end
    end
    
end

