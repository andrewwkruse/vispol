function arr_out = clipatperc(arr_in, perc)
if iscell(perc);
    perc = perc{:};
end
sh = size(arr_in);
arr_out = reshape(arr_in, [],1);
perc_num = prctile(arr_out, perc);
arr_out = arr_out ./ perc_num;
arr_out(arr_out > 1) = 1;
arr_out(arr_out < 0) = 0;
arr_out = reshape(arr_out,sh);
end