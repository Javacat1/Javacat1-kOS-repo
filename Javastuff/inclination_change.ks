CLEARSCREEN.
parameter ship_orbit is ship:orbit.
local eccentricity is ship_orbit:eccentricity.
local t is ship_orbit:epoch.
local b is ship_orbit:body.
local ndv is 0. //Initial node Delta V
local node is 0.
local thrt is 0. //for throttle
local tgtd is SHIP:FACING. //flight target direction
local eng is 0.
local done is 0.
local mf is 0.
local flow is 0.
local md is 0.
local burnt is 0.
local engine_flow is 0. //for multiple engine calculation
local engine_thrust is 0. //for multiple engine calculation
local avg_isp is 0. //for multiple engine calculation
LOCK Throttle to thrt.
LOCK Steering to tgtd.
local AN_true_anomaly is 360-obt:argumentofperiapsis.
local DN_true_anomaly is mod(AN_true_anomaly+180,360).
local AN_eccentric_anomaly is mod(360+arctan2(sqrt(1-eccentricity^2)*sin(AN_true_anomaly), eccentricity+cos(AN_true_anomaly)),360).
local AN_mean_anomaly is AN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(AN_eccentric_anomaly).
local AN_true_anomaly_to_AP is abs(AN_true_anomaly - 180).
local DN_true_anomaly_to_AP is abs(DN_true_anomaly - 180).
local node_timestamp is 0.
local AN_eccentric_anomaly is mod(360+arctan2(sqrt(1-eccentricity^2)*sin(AN_true_anomaly), eccentricity+cos(AN_true_anomaly)),360).
local AN_mean_anomaly is AN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(AN_eccentric_anomaly).
local base_meananomaly is ship_orbit:meananomalyatepoch.
local base_time is ship_orbit:epoch.
local AN_timestamp is mod(360+AN_mean_anomaly-base_meananomaly,360)/sqrt(b:mu/ship_orbit:semimajoraxis^3)/constant:RadToDeg + base_time.
local DN_eccentric_anomaly is mod(360+arctan2(sqrt(1-eccentricity^2)*sin(DN_true_anomaly), eccentricity+cos(DN_true_anomaly)),360).
local DN_mean_anomaly is DN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(DN_eccentric_anomaly).
local DN_timestamp is mod(360+DN_mean_anomaly-base_meananomaly,360)/sqrt(b:mu/ship_orbit:semimajoraxis^3)/constant:RadToDeg + base_time.
set node_timestamp to choose AN_timestamp if AN_true_anomaly_to_AP < DN_true_anomaly_to_AP else DN_timestamp.
local rs is positionat(ship,node_timestamp)-b:position.
local vs is velocityat(ship,node_timestamp):obt.
local ns is vcrs(vs,rs):normalized.
local v_tangential is vcrs(rs,ns):normalized * vs.
local nt is -body:angularvel:normalized.
local v_tangential is vcrs(rs,ns):normalized * vs.
local v_radial is rs:normalized * vs.
set dv to v_radial * rs:normalized + v_tangential * vcrs(rs,nt):normalized - vs.
SET node_prograde to dv * vs:normalized. 
SET node_radialout to dv * vxcl(vs,rs):normalized. 
SET node_normal to dv * vcrs(vs,rs):normalized. 
SET node to NODE(node_timestamp, node_radialout, node_normal, node_prograde).
ADD node.
List ENGINES in englist. //engines list
For eng in englist {
	If eng:ignition {
		Set engine_flow to engine_flow + (eng:availablethrust/(eng:ISP*Constant:g0)).
		Set engine_thrust to engine_thrust + eng:availablethrust.
	}.
}.
Set avg_isp to engine_thrust/engine_flow.
SET mf to SHIP:MASS/(Constant:e^(NODE:DELTAV:MAG/(avg_isp*Constant:g0))).
SET flow to SHIP:MAXTHRUST/(avg_isp*Constant:g0).
SET md to SHIP:MASS-mf.
SET burnt to md/flow.
RCS OFF.
Print "Burn time is " + burnt + "seconds".
Wait Until node:eta <=(burnt/2 + 60).
RCS On.
Print "60 Seconds to burn".
SET tgtd to NODE:DELTAV.
Wait Until vang(tgtd, SHIP:FACING:VECTOR) < 0.25. 
Print "aligned to node".
Wait Until NODE:ETA <= (burnt/2).
Print "Burning".
SET ndv to NODE:DELTAV.
Until done {
	SET thrt to min(NODE:DELTAV:MAG/(SHIP:MAXTHRUST/SHIP:MASS), 1).
	SET tgtd to NODE:DELTAV.
	If NODE:DELTAV:MAG < 0.1 {
		Print "Burn Finalizing".
		Wait Until vdot(ndv, NODE:DELTAV) < 0.5.
		SET thrt to 0.
		SET done to True.
	}.
	Wait 0.
}.
REMOVE node.
Print "Inclination Corrected. Manual Control".
UNLOCK ALL.
Run once Transfer.ks.