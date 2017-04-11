%# Copyright (C) 2017 Schinzilord <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.

%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{TermForward} @var{spotrates_floored} @var{forwardrates}  @var{forwardrates_floored}] =} getFlooredSpotByFlooringForwardCurve(@var{TermSpot}, @var{SpotRates}, @var{floor_rate}, @var{term_forwardrate}, @var{basis}, @var{comp_type}, @var{comp_freq}, @var{interp_method})
%#
%# Compute the floored spot curve calculated by flooring the forward curve.
%# @*
%# Explanation of Input Parameters:
%# @itemize @bullet
%# @item @var{TermSpot}: is a 1xN vector with all timesteps of the given curve
%# @item @var{SpotRates}: is MxN matrix with curve rates defined in columns. Each 
%# row contains a specific scenario with different curve structure
%# @item @var{floor_rate}: is a scalar, specifiying the floor applied to forward rates
%# @item @var{term_forwardrate}: is a scalar, specifiying forward period
%# @item @var{basis}: (optional) day count convention of instrument (default: act/365)
%# @item @var{comp_type}: (optional) specifies compounding rule (simple, 
%# discrete, continuous (defaults to 'cont')).
%# @item @var{comp_freq}: (optional) compounding frequency (default: annual)
%# @item @var{interp_method}: (optional) specifies interpolation method for 
%# retrieving interest rates (defaults to 'linear').
%# @end itemize
%# @*
%# Explanation of Output Parameters:
%# @itemize @bullet
%# @item @var{TermForward}: 1xN vector with all timesteps for output curves
%# @item @var{spotrates_floored}: MxN matrix with floored spot curves
%# @item @var{forwardrates}: MxN matrix with forward curves
%# @item @var{forwardrates_floored}: MxN matrix with floored forward curves
%# @end itemize
%# @seealso{timefactor}
%# @end deftypefn

function [TermForward spotrates_floored forwardrates forwardrates_floored ] = getFlooredSpotByFlooringForwardCurve(TermSpot, ...
			SpotRates,floor_rate,term_forwardrate,basis,comp_type,comp_freq,interp_method)

% 0) Input checks
if nargin < 4 || nargin > 8
    print_usage ();
end

% default settings
if nargin < 5
   basis = 3;   %act/365
   comp_type = 'cont';
   comp_freq = 1;
   interp_method = 'linear';
elseif nargin == 5
   comp_type = 'cont';
   comp_freq = 1;
   interp_method = 'linear';
elseif nargin == 6
   comp_freq = 1;
   interp_method = 'linear';
elseif nargin == 7
   interp_method = 'linear';
end

% check for length of vectors
if ~(columns(TermSpot) == columns(SpotRates))
	error('getFlooredSpotByFlooringForwardCurve: columns of TermSpot and SpotRates does not match!')
end


if ( strcmpi(comp_type,'disc'))
	% error check compounding frequency
	if ischar(comp_freq)
		if ( strcmpi(comp_freq,'daily') || strcmpi(comp_freq,'day'))
			compounding = 365;
		elseif ( strcmpi(comp_freq,'weekly') || strcmpi(comp_freq,'week'))
			compounding = 52;
		elseif ( strcmpi(comp_freq,'monthly') || strcmpi(comp_freq,'month'))
			compounding = 12;
		elseif ( strcmpi(comp_freq,'quarterly')  ||  strcmpi(comp_freq,'quarter'))
			compounding = 4;
		elseif ( strcmpi(comp_freq,'semi-annual'))
			compounding = 2;
		elseif ( strcmpi(comp_freq,'annual') )
			compounding = 1;       
		else
			error('Need valid compounding frequency')
		end
	else
		compounding = comp_freq;
	end
else
	compounding = 1;
end

% A) calculate (floored) forward rates
	TermForwardEnd = TermSpot(end);
	TermForwardEnd / term_forwardrate;

	TermForward = [1:1:floor(TermForwardEnd/term_forwardrate)] .* term_forwardrate;

	forwardrates = zeros(rows(SpotRates),length(TermForward));
	forwardrates_floored = zeros(rows(SpotRates),length(TermForward));
	for ii =1:1:length(TermForward)
		tmp_rate = get_forward_rate(TermSpot,SpotRates,TermForward(ii),term_forwardrate, ...
									comp_type,interp_method,comp_freq,basis,0, ...
									comp_type,basis,comp_freq,false);
		forwardrates(:,ii) = tmp_rate; 
		forwardrates_floored(:,ii) = max(tmp_rate,floor_rate);
	end

% B) derive spot rates from (floored) forward rates via bootstrapping
%	Start with first forward rate (fsd = 0, fed = first term) equal to floored spot rate
	spotrates_floored = zeros(rows(SpotRates),length(forwardrates_floored));
	spotrates_floored(:,1) = max(SpotRates(:,1),floor_rate); % floor first rate
	for ii = 2:1:length(TermForward)
		% get forward start and end dates
		tmp_fed 	= TermForward(ii);
		tmp_fsd 	= TermForward(ii - 1);
		tmp_spot 	= spotrates_floored(:,ii-1);
		tmp_fwd 	= forwardrates_floored(:,ii-1);
		% calculate timefactors
		tf_spot 	= timefactor(0,tmp_fsd,basis);
		tf_forward 	= timefactor(tmp_fsd,tmp_fed,basis);
		tf_total 	= timefactor(0,tmp_fed,basis);
		% calculate spotrate depending on compounding type
		
		if ( strcmpi(comp_type,'simple') )
			spotrates_floored(:,ii) = ((1 + tmp_spot .* tf_spot) ...
							   .* (1 + tmp_fwd .* tf_forward) - 1 ) ./ tf_total;
		elseif ( strcmpi(comp_type,'disc'))
			spotrates_floored(:,ii) = (  ( 1 + (tmp_spot ./ compounding) ).^(compounding .* tf_spot) ...
                .* ( 1 + (tmp_fwd ./ compounding) ).^(compounding .* tf_forward) ) ...
                .^(1 ./ tf_total) - 1;
		elseif ( strcmpi(comp_type,'cont')  || strcmpi(comp_type,'continuous') )
			spotrates_floored(:,ii) = (tmp_fwd .* tf_forward + ...
											tmp_spot .* tf_spot ) ./ tf_total ;
		else
			error('Need valid comp_type type [disc, simple, cont]')
		end
	end

end


%!test
%! TermSpot = [365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125,9490,9855,10220,10585,10950,11315,11680,12045,12410,12775,13140,13505,13870,14235,14600,14965,15330,15695,16060,16425,16790,17155,17520,17885,18250,18615,18980,19345,19710,20075,20440,20805,21170,21535,21900,22265];
%! SpotRates = [-0.00446402680389115,-0.00449040379647095,-0.00439108078905075,-0.00409644778163055,-0.00369144477421035,-0.00240257778818095,-0.00130182080215155,-0.00052702381612215,0.000577373169907252,0.00124309515593665,0.00229890469470163,0.0031892792334666,0.00382737377223158,0.00431041831099656,0.00512937284976153,0.00583233738852651,0.00634735192729148,0.00673734646605646,0.00705045100482143,0.00732130554358641,0.00739315558080373,0.00748193561802104,0.00761294565523836,0.00780441569245568,0.00807142572967299,0.00841923576689031,0.00883000580410763,0.00928351584132494,0.00976751587854226,0.0102699659157596,0.0107824459529769,0.0112972459901942,0.0118122060274115,0.0123224160646288,0.0128251561018462,0.0133171561390635,0.0137995561762808,0.0142700562134981,0.0147281562507154,0.0151721562879327,0.0156042563251501,0.0160232563623674,0.0164292563995847,0.016821456436802,0.0172021564740193,0.0175705565112366,0.017927156548454,0.0182713565856713,0.0186052566228886,0.0189284566601059,0.0192413566973232,0.0195434567345405,0.0198367567717579,0.0201209568089752,0.0203962568461925,0.0206625568834098,0.0209212569206271,0.0211722569578444,0.0214158569950618,0.0216516570322791,0.0218657570322791;
%! 			-0.00446402680389115,-0.00449040379647095,-0.00439108078905075,-0.00409644778163055,-0.00369144477421035,-0.00240257778818095,-0.00130182080215155,-0.00052702381612215,0.000577373169907252,0.00124309515593665,0.00229890469470163,0.0031892792334666,0.00382737377223158,0.00431041831099656,0.00512937284976153,0.00583233738852651,0.00634735192729148,0.00673734646605646,0.00705045100482143,0.00732130554358641,0.00739315558080373,0.00748193561802104,0.00761294565523836,0.00780441569245568,0.00807142572967299,0.00841923576689031,0.00883000580410763,0.00928351584132494,0.00976751587854226,0.0102699659157596,0.0107824459529769,0.0112972459901942,0.0118122060274115,0.0123224160646288,0.0128251561018462,0.0133171561390635,0.0137995561762808,0.0142700562134981,0.0147281562507154,0.0151721562879327,0.0156042563251501,0.0160232563623674,0.0164292563995847,0.016821456436802,0.0172021564740193,0.0175705565112366,0.017927156548454,0.0182713565856713,0.0186052566228886,0.0189284566601059,0.0192413566973232,0.0195434567345405,0.0198367567717579,0.0201209568089752,0.0203962568461925,0.0206625568834098,0.0209212569206271,0.0211722569578444,0.0214158569950618,0.0216516570322791,0.0218657570322791];
%! finalShockCurve = [1e-04,1e-04,1e-04,1e-04,1e-04,0.00075695952366101,0.00140635403657013,0.00184262916775932,0.00268373137780189,0.00313881754304183,0.00402228868297906,0.00476904788938758,0.00528562176231249,0.0056645057303574,0.00639318777449832,0.00701716388046724,0.0074624827432357,0.00779052557000378,0.00804819962961363,0.008269166737139,0.00829588052704429,0.00834362761215976,0.0084371727800667,0.00859430002041617,0.00882971468451506,0.00914835976193076,0.00953212520673918,0.00996055955100536,0.0104212132534061,0.010901873378128,0.011393969303656,0.0118896592361646,0.0123866673568373,0.0128799814726009,0.0133667910695905,0.0138437456910371,0.0143119135782011,0.0147689305258942,0.0152142389140757,0.015646086884709,0.0160666276390781,0.0164746188354876,0.0168701220710045,0.0172523024338714,0.0176234281155982,0.0179826700736508,0.0183305017371997,0.0186662987496515,0.018992138742706,0.0193076011375269,0.0196130669693046,0.0199080187320608,0.020194440241023,0.0204720165102909,0.020740933643848,0.02100107873825,0.0212538397955579,0.0214991056452764,0.0217371658742321,0.0219676107634633,0.0221765311940996];
%! term_forwardrate = 365;
%! floor_rate = 0.0001;
%! basis = 'act/365';
%! comp_type = 'cont';
%! comp_freq = 'annual';
%! interp_method = 'linear';
%! [TermForward spotrates_floored forwardrates forwardrates_floored  ] = getFlooredSpotByFlooringForwardCurve(TermSpot,SpotRates,floor_rate,term_forwardrate);
%! assert(spotrates_floored(1,:), finalShockCurve,0.0000001)
