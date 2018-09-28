function arr_out = clipatmax(arr_in, max)
arr_out = arr_in ./ max;
arr_out(arr_out > 1) = 1;
arr_out(arr_out < 0) = 0;
end