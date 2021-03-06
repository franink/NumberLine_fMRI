% IEM_spatial.m
%
% Adapted from Tommy Sprague, 3/11/2015 - Bernstein Center IEM workshop
% tommy.sprague@gmail.com or jserences@ucsd.edu
%
%
% (Brouwer & Heeger, 2009; 2011; Serences & Saproo, 2012; Sprague & Serences, 2013; 
% Sprague, Saproo & Serences, 2015).  
%

close all;

%root = '/Users/frankanayet/Google Drive/NLineData/Serences/Serences_IEM_tutorial/';
%addpath([root 'mFiles/']);
%root = '/Users/frankanayet/Google Drive/NLineData/fMRIResults/Peter_RSA/Peter_ROI_IEM/';
root = '/fMRI/NLine-Space/s_03001/Peter_ROI_IEM/';



%% load the data
load([root 'ips0.mat']);
load([root 'v1.mat']);
load([root 'rns.mat']);
load([root 'cond.mat']);

load([root 'ips0_trn.mat']);
load([root 'v1_trn.mat']);
load([root 'ips0_tst.mat']);
load([root 'v1_tst.mat']);
load([root 'trn_r.mat']);
load([root 'tst_r.mat']);
load([root 'trn_cond.mat']);
load([root 'tst_cond.mat']);

% you'll find several variables:
% - tst: the task data - each row is a trial, each column a voxel
% - trn: the encoding model estimation data - each row is a trial, each
%   column is a voxel. the number of columns should be the same in trn & tst
% - trn_r: run number for encoding model estimation data
% - tst_r: run number for task data
% - trn_conds: condition labels for each trial of the encoding model
%   estimation data, where columns indicate:
%    - 1: x position of center of training stimulus in DVA
%    - 2: y position of center of training stimulus in DVA (SCREEN COORDS!)
% - tst_conds: condition labels for each trial in testinf run
%    - 1: x position of center of training stimulus in DVA
%    - 2: y position of center of training stimulus in DVA (SCREEN COORDS



%% train encoding model
% this is broken up into several subtasks - the first of which is
% generating a stimulus mask. Because the stimulus is a circle w/ a known,
% jittered location on each trial, we can just generate a binary image of
% 0's and 1's, with 1's at the positions subtended by the stimulus and 0's
% elsewhere. A similar technique is used by those mapping population
% receptive fields (pRFs).(Dumoulin & Wandell, 2008; Kay et al, 2013)
%
% This trial-by-trial stimulus mask will then be projected onto each
% channel's filter (a 2-d Gaussian-like function, usually). This amounts to
% a reduction in dimensionality from n_pixels to n_channels, though the
% transformation is necessarily lossy in this framework
%
% Use the trn_conds coordinates (first column is x, second column is y),
% and the stimulus size of 1.5 dva to generate a stimulus mask of 1's and
% 0's. The visual field area subtended by the display was 12 dva
% horizontally and 12 dva vertically (full width/height edge-to-edge).
%
% At this stage, it doesn't matter if we overestimate the size of the
% screen, so for simplicity let's say the screen is 13 dva tall and 13 dva
% wide.
ru = unique(rns);
n_runs = length(ru);
cond(:,2) = cond(:,2)*-1; % flip to cartesian coordinates to make life easier

stim_size = 1.5; % radius

% we also need to decide on a resolution at which to compute stimulus masks
% and spatial filters (below) - let's do 130 (horiz) x 130 (vert)

res = [130 130];

[xx, yy] = meshgrid(linspace(-13/2,13/2,res(1)),linspace(-13/2,13/2,res(2)));
xx = reshape(xx,numel(xx),1);yy = reshape(yy,numel(yy),1);

stim_mask = zeros(length(xx),size(cond,1));

for ii = 1:size(cond,1)

    rr = sqrt((xx-cond(ii,1)).^2+(yy-cond(ii,2)).^2);
    stim_mask(rr <= stim_size,ii) = 1; % assume constant stimulus size here

end


% check the stimulus masks by plotting a column of the stimulus mask as an
% image
tr_num = 5;
figure;
this_img = reshape(stim_mask(:,tr_num),res(2),res(1)); % x, y are transposed here because images are row (y), column (x)
imagesc(xx,yy,this_img);colormap gray; axis xy equal off;
title(sprintf('Trial %i (%0.02f, %0.02f)',tr_num,cond(tr_num,1),cond(tr_num,2)));

% Spot-check a few trials - does everything look ok? Also try plotting a
% figure showing the visual field coverage - the extent of the screen
% subtended by *any* stimulus, across all trials. In this particular
% experiment, we randomized the position of each and every trial (relative
% to a fixed grid). This means that there will not necessarily be perfectly
% even coverage of the entire screen, but it does increase the number of
% unique stimulus positions we can use for encoding model estimation.
figure;
max_mask = max(stim_mask,[],2);
this_img = reshape(max_mask,res(2),res(1)); % x, y are transposed here because images are row (y), column (x)
imagesc(xx,yy,this_img);colormap gray; axis xy equal off;
title(sprintf('Visual field coverage'));


%% build an encoding model
%
% an encoding model describes how a neural unit responds to an arbitrary
% set of stimluli. A common encoding model for visual stimuli measured for
% decades in the spatial receptive field (RF). Rather than directly
% estimate the exact receptive field of each voxel, we'll instead suppose
% that there are a discrete number of possible RF positions (that is, a
% discrete number of spatial filters) which describe discrete neural
% subpopulations. Each voxel then can be modeled as a weighted sum of these
% discrete subpopulations. While this is of course an approximation of the
% actual nature of RF properties in the visual system, by supposing a small
% number of possible RF positions/subpopulations we can *invert* the
% estimated encoding model (which is a set of weights on each supopulation
% for each voxel) in order to reconstruct the activation of each
% population given a novel voxel activation pattern observed (below). 
%
% First, let's generate the filters corresponding to our hypothetical
% neural populations. We'll assume, for simplicity, that they are a square
% grid and are all the same "size" (FWHM). If interested, try varying these
% parameters. 

% Let's set the center points:
step_size = 1;
rfPtsX = [-3:step_size:3] * stim_size;
rfPtsY = [-3:step_size:3] * stim_size;
[rfGridX,rfGridY] = meshgrid(rfPtsX,rfPtsY); 
rfGridX = reshape(rfGridX,numel(rfGridX),1);rfGridY = reshape(rfGridY,numel(rfGridY),1);
rfSize = 1.25*step_size*stim_size;   % for the filter shape we use (see below), this size/spacing ratio works well (see Sprague & Serences, 2013)
%rfSize = 1.25*stim_size

% because we're projecting a stimulus mask onto a lower-dimensional set of
% filters, we call the set of filters (or information channels) our basis
% set

basis_set = nan(size(xx,1),size(rfGridX,1)); % initialize

for bb = 1:size(basis_set,2)

    % the form of the basis function I use is a gaussian-like blob which
    % reaches zero at a known distance from its center, which is 2.5166x
    % the FWHM of the function. We'll define the FWHM as rfSize (above),
    % which means the "size" parameter of our function is 2.5166*rfSize.
    %
    % I've made a function (make2dcos) which we can use for generating each
    % individual basis function

    basis_set(:,bb) = make2dcos(xx,yy,rfGridX(bb),rfGridY(bb),1*rfSize*2.5166,7);
end

% let's look at the basis set
% I've created a function "plot_basis_rect" which takes a matrix of the
% basis set, number of X & Y points spanned by the basis set, and the x/y
% resolution of each filter. The function plots all basis functions
% (filters), as well as a surface plot showing the sum of all filters

plot_basis_rect(basis_set',length(rfPtsX),length(rfPtsY),res(1),res(2));

% You can see that we've created a set of spatial RFs which span the space
% subtended by our mapping stimulus. Additionally, the second figure shows
% the "coverage" of the basis set, as well as the "smoothness" of its
% coverage over space. In our experience, this
% approxmimate ratio of FWHM:spacing for a square grid works well. A
% hexagonal grid of basis functions also works well, and in that case
% because the mean distance between each basis function is slightly
% smaller, the best FWHM:spacing ratio is also slightly smaller.
% 
% Above, you can try changing the size of each basis function by changing
% the "1" before "rfSize" in the call to make2dcos - try bigger and smaller
% basis function sizes. What are the advantages and disadvantages to each?
% Come back to this once you've reached the end of the tutorial and try
% processing the data w/ several basis function sizes. 

%% compute predicted channel responses
%
% Now that we have a stimulus mask and a set of spatial filters/information
% channels, we want to determine the contribution of each information
% channel (hypothetical neural population) to each voxel. We set up the
% problem like a standard general linear model often used for fMRI
% activation map-based analyses:
% y = beta*X, where:
% - y is the measured signal in a voxel across all trials (1 x n_trials)
% - beta is the weights corresponding to how much each channel's response
%   contributes to each voxel (stable across trials, 1 x n_channels)
% - X is a design matrix, which is how much each hypothetical population,
%   with its defined RF, should respond to the stimulus (which we know)
%   (n_trials x n_channels)
%
% note that X is the same design matrix used for any standard GLM-based
% analysis in fMRI - we're just defining our "predictors" a bit
% differently. Here, predictors are predicted channel responses to known
% stimuli on each trial (the stimulus mask above). 
%
% In order to compute the design matrix, we simply compute the overlap of
% the stimulus mask onto each channel. 

trnX = stim_mask.' * basis_set;
trnX = trnX./max(trnX(:));        % and normalize to 1


% now let's double-check our filtering by plotting the predicted channel
% responses for a given trial next to the stimulus mask for that trial
tr_num = 5;
figure;
subplot(1,2,1);
imagesc(xx,yy,reshape(stim_mask(:,tr_num), res(2),res(1)));
axis xy equal off;
title(sprintf('Trial %i: stimulus',tr_num));

subplot(1,2,2);
imagesc(rfPtsX,rfPtsY,reshape(trnX(tr_num,:),length(rfPtsY),length(rfPtsX)));
axis xy equal off;
title(sprintf('Predicted channel responses'));
colormap gray;
 
%% estimate channel weights using training data
% 
% Now that we have our design matrix and our measured signal, we need to
% solve for the weights ("betas" in above equation). Because we have more
% trials than channels, and because our stimulus positions are unique on
% each trial, we should be able to estimate a unique solution for the
% channel weights given our observed activation pattern using ordinary
% least squares regression. 

% first, let's be sure our design matrix is "full-rank" (that is, that no
% predicted channel responses are colinear). This is always important to
% check, and could come about if you're using channels that are not
% uniquely sampled by the stimulus set. For example, if above you multiply
% the rfPtsX, rfPtsY vectors each by 3 before generating the design matrix,
% you would notice that many of the channels (those correspondign to the
% edges of the display) will always have "0" predicted activity. This means
% that it is impossible to estimate the contribution of such a channel to
% the activation of a voxel. This is also why we can only model the
% stimulated portion of the screen along model dimensions which we control.
% As an example, V1 also has many orientation-selective populations (see
% IEM_ori_fMRI.m), but we did not systematically vary the stimulus orientation
% here, and so we cannot uniquely estimate the contribution of different
% oreintation-selective populations to the observed voxel activations in
% this dataset.
%
% As a thought exercise, what are other scenarios (stimulus conditions or
% hypothesized channel properties like size/position) which could result in
% design matrices w/out full rank?

fprintf('Rank of design matrix: %i\n',rank(trnX));

%Need to pick only the cross as design matrix
%create a mask
num_channels = length(rfPtsX)^2;
A = [1:num_channels];
mat_length = length(rfPtsX);
reshape(A,mat_length,mat_length);
B = zeros(mat_length,mat_length);
B(7:8,:) = 1;
B(:,7:8) = 1;
Mask = A(B==1);
trnX_Masked = trnX(:,Mask);

%check rank
fprintf('Rank of masked design matrix: %i\n',rank(trnX_Masked));


%% Select voxels with anova

vox_prctile = 50;
%vox_prctile = 100;
chan_resp_ips0 = zeros(size(trnX));
chan_resp_ips0_masked = nan(size(trnX_Masked));
chan_resp_v1 = zeros(size(trnX));
chan_resp_v1_masked = nan(size(trnX_Masked));
%also recover training set for debugging
chan_resp_ips0_trn = zeros([size(trnX) n_runs]);
chan_resp_ips0_masked_trn = nan([size(trnX_Masked) n_runs]);
chan_resp_v1_trn = zeros([size(trnX) n_runs]);
chan_resp_v1_masked_trn = nan([size(trnX_Masked) n_runs]);


for rr = 1:n_runs
    
    % identify the training & testing halves of the data
    trnIdx = rns~=ru(rr);
    tstIdx = rns==ru(rr);
    
    % voxel selection - compute ANOVA on each voxel, rank them, select top
    % n% of voxels
    ips0_ps = nan(size(ips0,2),1);
    v1_ps = nan(size(v1,2),1);

    %First for v1
    for ii = 1:size(v1,2)
        v1_ps(ii) = anova1(v1(trnIdx,ii),cond(trnIdx,3),'off');
    end
    % Look at which voxels are most significant with the anova in the
    % cortex
    which_vox_v1 = v1_ps <= prctile(v1_ps,vox_prctile);

    v1_trn = v1(trnIdx,which_vox_v1);
    v1_tst = v1(tstIdx,which_vox_v1);

    %Now for ips0
    for ii = 1:size(ips0,2)
        ips0_ps(ii) = anova1(ips0(trnIdx,ii),cond(trnIdx,3),'off');
    end

    % if using all voxels
    %which_vox = ones(size(myLbetas,2))==1;

    which_vox_ips0 = ips0_ps <= prctile(ips0_ps,vox_prctile);

    ips0_trn = ips0(trnIdx,which_vox_ips0);
    ips0_tst = ips0(tstIdx,which_vox_ips0);

    % So we've established that the design matrix is full-rank (the rank is
    % equal to the number of columns). Let's estimate the channel weights.

    % this is just pinv(trnX) * trn; - but I wrote out the full math for
    % completness
    % w_ips0 = inv(trnX_Masked.'*trnX_Masked)*trnX_Masked.' * ips0_trn;
    % w_v1 = inv(trnX_Masked.'*trnX_Masked)*trnX_Masked.' * v1_trn;
    % (the above can also be written as: w = trnX\trn; )
    
    w_v1 = trnX_Masked(trnIdx,:)\v1_trn;
    w_ips0 = trnX_Masked(trnIdx,:)\ips0_trn;
    
    % w is now n_channels x n_voxels. This step is massively univariate, and is
    % identical to the step of estimating the beta weight corresponding to each
    % predictor for each voxel in a standard fMRI GLM analysis. It's written
    % above as a single matrix operation for brevity, but identical results are
    % obtained when looping through individual voxels. 
    %

    %Invert the encoding model and compute channel responses
    %
    % Our estimated "w" above reflects an ENCODING MODEL for each voxel. For a
    % given region (here,  V1), we have an encoding model estimated for
    % all voxels. Given our linear framework described above, we can INVERT the
    % encoding model in order to estimate the channel activation pattern (like
    % our trnX) which is associated with any novel activation pattern that is
    % observed. The associated mapping from VOXEL SPACE into CHANNEL SPACE is
    % computed from the pseudoinverse of the estimated weight matrix.
    %
    % This inversion step is where we get "inverted" encoding model from -
    % we're not just estimating encoding models for single voxels and comparing
    % them; we're instead estimating all encoding models, and using the joint
    % set of encoding models to constrain a mapping from voxel space into
    % channel space. 
    %
    % Once we have the inverted mapping (the pseudoinverse), we can map the
    % novel activation pattern ("tst") back into channel space.

    chan_resp_ips0_masked(tstIdx,:) = (inv(w_ips0*w_ips0')*w_ips0*ips0_tst').';
    chan_resp_v1_masked(tstIdx,:) = (inv(w_v1*w_v1')*w_v1*v1_tst').';
    % or can write as chan_resp = (w.'\tst.').'


    % % This is just to see if I recover the training set as debugging
    chan_resp_v1_masked_trn(trnIdx,:,rr) = (inv(w_v1*w_v1')*w_v1*v1_trn').';
    chan_resp_ips0_masked_trn(trnIdx,:,rr) = (inv(w_ips0*w_ips0')*w_ips0*ips0_trn').';


    % "chan_resp" is now the estimated channel responses for a novel dataset
    % which was never used to estimate any encoding properties (that is, "tst"
    % was never used in the computation of "w"). Each column of chan_resp
    % corresponds to a channel, or hypothetical neural population response, and
    % each row corresponds to a trial.
    
    %Undo mask
    size(chan_resp_ips0)
    size(chan_resp_ips0(tstIdx,Mask))
    size(chan_resp_ips0_masked(tstIdx,:))
    
    chan_resp_ips0(tstIdx,Mask) = chan_resp_ips0_masked(tstIdx,:);
    chan_resp_v1(tstIdx,Mask) = chan_resp_v1_masked(tstIdx,:);
    % And to test on the training set
    chan_resp_ips0_trn(trnIdx,Mask,rr) = chan_resp_ips0_masked_trn(trnIdx,:,rr);
    chan_resp_v1_trn(trnIdx,Mask,rr) = chan_resp_v1_masked_trn(trnIdx,:,rr);
    
end
    %% Check Results
    % Let's see what the channel responses look like across different trial
    % types. For now, let's just look at high-contrast stimuli presented on the
    % right side of the screen on attend-stimulus trials. 
    %
    % This means we'll search for trials with the following values in each of
    % tst_conds' columns:
    % column 1 (stimulus side, L or R):  1
    % column 2 (stimulus contrast, 1-6): 6
    % column 3 (task condition, attend fix or attend stim): 2
    % column 4 (target present?): 0 (so that mean contrast is the same)
    % 
    
    thisidx = tst_cond(:,1)<=-2.5 & tst_cond(:,2)==0;
    thisidx = tst_cond(:,3)==1;
    %For training set
    thisidx = trn_cond(:,3)==1;
    thisidx = 46;
    %V1
    avg_chan_resp = mean(chan_resp_v1(thisidx,:),1);
    figure;ax(1)=subplot(1,2,1);
    imagesc(rfPtsX,rfPtsY,reshape(avg_chan_resp,length(rfPtsY),length(rfPtsX)));
    title('Left, high-contrast, attended stimuli');
    axis equal xy off;

    % now compare to trials when the stimulus was on the right

    clear thisidx avg_chan_resp;
    thisidx = tst_cond(:,1)>=2.5 & tst_cond(:,2)==0;
    thisidx = tst_cond(:,3)==6;
    %For training set
    thisidx = trn_cond(:,3)==6;
    %thisidx = 4;
    avg_chan_resp = mean(chan_resp_v1(thisidx,:),1);
    ax(2)=subplot(1,2,2);
    imagesc(rfPtsX,rfPtsY,reshape(avg_chan_resp,length(rfPtsY),length(rfPtsX)));
    title('Right, high-contrast, attended stimuli');
    axis equal xy off;

    % importantly, we want to be sure all the axes are on the same color-scale.
    % I wrote a function you can use for that called "match_clim", which takes
    % a set of axis handles as inputs, and optionally a new set of clim values
    % as a second argument. 

    match_clim(ax);


    %IPS0
    thisidx = tst_cond(:,1)<=-2.5 & tst_cond(:,2)==0;
    thisidx = tst_cond(:,3)==1;
    thisidx = 1;
    avg_chan_resp = mean(chan_resp_ips0(thisidx,:),1);
    figure;ax(1)=subplot(1,2,1);
    imagesc(rfPtsX,rfPtsY,reshape(avg_chan_resp,length(rfPtsY),length(rfPtsX)));
    title('Left, high-contrast, attended stimuli');
    axis equal xy off;

    % now compare to trials when the stimulus was on the right

    clear thisidx avg_chan_resp;
    thisidx = tst_cond(:,1)>=2.5 & tst_cond(:,2)==0;
    thisidx = tst_cond(:,3)==7;
    thisidx = 3;
    avg_chan_resp = mean(chan_resp_ips0(thisidx,:),1);
    ax(2)=subplot(1,2,2);
    imagesc(rfPtsX,rfPtsY,reshape(avg_chan_resp,length(rfPtsY),length(rfPtsX)));
    title('Right, high-contrast, attended stimuli');
    axis equal xy off;

    % importantly, we want to be sure all the axes are on the same color-scale.
    % I wrote a function you can use for that called "match_clim", which takes
    % a set of axis handles as inputs, and optionally a new set of clim values
    % as a second argument. 

    match_clim(ax);




    % It should be clear that the channels with RFs near the attended stimulus
    % position are those which are most active when that sitmulus is present &
    % attended.


    % Let's check out all the conditions - the easiest way to do this is have
    % one figure for stimuli on the left, and another figure for stimuli on the
    % right.
    
    ax = [];
    for rr = 1:n_runs
        rr
        trnIdx = rns~=ru(rr);
        tst_cond = cond;
        tst_cond(trnIdx,:) = 0;
        figure
        for stim_side = 1:2;
            for attn_cond = 1:6
                ax(end+1) = subplot(2,6,attn_cond+(6*(stim_side-1)));
                if stim_side ==1
                    thisidx = tst_cond(:,3)==attn_cond;
                    %thisidx = trn_cond(:,3)==attn_cond;
                end
                if stim_side ==2
                    thisidx = tst_cond(:,3)==attn_cond+(6*(stim_side-1));
                    %thisidx = trn_cond(:,3)==attn_cond+(6*(stim_side-1));
                end
                %avg_chan_resp = mean(chan_resp_v1(thisidx,:),1);
                avg_chan_resp = mean(chan_resp_ips0(thisidx,:),1);
                imagesc(rfPtsX,rfPtsY,reshape(avg_chan_resp,length(rfPtsY),length(rfPtsX)));
                axis equal xy tight;
                set(gca,'XTick',[],'YTick',[]); % turn off xtick/yticks
                clear thisidx avg_chan_resp;
            end
        end
    end
    match_clim(ax);
% Now ty to recover training examples
    ax = [];    
    for rr = 1:n_runs
        rr
        tstIdx = rns==ru(rr);
        tst_cond = cond;
        tst_cond(tstIdx,:) = 0;
        figure
        for stim_side = 1:2;
            for attn_cond = 1:6
                ax(end+1) = subplot(2,6,attn_cond+(6*(stim_side-1)));
                if stim_side ==1
                    thisidx = tst_cond(:,3)==attn_cond;
                    %thisidx = trn_cond(:,3)==attn_cond;
                end
                if stim_side ==2
                    thisidx = tst_cond(:,3)==attn_cond+(6*(stim_side-1));
                    %thisidx = trn_cond(:,3)==attn_cond+(6*(stim_side-1));
                end
                %avg_chan_resp = mean(chan_resp_v1_trn(thisidx,:,rr),1);
                avg_chan_resp = mean(chan_resp_ips0_trn(thisidx,:,rr),1);
                imagesc(rfPtsX,rfPtsY,reshape(avg_chan_resp,length(rfPtsY),length(rfPtsX)));
                axis equal xy tight;
                set(gca,'XTick',[],'YTick',[]); % turn off xtick/yticks
                clear thisidx avg_chan_resp;
            end
        end
    end
    match_clim(ax);

    %% Compute stimulus reconstructions from channel responses
    %
    % The channel response plots above are the *full* dataset, though sometimes
    % it is useful to compute a stimulus reconstruction that can be mroe easily
    % quanitfied by, e.g., curvefitting methods. Furthermore, the discrete
    % values above are challenging to "coregister" across different stimulus
    % position conditions (at least when stimuli are not simply at the same
    % position on different sides of the screen). Take for example a scenario
    % like Sprague, Ester & Serences, 2014 - during a spatial WM task, a
    % remembered stimulus appeared at a random position along a ring of a given
    % eccentricity. Because we were not interested in whether or not
    % representations for stimuli at different positions were different from
    % one another, we sought to average representations for stimuli at
    % different positions together. We did this by reconstructing an "image" of
    % the contents of WM via a weighted sum of the spatial filters for each
    % channel. Let's try that here.
    %
    % We have our basis_set, used to compute predicted channel responses, and
    % we have our estimated channel responses (chan_resp) - to compute the
    % weighted sum as an image, we just need to multiply the two.

    stim_reconstructions_v1 = chan_resp_v1 * basis_set.';

    stim_reconstructions_ips0 = chan_resp_ips0 * basis_set.';

    % Importantly, the dimensionality of each reconstruction remains equal to
    % the number of channels used, but this enables easy averaging of stimuli
    % at different positions (say, around a circular ring) by changing the
    % basis set in order to "undo" the stimulus manipulation performed. See
    % Sprague, Ester & Serences, 2014, for more details (Fig 2E). We won't go
    % over that here. This discussion is mainly to illustrate that we gain no
    % information in going from channel responses to stimulus reconstructions,
    % but the added ability to coregister and average different stimuli affords
    % better sensitivity to low-amplitude/low-SNR representations in stimulus
    % reconstructions. 

    % We can now do all the analyses we performed above on channel response
    % amplitudes instead on stimulus reconstructions. For example:

    clear ax;
    % trials when stimulus was on the left
    thisidx = tst_cond(:,1)<0 & tst_cond(:,2)==0;
    avg_reconstruction = mean(stim_reconstructions(thisidx,:),1);
    figure;ax(1)=subplot(1,2,1);
    imagesc(xx,yy,reshape(avg_reconstruction,res(2),res(1)));
    title('Left, high-contrast, attended stimuli');
    axis equal xy off;

    % now compare to trials when the stimulus was on the right

    clear thisidx avg_chan_resp;
    thisidx = tst_cond(:,1)>0 & tst_cond(:,2)==0;
    avg_reconstruction = mean(stim_reconstructions(thisidx,:),1);
    ax(2)=subplot(1,2,2);
    imagesc(xx,yy,reshape(avg_reconstruction,res(2),res(1)));
    title('Right, high-contrast, attended stimuli');
    axis equal xy off;

    match_clim(ax);


    %% combine non-like stimulus feature values
    %
    % One of the biggest advantages of the IEM technique is that by
    % transforming activation patterns into a "feature space" (here, spatial
    % information channels), you have full knowledge of how your activation is
    % related to feature values. Put another way, you know how to manipulate
    % your feature space in order to coregister non-like trials. For example,
    % here, we don't necessarily care too much about what may or may not be
    % different in stimulus reconstructions computed from trials in which
    % stimuli were on the left compared with trials when stimuli were on the
    % right. Accordingly, we can average these trials after "coregistering" the
    % reconstructions. Fortunately, this is an easy dataset to coregister. We
    % just need to flip the reconstructions across the vertical meridan for one
    % half of trials (sorted by trn_conds(:,1), which is the stimulus side). It
    % doesn't matter whether we flip left trials onto the right side of the
    % screen or vice versa. Try it below!

    % so that it's easy to "flip" the reconstructions, let's turn our
    % reconstruciton matrix, in which each reconstruction occupies a row (n_trials x n_pixels), 
    % into a reconstruction 3d-matrix in which each trial is the 3rd dimension,
    % and each "slice" is a single-trial's stimulus reconstruction. It's
    % easiest to make trial the 3rd dimension so that we don't need to
    % "squeeze" the data later on.

    stim_reconstructions_mat = reshape(stim_reconstructions',res(2),res(1),size(stim_reconstructions,1));

    % now, look for all trials with tst_cond(:,1)==1 and "coregister" them by 
    % flipping the slice of the matrix across the vertical axis (hint: FLIPLR)

    stim_reconstructions_mat(:,:,tst_conds(:,1)==1) = fliplr(stim_reconstructions_mat(:,:,tst_conds(:,1)==1));



    % now we can plot a similar figure as above, but with all trials on the
    % same plot.

    figure;ax = [];
    for attn_cond = 1:2
        for stim_contrast = 1:6
            ax(end+1) = subplot(6,2,attn_cond+(stim_contrast-1)*2);
            thisidx = tst_conds(:,2)==stim_contrast & tst_conds(:,3)==attn_cond & tst_conds(:,4)==0;

            imagesc(xx,yy,mean(stim_reconstructions_mat(:,:,thisidx),3));
            axis equal xy tight;
            if stim_contrast == 1
                title(task_str{attn_cond});
            end
            if attn_cond==1
                ylabel(sprintf('Contrast %i',stim_contrast));
            end
            set(gca,'XTick',[],'YTick',[]); % turn off xtick/yticks
            clear thisidx avg_chan_resp;
        end
    end
    match_clim(ax)
