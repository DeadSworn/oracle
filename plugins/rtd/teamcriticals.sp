/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***************************************//
//  -  Roll The Dice: Team Criticals  -  //
//***************************************//

#define MINICRIT TFCond_Buffed
#define FULLCRIT TFCond_CritOnFirstBlood

float	g_fTeamCritsRange	= 270.0;
bool	g_bTeamCritsFull	= true;

bool	g_bHasTeamCriticals[MAXPLAYERS+1] = {false, ...};
int		g_iCritBoostEnt[MAXPLAYERS+1][MAXPLAYERS+1];
int		g_iCritBoostsGetting[MAXPLAYERS+1] = {0, ...};

void TeamCriticals_Proc(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_fTeamCritsRange = StringToFloat(sPieces[0]);
	g_bTeamCritsFull = StringToInt(sPieces[1]) > 0 ? true : false;

}

void TeamCriticals_Perk(int client, bool apply){

	if(apply)
		TeamCriticals_ApplyPerk(client);
	
	else
		TeamCriticals_RemovePerk(client);

}

void TeamCriticals_ApplyPerk(int client){
	
	g_bHasTeamCriticals[client] = true;
	TF2_AddCondition(client, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	g_iCritBoostsGetting[client]++;
	
	CreateTimer(0.25, Timer_DrawBeamsFor, GetClientSerial(client), TIMER_REPEAT);

}

void TeamCriticals_RemovePerk(int client){

	g_bHasTeamCriticals[client] = false;
	TF2_RemoveCondition(client, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	g_iCritBoostsGetting[client]--;
	
	for(int i = 1; i <= MaxClients; i++)
		if(g_iCritBoostEnt[client][i] > MaxClients)
			TeamCriticals_SetCritBoost(client, i, false, 0);

}

public Action Timer_DrawBeamsFor(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bHasTeamCriticals[client])
		return Plugin_Stop;
	
	TeamCriticals_DrawBeamsFor(client);
	
	return Plugin_Continue;

}

void TeamCriticals_DrawBeamsFor(int client){

	int iTeam = GetClientTeam(client);
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client)
			continue;
		
		if(!IsClientInGame(i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(!TeamCriticals_IsValidTarget(client, i, iTeam)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
		
			continue;
		
		}
		
		if(!CanEntitySeeTarget(client, i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(g_iCritBoostEnt[client][i] <= MaxClients)
			TeamCriticals_SetCritBoost(client, i, true, iTeam);
	
	}

}

bool TeamCriticals_IsValidTarget(int client, int iTrg, int iClientTeam){
	
	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTrg, fEndPos);
	
	if(GetVectorDistance(fPos, fEndPos) > g_fTeamCritsRange)
		return false;
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Cloaked))
		return false;
	
	int iEndTeam = GetClientTeam(iTrg);
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Disguised)){
	
		if(iClientTeam == iEndTeam)
			return false;
		
		else
			return true;
	
	}
	
	return (iClientTeam == iEndTeam);

}

void TeamCriticals_SetCritBoost(int client, int iTrg, bool bSet, int iTeam){

	g_iCritBoostsGetting[iTrg] += bSet ? 1 : -1;

	if(bSet){
	
		g_iCritBoostEnt[client][iTrg] = ConnectWithBeam(client, iTrg, iTeam == 2 ? 255 : 64, 64, iTeam == 2 ? 64 : 255);
	
		if(g_iCritBoostsGetting[iTrg] < 2)
			TF2_AddCondition(iTrg, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	
	}else{
	
		if(IsValidEntity(g_iCritBoostEnt[client][iTrg]))
			AcceptEntityInput(g_iCritBoostEnt[client][iTrg], "Kill");
		
		g_iCritBoostEnt[client][iTrg] = 0;
	
		if(g_iCritBoostsGetting[iTrg] < 1)
			TF2_RemoveCondition(iTrg, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	
	}

}