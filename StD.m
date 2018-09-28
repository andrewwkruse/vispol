

function dolp = StD(S)
dolp = sqrt(S(:,:,2).^2 + S(:,:,3).^2);
dolp(dolp>1)=1;
end