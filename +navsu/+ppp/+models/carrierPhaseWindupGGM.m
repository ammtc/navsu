function [phwindup] = carrierPhaseWindupGGM(epochi, XR, XS, phwindup)

% SYNTAX:
%   [phwindup] = phase_windup_correction(time, XR, XS, SP3, phwindup);
%
% INPUT:
%   time = GPS time
%   XR   = receiver position  (X,Y,Z)
%   XS   = satellite position (X,Y,Z)
%   SP3  = structure containing precise ephemeris data
%   phwindup = phase wind-up (previous value)
%
% OUTPUT:
%   phwindup = phase wind-up (updated value)
%
% DESCRIPTION:
%   Computation of the phase wind-up terms.

%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 0.5.1 beta 3
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2017 Mirko Reguzzoni, Eugenio Realini
%  Written by:
%  Contributors:     ...
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------

%east (a) and north (b) local unit vectors
% phwindup = zeros(size(XS,1),1);
for s = 1 : size(XS,1)
    llh = navsu.geo.xyz2llh(XR(s,:));
    phi = llh(1)*pi/180;
    lam = llh(2)*pi/180;
    a = [-sin(lam); cos(lam); 0];
    b = [-sin(phi)*cos(lam); -sin(phi)*sin(lam); cos(phi)];
    
    
    %satellite-fixed local unit vectors
    %     [i, j, k] = satellite_fixed_frame(time, XS(s,:)', SP3);
    if s == 1
        [R,sunpos] = navsu.geo.svLocalFrame(XS(s,:),epochi);
    else
        R = navsu.geo.svLocalFrame(XS(s,:),epochi,sunpos);
    end
    i = R(:,1); j = R(:,2); k = R(:,3);
    
    %receiver and satellites effective dipole vectors
    Dr = a - k*dot(k,a) + cross(k,b);
    Ds = i - k*dot(k,i) - cross(k,j);
    
    %phase wind-up computation
    psi = dot(k, cross(Ds, Dr));
    arg = dot(Ds,Dr)/(norm(Ds)*norm(Dr));
    if (arg < -1)
        arg = -1;
    elseif (arg > 1)
        arg = 1;
    end
    dPhi = sign(psi)*acos(arg)/(2*pi);
    if (isempty(phwindup) || phwindup(s,1) == 0)
        N = 0;
    else
        N = round(phwindup(s,1) - dPhi);
    end
    phwindup(s,1) = dPhi + N;
end

phwindup(isnan(phwindup)) = 0;
