function [ output_args ] = openASC( this )
%ASC_READER Summary of this function goes here
%   Detailed explanation goes here

name = this.fileinfo.name;

formatSpec = '%s%[^\n\r]';
delimiter = ',';

if iscell(name)    
    for i = 1:length(name)
        %         this.fileinfo.size = [length(name), 1, 1];
        fileID = fopen([this.fileinfo.path name{i}],'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
        %% Close the text file.
        fclose(fileID);
        
        dataArray = dataArray{1};
        
        
        try
            startIndex = find(contains(dataArray, '*BLOCK')); %geht erst ab 2016b
            endIndex = find(contains(dataArray, '*END')); %geht erst ab 2016b
        catch me
            IndexC = strfind(dataArray, '*BLOCK');
            startIndex = find(not(cellfun('isempty', IndexC)));
            IndexC = strfind(dataArray, '*END');
            endIndex = find(not(cellfun('isempty', IndexC)));
            disp(me)
        end
        
        if i == 1
            data = nan(length(name),1,1,1,endIndex(1)-startIndex(1)-1);
            size(data)
        end
            
        %         d = dlmread([this.fileinfo.path name{i}]);
%         if i > 1
%             if length(d) > size(data, 5)
%                 d = d(1:size(data, 5));
%                 this.update_infos(['    |    Länge der Daten ungleich in ' name{i}]);
%             elseif length(d) < size(data, 5)
%                 d = [d; zeros(size(data, 5) - length(d),1)];
%             end
%         end
        
        for k = 1:length(startIndex)
            d = str2double(dataArray(startIndex(k)+1:endIndex(k)-1));
            size(d)
            data(i, 1, 1, k,:) = d;
        end
        
    end
    this.fileinfo.np = length(name);
elseif isstruct(name)
    this.fileinfo.name = cell(length(name),1);
    for i = 1:length(name)
        if name(i).isdir
            files = dir([name(i).name '\*.diff']);
            for j = 1:length(files)
                d = dlmread([name(i).name '\' files(j).name]);
                if i == 1 && j == 1
                    data = zeros(length(name),length(files),1,1,length(d));
                end
                this.fileinfo.name{i,j} = files(j).name;
                data(i, j, 1, 1,:) = d;
            end
        end
    end
end
this.data_read = true;

tmp = size(data);
this.fileinfo.size = tmp(1:4);

for i = 1:length(name)
    if mod(i, round(length(name)/10)) == 0
        this.update_infos(['   |   Metadaten einlesen ' num2str(i) '.']);
    end
end

reader = this.guess_channel_width();
this.modes{1} = SiSaMode(this, double(data),reader,1);

end

