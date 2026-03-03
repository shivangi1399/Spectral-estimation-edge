function p = permutate(vec)
% this function scrambles a vector;

% check if the vector has the right format
if size(vec,1)>1
    error('vector does not have appropriate format')
end

permute=randperm(length(vec));

p=nan(1,length(vec));

for x=1:length(vec)
    p(1,x)=vec(permute(1,x));
end

end