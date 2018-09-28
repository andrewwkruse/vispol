function bounds = Jbounds(M,xspline,yspline)
bound_size = size(M);
bound_size(3) = 2;
bounds = zeros(bound_size);
slopes = zeros(length(yspline)-1);
for idx = 1:(length(yspline)-1)  
    slopes(idx) = (yspline(idx + 1) - yspline(idx))...
        /(xspline(idx + 1) - xspline(idx));
end
bounds(:,:,1) = arrayfun(@(m)lowerbound(m,xspline,yspline,slopes),M);
bounds(:,:,2) = arrayfun(@(m)upperbound(m,xspline,yspline,slopes),M);
end

function lb = lowerbound(m,xspline,yspline,slopes)
if m >= max(yspline)
    lb = xspline(yspline == max(yspline));
else
    for idx = 1:(length(yspline)-1)
        if (m >= yspline(idx)) && (m < yspline(idx+1))
            if slopes(idx) == 0
                lb = yspline(idx);
                break;
            else
                lb = (m - yspline(idx)) ./ slopes(idx) + xspline(idx);
                break;
            end
        end
    end
end
end

function ub = upperbound(m,xspline,yspline,slopes)
if m > max(yspline)
    ub = xspline(yspline == max(yspline));
else
    for idx = (length(yspline)-1):-1:1
        if (m <= yspline(idx)) && (m >= yspline(idx+1))
            if slopes(idx) == 0
                ub = yspline(idx);
                break
            else
                ub = (m - yspline(idx)) ./ slopes(idx) + xspline(idx);
                break
            end
        end
    end
end
end