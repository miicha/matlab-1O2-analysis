classdef invivo_reader < HDF5_reader
    %INVIVO Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function this = invivo_reader(file)
            this.filename =  file;

            if strcmp('1.0', this.get_version())
                this.read_1_0();
            else
                error('Cannot read this version of in-vivo HDF5 file.');
            end
        end
    end
    
    methods (Access = private)
        function read_1_0(this)
            idx_type = 'H5_INDEX_NAME';
            order = 'H5_ITER_INC';
            lapl_id = 'H5P_DEFAULT';

            file = this.filename;
            
            info = h5info(file, '/Data');

            % get all locations for measurements
            locs = {info.Groups.Name};

            % find modi
            tmp = regexp({info.Groups(1).Groups.Name}, '/\w+$', 'match');
            modi = cell(length(tmp), 1);
            for i = 1:length(tmp)
                modi{i} = tmp{i}{1};
            end

            % open the HDF5
            f_id = H5F.open(file);
            %% read Data
            % iterate over all locations
            for i = 1:length(locs)
                loc_id = H5G.open(f_id, locs{i});

                % iterate over all modi
                for j = 1:length(modi)
                    mod_id = H5G.open(f_id, [locs{i} modi{j}]);
                    mod_info = H5G.get_info(mod_id);
                    N = mod_info.nlinks; % number of files in group

                    switch modi{j}
                        case '/sisa'
                            % iterate over all samples and read them
                            v_num = 1;
                            d_num = 1;
                            for k = 1:N
                                obj_id = H5O.open_by_idx(f_id, [locs{i} modi{j}], idx_type, order, k-1, 'H5P_DEFAULT');
                                name = H5I.get_name(obj_id);
                                H5O.close(obj_id);
                                data_id = H5D.open(f_id, name);

                                if regexp(name, 'Verlauf')
                                    this.data.sisa.verlauf(1, i, 1, v_num, :) = H5D.read(data_id);
                                    v_num = v_num + 1;
                                else
                                    this.data.sisa.data(1, i, 1, d_num, :) = H5D.read(data_id);
                                    d_num = d_num + 1;
                                end

                                H5D.close(data_id);
                            end
                        case '/fluo'
                            % iterate over all samples and read them
                            for k = 1:N
                                sa_id = H5G.open(f_id, [locs{i} modi{j}]);
                                sa_info = H5G.get_info(sa_id);
                                M = sa_info.nlinks; % number of files in group
                                sa_name = H5L.get_name_by_idx(f_id, [locs{i} modi{j}], idx_type, order, k-1, lapl_id);
                                for l = 1:M
                                    obj_id = H5O.open_by_idx(f_id, [locs{i} modi{j} '/' sa_name], idx_type, order, l-1, 'H5P_DEFAULT');
                                    name = H5I.get_name(obj_id);
                                    H5O.close(obj_id);
                                    data_id = H5D.open(f_id, name);

                                    this.data.fluo.data(1, i, 1, l, :) = H5D.read(data_id);

                                    H5D.close(data_id);
                                end
                                H5G.close(sa_id);
                            end
                    end
                    H5G.close(mod_id);
                end
                H5G.close(loc_id);
            end

            %% read Meta
            this.meta.fluo.x_achse = h5read(file, '/Meta/Fluo/X-Achse');
            this.meta.sisa = h5read(file, '/Meta/sisa/Parameter');

            tmp = h5readatt(file, '/Meta/Sample', 'Injektionszeit');
            this.meta.sample.Injektionszeit = tmp{1};

            % get the real locations of the measurements, not the HDF-path to them
            tmp = regexp(locs, '/\w+$', 'match');
            locations = cell(length(tmp), 1);
            for i = 1:length(tmp)
                locations{i} = tmp{i}{1}(2:end);
            end
            this.meta.locations = locations;

            H5F.close(f_id);
        end
    end
end

