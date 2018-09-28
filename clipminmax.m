function arr_out = clipminmax(arr_in, minmax)
minmax = cell2mat(minmax);
min = minmax(1);
max = minmax(2);
arr_out = (arr_in - min)./(max - min);
arr_out(arr_out > 1) = 1; arr_out(arr_out < 0) = 0;
end