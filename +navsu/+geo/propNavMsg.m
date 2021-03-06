function pos = propNavMsg(beph, prn, const, epochs, varargin)
% propNavMsg  Propagate navigation messages for various constellations to
% desired times for desired satellites
% INPUTS:
%   beph   - broadcast ephemeris structure- output of navsu.readfiles.loadRinexNav
%   prn    - Nx1 vector of desired PRN to propagate
%   const  - Nx1 vector of constellation index associated with the
%            previously described prn input
%   epochs - Nx1 vector of desired propagation time in seconds since GPS
%            time start
%
% OUTPUTS:
%   pos    - structure containing lots of data from the navigation message
%    .x            - ECEF x position [m]
%    .y            - ECEF y position [m]
%    .z            - ECEF z position [m]
%    .x_dot        - ECEF x velocity [m]
%    .y_dot        - ECEF y velocity [m]
%    .z_dot        - ECEF z velocity [m]
%    .clock_bias   - satellite clock bias [s]
%    .clock_drift  - satellite clock drift [s/s]
%    .clock_rel    - relativistic clock correction [s]
%    .accuracy     - URA or SISA- should be [m] but sometimes is incorrectly
%                    logged and may be index
%    .health       - health flag
%    .IODC         - issue of data clock
%    .t_m_toe      - time of propagation minus time of ephemeris
%    .tslu         - time since last upload to the satellite from the CS
%    .toe_m_ttom   - time of ephemeris minus time tag of message (when the
%                    received first logged the nav message)
%    .Fit_interval - time of validity of the nav message [s]
%    .TGD          - timing group delay
%    .t_m_toc      - time of propagation minus time of clock
%    .freqNum      - GLONASS frequency index

% prn, const, and epochs must all be the same size
if ~isequal(size(prn),size(const),size(epochs))
   error('Inputs must be the same size')
end

nProp = length(prn);

% Initialize the output structure
pos = struct('x', NaN(nProp, 1), 'y', NaN(nProp, 1), 'z', NaN(nProp, 1), ...
    'x_dot', NaN(nProp, 1), 'y_dot', NaN(nProp, 1), 'z_dot', NaN(nProp, 1), ...
    'clock_bias', NaN(nProp, 1), 'clock_drift', NaN(nProp, 1),'clock_rel', NaN(nProp, 1), ...
    'accuracy', NaN(nProp, 1), 'health', NaN(nProp, 1), ...
	'IODC', NaN(nProp, 1), 't_m_toe', NaN(nProp, 1), ...
    'tslu', NaN(nProp, 1), 'toe_m_ttom', NaN(nProp, 1), ...
    'Fit_interval', NaN(nProp, 1),'TGD',NaN(nProp,1),'t_m_toc',NaN(nProp,1),...
    'freqNum',nan(nProp,1));

% Inputs to the subfunctions are actually week number and time of week 
[weeks,tows] = navsu.time.epochs2gps(epochs);


% Loop through each potential constellation and do the propgation for that
constFull = [1 2 3 4];  % GPS GLO GAL BDS QZSS

for cdx = constFull
   % Input indices for this constellation
   indsi = const == constFull(cdx);
   
   if ~any(indsi)
       continue;
   end
   
   switch constFull(cdx)
       case 1 
           % GPS 
           posi = navsu.geo.propNavMsgGps(beph.gps,prn(indsi),weeks(indsi),...
               tows(indsi),'GPS');

       case 2
           % GLONASS
           posi = navsu.geo.propNavMsgGlo(beph.glo,prn(indsi),weeks(indsi),...
               tows(indsi));
           
       case 3
           % Galileo
           posi = navsu.geo.propNavMsgGps(beph.gal,prn(indsi),weeks(indsi),...
               tows(indsi),'GAL');
           
       case 4
           % BeiDou
            posi = navsu.geo.propNavMsgGps(beph.bds,prn(indsi),weeks(indsi),...
               tows(indsi),'BDS');
           
       otherwise
           warning('This constellation is not supported- sorry')
   end
   
   % Put this data into the output structure
   fieldNames = fields(posi);
   for fdx = 1:length(fieldNames)
       pos.(fieldNames{fdx})(indsi) = posi.(fieldNames{fdx}); 
   end
    
end







end