/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//****************************************//
//  -  Roll The Dice: Full Übercharge  -  //
//****************************************//

int		g_iMediGunCond[MAXPLAYERS+1]	= {-1, ...};
int		g_iMediGun[MAXPLAYERS+1]		= {INVALID_ENT_REFERENCE, ...};
bool	g_bRefreshUber[MAXPLAYERS+1]	= {false, ...};
bool	g_bUberComplete[MAXPLAYERS+1]	= {true, ...};

void FullUbercharge_Perk(int client, bool apply){

	if(apply)
		FullUbercharge_ApplyPerk(client);
	
	else
		FullUbercharge_RemovePerk(client);

}

void FullUbercharge_ApplyPerk(int client){

	int iWeapon = GetPlayerWeaponSlot(client, 1);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
	
		char sClass[20];GetEdictClassname(iWeapon, sClass, sizeof(sClass));
		if(strcmp(sClass, "tf_weapon_medigun") == 0){
		
			g_iMediGun[client]		= EntIndexToEntRef(iWeapon);
			g_bRefreshUber[client]	= true;
			g_bUberComplete[client]	= false;
			
			CreateTimer(0.2, Timer_RefreshUber, GetClientSerial(client), TIMER_REPEAT);
			
			int iWeapIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(iWeapIndex){
			
				case 35:	g_iMediGunCond[client] = view_as<int>(TFCond_Kritzkrieged);	//Kritzkrieg
				case 411:	g_iMediGunCond[client] = view_as<int>(TFCond_MegaHeal);		//Quick-Fix
				case 998:	g_iMediGunCond[client] = -1;								//Screw you, Vaccinator
				default:	g_iMediGunCond[client] = view_as<int>(TFCond_Ubercharged);	//Default
			
			}
		
		}
	
	}

}

void FullUbercharge_RemovePerk(int client){

	g_bRefreshUber[client] = false;

	if(g_iMediGunCond[client] > -1)
		CreateTimer(0.2, Timer_UberchargeEnd, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RefreshUber(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bRefreshUber[client])
		return Plugin_Stop;
	
	int iMediGun = EntRefToEntIndex(g_iMediGun[client]);
	if(iMediGun <= MaxClients)
		return Plugin_Stop;
	
	SetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel", 1.0);
	
	return Plugin_Continue;

}

public Action Timer_UberchargeEnd(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	int iMediGun = EntRefToEntIndex(g_iMediGun[client]);
	if(iMediGun <= MaxClients)
		return Plugin_Stop;
	
	if(GetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel") > 0.05)
		return Plugin_Continue;
	
	g_bUberComplete[client] = true;
	return Plugin_Stop;

}

void FullUbercharge_OnConditionRemoved(int client, TFCond cond){

	if(g_bUberComplete[client])
		return;
	
	if(view_as<int>(cond) != g_iMediGunCond[client])
		return;

	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == EntRefToEntIndex(g_iMediGun[client]))
		TF2_AddCondition(client, cond, 2.0);

}