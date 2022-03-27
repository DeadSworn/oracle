/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***************************************//
//  -  Roll The Dice: Infinite Cloak  -  //
//***************************************//

bool g_bInfiniteCloak[MAXPLAYERS+1]	= {false, ...};

void InfiniteCloak_Perk(int client, bool apply){

	if(apply)
		InfiniteCloak_ApplyPerk(client);
	
	else
		g_bInfiniteCloak[client] = false;

}

void InfiniteCloak_ApplyPerk(int client){

	g_bInfiniteCloak[client] = true;
	CreateTimer(0.25, Timer_RefreshCloak, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RefreshCloak(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bInfiniteCloak[client])
		return Plugin_Stop;
	
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 105.0);
	
	return Plugin_Continue;

}