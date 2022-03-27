/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*************************************//
//  -  Roll The Dice: Forced Taunt  -  //
//*************************************//

bool	g_bIsForcedTaunt[MAXPLAYERS+1]	= {false, ...};
float	g_fTauntInterval				= 1.0;
bool	g_bShouldTaunt[MAXPLAYERS+1]	= {false, ...};
char	g_sSoundScoutBB[][] = {
	"items/scout_boombox_02.wav",
	"items/scout_boombox_03.wav",
	"items/scout_boombox_04.wav",
	"items/scout_boombox_05.wav"
};

void ForcedTaunt_Proc(const char[] sSettings){

	g_fTauntInterval = StringToFloat(sSettings);

}

void ForcedTaunt_Start(){

	for(int i = 0; i < sizeof(g_sSoundScoutBB); i++){
	
		PrecacheSound(g_sSoundScoutBB[i]);
	
	}

}

void ForcedTaunt_Perk(int client, bool apply){

	if(apply)
		ForcedTaunt_ApplyPerk(client);
	
	else
		g_bIsForcedTaunt[client] = false;

}

void ForcedTaunt_ApplyPerk(int client){
	
	ForceTaunt_PerformTaunt(client);

	g_bIsForcedTaunt[client] = true;

}

public Action Timer_ForceTaunt(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(g_bIsForcedTaunt[client])
		ForceTaunt_PerformTaunt(client);
	
	return Plugin_Stop;

}

void ForceTaunt_PerformTaunt(int client){

	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") > -1){
		FakeClientCommand(client, "taunt");
		return;
	}
	
	g_bShouldTaunt[client] = true;
	CreateTimer(0.1, Timer_RetryForceTaunt, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RetryForceTaunt(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bIsForcedTaunt[client])
		return Plugin_Stop;
	
	if(!g_bShouldTaunt[client])
		return Plugin_Stop;
	
	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
		return Plugin_Continue;
	
	g_bShouldTaunt[client] = false;
	FakeClientCommand(client, "taunt");
	
	return Plugin_Stop;

}

void ForcedTaunt_OnConditionAdded(int client, TFCond condition){

	if(g_bIsForcedTaunt[client] && condition == TFCond_Taunting)
		EmitSoundToAll(g_sSoundScoutBB[GetRandomInt(0, sizeof(g_sSoundScoutBB)-1)], client);

}

void ForcedTaunt_OnConditionRemoved(int client, TFCond condition){

	if(g_bIsForcedTaunt[client] && condition == TFCond_Taunting)
		CreateTimer(g_fTauntInterval, Timer_ForceTaunt, GetClientSerial(client));

}