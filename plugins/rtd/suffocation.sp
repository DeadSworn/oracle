/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//************************************//
//  -  Roll The Dice: Suffocation  -  //
//************************************//

bool	g_bIsSuffocating[MAXPLAYERS+1] = {false, ...};
float	g_fSuffocationStart		= 12.0;
float	g_fSuffocationInterval	= 1.0;
float	g_fSuffocationDamage	= 5.0;

void Suffocation_Proc(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);
	
	g_fSuffocationStart		= StringToFloat(sPieces[0]);
	g_fSuffocationInterval	= StringToFloat(sPieces[1]);
	g_fSuffocationDamage	= StringToFloat(sPieces[2]);

}

void Suffocation_Perk(int client, bool apply){

	if(apply)
		Suffocation_ApplyPerk(client);

	else
		g_bIsSuffocating[client] = false;

}

void Suffocation_ApplyPerk(client){
	
	g_bIsSuffocating[client] = true;
	
	CreateTimer(g_fSuffocationStart, Timer_Suffocation_Begin, GetClientSerial(client));

}

public Action Timer_Suffocation_Begin(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bIsSuffocating[client])
		return Plugin_Stop;

	SDKHooks_TakeDamage(client, 0, 0, g_fSuffocationDamage, DMG_DROWN);
	
	CreateTimer(g_fSuffocationInterval, Timer_Suffocation_Cont, GetClientSerial(client), TIMER_REPEAT);
	
	return Plugin_Stop;

}

public Action Timer_Suffocation_Cont(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bIsSuffocating[client])
		return Plugin_Stop;

	SDKHooks_TakeDamage(client, 0, 0, g_fSuffocationDamage, DMG_DROWN);
	
	return Plugin_Continue;

}