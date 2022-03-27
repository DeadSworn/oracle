/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**************************************//
//  -  Roll The Dice: Powerful Hits  -  //
//**************************************//

bool	g_bHasPowerfulHits[MAXPLAYERS+1]	= {false, ...};
float	g_fPowerFulHitsMultiplayer			= 5.0;

void PowerfulHits_Proc(const char[] sSettings){

	g_fPowerFulHitsMultiplayer = StringToFloat(sSettings);

}

void PowerfulHits_OnClientPutInServer(int client){

	SDKHook(client, SDKHook_OnTakeDamage, PowerfulHits_OnTakeDamage);

}

void PowerfulHits_Perk(int client, bool apply){

	g_bHasPowerfulHits[client] = apply;

}

public Action PowerfulHits_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype){

	if(victim == attacker)
		return Plugin_Continue;

	if(attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

	if(!IsClientInGame(attacker))
		return Plugin_Continue;

	if(!g_bHasPowerfulHits[attacker])
		return Plugin_Continue;

	damage *= g_fPowerFulHitsMultiplayer;

	return Plugin_Changed;

}