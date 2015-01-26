function [ pfad,dims ] = Untitled( dateiname )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

info=h5info(dateiname);

X_temp={info.Groups.Name};
X_temp=X_temp(1:end-3);

Y_temp=h5info(dateiname,X_temp{1});
Y_temp={Y_temp.Groups.Name};

Z_temp=h5info(dateiname,Y_temp{1});
Z_temp={Z_temp.Groups.Name};

for i=1:length(X_temp)
    x(i)=str2double(X_temp{i}(2:end));  
end

for i=1:length(Y_temp)
    temp=strsplit(Y_temp{i},'/');
    y(i)=str2double(temp{3});
end

for i=1:length(Z_temp)
    temp=strsplit(Z_temp{i},'/');
    z(i)=str2double(temp{3});  
end


%% pfad bauen
lauf=0;
for i=1:length(x)
    for j=1:length(y)
        for k=1:length(z)
            lauf=lauf+1;
            pfad{lauf,1}=sprintf('%d/%d/%d',x(i),y(j),z(k));
        end
    end
end

pfad{lauf+1,1}='CHECKPOINT';

dims{1}=length(x);
dims{2}=length(y);
dims{3}=length(z);
end