/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//******************************//
//  -  Roll The Dice: Toxic  -  //
//******************************//

#define TOXIC_PARTICLE "eb_aura_angry01"

float	g_fToxicRange		= 128.0;
float	g_fToxicInterval	= 0.25;
float	g_fToxicDamage		= 24.0;

bool	g_bIsToxic[MAXPLAYERS+1]		= {false, ...};
int		g_iToxicParticle[MAXPLAYERS+1]	= {INVALID_ENT_REFERENCE, ...};

void Toxic_Proc(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_fToxicRange		= StringToFloat(sPieces[0]);
	g_fToxicInterval	= StringToFloat(sPieces[1]);
	g_fToxicDamage		= StringToFloat(sPieces[2]);

}

void Toxic_Perk(int client, bool apply){

	if(apply)
		Toxic_ApplyPerk(client);
	
	else
		g_bIsToxic[client] = false;

}

void Toxic_ApplyPerk(int client){

	g_bIsToxic[client]		 = true;
	g_iToxicParticle[client] = EntIndexToEntRef(CreateParticle(client, TOXIC_PARTICLE));
	
	CreateTimer(g_fToxicInterval, Timer_Toxic, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_Toxic(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))	return Plugin_Stop;
	
	if(!g_bIsToxic[client]){
	
		int iParticle = EntRefToEntIndex(g_iToxicParticle[client]);
		if(iParticle > MaxClients && IsValidEntity(iParticle))
			AcceptEntityInput(iParticle, "Kill");
		
		g_iToxicParticle[client] = INVALID_ENT_REFERENCE;
		
		return Plugin_Stop;
	
	}
	
	Toxic_HurtSurroundings(client);
	
	return Plugin_Continue;

}

void Toxic_HurtSurroundings(client){

	if(!IsValidClient(client)) return;
	
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(!Toxic_IsValidTargetFor(client, i)) continue;
		
		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);
		
		float fDistance = GetVectorDistance(fClientPos, fTargetPos);
		if(fDistance < g_fToxicRange)
			SDKHooks_TakeDamage(i, 0, client, g_fToxicDamage, DMG_BLAST);
	
	}

}

stock bool Toxic_IsValidTargetFor(int client, int target){

	if(client == target)
		return false;
	
	if(!IsClientInGame(target))
		return false;
		
	if(!IsPlayerAlive(target))
		return false;
	
	if(!CanEntitySeeTarget(client, target))
		return false;
	
	return CanPlayerBeHurt(target, client);

}