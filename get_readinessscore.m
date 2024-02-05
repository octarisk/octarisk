%# Copyright (C) 2019 Stefan Schlögl <schinzilord@octarisk.com>
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
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.
 
%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{score} ] =} get_readinessscore(@var{isocode})
%#
%# Map the ISO-2 currency code to ND-GAIN readiness risk score.
%# See https://gain.nd.edu/our-work/country-index/methodology/ for further information.
%# @end deftypefn

function score = get_readinessscore(isocode)

if nargin < 1
    error('get_readinessscore: no country iso code provided.\n');
end

if nargin > 1
    fprintf('get_readinessscore: ignoring further argument(s).\n');
end
if ~(ischar(isocode))
    error('get_readinessscore: isocode not a string >>%s<<..\n',any2str(isocode));
end

% dictionary with all iso codes and their mapping to the INFORM risk score:

% manual update: map Hong Kong (HK) and Taiwan (TW) to China (CN)
if strcmpi(isocode,'TW') || strcmpi(isocode,'HK')
	isocode = 'CN';
end

% map iso-2 code to iso-3 code:
iso3 = map_country_isocodes(isocode);


% last update from https://gain.nd.edu/our-work/country-index/rankings/ 20240204: 2021 data for resources/readiness/readiness.csv
% =CONCATENATE("'",A2,"',",B2,", ...")

inform = struct(   ...
                'AFG',0.246442145333371, ...
				'ALB',0.410559121234659, ...
				'DZA',0.33334509314068, ...
				'AND',0.478714965470705, ...
				'AGO',0.268117798333208, ...
				'ATG',0.449260130429268, ...
				'ARG',0.376037316185072, ...
				'ARM',0.50573276439272, ...
				'AUS',0.690552124980166, ...
				'AUT',0.68230738466746, ...
				'AZE',0.447625682772037, ...
				'BHS',0.427831425066084, ...
				'BHR',0.519334145918882, ...
				'BGD',0.281041117917878, ...
				'BRB',0.53612684461446, ...
				'BLR',0.490112049917615, ...
				'BEL',0.600207432355383, ...
				'BLZ',0.333388191619152, ...
				'BEN',0.337878182675485, ...
				'BTN',0.483057133272884, ...
				'BOL',0.285575320993661, ...
				'BIH',0.365011698800217, ...
				'BWA',0.435281034527861, ...
				'BRA',0.352189900720644, ...
				'BRN',0.53483389164747, ...
				'BGR',0.465516582817461, ...
				'BFA',0.288728125748664, ...
				'BDI',0.267448274803181, ...
				'KHM',0.288194806059589, ...
				'CMR',0.26106690867762, ...
				'CAN',0.649978713029132, ...
				'CPV',0.451801829242007, ...
				'CAF',0.1375591376644, ...
				'TCD',0.190699471593662, ...
				'CHL',0.534454195081214, ...
				'CHN',0.553517588282449, ...
				'COL',0.370442347549278, ...
				'COM',0.282299505900384, ...
				'COG',0.224438147933123, ...
				'COD',0.211885138899873, ...
				'CRI',0.452252376111086, ...
				'CIV',0.309122416860386, ...
				'HRV',0.487970102751274, ...
				'CUB',0.352805711408914, ...
				'CYP',0.519999824249797, ...
				'CZE',0.560700419800513, ...
				'DNK',0.779030737720829, ...
				'DJI',0.32248454215365, ...
				'DMA',0.520670384116794, ...
				'DOM',0.363155330917451, ...
				'ECU',0.345680347986533, ...
				'EGY',0.352602567800585, ...
				'SLV',0.339460633481699, ...
				'GNQ',0.245496555754978, ...
				'ERI',0.220332066245631, ...
				'EST',0.62035371104656, ...
				'ETH',0.296644904496383, ...
				'FJI',0.478050372876623, ...
				'FIN',0.75333429246666, ...
				'FRA',0.652971827383289, ...
				'GAB',0.301743181871817, ...
				'GMB',0.322245367857833, ...
				'GEO',0.56918169824784, ...
				'DEU',0.691691591276193, ...
				'GHA',0.347197281079318, ...
				'GRC',0.533062293350088, ...
				'GRD',0.478677191183481, ...
				'GTM',0.31114852467828, ...
				'GIN',0.308539672726354, ...
				'GNB',0.275340151042531, ...
				'GUY',0.321524527403582, ...
				'HTI',0.224116716913147, ...
				'HND',0.259881918751636, ...
				'HUN',0.500534578388166, ...
				'ISL',0.720612612108791, ...
				'IND',0.389243162219222, ...
				'IDN',0.392072477529295, ...
				'IRN',0.380676903126441, ...
				'IRQ',0.300762103892975, ...
				'IRL',0.599930574533736, ...
				'ISR',0.542475367884345, ...
				'ITA',0.528435439662085, ...
				'JAM',0.407936091387755, ...
				'JPN',0.690355888096363, ...
				'JOR',0.409060605913051, ...
				'KAZ',0.517561575966312, ...
				'KEN',0.302249306658264, ...
				'KIR',0.448070135836187, ...
				'PRK',0.341387141812213, ...
				'KOR',0.728628642519787, ...
				'KWT',0.463856448767189, ...
				'KGZ',0.39610485596509, ...
				'LAO',0.335982734024311, ...
				'LVA',0.585590039038051, ...
				'LBN',0.286414526942658, ...
				'LSO',0.306577258074482, ...
				'LBR',0.283083134199108, ...
				'LBY',0.280532279976254, ...
				'LIE',0.636907445295931, ...
				'LTU',0.599581362317969, ...
				'LUX',0.670269218418277, ...
				'MKD',0.46888320937586, ...
				'MDG',0.26335033523937, ...
				'MWI',0.294208206889221, ...
				'MYS',0.506829949294301, ...
				'MDV',0.445659339841081, ...
				'MLI',0.288187213729466, ...
				'MLT',0.501001597432243, ...
				'MHL',0.365102670215741, ...
				'MRT',0.35655185077059, ...
				'MUS',0.567298727976744, ...
				'MEX',0.360404521288543, ...
				'FSM',0.35901674130701, ...
				'MDA',0.441634471519961, ...
				'MCO',0.759914535367625, ...
				'MNG',0.459580441142239, ...
				'MNE',0.465474291212242, ...
				'MAR',0.428190939863482, ...
				'MOZ',0.262655352343329, ...
				'MMR',0.257304560172515, ...
				'NAM',0.380351963309832, ...
				'NRU',0.49342589235893, ...
				'NPL',0.361060277079129, ...
				'NLD',0.686860447592992, ...
				'NZL',0.700840497649587, ...
				'NIC',0.27209211176786, ...
				'NER',0.341493817866521, ...
				'NGA',0.256263058852615, ...
				'NOR',0.762780591284391, ...
				'OMN',0.500333864470159, ...
				'PAK',0.313151216696585, ...
				'PLW',0.426781106465084, ...
				'PAN',0.37558058607094, ...
				'PNG',0.28299987579688, ...
				'PRY',0.339978989015479, ...
				'PER',0.390264900504474, ...
				'PHL',0.336969203815654, ...
				'POL',0.541488169712384, ...
				'PRT',0.577479892748329, ...
				'QAT',0.542601955597643, ...
				'ROU',0.43883517052768, ...
				'RUS',0.547572122021314, ...
				'RWA',0.429419128790523, ...
				'KNA',0.556189321294421, ...
				'LCA',0.454341257914219, ...
				'VCT',0.473974757664791, ...
				'WSM',0.439233432063704, ...
				'SMR',0.63884343193207, ...
				'STP',0.368467386674205, ...
				'SAU',0.548313546782412, ...
				'SEN',0.349707443447232, ...
				'SRB',0.44459693488857, ...
				'SYC',0.473056860162436, ...
				'SLE',0.301200367809876, ...
				'SGP',0.805360836304684, ...
				'SVK',0.509673666560524, ...
				'SVN',0.601436501748941, ...
				'SLB',0.395643041989466, ...
				'SOM',0.353203178853356, ...
				'ZAF',0.355885537465633, ...
				'ESP',0.539452471862296, ...
				'LKA',0.398622205167377, ...
				'SDN',0.261012994420174, ...
				'SUR',0.333243249899891, ...
				'SWZ',0.316023339223037, ...
				'SWE',0.724478883051999, ...
				'CHE',0.694441061791215, ...
				'SYR',0.227445004357556, ...
				'TJK',0.324935883020651, ...
				'TZA',0.304678683988324, ...
				'THA',0.482939085927613, ...
				'TLS',0.374739882818128, ...
				'TGO',0.355017584042284, ...
				'TON',0.426455448392996, ...
				'TTO',0.33777437131194, ...
				'TUN',0.43570915894476, ...
				'TUR',0.483143204439118, ...
				'TKM',0.23414007860401, ...
				'TUV',0.612927050347907, ...
				'UGA',0.283635599755408, ...
				'UKR',0.427721913746203, ...
				'ARE',0.585129596207752, ...
				'GBR',0.68502653368568, ...
				'USA',0.65634729662513, ...
				'URY',0.508966689607352, ...
				'UZB',0.408217634958793, ...
				'VUT',0.38392649734739, ...
				'VEN',0.187419084259151, ...
				'VNM',0.425831102772359, ...
				'YEM',0.243635289083702, ...
				'ZMB',0.323668187427337, ...
				'ZWE',0.217533679070575
            );
                       
if ~(isfield(inform,upper(iso3)))
    error('get_readinessscore: no valid country iso code >>%s<< provided.\n',isocode);
end                       
% map the string to the number 1:length(dcc_cell):
score = getfield(inform,upper(iso3));
end 

%!assert(get_readinessscore('DE'),0.691691591276193)

