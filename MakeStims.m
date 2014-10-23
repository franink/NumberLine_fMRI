%% Make natural number stimuli... both orders come out of this

NatStim = [];

for ii = 1:9
    for jj = 1:9
        NatStim = [NatStim; ii jj];
    end
end

RmInd = (NatStim(:,1) == NatStim(:,2));

NatStim(RmInd,:) = [];

%% Make fraction stims as discussed in meeting with Jay

FracStim = [1 2; ...
            2 3; ...
            1 4;
            2 4; ...
            3 4; ...
            2 5; ...
            4 5; ...
            3 6; ...
            4 6; ...
            5 6; ...
            3 7; ...
            4 7; ...
            5 7; ...
            6 7; ...
            3 8; ...
            4 8; ...
            5 8; ...
            6 8; ...
            3 9; ...
            4 9; ...
            5 9; ...
            6 9; ...
            7 9; ...
            8 9]
            
%% Save stims

save ECOG_Stims.mat NatStim FracStim