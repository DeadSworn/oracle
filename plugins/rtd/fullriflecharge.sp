/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//******************************************//
//  -  Roll The Dice: Full Rifle Charge  -  //
//******************************************//

int		g_iSniperPrimary[MAXPLAYERS+1]	= {0, ...};
bool	g_bHasFullCharge[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasBow[MAXPLAYERS+1]			= {false, ...};

void FullRifleCharge_Start(){

	HookEvent("post_inventory_application", Event_FullRifleCharge_Resupply, EventHookMode_Post);

}

public void FullRifleCharge_Perk(int client, bool apply){

	if(apply)
		FullRifleCharge_ApplyPerk(client);
	
	else
		g_bHasFullCharge[client] = false;

}

void FullRifleCharge_ApplyPerk(int client){
	
	FullRifleCharge_SetSniperPrimary(client);
	g_bHasFullCharge[client] = true;

}

void FullRifleCharge_SetSniperPrimary(int client){

	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
	
		char sClass[32];GetEdictClassname(iWeapon, sClass, sizeof(sClass));
		if(StrContains(sClass, "tf_weapon_sniperrifle") > -1){
			
			g_iSniperPrimary[client]	= iWeapon;
			g_bHasBow[client]			= false;
		
		}else if(StrContains(sClass, "tf_weapon_compound_bow") > -1){
			
			g_iSniperPrimary[client]	= iWeapon;
			g_bHasBow[client]			= true;
		
		}
	
	}

}

void FullRifleCharge_OnConditionAdded(int client, TFCond condition){

	if(!IsValidClient(client))
		return;
	
	if(!g_bHasFullCharge[client])
		return;
	
	if(condition != TFCond_Slowed)
		return;

	if(g_iSniperPrimary[client] > MaxClients && IsValidEntity(g_iSniperPrimary[client]))
		SetEntPropFloat(
			g_iSniperPrimary[client], Prop_Send,
			g_bHasBow[client] ? "m_flChargeBeginTime"	: "m_flChargedDamage",
			g_bHasBow[client] ? GetGameTime()-1.0		: 150.0
		);

}

public void Event_FullRifleCharge_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(client))
		return;
	
	if(!g_bHasFullCharge[client])
		return;
	
	FullRifleCharge_SetSniperPrimary(client);

}