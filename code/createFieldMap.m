function fieldMap = createFieldMap(vals,polarVals,eccenVals,sigmaVals)

eccenMax = 90;
mapRes = 100;

X = mapRes/2 - ( (mapRes/2).* eccenVals .* cosd( polarVals ) ./ eccenMax);
Y = mapRes/2 - ( (mapRes/2).* eccenVals .* sind( polarVals ) ./ eccenMax);

[R,C] = ndgrid(1:mapRes, 1:mapRes);
gaussWeight = @(x,y,sigma) exp(-((R-x).^2 + (C-y).^2)./(2*sigma));

for ii = 1:length(vals)
    w(:,:,ii) = gaussWeight(X(ii), Y(ii), sigmaVals(ii));
    wv(:,:,ii) = w(:,:,ii).*vals(ii);
end

weightSum = sum(w,3);
fieldMap = sum(wv,3)./weightSum;
fieldMap(weightSum<0.1)=nan;

figure
imagesc(fieldMap)
axis square
caxis([-0.5 0.5])
%caxis([0 25])

end