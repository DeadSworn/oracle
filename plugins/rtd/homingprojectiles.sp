/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*******************************************//
//  -  Roll The Dice: Homing Projectiles  -  //
//*******************************************//

#define HOMING_SPEED 0.5
#define HOMING_REFLE 1.1

#define MINICRIT TFCond_Buffed
#define FULLCRIT TFCond_CritOnFirstBlood

bool	g_bHasHomingProjectiles[MAXPLAYERS+1] = {false, ...};
Handle	g_hArrayHoming;
int		g_iHomingCrits = 0;

void HomingProjectiles_Proc(const char[] sSettings){

	g_iHomingCrits = StringToInt(sSettings);

}

void HomingProjectiles_Start(){

	delete g_hArrayHoming;
	g_hArrayHoming = CreateArray(2);
	HookEvent("teamplay_round_start", Event_HomingProjectiles_RoundStart);

}

void HomingProjectiles_Perk(int client, bool apply){

	if(apply)
		HomingProjectiles_ApplyPerk(client);
	else
		HomingProjectiles_RemovePerk(client);

}

void HomingProjectiles_ApplyPerk(int client){

	g_bHasHomingProjectiles[client] = true;

	if(g_iHomingCrits > 0)
		TF2_AddCondition(client, g_iHomingCrits < 2 ? MINICRIT : FULLCRIT);

}

void HomingProjectiles_RemovePerk(int client){

	g_bHasHomingProjectiles[client] = false;
	
	if(g_iHomingCrits > 0)
		TF2_RemoveCondition(client, g_iHomingCrits < 2 ? MINICRIT : FULLCRIT);

}

public void Event_HomingProjectiles_RoundStart(Handle hEvent, const char[] strEventName, bool bDontBroadcast){

	ClearArray(g_hArrayHoming);

}

//Just copy every bit of code from the original RTD!

void HomingProjectiles_OnEntityCreated(int iEnt, const char[] sClassname){

	if(!IsAcceptableForHoming(sClassname))
		return;
	
	if(!IsHomingPerkPresent())
		return;
	
	CreateTimer(0.2, Timer_HomingProjectiles_CheckOwnership, EntIndexToEntRef(iEnt));

}

public Action Timer_HomingProjectiles_CheckOwnership(Handle hTimer, any iRef){

	int iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Stop;
	
	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	
	if(iLauncher < 1 || !IsValidClient(iLauncher) || !IsPlayerAlive(iLauncher))
		return Plugin_Stop;
	
	if(!g_bHasHomingProjectiles[iLauncher])
		return Plugin_Stop;
	
	if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0)
		return Plugin_Stop;
	
	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);
	
	int iData[2];
	iData[0] = EntIndexToEntRef(iProjectile);
	PushArrayArray(g_hArrayHoming, iData);
	
	return Plugin_Stop;

}

void HomingProjectiles_OnGameFrame(){

	int iArrayHomingLength = GetArraySize(g_hArrayHoming)-1;
	for(int i = iArrayHomingLength; i >= 0; i--){
	
		int iData[2];
		GetArrayArray(g_hArrayHoming, i, iData);
		
		if(iData[0] == 0){
		
			RemoveFromArray(g_hArrayHoming, i);
			continue;
		
		}
		
		int iProjectile = EntRefToEntIndex(iData[0]);
		if(iProjectile > MaxClients)
			HomingProjectile_Think(iProjectile, iData[0], i, iData[1]);
		else
			RemoveFromArray(g_hArrayHoming, i);
		
	}

}

public void HomingProjectile_Think(int iProjectile, int iRefProjectile, int iArrayIndex, int iCurrentTarget){

	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam))
		HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex);
	else
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile);
	
}

bool HomingProjectile_IsValidTarget(int client, int iProjectile, int iTeam){

	if(client < 1 || client > MaxClients)return false;
	if(!IsClientInGame(client))			return false;
	if(!IsPlayerAlive(client))			return false;
	if(GetClientTeam(client) == iTeam)	return false;
	
	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return false;
	
	if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		return false;
	
	if(IsPlayerFriendly(client))
		return false;
	
	return CanEntitySeeTarget(iProjectile, client);
	
}

void HomingProjectile_FindTarget(int iProjectile, int iRefProjectile, int iArrayIndex){

	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	float fPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fPos1);
	
	int iBestTarget;
	float fBestLength = 99999.9;
	for(int i = 1; i <= MaxClients; i++){
	
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam)){
		
			float fPos2[3];
			GetClientEyePosition(i, fPos2);
			
			float fDistance = GetVectorDistance(fPos1, fPos2);
			
			if(fDistance < fBestLength)
			{
				iBestTarget = i;
				fBestLength = fDistance;
			}
		}
	}
	
	if(iBestTarget >= 1 && iBestTarget <= MaxClients){
	
		int iData[2];
		iData[0] = iRefProjectile;
		iData[1] = iBestTarget;
		SetArrayArray(g_hArrayHoming, iArrayIndex, iData);
		
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
	
	}else{
	
		int iData[2];
		iData[0] = iRefProjectile;
		iData[1] = 0;
		SetArrayArray(g_hArrayHoming, iArrayIndex, iData);
	
	}

}

void HomingProjectile_TurnToTarget(int client, int iProjectile){

	float fTargetPos[3], fRocketPos[3], fInitialVelocity[3];
	GetClientAbsOrigin(client, fTargetPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fRocketPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fInitialVelocity);
	
	float fSpeedInit = GetVectorLength(fInitialVelocity);
	float fSpeedBase = fSpeedInit *HOMING_SPEED;
	
	fTargetPos[2] += 30 +Pow(GetVectorDistance(fTargetPos, fRocketPos), 2.0) /10000;
	
	float fNewVec[3], fAng[3];
	SubtractVectors(fTargetPos, fRocketPos, fNewVec);
	NormalizeVector(fNewVec, fNewVec);
	GetVectorAngles(fNewVec, fAng);

	float fSpeedNew = fSpeedBase +GetEntProp(iProjectile, Prop_Send, "m_iDeflected") *fSpeedBase *HOMING_REFLE;
	
	ScaleVector(fNewVec, fSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, fAng, fNewVec);

}

stock bool IsAcceptableForHoming(const char[] sClassname){

	if(strcmp(sClassname, "tf_projectile_rocket")		== 0
	|| strcmp(sClassname, "tf_projectile_arrow")		== 0
	|| strcmp(sClassname, "tf_projectile_flare")		== 0
	|| strcmp(sClassname, "tf_projectile_energy_ball")	== 0
	|| strcmp(sClassname, "tf_projectile_healing_bolt")	== 0)
		return true;
	
	return false;

}

stock bool IsHomingPerkPresent(){

	for(int i = 1; i <= MaxClients; i++){
	
		if(!IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;
		
		if(g_bHasHomingProjectiles[i])
			return true;

	}
	
	return false;

}