classdef HDF5_reader < handle
    %HDF5_READER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data
        meta
        filename
    end
    
    methods
        function version = get_version(this)
            FileInfo = h5info(this.filename);
            try
                version = FileInfo.Attributes.Value.Nummer{1};
            catch
                % old file.
                version = '1.0';
            end
        end
    end
    
end

