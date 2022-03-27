/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***********************************//
//  -  Roll The Dice: Fast Hands  -  //
//***********************************//

#define ATTRIB_RATE 6
#define ATTRIB_RELOAD 97

bool	g_bHasFastHands[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasFastHands2[MAXPLAYERS+1]	= {false, ...};
float	g_fFastHandsRateMultiplier		= 2.0;
float	g_fFastHandsReloadMultiplier	= 2.0;

void FastHands_Proc(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);
	
	g_fFastHandsRateMultiplier		= 1/StringToFloat(sPieces[0]);
	g_fFastHandsReloadMultiplier	= 1/StringToFloat(sPieces[1]);

}

void FastHands_Start(){

	HookEvent("post_inventory_application", FastHands_Resupply, EventHookMode_Post);

}

public void FastHands_OnEntityCreated(int iEnt, const char[] sClassname){

	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, FastHands_OnDroppedWeaponSpawn);

}

public void FastHands_OnDroppedWeaponSpawn(int iEnt){

	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));

	if(client == -1)
		return;
	
	if(g_bHasFastHands2[client])
		AcceptEntityInput(iEnt, "Kill");

}

void FastHands_Perk(int client, bool apply){

	if(apply)
		FastHands_ApplyPerk(client);
	
	else
		FastHands_RemovePerk(client);

}

void FastHands_ApplyPerk(int client){

	FastHands_EditClientWeapons(client, true);
	g_bHasFastHands[client]	= true;
	g_bHasFastHands2[client]= true;

}

void FastHands_RemovePerk(int client){

	FastHands_EditClientWeapons(client, false);
	g_bHasFastHands[client] = false;
	CreateTimer(0.5, Timer_FastHands_FullUnset, GetClientSerial(client));

}

public Action Timer_FastHands_FullUnset(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	
	if(client < 1)
		return Plugin_Stop;
	
	g_bHasFastHands2[client] = false;
	
	return Plugin_Stop;

}

void FastHands_EditClientWeapons(int client, bool apply){

	int iWeapon = 0;
	for(int i = 0; i < 3; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(apply){
		
			if(g_fFastHandsRateMultiplier != 0.0)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RATE, g_fFastHandsRateMultiplier);
			
			if(g_fFastHandsReloadMultiplier != 0.0)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RELOAD, g_fFastHandsReloadMultiplier);
		
		}else{
		
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RATE);
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RELOAD);
		
		}
	
	}

}

public void FastHands_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(client))
		return;
	
	if(g_bHasFastHands[client])
		FastHands_EditClientWeapons(client, true);

}